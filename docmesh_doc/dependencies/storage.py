from fastapi import Depends, Request
from minio import Minio

from docmesh_doc.services.document import DocumentService


def get_minio_client(request: Request) -> Minio:
    return request.app.state.minio_client


def get_document_service(
    request: Request,
    minio_client: Minio = Depends(get_minio_client),
) -> DocumentService:
    bucket_name = request.app.state.env_settings.minio.bucket_name
    return DocumentService(minio_client=minio_client, bucket_name=bucket_name)
