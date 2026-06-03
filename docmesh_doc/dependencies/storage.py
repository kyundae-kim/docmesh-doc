from fastapi import Depends, Request
from fastapi_core.dependencies.storage import get_minio_client as core_get_minio_client
from minio import Minio

from docmesh_doc.services.document import DocumentService


def get_minio_client(minio_client: Minio = Depends(core_get_minio_client)) -> Minio:
    return minio_client


def get_document_service(
    request: Request,
    minio_client: Minio = Depends(get_minio_client),
) -> DocumentService:
    bucket_name = request.app.state.env_config.minio.bucket
    return DocumentService(minio_client=minio_client, bucket_name=bucket_name)
