from __future__ import annotations

from typing import Annotated

import dms
from fastapi import APIRouter, Depends, File, Form, Query, Response, UploadFile
from fastapi.responses import StreamingResponse
from fastapi_core.dependencies import get_current_user

from docmesh_doc.dependencies import CurrentUser, DmsSdk, require_hard_delete
from docmesh_doc.document_http import (
    content_disposition,
    parse_metadata_form,
    require_readable_document,
    validate_upload_file,
)
from docmesh_doc.schemas import DeleteDocumentResponse, DocumentMetadataResponse

router = APIRouter(
    prefix="/documents",
    tags=["documents"],
    dependencies=[Depends(get_current_user)],
)


@router.post("", status_code=201, response_model=DocumentMetadataResponse)
def upload_document(
    response: Response,
    sdk: DmsSdk,
    user: CurrentUser,
    file: Annotated[UploadFile, File()],
    document_id: Annotated[str | None, Form()] = None,
    metadata: Annotated[str, Form()] = "{}",
    checksum: Annotated[str | None, Form()] = None,
) -> DocumentMetadataResponse:
    extra_metadata = parse_metadata_form(metadata)
    filename, content_type, size = validate_upload_file(file)
    request = dms.UploadDocumentStreamRequest(
        stream=file.file,
        size=size,
        filename=filename,
        content_type=content_type,
        document_id=document_id or None,
        metadata=extra_metadata,
        created_by=user.sub,
        checksum=checksum or None,
    )
    result = sdk.upload_document_stream(request)
    response.headers["Location"] = f"/documents/{result.document_id}"
    return result.metadata


@router.get("", response_model=list[DocumentMetadataResponse])
def list_documents(
    sdk: DmsSdk,
    offset: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1)] = 100,
    status: dms.DocumentStatus | None = None,
) -> list[DocumentMetadataResponse]:
    items = sdk.list_documents(offset=offset, limit=limit, status=status)
    return items


@router.get("/{document_id}", response_model=DocumentMetadataResponse)
def get_document_metadata(
    document_id: str,
    sdk: DmsSdk,
) -> DocumentMetadataResponse:
    return require_readable_document(sdk, document_id)


@router.get("/{document_id}/content")
def get_document_content(document_id: str, sdk: DmsSdk) -> Response:
    item = sdk.get_document_content(document_id)
    return Response(content=item.content, media_type=item.content_type, headers={
        "Content-Length": str(item.size),
        "Content-Disposition": content_disposition("inline", item.filename),
    })


@router.get("/{document_id}/download")
def download_document(
    document_id: str,
    sdk: DmsSdk,
    chunk_size: Annotated[int, Query(ge=1)] = 65536,
) -> StreamingResponse:
    item = sdk.get_document_content_stream(document_id, chunk_size=chunk_size)

    def body():
        with item:
            yield from item.iter_chunks()

    return StreamingResponse(body(), media_type=item.content_type, headers={
        "Content-Length": str(item.size),
        "Content-Disposition": content_disposition("attachment", item.filename),
    })


@router.delete("/{document_id}", response_model=DeleteDocumentResponse)
async def delete_document(
    document_id: str,
    sdk: DmsSdk,
    user: CurrentUser,
    hard: bool = False,
):
    if hard:
        await require_hard_delete(user)
    return (
        sdk.hard_delete_document(document_id)
        if hard
        else sdk.soft_delete_document(document_id)
    )
