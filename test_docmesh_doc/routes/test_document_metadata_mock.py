from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import json
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.testclient import TestClient
from fastapi_core.dependencies.messaging import get_nats_client

from docmesh_doc.dependencies.metadata import get_metadata_service
from docmesh_doc.dependencies.security import User, get_current_user
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.routes.metadata import router as metadata_router
from docmesh_doc.services.metadata import MetadataConflictError
from fastapi_core.dependencies.auth import get_settings
from unittest.mock import MagicMock


@dataclass
class _Record:
    document_id: UUID
    filename: str
    uploaded_by: str
    metadata_value: dict
    created_at: datetime
    updated_at: datetime


class _FakeDocumentService:
    def __init__(self):
        self.doc_exists = True
        self.get_calls: list[tuple[str, UUID]] = []

    def get(self, username: str, document_id: UUID):
        self.get_calls.append((username, document_id))
        if not self.doc_exists:
            return None
        return type("StoredDocument", (), {"filename": "stored.txt"})()


class _FakeMetadataService:
    def __init__(self):
        self.create_result: _Record | None = None
        self.get_result: _Record | None = None
        self.update_result: _Record | None = None
        self.delete_result: bool = True
        self.raise_conflict = False
        self.create_calls: list[tuple[str, UUID, str, dict]] = []
        self.get_calls: list[tuple[str, UUID]] = []
        self.update_calls: list[tuple[str, UUID, dict]] = []
        self.delete_calls: list[tuple[str, UUID]] = []

    def create(self, *, username: str, document_id: UUID, filename: str, metadata_value: dict):
        self.create_calls.append((username, document_id, filename, metadata_value))
        if self.raise_conflict:
            raise MetadataConflictError("conflict")
        if self.create_result is not None:
            return self.create_result
        now = datetime.now(timezone.utc)
        return _Record(document_id, filename, username, metadata_value, now, now)

    def get(self, *, username: str, document_id: UUID):
        self.get_calls.append((username, document_id))
        return self.get_result

    def update(self, *, username: str, document_id: UUID, metadata_value: dict):
        self.update_calls.append((username, document_id, metadata_value))
        return self.update_result

    def delete(self, *, username: str, document_id: UUID):
        self.delete_calls.append((username, document_id))
        return self.delete_result


class _FakeNatsClient:
    def __init__(self):
        self.publish_calls: list[tuple[str, bytes]] = []

    async def publish(self, subject: str, payload: bytes):
        self.publish_calls.append((subject, payload))


def _build_client(
    doc_service: _FakeDocumentService,
    meta_service: _FakeMetadataService,
    nats_client: _FakeNatsClient | None = None,
) -> TestClient:
    app = FastAPI()
    app.include_router(metadata_router)
    app.dependency_overrides[get_current_user] = lambda: User(sub="sub-1", username="mock-user")
    app.dependency_overrides[get_document_service] = lambda: doc_service
    app.dependency_overrides[get_metadata_service] = lambda: meta_service
    if nats_client is None:
        nats_client = _FakeNatsClient()
    app.dependency_overrides[get_nats_client] = lambda: nats_client
    app.dependency_overrides[get_settings] = lambda: MagicMock()
    return TestClient(app)


def test_create_metadata_mock_success_201_and_calls():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    nats_client = _FakeNatsClient()
    now = datetime.now(timezone.utc)
    meta_service.create_result = _Record(document_id, "stored.txt", "mock-user", {"k": "v"}, now, now)

    with _build_client(doc_service, meta_service, nats_client) as client:
        response = client.post(
            f"/documents/{document_id}/metadata",
            json={"metadata_value": {"k": "v"}},
        )

    assert response.status_code == 201
    assert response.json()["document_id"] == str(document_id)
    assert response.json()["filename"] == "stored.txt"
    assert response.json()["uploaded_by"] == "mock-user"
    assert response.json()["metadata_value"] == {"k": "v"}
    assert doc_service.get_calls == [("mock-user", document_id)]
    assert meta_service.create_calls == [("mock-user", document_id, "stored.txt", {"k": "v"})]
    assert len(nats_client.publish_calls) == 1
    subject, payload = nats_client.publish_calls[0]
    assert subject == "documents.metadata.created"
    assert json.loads(payload) == {
        "event": "documents.metadata.created",
        "schema_version": 1,
        "document_id": str(document_id),
        "username": "mock-user",
        "filename": "stored.txt",
        "metadata_value": {"k": "v"},
    }


def test_create_metadata_mock_conflict_409():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    meta_service.raise_conflict = True

    with _build_client(doc_service, meta_service) as client:
        response = client.post(
            f"/documents/{document_id}/metadata",
            json={"metadata_value": {"tag": "dup"}},
        )

    assert response.status_code == 409


def test_create_metadata_mock_document_not_found_404_and_no_metadata_call():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    doc_service.doc_exists = False
    meta_service = _FakeMetadataService()

    with _build_client(doc_service, meta_service) as client:
        response = client.post(
            f"/documents/{document_id}/metadata",
            json={"metadata_value": {"k": 1}},
        )

    assert response.status_code == 404
    assert meta_service.create_calls == []


def test_get_metadata_mock_not_found_404():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    meta_service.get_result = None

    with _build_client(doc_service, meta_service) as client:
        response = client.get(f"/documents/{document_id}/metadata")

    assert response.status_code == 404


def test_patch_metadata_mock_success_200_and_calls():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    nats_client = _FakeNatsClient()
    now = datetime.now(timezone.utc)
    meta_service.update_result = _Record(document_id, "stored.txt", "mock-user", {"priority": 2}, now, now)

    with _build_client(doc_service, meta_service, nats_client) as client:
        response = client.patch(
            f"/documents/{document_id}/metadata",
            json={"metadata_value": {"priority": 2}},
        )

    assert response.status_code == 200
    assert response.json()["filename"] == "stored.txt"
    assert response.json()["uploaded_by"] == "mock-user"
    assert response.json()["metadata_value"] == {"priority": 2}
    assert meta_service.update_calls == [("mock-user", document_id, {"priority": 2})]
    assert len(nats_client.publish_calls) == 1
    subject, payload = nats_client.publish_calls[0]
    assert subject == "documents.metadata.updated"
    assert json.loads(payload) == {
        "event": "documents.metadata.updated",
        "schema_version": 1,
        "document_id": str(document_id),
        "username": "mock-user",
        "filename": "stored.txt",
        "metadata_value": {"priority": 2},
    }


def test_delete_metadata_mock_success_204_and_calls():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    nats_client = _FakeNatsClient()
    meta_service.delete_result = True

    with _build_client(doc_service, meta_service, nats_client) as client:
        response = client.delete(f"/documents/{document_id}/metadata")

    assert response.status_code == 204
    assert meta_service.delete_calls == [("mock-user", document_id)]
    assert len(nats_client.publish_calls) == 1
    subject, payload = nats_client.publish_calls[0]
    assert subject == "documents.metadata.deleted"
    assert json.loads(payload) == {
        "event": "documents.metadata.deleted",
        "schema_version": 1,
        "document_id": str(document_id),
        "username": "mock-user",
    }


def test_delete_metadata_mock_missing_metadata_404():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()
    meta_service.delete_result = False

    with _build_client(doc_service, meta_service) as client:
        response = client.delete(f"/documents/{document_id}/metadata")

    assert response.status_code == 404


def test_metadata_mock_payload_validation_422():
    document_id = uuid4()
    doc_service = _FakeDocumentService()
    meta_service = _FakeMetadataService()

    with _build_client(doc_service, meta_service) as client:
        response = client.post(f"/documents/{document_id}/metadata", json="invalid")

    assert response.status_code == 422
