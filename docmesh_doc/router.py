from __future__ import annotations

import json
from collections.abc import Iterator

from dms.sdk import (
    AuthenticationError,
    ConfigurationError,
    ConsistencyError,
    DocumentNotFoundError,
    DuplicateDocumentError,
    MetadataStoreError,
    StorageError,
    UploadDocumentRequest,
    ValidationError,
)
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import Response, StreamingResponse
from fastapi_core.dependencies.auth import get_current_user, require_permissions
from fastapi_core.schemas.user import UserInfo

from .dependencies import get_dms_sdk
from .schemas import (
    DeleteDocumentResponse,
    DocumentMetadataResponse,
    ErrorPayload,
    ErrorResponse,
    HealthResponse,
    HealthServiceResponse,
    UploadDocumentResponse,
)

router = APIRouter(prefix="/documents", tags=["documents"])


def _map_dms_error(exc: Exception) -> HTTPException:
    mappings: list[tuple[type[Exception], int]] = [
        (ValidationError, status.HTTP_400_BAD_REQUEST),
        (AuthenticationError, status.HTTP_401_UNAUTHORIZED),
        (DocumentNotFoundError, status.HTTP_404_NOT_FOUND),
        (DuplicateDocumentError, status.HTTP_409_CONFLICT),
        (ConfigurationError, status.HTTP_500_INTERNAL_SERVER_ERROR),
        (StorageError, status.HTTP_500_INTERNAL_SERVER_ERROR),
        (MetadataStoreError, status.HTTP_500_INTERNAL_SERVER_ERROR),
        (ConsistencyError, status.HTTP_500_INTERNAL_SERVER_ERROR),
    ]
    for error_type, code in mappings:
        if isinstance(exc, error_type):
            raise HTTPException(
                status_code=code,
                detail=ErrorResponse(
                    error=ErrorPayload(type=exc.__class__.__name__, message=str(exc))
                ).model_dump(),
            ) from exc
    raise exc


def _to_metadata_response(metadata: object) -> DocumentMetadataResponse:
    payload = DocumentMetadataResponse.model_validate(metadata).model_dump()
    payload["status"] = getattr(metadata, "status").value
    return DocumentMetadataResponse(**payload)


def _iter_stream(content_stream: object) -> Iterator[bytes]:
    try:
        stream = content_stream.stream
        while True:
            chunk = stream.read(content_stream.chunk_size)
            if not chunk:
                break
            yield chunk
    finally:
        close = getattr(content_stream, "close", None)
        if callable(close):
            close()


@router.post(
    "",
    status_code=status.HTTP_201_CREATED,
    response_model=UploadDocumentResponse,
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 409: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
    dependencies=[Depends(require_permissions("documents:write"))],
)
async def upload_document(
    file: UploadFile = File(...),
    document_id: str | None = Form(default=None),
    content_type: str | None = Form(default=None),
    created_by: str | None = Form(default=None),
    metadata: str | None = Form(default=None),
    current_user: UserInfo = Depends(get_current_user),
    sdk=Depends(get_dms_sdk),
) -> UploadDocumentResponse:
    try:
        raw_metadata = json.loads(metadata) if metadata else {}
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=400, detail="Invalid metadata JSON") from exc

    effective_created_by = current_user.sub or current_user.username or current_user.email or created_by
    request = UploadDocumentRequest(
        content=await file.read(),
        filename=file.filename or "",
        content_type=content_type or file.content_type or "application/octet-stream",
        document_id=document_id,
        metadata=raw_metadata,
        created_by=effective_created_by,
    )

    try:
        result = sdk.upload_document(request)
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)

    return UploadDocumentResponse(
        document_id=result.document_id,
        storage_key=result.storage_key,
        created=result.created,
        metadata=_to_metadata_response(result.metadata),
    )


@router.get(
    "/{document_id}/metadata",
    response_model=DocumentMetadataResponse,
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
    dependencies=[Depends(require_permissions("documents:read"))],
)
def get_document_metadata(document_id: str, sdk=Depends(get_dms_sdk), _: UserInfo = Depends(get_current_user)) -> DocumentMetadataResponse:
    try:
        metadata = sdk.get_document_metadata(document_id)
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)
    return _to_metadata_response(metadata)


@router.get(
    "/{document_id}/content",
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
    dependencies=[Depends(require_permissions("documents:read"))],
)
def get_document_content(document_id: str, sdk=Depends(get_dms_sdk), _: UserInfo = Depends(get_current_user)) -> Response:
    try:
        content = sdk.get_document_content(document_id)
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)

    headers = {
        "Content-Disposition": f'attachment; filename="{content.filename}"',
    }
    if content.checksum:
        headers["ETag"] = content.checksum
    return Response(content=content.content, media_type=content.content_type, headers=headers)


@router.get(
    "/{document_id}/stream",
    responses={400: {"model": ErrorResponse}, 401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
    dependencies=[Depends(require_permissions("documents:read"))],
)
def stream_document_content(
    document_id: str,
    chunk_size: int = 65536,
    sdk=Depends(get_dms_sdk),
    _: UserInfo = Depends(get_current_user),
) -> StreamingResponse:
    try:
        content_stream = sdk.get_document_content_stream(document_id, chunk_size=chunk_size)
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)

    headers = {
        "Content-Disposition": f'attachment; filename="{content_stream.filename}"',
    }
    if content_stream.checksum:
        headers["ETag"] = content_stream.checksum
    return StreamingResponse(
        _iter_stream(content_stream),
        media_type=content_stream.content_type,
        headers=headers,
    )


@router.delete(
    "/{document_id}",
    response_model=DeleteDocumentResponse,
    responses={401: {"model": ErrorResponse}, 404: {"model": ErrorResponse}, 500: {"model": ErrorResponse}},
    dependencies=[Depends(require_permissions("documents:delete"))],
)
def delete_document(
    document_id: str,
    hard_delete: bool = False,
    sdk=Depends(get_dms_sdk),
    _: UserInfo = Depends(get_current_user),
) -> DeleteDocumentResponse:
    try:
        result = sdk.delete_document(document_id, hard_delete=hard_delete)
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)

    return DeleteDocumentResponse(
        document_id=result.document_id,
        deleted=result.deleted,
        hard_deleted=result.hard_deleted,
        status=result.status.value,
    )


@router.get("/health", response_model=HealthResponse)
def get_documents_health(sdk=Depends(get_dms_sdk)) -> HealthResponse:
    try:
        health = sdk.check_health()
    except Exception as exc:  # pragma: no cover - exercised through tests
        _map_dms_error(exc)

    return HealthResponse(
        ok=health.ok,
        checked_at=health.checked_at,
        services=[
            HealthServiceResponse(
                service=service.service,
                ok=service.ok,
                latency_ms=service.latency_ms,
                error=service.error,
            )
            for service in health.services
        ],
    )
