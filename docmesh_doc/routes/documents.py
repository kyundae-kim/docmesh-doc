import json
import os
from tempfile import NamedTemporaryFile
from uuid import UUID

from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from fastapi_core.dependencies.messaging import get_nats_client
from starlette.background import BackgroundTask

from docmesh_doc.core.messaging import publish_json_event
from docmesh_doc.dependencies.metadata import get_metadata_service
from docmesh_doc.dependencies.security import User, get_current_user, get_username
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.schemas.document import DocumentUploadResponse
from docmesh_doc.services.document import DocumentService
from docmesh_doc.services.metadata import MetadataService


router = APIRouter(tags=["Documents"])


@router.post(
    "/documents",
    response_model=DocumentUploadResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_document(
    file: UploadFile = File(...),
    metadata_value: str | None = Form(None),
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
    metadata_service: MetadataService = Depends(get_metadata_service),
    nats_client=Depends(get_nats_client),
):
    parsed_metadata: dict | None = None
    filename = file.filename or "uploaded.bin"
    if metadata_value is not None:
        try:
            parsed_metadata = json.loads(metadata_value)
        except json.JSONDecodeError as exc:
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="metadata_value must be a valid JSON object",
            ) from exc
        if not isinstance(parsed_metadata, dict):
            raise HTTPException(
                status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
                detail="metadata_value must be a JSON object",
            )

    username = get_username(current_user)
    stream = file.file
    stream.seek(0, 2)
    content_length = stream.tell()
    stream.seek(0)

    content_type = file.content_type or "application/octet-stream"
    document_id = document_service.upload(
        username=username,
        filename=filename,
        content_type=content_type,
        data_stream=stream,
        content_length=content_length,
    )

    metadata_service.create(
        username=username,
        document_id=document_id,
        filename=filename,
        metadata_value=parsed_metadata or {},
    )
    await publish_json_event(
        nats_client,
        "documents.file.created",
        {
            "document_id": str(document_id),
            "username": username,
            "filename": filename,
            "metadata_value": parsed_metadata or {},
        },
    )

    return DocumentUploadResponse(
        document_id=document_id,
        filename=filename,
        metadata_value=parsed_metadata,
    )


@router.get("/documents/{document_id}")
def download_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
    metadata_service: MetadataService = Depends(get_metadata_service),
):
    username = get_username(current_user)

    document = document_service.get(username, document_id)
    if document is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )

    metadata_record = metadata_service.get(username=username, document_id=document_id)
    download_filename = metadata_record.filename if metadata_record is not None else document.filename
    temp_file = NamedTemporaryFile(delete=False)
    try:
        temp_file.write(document.content)
        temp_file.flush()
    finally:
        temp_file.close()

    return FileResponse(
        path=temp_file.name,
        media_type=document.content_type,
        filename=download_filename,
        background=BackgroundTask(os.unlink, temp_file.name),
    )


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
    nats_client=Depends(get_nats_client),
):
    username = get_username(current_user)

    deleted = document_service.soft_delete(username, document_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )
    await publish_json_event(
        nats_client,
        "documents.file.deleted",
        {
            "document_id": str(document_id),
            "username": username,
        },
    )
