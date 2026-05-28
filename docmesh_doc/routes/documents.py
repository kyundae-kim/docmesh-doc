from io import BytesIO
from uuid import UUID

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse

from docmesh_doc.dependencies.security import User, get_current_user, get_username
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.schemas.document import DocumentUploadResponse
from docmesh_doc.services.document import DocumentService


router = APIRouter(tags=["Documents"])


@router.post(
    "/documents",
    response_model=DocumentUploadResponse,
    status_code=status.HTTP_201_CREATED,
)
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = get_username(current_user)
    stream = file.file
    stream.seek(0, 2)
    content_length = stream.tell()
    stream.seek(0)

    content_type = file.content_type or "application/octet-stream"
    document_id = document_service.upload(
        username=username,
        filename=file.filename or "uploaded.bin",
        content_type=content_type,
        data_stream=stream,
        content_length=content_length,
    )

    return DocumentUploadResponse(document_id=document_id, filename=file.filename or "uploaded.bin")


@router.get("/documents/{document_id}")
def download_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = get_username(current_user)

    document = document_service.get(username, document_id)
    if document is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )

    stream = BytesIO(document.content)

    return StreamingResponse(
        iter([stream.read()]),
        media_type=document.content_type,
        headers={
            "Content-Disposition": f'attachment; filename="{document.filename}"',
        },
    )


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: UUID,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = get_username(current_user)

    deleted = document_service.soft_delete(username, document_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )
