from __future__ import annotations

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient
from minio import Minio
from minio.error import S3Error
from urllib3.exceptions import HTTPError

from docmesh_doc.application import create_application
from docmesh_doc.dms_factory import DmsRuntime, DmsSettings, create_dms_runtime

pytestmark = pytest.mark.integration

MINIO_ENDPOINT = "minio:9000"
MINIO_ACCESS_KEY = "admin"
MINIO_SECRET_KEY = "password123"


@pytest.fixture
def minio_bucket():
    client = Minio(
        MINIO_ENDPOINT,
        access_key=MINIO_ACCESS_KEY,
        secret_key=MINIO_SECRET_KEY,
        secure=False,
    )
    try:
        client.list_buckets()
    except HTTPError as error:
        pytest.skip(f"MinIO is unavailable at http://{MINIO_ENDPOINT}: {error}")
    except S3Error as error:
        pytest.fail(f"MinIO rejected the integration credentials: {error}")

    bucket_name = f"docmesh-integration-{uuid4().hex[:16]}"
    client.make_bucket(bucket_name)
    try:
        yield client, bucket_name
    finally:
        for item in client.list_objects(bucket_name, recursive=True):
            client.remove_object(bucket_name, item.object_name)
        client.remove_bucket(bucket_name)


@pytest.fixture
def integration_client(tmp_path, minio_bucket):
    _minio_client, bucket_name = minio_bucket
    settings = DmsSettings(
        metadata_backend="sqlite",
        # sqlite_path=str(tmp_path / "docmesh.sqlite3"),
        sqlite_path=":memory:",
        minio_endpoint=MINIO_ENDPOINT,
        minio_access_key=MINIO_ACCESS_KEY,
        minio_secret_key=MINIO_SECRET_KEY,
        minio_bucket=bucket_name,
        minio_secure=False,
    )
    runtime: DmsRuntime = create_dms_runtime(settings)
    try:
        with TestClient(create_application(runtime=runtime)) as client:
            yield client
    finally:
        runtime.close()


def test_sqlite_minio_http_document_lifecycle(integration_client):
    content = b"integration document"
    document_id = f"integration-{uuid4().hex}"

    uploaded = integration_client.post(
        "/documents",
        files={"file": ("integration.txt", content, "text/plain")},
        data={
            "document_id": document_id,
        },
    )

    assert uploaded.status_code == 201
    assert uploaded.json()["document_id"] == document_id
    assert uploaded.json()["file_size"] == len(content)
    assert uploaded.json()["metadata"] == {}

    metadata = integration_client.get(f"/documents/{document_id}")
    assert metadata.status_code == 200
    assert metadata.json()["original_filename"] == "integration.txt"

    content_response = integration_client.get(f"/documents/{document_id}/content")
    assert content_response.status_code == 200
    assert content_response.content == content
    assert content_response.headers["content-type"].startswith("text/plain")

    listed = integration_client.get("/documents?limit=100")
    assert listed.status_code == 200
    assert document_id in {item["document_id"] for item in listed.json()["items"]}

    deleted = integration_client.delete(f"/documents/{document_id}?hard=true")
    assert deleted.status_code == 200
    assert deleted.json()["hard_deleted"] is True

    missing = integration_client.get(f"/documents/{document_id}")
    assert missing.status_code == 404
