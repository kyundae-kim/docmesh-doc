from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Request, status
from fastapi_core.dependencies.messaging import get_nats_client
from pydantic import ValidationError

from docmesh_doc.core.messaging import publish_json_event
from docmesh_doc.dependencies.metadata import get_metadata_service
from docmesh_doc.dependencies.security import User, get_current_user, get_username
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.schemas.document import DocumentMetadataRequest, DocumentMetadataResponse
from docmesh_doc.services.metadata import MetadataConflictError, MetadataService


router = APIRouter(tags=["Metadata"])


@router.post(
    "/documents/{document_id}/metadata",
    response_model=DocumentMetadataResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_metadata(
    document_id: UUID,
    request: Request,
    current_user: User = Depends(get_current_user),
    metadata_service: MetadataService = Depends(get_metadata_service),
    document_service=Depends(get_document_service),
    nats_client=Depends(get_nats_client),
):
    try:
        payload = DocumentMetadataRequest.model_validate(await request.json())
    except (ValidationError, Exception) as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    username = get_username(current_user)
    document = document_service.get(username, document_id)
    if document is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")

    try:
        record = metadata_service.create(
            username=username,
            document_id=document_id,
            filename=document.filename,
            metadata_value=payload.metadata_value,
        )
    except MetadataConflictError:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Metadata already exists")

    await publish_json_event(
        nats_client,
        "documents.metadata.created",
        {
            "document_id": str(record.document_id),
            "username": record.uploaded_by,
            "filename": record.filename,
            "metadata_value": record.metadata_value,
        },
    )

    return DocumentMetadataResponse(
        document_id=record.document_id,
        filename=record.filename,
        uploaded_by=record.uploaded_by,
        metadata_value=record.metadata_value,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )


@router.get("/documents/{document_id}/metadata", response_model=DocumentMetadataResponse)
def get_metadata(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    metadata_service: MetadataService = Depends(get_metadata_service),
    document_service=Depends(get_document_service),
):
    username = get_username(current_user)
    if document_service.get(username, document_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")

    record = metadata_service.get(username=username, document_id=document_id)
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Metadata not found")

    return DocumentMetadataResponse(
        document_id=record.document_id,
        filename=record.filename,
        uploaded_by=record.uploaded_by,
        metadata_value=record.metadata_value,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )


@router.patch("/documents/{document_id}/metadata", response_model=DocumentMetadataResponse)
async def patch_metadata(
    document_id: UUID,
    request: Request,
    current_user: User = Depends(get_current_user),
    metadata_service: MetadataService = Depends(get_metadata_service),
    document_service=Depends(get_document_service),
    nats_client=Depends(get_nats_client),
):
    try:
        payload = DocumentMetadataRequest.model_validate(await request.json())
    except (ValidationError, Exception) as e:
        raise HTTPException(status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail=str(e))
    username = get_username(current_user)
    if document_service.get(username, document_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")

    record = metadata_service.update(
        username=username,
        document_id=document_id,
        metadata_value=payload.metadata_value,
    )
    if record is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Metadata not found")

    await publish_json_event(
        nats_client,
        "documents.metadata.updated",
        {
            "document_id": str(record.document_id),
            "username": record.uploaded_by,
            "filename": record.filename,
            "metadata_value": record.metadata_value,
        },
    )

    return DocumentMetadataResponse(
        document_id=record.document_id,
        filename=record.filename,
        uploaded_by=record.uploaded_by,
        metadata_value=record.metadata_value,
        created_at=record.created_at,
        updated_at=record.updated_at,
    )


@router.delete("/documents/{document_id}/metadata", status_code=status.HTTP_204_NO_CONTENT)
async def delete_metadata(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    metadata_service: MetadataService = Depends(get_metadata_service),
    document_service=Depends(get_document_service),
    nats_client=Depends(get_nats_client),
):
    username = get_username(current_user)
    if document_service.get(username, document_id) is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Document not found")

    deleted = metadata_service.delete(username=username, document_id=document_id)
    if not deleted:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Metadata not found")
    await publish_json_event(
        nats_client,
        "documents.metadata.deleted",
        {
            "document_id": str(document_id),
            "username": username,
        },
    )
