from __future__ import annotations

import json
from typing import Annotated, Any
from urllib.parse import quote

import dms
from fastapi import APIRouter, File, Form, Query, Response, UploadFile
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies import CurrentUser, DmsSdk
from docmesh_doc.errors import ErrorContract, error_response
from docmesh_doc.schemas import DeleteDocumentResponse, DocumentMetadataResponse

router = APIRouter(prefix="/documents", tags=["documents"])


def metadata_response(item: dms.DocumentMetadata) -> DocumentMetadataResponse:
    return DocumentMetadataResponse(
        document_id=item.document_id,
        original_filename=item.original_filename,
        content_type=item.content_type,
        file_size=item.file_size,
        status=item.status.value,
        created_at=item.created_at,
        updated_at=item.updated_at,
        deleted_at=item.deleted_at,
        created_by=item.created_by,
        checksum=item.checksum,
        metadata=item.extra_metadata,
    )


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
    content = file.file.read()
    filename = (file.filename or "").strip()
    content_type = (file.content_type or "").strip()
    try:
        extra_metadata: Any = json.loads(metadata)
    except json.JSONDecodeError as exc:
        raise dms.ValidationError("metadata must be valid JSON") from exc
    if not content or not filename or filename == "." or not content_type or not isinstance(extra_metadata, dict):
        raise dms.ValidationError("invalid upload")
    result = sdk.upload_document(dms.UploadDocumentRequest(
        content=content,
        filename=filename,
        content_type=content_type,
        document_id=document_id or None,
        metadata=extra_metadata,
        created_by=user.sub,
        checksum=checksum or None,
    ))
    response.headers["Location"] = f"/documents/{result.document_id}"
    return metadata_response(result.metadata)


@router.get("/{document_id}", response_model=DocumentMetadataResponse)
def get_document_metadata(document_id: str, sdk: DmsSdk, user: CurrentUser) -> DocumentMetadataResponse:
    return metadata_response(sdk.get_document_metadata(document_id))


@router.get("/{document_id}/content")
def get_document_content(document_id: str, sdk: DmsSdk, user: CurrentUser) -> Response:
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
        from fastapi import Request
        # Raised as a documented service error by the application handler.
        raise PermissionError("document:delete:hard")
    result = sdk.delete_document(document_id, hard_delete=hard)
    return DeleteDocumentResponse(
        document_id=result.document_id,
        deleted=result.deleted,
        hard_deleted=result.hard_deleted,
        status=result.status.value,
    )
