from __future__ import annotations

from typing import Annotated

import dms
from fastapi import APIRouter, File, Form, Query, Response, UploadFile
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies import CurrentUser, DmsSdk
from docmesh_doc.document_http import (
    build_upload_request,
    content_disposition,
    parse_metadata_form,
    require_readable_document,
    to_metadata_response,
    validate_upload_file,
)
from docmesh_doc.schemas import DeleteDocumentResponse, DocumentMetadataResponse

router = APIRouter(prefix="/documents", tags=["documents"])


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
    request = build_upload_request(
        stream=file.file,
        size=size,
        filename=filename,
        content_type=content_type,
        document_id=document_id,
        metadata=extra_metadata,
        created_by=user.sub,
        checksum=checksum,
    )
    result = sdk.upload_document_stream(request)
    response.headers["Location"] = f"/documents/{result.document_id}"
    return to_metadata_response(result.metadata)


@router.get("", response_model=list[DocumentMetadataResponse])
def list_documents(
    sdk: DmsSdk,
    user: CurrentUser,
    offset: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1)] = 100,
    status: dms.DocumentStatus | None = None,
) -> list[DocumentMetadataResponse]:
    items = sdk.list_documents(offset=offset, limit=limit, status=status)
    return [to_metadata_response(item) for item in items]


@router.get("/{document_id}", response_model=DocumentMetadataResponse)
def get_document_metadata(document_id: str, sdk: DmsSdk, user: CurrentUser) -> DocumentMetadataResponse:
    return to_metadata_response(require_readable_document(sdk, document_id))


@router.get("/{document_id}/content")
def get_document_content(document_id: str, sdk: DmsSdk, user: CurrentUser) -> Response:
    require_readable_document(sdk, document_id)
    item = sdk.get_document_content(document_id)
    return Response(content=item.content, media_type=item.content_type, headers={
        "Content-Length": str(item.size),
        "Content-Disposition": content_disposition("inline", item.filename),
    })


@router.get("/{document_id}/download")
def download_document(
    document_id: str,
    sdk: DmsSdk,
    user: CurrentUser,
    chunk_size: Annotated[int, Query(ge=1)] = 65536,
) -> StreamingResponse:
    require_readable_document(sdk, document_id)
    item = sdk.get_document_content_stream(document_id, chunk_size=chunk_size)

    def body():
        try:
            yield from item.iter_chunks()
        finally:
            item.close()

    return StreamingResponse(body(), media_type=item.content_type, headers={
        "Content-Length": str(item.size),
        "Content-Disposition": content_disposition("attachment", item.filename),
    })


@router.delete("/{document_id}", response_model=DeleteDocumentResponse)
def delete_document(
    document_id: str,
    sdk: DmsSdk,
    user: CurrentUser,
    hard: bool = False,
):
    if hard and "document:delete:hard" not in user.roles:
        # Raised as a documented service error by the application handler.
        raise PermissionError("document:delete:hard")
    result = (
        sdk.hard_delete_document(document_id)
        if hard
        else sdk.soft_delete_document(document_id)
    )
    return DeleteDocumentResponse(
        document_id=result.document_id,
        deleted=result.deleted,
        hard_deleted=result.hard_deleted,
        status=result.status.value,
    )
