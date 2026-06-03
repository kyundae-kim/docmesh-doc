from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from minio import Minio

from docmesh_doc.dependencies.storage import get_document_service


def test_get_document_service_uses_bucket_from_config_dependency():
    config = SimpleNamespace(minio=SimpleNamespace(bucket="documents"))
    minio_client = MagicMock(spec=Minio)

    with patch("docmesh_doc.services.document.ensure_bucket_exists"):
        service = get_document_service(minio_client=minio_client, config=config)

    assert service._bucket_name == "documents"
    assert service._minio_client is minio_client
