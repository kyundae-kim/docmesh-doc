from __future__ import annotations

from typing import Annotated, Literal

import dms
from fastapi import APIRouter, Depends, File, Form, Query, Request, Response, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies import (
    DmsSdk,
)
from docmesh_doc.document_http import (
    content_disposition,
    validate_upload_file,
)
from docmesh_doc.schemas import (
    DeleteDocumentResponse,
    DocumentMetadataResponse,
    DocumentPageResponse,
    ErrorResponse,
)


DEFAULT_DOWNLOAD_CHUNK_SIZE = 64 * 1024
MAX_DOWNLOAD_CHUNK_SIZE = 8 * 1024 * 1024

_ERROR_RESPONSES = {
    400: {"model": ErrorResponse},
    403: {"model": ErrorResponse},
    404: {"model": ErrorResponse},
    413: {"model": ErrorResponse},
    500: {"model": ErrorResponse},
    503: {"model": ErrorResponse},
}


router = APIRouter(prefix="/documents", tags=["documents"])


class _DmsStreamingResponse(StreamingResponse):
    def __init__(self, *args, close_callback, **kwargs):
        super().__init__(*args, **kwargs)
        self._close_callback = close_callback
        self._closed = False

    def _close_once(self) -> None:
        if not self._closed:
            self._closed = True
            self._close_callback()

    async def __call__(self, scope, receive, send):
        try:
            await super().__call__(scope, receive, send)
        finally:
            self._close_once()


def _stream_document(
    item: dms.DocumentContentStream,
    *,
    disposition: Literal["inline", "attachment"],
) -> StreamingResponse:
    closed = False

    def close_once() -> None:
        nonlocal closed
        if not closed:
            closed = True
            item.close()

    def body():
        try:
            yield from item.iter_chunks()
        finally:
            close_once()

    return _DmsStreamingResponse(
        body(),
        media_type=item.content_type,
        close_callback=close_once,
        headers={
            "Content-Length": str(item.size),
            "Content-Disposition": content_disposition(disposition, item.filename),
        },
    )


@router.post(
    "",
    name="create_document",
    status_code=201,
    response_model=DocumentMetadataResponse,
    responses=_ERROR_RESPONSES,
)
def upload_document(
    request: Request,
    response: Response,
    sdk: DmsSdk,
    file: Annotated[UploadFile, File(...)],
    document_id: Annotated[str | None, Form()] = None,
) -> dms.PublicDocumentMetadata:
    filename, content_type, size = validate_upload_file(file)
    normalized_document_id = document_id.strip() if document_id else None
    result = sdk.upload_document_stream(
        dms.UploadDocumentStreamRequest(
            stream=file.file,
            size=size,
            filename=filename,
            content_type=content_type,
            document_id=normalized_document_id or None,
        )
    )
    response.headers["Location"] = request.url_for(
        "get_document_metadata",
        document_id=result.document_id,
    ).path
    return result.metadata


@router.get(
    "",
    name="list_documents",
    response_model=DocumentPageResponse,
    responses=_ERROR_RESPONSES,
)
def list_documents(
    sdk: DmsSdk,
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    document_status: Annotated[
        dms.DocumentStatus | None,
        Query(alias="status"),
    ] = None,
) -> dms.DocumentPage:
    return sdk.list_documents(
        cursor=cursor,
        limit=limit,
        status=document_status,
    )


@router.get(
    "/{document_id}",
    name="get_document_metadata",
    response_model=DocumentMetadataResponse,
    responses=_ERROR_RESPONSES,
)
def get_document_metadata(
    document_id: str,
    sdk: DmsSdk,
) -> dms.PublicDocumentMetadata:
    return sdk.get_document_metadata(document_id)


@router.get(
    "/{document_id}/content",
    name="get_document_content",
    responses=_ERROR_RESPONSES,
)
def get_document_content(
    document_id: str,
    sdk: DmsSdk,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(document_id)
    return _stream_document(item, disposition="inline")


@router.get(
    "/{document_id}/download",
    name="download_document",
    responses=_ERROR_RESPONSES,
)
def download_document(
    document_id: str,
    sdk: DmsSdk,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(
        document_id,
        chunk_size=chunk_size,
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
    hard: bool = Query(False),
) -> dms.DeleteDocumentResult:
    return await run_in_threadpool(
        sdk.delete_document,
        document_id,
        hard_delete=hard,
    )
