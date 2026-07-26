from typing import Annotated

import dms
from fastapi import APIRouter, Depends, File, Form, Query, Request, Response, UploadFile
from fastapi.concurrency import run_in_threadpool
from fastapi.responses import StreamingResponse
from fastapi_core.dependencies import get_current_user

from docmesh_doc.dependencies import CurrentUser, DmsSdk, require_hard_delete
from docmesh_doc.document_http import (
    content_disposition,
    parse_metadata_form,
    require_readable_document,
    validate_upload_file,
)
from docmesh_doc.schemas import (
    DeleteDocumentResponse,
    DocumentMetadataResponse,
    DocumentPageResponse,
    ErrorResponse,
)

router = APIRouter(
    prefix="/documents",
    tags=["documents"],
    dependencies=[Depends(get_current_user)],
    responses={
        400: {"model": ErrorResponse, "description": "Invalid request"},
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
    metadata: Annotated[str, Form()] = "{}",
    checksum: Annotated[str | None, Form()] = None,
) -> DocumentMetadataResponse:
    extra_metadata = parse_metadata_form(metadata)
    filename, content_type, size = validate_upload_file(file)
    result = sdk.upload_document_stream(
        dms.UploadDocumentStreamRequest(
            stream=file.file,
            size=size,
            filename=filename,
            content_type=content_type,
            document_id=document_id or None,
            metadata=extra_metadata,
            created_by=user.sub,
            checksum=checksum or None,
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
        await require_hard_delete(current_user=user)
    delete = sdk.hard_delete_document if hard else sdk.soft_delete_document
    return await run_in_threadpool(delete, document_id)
