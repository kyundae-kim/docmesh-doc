from __future__ import annotations

import json
from typing import Annotated, Any
from urllib.parse import quote

import dms
from fastapi import APIRouter, File, Form, Query, Response, UploadFile
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies import CurrentUser, DmsSdk
from docmesh_doc.schemas import DeleteDocumentResponse, DocumentMetadataResponse

router = APIRouter(prefix="/documents", tags=["documents"])


def metadata_response(item: dms.DocumentMetadata) -> DocumentMetadataResponse:
    public_item = dms.public_metadata(item)
    return DocumentMetadataResponse(
        document_id=public_item.document_id,
        original_filename=public_item.original_filename,
        content_type=public_item.content_type,
        file_size=public_item.file_size,
        status=public_item.status.value,
        created_at=public_item.created_at,
        updated_at=public_item.updated_at,
        deleted_at=public_item.deleted_at,
        created_by=public_item.created_by,
        checksum=public_item.checksum,
        metadata=public_item.extra_metadata,
    )


def require_readable_document(
    sdk: dms.DefaultDocumentManagementSDK,
    document_id: str,
) -> dms.DocumentMetadata:
    item = sdk.get_document_metadata(document_id)
    if item.status is dms.DocumentStatus.DELETED:
        raise dms.DocumentNotFoundError(document_id)
    return item


def disposition(kind: str, filename: str) -> str:
    return f"{kind}; filename*=UTF-8''{quote(filename, safe='')}"


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
    filename = (file.filename or "").strip()
    content_type = (file.content_type or "").strip()
    try:
        extra_metadata: Any = json.loads(metadata)
    except json.JSONDecodeError as exc:
        raise dms.ValidationError("metadata must be valid JSON") from exc
    size = file.size
    if size is None:
        file.file.seek(0, 2)
        size = file.file.tell()
    file.file.seek(0)
    if size <= 0 or not filename or filename == "." or not content_type or not isinstance(extra_metadata, dict):
        raise dms.ValidationError("invalid upload")
    result = sdk.upload_document_stream(dms.UploadDocumentStreamRequest(
        stream=file.file,
        size=size,
        filename=filename,
        content_type=content_type,
        document_id=document_id or None,
        metadata=extra_metadata,
        created_by=user.sub,
        checksum=checksum or None,
    ))
    response.headers["Location"] = f"/documents/{result.document_id}"
    return metadata_response(result.metadata)


@router.get("", response_model=list[DocumentMetadataResponse])
def list_documents(
    sdk: DmsSdk,
    user: CurrentUser,
    offset: Annotated[int, Query(ge=0)] = 0,
    limit: Annotated[int, Query(ge=1)] = 100,
    status: dms.DocumentStatus | None = None,
) -> list[DocumentMetadataResponse]:
    items = sdk.list_documents(offset=offset, limit=limit, status=status)
    return [metadata_response(item) for item in items]


@router.get("/{document_id}", response_model=DocumentMetadataResponse)
def get_document_metadata(document_id: str, sdk: DmsSdk, user: CurrentUser) -> DocumentMetadataResponse:
    return metadata_response(require_readable_document(sdk, document_id))


@router.get("/{document_id}/content")
def get_document_content(document_id: str, sdk: DmsSdk, user: CurrentUser) -> Response:
    require_readable_document(sdk, document_id)
    item = sdk.get_document_content(document_id)
    return Response(content=item.content, media_type=item.content_type, headers={
        "Content-Length": str(item.size),
        "Content-Disposition": disposition("inline", item.filename),
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
        "Content-Disposition": disposition("attachment", item.filename),
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
