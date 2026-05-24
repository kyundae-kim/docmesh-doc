from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from io import BytesIO

from docmesh_doc.dependencies.security import get_current_user, User
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.schemas.document import DocumentUploadResponse
from docmesh_doc.services.document import DocumentService


router = APIRouter(tags=["Documents"])


def _current_username(current_user: User) -> str:
    username = getattr(current_user, "preferred_username", None) or getattr(
        current_user, "username", None
    )
    return username or current_user.sub


@router.post("/documents", response_model=DocumentUploadResponse)
async def upload_document(
    file_path: str = Form(...),
    file: UploadFile = File(...),
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = _current_username(current_user)
    stream = file.file
    stream.seek(0, 2)
    content_length = stream.tell()
    stream.seek(0)

    content_type = file.content_type or "application/octet-stream"
    document_id = document_service.upload(
        username=username,
        file_path=file_path,
        filename=file.filename,
        content_type=content_type,
        data_stream=stream,
        content_length=content_length,
    )

    return DocumentUploadResponse(file_path=file_path)


@router.get("/documents/{file_path:path}")
def download_document(
    file_path: str,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = _current_username(current_user)

    document = document_service.get(username, file_path)
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


@router.delete("/documents/{file_path:path}", status_code=status.HTTP_204_NO_CONTENT)
def delete_document(
    file_path: str,
    current_user: User = Depends(get_current_user),
    document_service: DocumentService = Depends(get_document_service),
):
    username = _current_username(current_user)

    deleted = document_service.soft_delete(username, file_path)
    if not deleted:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Document not found",
        )
