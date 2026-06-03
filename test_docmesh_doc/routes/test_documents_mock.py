from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
import json
from uuid import UUID, uuid4

from fastapi import FastAPI
from fastapi.testclient import TestClient

from docmesh_doc.dependencies.metadata import get_metadata_service
from docmesh_doc.dependencies.security import User, get_current_user
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.routes.documents import router as documents_router


@dataclass
class _StoredDocument:
    document_id: UUID
    filename: str
    content_type: str
    content: bytes


class _FakeDocumentService:
    def __init__(self):
        self.upload_result = uuid4()
        self.get_result: _StoredDocument | None = None
        self.soft_delete_result: bool = True
        self.upload_calls: list[dict] = []
        self.get_calls: list[tuple[str, UUID]] = []
        self.soft_delete_calls: list[tuple[str, UUID]] = []

    def upload(self, **kwargs):
        self.upload_calls.append(kwargs)
        return self.upload_result

    def get(self, username: str, document_id: UUID):
        self.get_calls.append((username, document_id))
        return self.get_result

    def soft_delete(self, username: str, document_id: UUID):
        self.soft_delete_calls.append((username, document_id))
        return self.soft_delete_result


class _FakeMetadataService:
    def __init__(self):
        self.create_calls: list[tuple[str, UUID, str, dict]] = []
        self.get_calls: list[tuple[str, UUID]] = []
        self.get_result = None

    def create(self, *, username: str, document_id: UUID, filename: str, metadata_value: dict):
        self.create_calls.append((username, document_id, filename, metadata_value))
        now = datetime.now(timezone.utc)
        return {
            "document_id": document_id,
            "filename": filename,
            "uploaded_by": username,
            "metadata_value": metadata_value,
            "created_at": now,
            "updated_at": now,
        }

    def get(self, *, username: str, document_id: UUID):
        self.get_calls.append((username, document_id))
        return self.get_result


def _build_client(
    service: _FakeDocumentService,
    metadata_service: _FakeMetadataService | None = None,
) -> TestClient:
    app = FastAPI()
    app.include_router(documents_router)
    app.dependency_overrides[get_current_user] = lambda: User(sub="sub-1", username="mock-user")
    app.dependency_overrides[get_document_service] = lambda: service
    if metadata_service is None:
        metadata_service = _FakeMetadataService()
    app.dependency_overrides[get_metadata_service] = lambda: metadata_service
    return TestClient(app)


def test_upload_document_mock_success_201_and_calls():
    service = _FakeDocumentService()
    metadata_service = _FakeMetadataService()
    expected_id = uuid4()
    service.upload_result = expected_id

    with _build_client(service, metadata_service) as client:
        response = client.post(
            "/documents",
            files={"file": ("hello.txt", b"hello", "text/plain")},
        )

    assert response.status_code == 201
    assert response.json()["document_id"] == str(expected_id)
    assert response.json()["filename"] == "hello.txt"
    assert response.json()["metadata_value"] is None
    assert metadata_service.create_calls == [("mock-user", expected_id, "hello.txt", {})]
    assert len(service.upload_calls) == 1
    assert service.upload_calls[0]["username"] == "mock-user"
    assert service.upload_calls[0]["filename"] == "hello.txt"
    assert service.upload_calls[0]["content_type"] == "text/plain"


def test_upload_document_mock_saves_metadata_when_provided():
    service = _FakeDocumentService()
    metadata_service = _FakeMetadataService()
    expected_id = uuid4()
    service.upload_result = expected_id

    with _build_client(service, metadata_service) as client:
        response = client.post(
            "/documents",
            files={"file": ("hello.txt", b"hello", "text/plain")},
            data={"metadata_value": json.dumps({"category": "guide", "priority": 1})},
        )

    assert response.status_code == 201
    assert response.json()["document_id"] == str(expected_id)
    assert response.json()["filename"] == "hello.txt"
    assert response.json()["metadata_value"] == {"category": "guide", "priority": 1}
    assert metadata_service.create_calls == [
        ("mock-user", expected_id, "hello.txt", {"category": "guide", "priority": 1})
    ]


def test_upload_document_mock_with_korean_filename_persists_filename_in_document_metadata():
    service = _FakeDocumentService()
    metadata_service = _FakeMetadataService()
    expected_id = uuid4()
    service.upload_result = expected_id

    with _build_client(service, metadata_service) as client:
        response = client.post(
            "/documents",
            files={"file": ("한글 문서.txt", b"hello", "text/plain")},
        )

    assert response.status_code == 201
    assert response.json()["filename"] == "한글 문서.txt"
    assert metadata_service.create_calls == [
        ("mock-user", expected_id, "한글 문서.txt", {})
    ]


def test_upload_document_mock_returns_422_when_metadata_is_not_json_object():
    service = _FakeDocumentService()
    metadata_service = _FakeMetadataService()

    with _build_client(service, metadata_service) as client:
        response = client.post(
            "/documents",
            files={"file": ("hello.txt", b"hello", "text/plain")},
            data={"metadata_value": json.dumps(["not", "an", "object"])},
        )

    assert response.status_code == 422
    assert service.upload_calls == []
    assert metadata_service.create_calls == []


def test_upload_document_mock_validation_422_when_file_missing():
    service = _FakeDocumentService()

    with _build_client(service) as client:
        response = client.post("/documents")

    assert response.status_code == 422
    assert service.upload_calls == []


def test_download_document_mock_success_200():
    service = _FakeDocumentService()
    document_id = uuid4()
    service.get_result = _StoredDocument(
        document_id=document_id,
        filename="a.txt",
        content_type="text/plain",
        content=b"abc",
    )

    with _build_client(service) as client:
        response = client.get(f"/documents/{document_id}")

    assert response.status_code == 200
    assert response.content == b"abc"
    assert response.headers["content-type"].startswith("text/plain")
    assert "filename=\"a.txt\"" in response.headers["content-disposition"]


def test_download_document_mock_not_found_404():
    service = _FakeDocumentService()
    document_id = uuid4()
    service.get_result = None

    with _build_client(service) as client:
        response = client.get(f"/documents/{document_id}")

    assert response.status_code == 404


def test_delete_document_mock_success_204_and_calls():
    service = _FakeDocumentService()
    document_id = uuid4()
    service.soft_delete_result = True

    with _build_client(service) as client:
        response = client.delete(f"/documents/{document_id}")

    assert response.status_code == 204
    assert service.soft_delete_calls == [("mock-user", document_id)]


def test_delete_document_mock_missing_404():
    service = _FakeDocumentService()
    document_id = uuid4()
    service.soft_delete_result = False

    with _build_client(service) as client:
        response = client.delete(f"/documents/{document_id}")

    assert response.status_code == 404
