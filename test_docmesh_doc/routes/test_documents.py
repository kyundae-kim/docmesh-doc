import pytest
from fastapi.testclient import TestClient
from minio.error import S3Error

from docmesh_doc import factory
from docmesh_doc.core.security import User
from docmesh_doc.dependencies.security import get_current_user


TEST_USERNAME = "test-user"
CREATED_FILE_PATHS: list[str] = []


@pytest.fixture(scope="module")
def app():
    app = factory.create_app()
    app.dependency_overrides[get_current_user] = lambda: User(
        sub=TEST_USERNAME,
        preferred_username=TEST_USERNAME,
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

        for file_path in CREATED_FILE_PATHS:
            object_key = f"{TEST_USERNAME}/{file_path}"
            try:
                minio_client.remove_object(bucket_name, object_key)
            except S3Error:
                # Deletion is best-effort so test failures are not masked.
                pass
        CREATED_FILE_PATHS.clear()


def test_upload_and_download_document(app):
    file_path = "projects/specs/example.txt"
    upload_response = app.post(
        "/documents",
        data={"file_path": file_path},
        files={"file": ("example.txt", b"hello docmesh", "text/plain")},
    )

    assert upload_response.status_code == 200
    payload = upload_response.json()
    assert "document_id" in payload

    CREATED_FILE_PATHS.append(file_path)
    assert payload["document_id"] == f"{TEST_USERNAME}/{file_path}"
    download_response = app.get(f"/documents/{file_path}")

    assert download_response.status_code == 200
    assert download_response.content == b"hello docmesh"
    assert download_response.headers["content-type"].startswith("text/plain")


def test_soft_delete_document(app):
    file_path = "projects/specs/delete-me.txt"
    upload_response = app.post(
        "/documents",
        data={"file_path": file_path},
        files={"file": ("delete-me.txt", b"to delete", "text/plain")},
    )
    CREATED_FILE_PATHS.append(file_path)

    delete_response = app.delete(f"/documents/{file_path}")
    assert delete_response.status_code == 204

    download_response = app.get(f"/documents/{file_path}")
    assert download_response.status_code == 404


def test_delete_missing_document_returns_404(app):
    response = app.delete("/documents/projects/specs/not-found.txt")
    assert response.status_code == 404
