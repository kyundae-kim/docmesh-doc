from typing import Annotated, Any, Literal

import dms
from fastapi import APIRouter, Depends, File, Form, Query, Request, Response, UploadFile
from fastapi.responses import StreamingResponse
from fastapi_core import ManagedStreamingResponse, invoke_resource
from fastapi_core.dependencies import get_current_user
from pydantic import Json

from docmesh_doc.dependencies import CurrentUser, DmsSdk, require_hard_delete
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


def _stream_document(
    item: dms.DocumentContentStream,
    *,
    disposition: Literal["inline", "attachment"],
) -> StreamingResponse:
    return ManagedStreamingResponse(
        item.iter_chunks(),
        resource=item,
        media_type=item.content_type,
        headers={
            "Content-Length": str(item.size),
            "Content-Disposition": content_disposition(disposition, item.filename),
        },
    )


router = APIRouter(
    prefix="/documents",
    tags=["documents"],
    dependencies=[Depends(get_current_user)],
    responses={
        "default": {"model": ErrorResponse, "description": "Request failed"},
    },
)


@router.post("", status_code=201, response_model=DocumentMetadataResponse)
def upload_document(
    request: Request,
    response: Response,
    sdk: DmsSdk,
    user: CurrentUser,
    file: Annotated[UploadFile, File()],
    document_id: Annotated[str | None, Form()] = None,
    metadata: Annotated[Json[dict[str, Any]], Form()] = "{}",
) -> DocumentMetadataResponse:
    filename, content_type, size = validate_upload_file(file)
    result = sdk.upload_document_stream(
        dms.UploadDocumentStreamRequest(
            stream=file.file,
            size=size,
            filename=filename,
            content_type=content_type,
            document_id=document_id or None,
            metadata=metadata,
            created_by=user.sub,
        )
    )
    response.headers["Location"] = request.url_for(
        "get_document_metadata", document_id=result.document_id
    ).path
    return result.metadata


@router.get("", response_model=DocumentPageResponse)
def list_documents(
    sdk: DmsSdk,
    cursor: str | None = None,
    limit: Annotated[int, Query(ge=1, le=1000)] = 100,
    status: dms.DocumentStatus | None = None,
) -> dms.DocumentPage:
    return sdk.list_documents(cursor=cursor, limit=limit, status=status)


@router.get("/{document_id}", response_model=DocumentMetadataResponse)
def get_document_metadata(
    document_id: str,
    sdk: DmsSdk,
) -> DocumentMetadataResponse:
    return sdk.get_document_metadata(document_id)


@router.get("/{document_id}/content")
def get_document_content(document_id: str, sdk: DmsSdk) -> StreamingResponse:
    item = sdk.get_document_content_stream(document_id)
    return _stream_document(item, disposition="inline")


@router.get("/{document_id}/download")
def download_document(
    document_id: str,
    sdk: DmsSdk,
    chunk_size: Annotated[
        int,
        Query(ge=1, le=MAX_DOWNLOAD_CHUNK_SIZE),
    ] = DEFAULT_DOWNLOAD_CHUNK_SIZE,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(document_id, chunk_size=chunk_size)
    return _stream_document(item, disposition="attachment")


@router.delete("/{document_id}", response_model=DeleteDocumentResponse)
async def delete_document(
    document_id: str,
    sdk: DmsSdk,
    user: CurrentUser,
    hard: bool = False,
):
    if hard:
        await require_hard_delete(current_user=user)
    return await invoke_resource(
        sdk.delete_document,
        document_id,
        hard_delete=hard,
    )
