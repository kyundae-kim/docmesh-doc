import pytest
from fastapi.testclient import TestClient
from minio.error import S3Error

from docmesh_doc import factory
from docmesh_doc.core.security import User
from docmesh_doc.dependencies.security import get_current_user


CREATED_DOCUMENT_IDS: list[str] = []


@pytest.fixture(scope="module")
def app():
    app = factory.create_app()
    app.dependency_overrides[get_current_user] = lambda: User(
        sub="test-user",
        roles={"create", "read", "delete"},
        scopes={"profile"},
    )
    with TestClient(app) as client:
        minio_client = client.app.state.minio_client
        bucket_name = client.app.state.env_settings.minio.bucket_name

        try:
            minio_client.bucket_exists(bucket_name)
        except Exception as exc:
            pytest.skip(f"MinIO is not reachable for integration tests: {exc}")

        yield client

        for document_id in CREATED_DOCUMENT_IDS:
            try:
                minio_client.remove_object(bucket_name, document_id)
            except S3Error:
                # Deletion is best-effort so test failures are not masked.
                pass
        CREATED_DOCUMENT_IDS.clear()


def test_upload_and_download_document(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("example.txt", b"hello docmesh", "text/plain")},
    )

    assert upload_response.status_code == 200
    payload = upload_response.json()
    assert "document_id" in payload

    document_id = payload["document_id"]
    CREATED_DOCUMENT_IDS.append(document_id)
    download_response = app.get(f"/documents/{document_id}")

    assert download_response.status_code == 200
    assert download_response.content == b"hello docmesh"
    assert download_response.headers["content-type"].startswith("text/plain")


def test_soft_delete_document(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("delete-me.txt", b"to delete", "text/plain")},
    )
    document_id = upload_response.json()["document_id"]
    CREATED_DOCUMENT_IDS.append(document_id)

    delete_response = app.delete(f"/documents/{document_id}")
    assert delete_response.status_code == 204

    download_response = app.get(f"/documents/{document_id}")
    assert download_response.status_code == 404


def test_delete_missing_document_returns_404(app):
    response = app.delete("/documents/not-found")
    assert response.status_code == 404
