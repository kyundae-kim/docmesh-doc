import json
from uuid import UUID

import pytest
from fastapi.testclient import TestClient
from minio.error import S3Error

from docmesh_doc import factory
from docmesh_doc.dependencies.security import User, get_current_user


TEST_USERNAME = "test"
CREATED_DOCUMENT_IDS: list[UUID] = []


@pytest.fixture(scope="module")
def app():
    app = factory.create_app()
    app.dependency_overrides[get_current_user] = lambda: User(
        sub=TEST_USERNAME,
        username=TEST_USERNAME,
        roles=["create", "read", "delete"],
        scopes=["profile"],
    )
    with TestClient(app) as client:
        minio_client = client.app.state.minio_client
        bucket_name = client.app.state.env_config.minio.bucket

        try:
            minio_client.bucket_exists(bucket_name)
        except Exception as exc:
            pytest.skip(f"MinIO is not reachable for integration tests: {exc}")

        yield client

        for document_id in CREATED_DOCUMENT_IDS:
            object_key = f"{TEST_USERNAME}/{document_id}"
            try:
                minio_client.remove_object(bucket_name, object_key)
            except S3Error:
                pass
        CREATED_DOCUMENT_IDS.clear()


def test_upload_and_download_document(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("example.txt", b"hello docmesh", "text/plain")},
    )

    assert upload_response.status_code == 201
    payload = upload_response.json()
    assert "document_id" in payload

    document_id = UUID(payload["document_id"])
    CREATED_DOCUMENT_IDS.append(document_id)
    assert payload["filename"] == "example.txt"
    assert payload["metadata_value"] is None

    metadata_response = app.get(f"/documents/{document_id}/metadata")
    assert metadata_response.status_code == 200
    assert metadata_response.json()["filename"] == "example.txt"
    assert metadata_response.json()["uploaded_by"] == TEST_USERNAME
    assert metadata_response.json()["metadata_value"] == {}

    download_response = app.get(f"/documents/{document_id}")

    assert download_response.status_code == 200
    assert download_response.content == b"hello docmesh"
    assert download_response.headers["content-type"].startswith("text/plain")
    assert download_response.headers["content-length"] == str(len(b"hello docmesh"))
    assert download_response.headers["accept-ranges"] == "bytes"


def test_upload_document_saves_metadata_when_provided(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("한글-메타.txt", b"hello metadata", "text/plain")},
        data={"metadata_value": json.dumps({"category": "reference", "priority": 7})},
    )

    assert upload_response.status_code == 201
    payload = upload_response.json()
    assert payload["filename"] == "한글-메타.txt"
    assert payload["metadata_value"] == {"category": "reference", "priority": 7}
    document_id = UUID(payload["document_id"])
    CREATED_DOCUMENT_IDS.append(document_id)

    metadata_response = app.get(f"/documents/{document_id}/metadata")
    assert metadata_response.status_code == 200
    assert metadata_response.json()["filename"] == "한글-메타.txt"
    assert metadata_response.json()["uploaded_by"] == TEST_USERNAME
    assert metadata_response.json()["metadata_value"] == {
        "category": "reference",
        "priority": 7,
    }


def test_soft_delete_document(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("delete-me.txt", b"to delete", "text/plain")},
    )
    assert upload_response.status_code == 201
    document_id = UUID(upload_response.json()["document_id"])
    CREATED_DOCUMENT_IDS.append(document_id)

    delete_response = app.delete(f"/documents/{document_id}")
    assert delete_response.status_code == 204

    download_response = app.get(f"/documents/{document_id}")
    assert download_response.status_code == 404


def test_delete_missing_document_returns_404(app):
    response = app.delete("/documents/11111111-1111-1111-1111-111111111111")
    assert response.status_code == 404
