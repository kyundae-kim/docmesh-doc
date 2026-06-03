from uuid import UUID

import pytest
from fastapi.testclient import TestClient

from docmesh_doc import factory
from docmesh_doc.dependencies.security import User, get_current_user


TEST_USERNAME = "test-user"


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


def _create_document(app: TestClient) -> UUID:
    response = app.post(
        "/documents",
        files={"file": ("metadata.txt", b"metadata target", "text/plain")},
    )
    assert response.status_code == 201
    return UUID(response.json()["document_id"])


def test_metadata_crud(app):
    document_id = _create_document(app)

    get_response = app.get(f"/documents/{document_id}/metadata")
    assert get_response.status_code == 200
    assert get_response.json()["filename"] == "metadata.txt"
    assert get_response.json()["uploaded_by"] == TEST_USERNAME
    assert get_response.json()["metadata_value"] == {}

    patch_response = app.patch(
        f"/documents/{document_id}/metadata",
        json={"metadata_value": {"category": "architecture", "priority": 2}},
    )
    assert patch_response.status_code == 200
    assert patch_response.json()["filename"] == "metadata.txt"
    assert patch_response.json()["uploaded_by"] == TEST_USERNAME
    assert patch_response.json()["metadata_value"]["priority"] == 2

    delete_response = app.delete(f"/documents/{document_id}/metadata")
    assert delete_response.status_code == 204

    get_after_delete = app.get(f"/documents/{document_id}/metadata")
    assert get_after_delete.status_code == 404


def test_metadata_conflict_returns_409(app):
    document_id = _create_document(app)

    second = app.post(
        f"/documents/{document_id}/metadata",
        json={"metadata_value": {"tag": "second"}},
    )
    assert second.status_code == 409


def test_metadata_missing_document_returns_404(app):
    missing_doc = UUID("11111111-1111-1111-1111-111111111111")

    response = app.post(
        f"/documents/{missing_doc}/metadata",
        json={"metadata_value": {"x": 1}},
    )
    assert response.status_code == 404
