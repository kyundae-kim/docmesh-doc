from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import Response

from docmesh_doc.dependencies.security import get_current_user, User
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.schemas.document import DocumentUploadResponse
from docmesh_doc.services.document import DocumentService


router = APIRouter(tags=["Documents"])


@router.post("/documents", response_model=DocumentUploadResponse)
async def upload_document(
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    _ = current_user

    content = await file.read()
    content_type = file.content_type or "application/octet-stream"
    document_id = document_service.upload(
        filename=file.filename,
        content_type=content_type,
        content=content,
    )

    return DocumentUploadResponse(document_id=document_id)


@router.get("/documents/{document_id}")
def download_document(
    document_id: str,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    _ = current_user

    document = document_service.get(document_id)
    if document is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )

    return Response(
        content=document.content,
        media_type=document.content_type,
        headers={
            "Content-Disposition": f'attachment; filename="{document.filename}"',
        },
    )


@router.delete("/documents/{document_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    document_id: str,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    _ = current_user

    deleted = document_service.soft_delete(document_id)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )

    return Response(status_code=status.HTTP_204_NO_CONTENT)
