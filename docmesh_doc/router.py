from __future__ import annotations

import inspect
import shutil
import tempfile
from collections.abc import Callable
from pathlib import Path
from typing import Annotated, Any, Literal

import dms
from fastapi import APIRouter, File, Form, Query, Request, Response, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies import DmsApplicationContext, DmsContext, DmsSdk
from docmesh_doc.document_http import (
    content_disposition,
    decode_base64_content,
    parse_metadata,
    validate_upload_file,
)
from docmesh_doc.schemas import (
    BatchReconciliationResponse,
    BytesUploadRequest,
    DataResetResponse,
    DeleteDocumentResponse,
    DocumentInspectionResponse,
    DocumentItemsResponse,
    DocumentMetadataResponse,
    DocumentPageResponse,
    ErrorResponse,
    ExecuteReconciliationPlanRequest,
    InternalDocumentItemsResponse,
    InternalDocumentMetadataResponse,
    ReconcileDocumentRequest,
    ReconcileDocumentsRequest,
    ReconciliationResultResponse,
    UploadDocumentResponse,
    UploadOperationResponse,
)

DEFAULT_DOWNLOAD_CHUNK_SIZE = 64 * 1024
MAX_DOWNLOAD_CHUNK_SIZE = 8 * 1024 * 1024
COPY_SPOOL_MEMORY_LIMIT = 8 * 1024 * 1024

_ERROR_RESPONSES: dict[int | str, dict[str, Any]] = {
    400: {"model": ErrorResponse},
    403: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    413: {"model": ErrorResponse},
    409: {"model": ErrorResponse},
    425: {"model": ErrorResponse},
    500: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}

_BINARY_RESPONSES: dict[int | str, dict[str, Any]] = {
    200: {
        "description": "Document content",
        "content": {
            "application/octet-stream": {
                "schema": {"type": "string", "format": "binary"},
            },
        },
        "headers": {
            "Content-Length": {"schema": {"type": "integer"}},
            "Content-Disposition": {"schema": {"type": "string"}},
            "X-Document-Checksum": {"schema": {"type": "string"}},
        },
    },
    **_ERROR_RESPONSES,
}

_UPLOAD_RESPONSES: dict[int | str, dict[str, Any]] = {
    200: {"model": UploadDocumentResponse},
    **_ERROR_RESPONSES,
}

_COPY_RESPONSES: dict[int | str, dict[str, Any]] = {
    **_BINARY_RESPONSES,
    200: {
        **_BINARY_RESPONSES[200],
        "headers": {
            **_BINARY_RESPONSES[200]["headers"],
            "X-Checksum-Verified": {"schema": {"type": "string"}},
        },
    },
}


router = APIRouter(prefix="/documents", tags=["documents"])
upload_operations_router = APIRouter(
    prefix="/upload-operations",
    tags=["upload-operations"],
)
management_router = APIRouter(prefix="/management", tags=["management"])
API_ROUTERS: tuple[APIRouter, ...] = (
    router,
    upload_operations_router,
    management_router,
)
API_ROUTE_PREFIXES: tuple[str, ...] = tuple(
    api_router.prefix for api_router in API_ROUTERS
)


class _DmsStreamingResponse(StreamingResponse):
    def __init__(self, *args, close_callback: Callable[[], object], **kwargs):
        super().__init__(*args, **kwargs)
        self._close_callback = close_callback

    async def _close(self) -> None:
        result = await run_in_threadpool(self._close_callback)
        if inspect.isawaitable(result):
            await result

    async def __call__(self, scope, receive, send):
        try:
            await super().__call__(scope, receive, send)
        finally:
            await self._close()


def _content_headers(
    *,
    disposition: Literal["inline", "attachment"],
    filename: str,
    size: int,
    checksum: str | None,
) -> dict[str, str]:
    headers = {
        "Content-Length": str(size),
        "Content-Disposition": content_disposition(disposition, filename),
    }
    if checksum is not None:
        headers["X-Document-Checksum"] = checksum
    return headers


def _stream_document(
    item: dms.DocumentContentStream,
    *,
    disposition: Literal["inline", "attachment"],
) -> StreamingResponse:
    def body():
        yield from item.iter_chunks_closing()

    headers = _content_headers(
        disposition=disposition,
        filename=item.filename,
        size=item.size,
        checksum=item.checksum,
    )
    return _DmsStreamingResponse(
        body(),
        media_type=item.content_type,
        close_callback=item.close,
        headers=headers,
    )


def _stream_async_document(
    item: dms.AsyncDocumentContentStream,
    *,
    disposition: Literal["inline", "attachment"],
) -> StreamingResponse:
    async def body():
        async for chunk in item.aiter_chunks_closing():
            yield chunk

    headers = _content_headers(
        disposition=disposition,
        filename=item.filename,
        size=item.size,
        checksum=item.checksum,
    )
    return _DmsStreamingResponse(
        body(),
        media_type=item.content_type,
        close_callback=item.aclose,
        headers=headers,
    )


def _stream_document_chunks(
    chunks,
    *,
    metadata: dms.PublicDocumentMetadata,
) -> StreamingResponse:
    close = getattr(chunks, "close", None)

    def close_chunks() -> None:
        if close is not None:
            close()

    def body():
        yield from chunks

    headers = _content_headers(
        disposition="inline",
        filename=metadata.original_filename,
        size=metadata.file_size,
        checksum=metadata.checksum,
    )
    return _DmsStreamingResponse(
        body(),
        media_type=metadata.content_type,
        close_callback=close_chunks,
        headers=headers,
    )


def _upload_response(
    result: dms.UploadDocumentResult,
) -> UploadDocumentResponse:
    metadata = DocumentMetadataResponse.model_validate(result.metadata)
    return UploadDocumentResponse(
        **metadata.model_dump(),
        created=result.created,
    )


def _set_upload_headers(
    request: Request,
    response: Response,
    result: dms.UploadDocumentResult,
) -> None:
    response.status_code = 201 if result.created else 200
    response.headers["Location"] = request.url_for(
        "get_document_metadata",
        document_id=result.document_id,
    ).path


@router.post(
    "",
    name="create_document",
    status_code=201,
    response_model=UploadDocumentResponse,
    responses=_UPLOAD_RESPONSES,
)
def upload_document(
    request: Request,
    response: Response,
    sdk: DmsSdk,
    context: DmsContext,
    file: Annotated[UploadFile, File(...)],
    document_id: Annotated[str | None, Form()] = None,
    metadata: Annotated[str | None, Form()] = None,
    created_by: Annotated[str | None, Form()] = None,
) -> UploadDocumentResponse:
    filename, content_type, size = validate_upload_file(file)
    normalized_document_id = document_id.strip() if document_id else None
    result = sdk.upload_document_stream(
        dms.UploadDocumentStreamRequest(
            stream=file.file,
            size=size,
            filename=filename,
            content_type=content_type,
            document_id=normalized_document_id or None,
            metadata=parse_metadata(metadata),
            created_by=created_by,
        ),
        partition=context.partition,
        access_context=context.access_context,
    )
    _set_upload_headers(request, response, result)
    return _upload_response(result)


@router.post(
    "/bytes",
    name="create_document_from_bytes",
    status_code=201,
    response_model=UploadDocumentResponse,
    responses=_UPLOAD_RESPONSES,
)
def upload_document_bytes(
    payload: BytesUploadRequest,
    request: Request,
    response: Response,
    sdk: DmsSdk,
    context: DmsContext,
) -> UploadDocumentResponse:
    result = sdk.upload_document(
        dms.UploadDocumentRequest(
            content=decode_base64_content(payload.content_base64),
            filename=payload.filename,
            content_type=payload.content_type,
            document_id=payload.document_id,
            metadata=payload.metadata,
            created_by=payload.created_by,
            checksum=payload.checksum,
            idempotency_key=payload.idempotency_key,
            idempotency_scope=(
                context.user_id
                if payload.idempotency_scope is None
                else payload.idempotency_scope
            ),
        ),
        partition=context.partition,
        access_context=context.access_context,
    )
    _set_upload_headers(request, response, result)
    return _upload_response(result)


@router.post(
    "/file",
    name="create_document_from_file",
    status_code=201,
    response_model=UploadDocumentResponse,
    responses=_UPLOAD_RESPONSES,
)
def upload_document_file(
    request: Request,
    response: Response,
    sdk: DmsSdk,
    context: DmsContext,
    file: Annotated[UploadFile, File(...)],
    document_id: Annotated[str | None, Form()] = None,
    metadata: Annotated[str | None, Form()] = None,
    created_by: Annotated[str | None, Form()] = None,
) -> UploadDocumentResponse:
    filename, content_type, _size = validate_upload_file(file)
    path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix="docmesh-upload-",
            suffix=Path(filename).suffix,
            delete=False,
        ) as temporary:
            path = Path(temporary.name)
            shutil.copyfileobj(file.file, temporary)
        assert path is not None
        result = sdk.upload_file(
            path,
            filename=filename,
            content_type=content_type,
            document_id=document_id.strip() if document_id else None,
            metadata=parse_metadata(metadata),
            created_by=created_by,
            partition=context.partition,
            access_context=context.access_context,
        )
    finally:
        if path is not None:
            path.unlink(missing_ok=True)
    _set_upload_headers(request, response, result)
    return _upload_response(result)


def _list_documents(
    list_method: Callable[..., dms.DocumentPage],
    *,
    cursor: str | None,
    limit: int,
    document_status: dms.DocumentStatus | None,
    context: DmsApplicationContext,
) -> dms.DocumentPage:
    return list_method(
        cursor=cursor,
        limit=limit,
        status=document_status,
        partition=context.partition,
        access_context=context.access_context,
    )


@router.get(
    "",
    name="list_documents",
    response_model=DocumentPageResponse,
    responses=_ERROR_RESPONSES,
)
def list_documents(
    sdk: DmsSdk,
    context: DmsContext,
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    document_status: Annotated[
        dms.DocumentStatus | None,
        Query(alias="status"),
    ] = None,
) -> dms.DocumentPage:
    return _list_documents(
        sdk.list_documents,
        cursor=cursor,
        limit=limit,
        document_status=document_status,
        context=context,
    )


@router.get(
    "/page",
    name="list_documents_page",
    response_model=DocumentPageResponse,
    responses=_ERROR_RESPONSES,
)
def list_documents_page(
    sdk: DmsSdk,
    context: DmsContext,
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    document_status: Annotated[
        dms.DocumentStatus | None,
        Query(alias="status"),
    ] = None,
) -> dms.DocumentPage:
    return _list_documents(
        sdk.list_documents_page,
        cursor=cursor,
        limit=limit,
        document_status=document_status,
        context=context,
    )


@router.get(
    "/iterator",
    name="iterate_documents",
    response_model=DocumentItemsResponse,
    responses=_ERROR_RESPONSES,
)
def iterate_documents(
    sdk: DmsSdk,
    context: DmsContext,
    page_size: Annotated[int, Query(ge=1, le=1000)] = 100,
    document_status: Annotated[
        dms.DocumentStatus | None,
        Query(alias="status"),
    ] = None,
) -> dict[str, object]:
    return {
        "items": list(
            sdk.iter_documents(
                status=document_status,
                page_size=page_size,
                partition=context.partition,
                access_context=context.access_context,
            )
        )
    }


@router.get(
    "/{document_id}",
    name="get_document_metadata",
    response_model=DocumentMetadataResponse,
    responses=_ERROR_RESPONSES,
)
def get_document_metadata(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.PublicDocumentMetadata:
    return sdk.get_document_metadata(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )


@router.get(
    "/{document_id}/content",
    name="get_document_content",
    response_class=StreamingResponse,
    responses=_BINARY_RESPONSES,
)
def get_document_content(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )
    return _stream_document(item, disposition="inline")


@router.get(
    "/{document_id}/download",
    name="download_document",
    response_class=StreamingResponse,
    responses=_BINARY_RESPONSES,
)
def download_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(
        document_id,
        chunk_size=chunk_size,
        partition=context.partition,
        access_context=context.access_context,
    )
    return _stream_document(item, disposition="attachment")


@router.delete(
    "/{document_id}",
    name="delete_document",
    response_model=DeleteDocumentResponse,
    responses=_ERROR_RESPONSES,
)
async def delete_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
    hard: bool = Query(False),
) -> dms.DeleteDocumentResult:
    return await run_in_threadpool(
        sdk.delete_document,
        document_id,
        hard_delete=hard,
        partition=context.partition,
        access_context=context.access_context,
    )


@router.get(
    "/{document_id}/content/eager",
    name="get_document_content_eager",
    response_class=Response,
    responses=_BINARY_RESPONSES,
)
def get_document_content_eager(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> Response:
    item = sdk.get_document_content(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )
    headers = _content_headers(
        disposition="inline",
        filename=item.filename,
        size=item.size,
        checksum=item.checksum,
    )
    return Response(
        content=item.content,
        media_type=item.content_type,
        headers=headers,
    )


@router.get(
    "/{document_id}/content/async",
    name="get_document_content_async_stream",
    response_class=StreamingResponse,
    responses=_BINARY_RESPONSES,
)
async def get_document_content_async_stream(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
) -> StreamingResponse:
    item = await sdk.get_document_content_async_stream(
        document_id,
        chunk_size=chunk_size,
        partition=context.partition,
        access_context=context.access_context,
    )
    return _stream_async_document(item, disposition="inline")


@router.get(
    "/{document_id}/chunks",
    name="iterate_document_chunks",
    response_class=StreamingResponse,
    responses=_BINARY_RESPONSES,
)
def iterate_document_chunks(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
) -> StreamingResponse:
    metadata = sdk.get_document_metadata(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )
    chunks = sdk.iter_document_chunks(
        document_id,
        chunk_size=chunk_size,
        partition=context.partition,
        access_context=context.access_context,
    )
    return _stream_document_chunks(chunks, metadata=metadata)


@router.get(
    "/{document_id}/copy",
    name="copy_document",
    response_class=StreamingResponse,
    responses=_COPY_RESPONSES,
)
def copy_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
    verify_checksum: bool = True,
) -> StreamingResponse:
    metadata = sdk.get_document_metadata(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )
    sink = tempfile.SpooledTemporaryFile(  # noqa: SIM115 - response owns sink
        max_size=COPY_SPOOL_MEMORY_LIMIT,
        mode="w+b",
    )
    try:
        result = sdk.copy_document_to(
            document_id,
            sink,
            chunk_size=chunk_size,
            verify_checksum=verify_checksum,
            partition=context.partition,
            access_context=context.access_context,
        )
        sink.seek(0)
    except BaseException:
        sink.close()
        raise

    item = dms.DocumentContentStream(
        document_id=document_id,
        stream=sink,
        content_type=metadata.content_type,
        filename=metadata.original_filename,
        size=result.bytes_copied,
        checksum=result.checksum,
        chunk_size=chunk_size,
    )
    response = _stream_document(item, disposition="attachment")
    response.headers["X-Document-Checksum"] = result.checksum
    response.headers["X-Checksum-Verified"] = str(result.checksum_verified).lower()
    return response


@router.delete(
    "/{document_id}/soft",
    name="soft_delete_document",
    response_model=DeleteDocumentResponse,
    responses=_ERROR_RESPONSES,
)
def soft_delete_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DeleteDocumentResult:
    return sdk.soft_delete_document(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )


@router.delete(
    "/{document_id}/hard",
    name="hard_delete_document",
    response_model=DeleteDocumentResponse,
    responses=_ERROR_RESPONSES,
)
def hard_delete_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DeleteDocumentResult:
    return sdk.hard_delete_document(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )


@upload_operations_router.get(
    "/{idempotency_key}",
    name="get_upload_operation",
    response_model=UploadOperationResponse,
    responses=_ERROR_RESPONSES,
)
def get_upload_operation(
    idempotency_key: str,
    sdk: DmsSdk,
    context: DmsContext,
    scope: str | None = None,
) -> dms.UploadOperationResult:
    resolved_scope = context.user_id if scope is None else scope
    return sdk.get_upload_operation(
        idempotency_key=idempotency_key,
        scope=resolved_scope,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.get(
    "/documents/{document_id}/metadata",
    name="get_internal_document_metadata",
    response_model=InternalDocumentMetadataResponse,
    responses=_ERROR_RESPONSES,
)
def get_internal_document_metadata(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DocumentMetadata:
    return sdk.get_internal_document_metadata(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.get(
    "/documents/{document_id}/inspection",
    name="inspect_document",
    response_model=DocumentInspectionResponse,
    responses=_ERROR_RESPONSES,
)
def inspect_document(
    document_id: str,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DocumentInspection:
    return sdk.inspect_document(
        document_id,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.get(
    "/recovery-candidates",
    name="list_recovery_candidates",
    response_model=InternalDocumentItemsResponse,
    responses=_ERROR_RESPONSES,
)
def list_recovery_candidates(
    sdk: DmsSdk,
    context: DmsContext,
    status: dms.DocumentStatus,
    offset: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
) -> dict[str, object]:
    return {
        "items": sdk.list_recovery_candidates(
            status=status,
            offset=offset,
            limit=limit,
            partition=context.partition,
            access_context=context.access_context,
        )
    }


@management_router.get(
    "/recovery-candidates/iterator",
    name="iterate_recovery_candidates",
    response_model=InternalDocumentItemsResponse,
    responses=_ERROR_RESPONSES,
)
def iterate_recovery_candidates(
    sdk: DmsSdk,
    context: DmsContext,
    status: dms.DocumentStatus,
    page_size: Annotated[int, Query(ge=1, le=1000)] = 100,
) -> dict[str, object]:
    return {
        "items": list(
            sdk.iter_recovery_candidates(
                status=status,
                page_size=page_size,
                partition=context.partition,
                access_context=context.access_context,
            )
        )
    }


@management_router.post(
    "/documents/{document_id}/reconciliations",
    name="reconcile_document",
    response_model=ReconciliationResultResponse,
    responses=_ERROR_RESPONSES,
)
def reconcile_document(
    document_id: str,
    payload: ReconcileDocumentRequest,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.ReconciliationResult:
    return sdk.reconcile_document(
        document_id,
        payload.action,
        storage_key=payload.storage_key,
        dry_run=payload.dry_run,
        actor=payload.actor,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.post(
    "/reconciliations",
    name="reconcile_documents",
    response_model=BatchReconciliationResponse,
    responses=_ERROR_RESPONSES,
)
def reconcile_documents(
    payload: ReconcileDocumentsRequest,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.BatchReconciliationResult:
    return sdk.reconcile_documents(
        status=payload.status,
        action=payload.action,
        offset=payload.offset,
        limit=payload.limit,
        dry_run=payload.dry_run,
        actor=payload.actor,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.post(
    "/reconciliation-plans/executions",
    name="execute_reconciliation_plan",
    response_model=BatchReconciliationResponse,
    responses=_ERROR_RESPONSES,
)
def execute_reconciliation_plan(
    payload: ExecuteReconciliationPlanRequest,
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.BatchReconciliationResult:
    try:
        plan = dms.ReconciliationPlan(
            partition=context.partition,
            status=payload.status,
            action=payload.action,
            items=tuple(
                dms.ReconciliationPlanItem(
                    document_id=item.document_id,
                    action=item.action,
                    storage_key=item.storage_key,
                )
                for item in payload.items
            ),
        )
    except ValueError as error:
        raise dms.ValidationError(str(error)) from error
    return sdk.execute_reconciliation_plan(
        plan,
        actor=payload.actor,
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.delete(
    "/data",
    name="clear_all_data",
    response_model=DataResetResponse,
    responses=_ERROR_RESPONSES,
)
def clear_all_data(sdk: DmsSdk, context: DmsContext) -> dms.DataResetResult:
    return sdk.clear_all_data(access_context=context.access_context)


@management_router.delete(
    "/data/partition",
    name="clear_partition_data",
    response_model=DataResetResponse,
    responses=_ERROR_RESPONSES,
)
def clear_partition_data(sdk: DmsSdk, context: DmsContext) -> dms.DataResetResult:
    return sdk.clear_partition_data(
        partition=context.partition,
        access_context=context.access_context,
    )


@management_router.post(
    "/data/initializations",
    name="initialize_for_data_load",
    response_model=DataResetResponse,
    responses=_ERROR_RESPONSES,
)
def initialize_for_data_load(
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DataResetResult:
    return sdk.initialize_for_data_load(access_context=context.access_context)


@management_router.post(
    "/data/partition/initializations",
    name="initialize_partition_for_data_load",
    response_model=DataResetResponse,
    responses=_ERROR_RESPONSES,
)
def initialize_partition_for_data_load(
    sdk: DmsSdk,
    context: DmsContext,
) -> dms.DataResetResult:
    return sdk.initialize_partition_for_data_load(
        partition=context.partition,
        access_context=context.access_context,
    )
