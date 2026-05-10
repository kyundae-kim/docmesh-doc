import pytest
from fastapi.testclient import TestClient

from docmesh_doc import factory
from docmesh_doc.core.security import User
from docmesh_doc.dependencies.security import get_current_user
from docmesh_doc.dependencies.storage import get_document_service
from docmesh_doc.services.document import StoredDocument


class FakeDocumentService:
    def __init__(self) -> None:
        self._documents: dict[str, StoredDocument] = {}

    def upload(self, *, filename: str, content_type: str, content: bytes) -> str:
        document_id = f"doc-{len(self._documents) + 1}"
        self._documents[document_id] = StoredDocument(
            document_id=document_id,
            filename=filename,
            content_type=content_type,
            content=content,
            is_deleted=False,
        )
        return document_id

    def get(self, document_id: str) -> StoredDocument | None:
        document = self._documents.get(document_id)
        if document is None or document.is_deleted:
            return None
        return document

    def soft_delete(self, document_id: str) -> bool:
        document = self._documents.get(document_id)
        if document is None:
            return False
        document.is_deleted = True
        return True


@pytest.fixture(scope="module")
def app():
    app = factory.create_app()
    fake_document_service = FakeDocumentService()
    app.dependency_overrides[get_current_user] = lambda: User(
        sub="test-user",
        roles={"create", "read", "delete"},
        scopes={"profile"},
    )
    app.dependency_overrides[get_document_service] = lambda: fake_document_service
    with TestClient(app) as client:
        yield client


def test_upload_and_download_document(app):
    upload_response = app.post(
        "/documents",
        files={"file": ("example.txt", b"hello docmesh", "text/plain")},
    )

    assert upload_response.status_code == 200
    payload = upload_response.json()
    assert "document_id" in payload

    document_id = payload["document_id"]
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

    delete_response = app.delete(f"/documents/{document_id}")
    assert delete_response.status_code == 204

    download_response = app.get(f"/documents/{document_id}")
    assert download_response.status_code == 404


def test_delete_missing_document_returns_404(app):
    response = app.delete("/documents/not-found")
    assert response.status_code == 404
