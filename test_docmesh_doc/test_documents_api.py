from __future__ import annotations

from dataclasses import dataclass
from datetime import UTC, datetime
from io import BytesIO

import pytest
from fastapi.testclient import TestClient
from fastapi_core import EnvConfig, ServiceSettings, UserInfo

from dms.sdk import (
    DeleteDocumentResult,
    DocumentContent,
    DocumentContentStream,
    DocumentMetadata,
    DocumentNotFoundError,
    HealthStatus,
    ServiceHealth,
)
from dms.sdk import UploadDocumentResult
from dms.domain.models import DocumentStatus
from docmesh_doc.main import create_app


@dataclass
class FakeSdk:
    closed: bool = False
    last_upload_request: object | None = None

    def __post_init__(self) -> None:
        now = datetime.now(UTC)
        self.metadata = DocumentMetadata(
            document_id="doc-123",
            original_filename="report.pdf",
            content_type="application/pdf",
            file_size=7,
            storage_key="documents/doc-123/report.pdf",
            status=DocumentStatus.AVAILABLE,
            created_at=now,
            updated_at=now,
            checksum="abc123",
            deleted_at=None,
            created_by="user-123",
            extra_metadata={"team": "platform"},
        )

    def upload_document(self, request):
        self.last_upload_request = request
        return UploadDocumentResult(
            document_id=self.metadata.document_id,
            storage_key=self.metadata.storage_key,
            created=True,
            metadata=self.metadata,
        )

    def get_document_metadata(self, document_id: str):
        if document_id != self.metadata.document_id:
            raise DocumentNotFoundError(f"Document not found: {document_id}")
        return self.metadata

    def get_document_content(self, document_id: str):
        if document_id != self.metadata.document_id:
            raise DocumentNotFoundError(f"Document not found: {document_id}")
        return DocumentContent(
            document_id=document_id,
            content=b"payload",
            content_type=self.metadata.content_type,
            filename=self.metadata.original_filename,
            size=7,
            checksum=self.metadata.checksum,
        )

    def get_document_content_stream(self, document_id: str, *, chunk_size: int = 65536):
        if document_id != self.metadata.document_id:
            raise DocumentNotFoundError(f"Document not found: {document_id}")
        return DocumentContentStream(
            document_id=document_id,
            stream=BytesIO(b"payload"),
            content_type=self.metadata.content_type,
            filename=self.metadata.original_filename,
            size=7,
            checksum=self.metadata.checksum,
            chunk_size=chunk_size,
        )

    def delete_document(self, document_id: str, *, hard_delete: bool = False):
        if document_id != self.metadata.document_id:
            raise DocumentNotFoundError(f"Document not found: {document_id}")
        return DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=hard_delete,
            status=DocumentStatus.DELETED,
        )

    def check_health(self):
        return HealthStatus(
            ok=True,
            checked_at=datetime.now(UTC),
            services=[ServiceHealth(service="sqlite", ok=True, latency_ms=1.2, error=None)],
        )

    def close(self):
        self.closed = True


@pytest.fixture
def app_and_sdk():
    sdk = FakeSdk()
    config = EnvConfig(config_path=".devcontainer/config.yaml")
    settings = ServiceSettings.model_validate(
        {
            "cors": {"origins": ["*"], "credentials": False},
            "auth": {
                "verify_jwt": False,
                "allow_insecure_jwt_decode": True,
                "use_introspection": False,
            },
            "health": {
                "check_keycloak": False,
                "check_database": False,
                "check_minio": False,
                "check_langfuse": False,
            },
            "lifecycle": {
                "eager_keycloak": False,
                "eager_database": False,
                "eager_minio": False,
                "eager_langfuse": False,
                "eager_milvus": False,
                "eager_async_milvus": False,
                "eager_ollama": False,
                "eager_nats": False,
                "use_docmesh_registry": False,
                "use_docmesh_healthchecks": False,
            },
        }
    )
    app = create_app(config=config, settings=settings, sdk_factory=lambda *_: sdk)

    from fastapi_core.dependencies.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: UserInfo(
        sub="user-123",
        username="alice",
        email="alice@example.com",
        name="Alice",
        roles=["documents:write", "documents:read", "documents:delete", "documents:admin"],
        scopes=[],
    )
    return app, sdk


def test_startup_registers_sdk_and_shutdown_closes_it(app_and_sdk):
    app, sdk = app_and_sdk

    with TestClient(app) as client:
        assert client.app.state.dms_sdk is sdk
        assert sdk.closed is False

    assert sdk.closed is True



def test_upload_document_uses_authenticated_user_for_created_by(app_and_sdk):
    app, sdk = app_and_sdk

    with TestClient(app) as client:
        response = client.post(
            "/documents",
            files={"file": ("report.pdf", b"payload", "application/pdf")},
            data={"metadata": '{"team":"platform"}', "created_by": "client-supplied"},
        )

    assert response.status_code == 201, response.text
    body = response.json()
    assert body["document_id"] == "doc-123"
    assert body["metadata"]["created_by"] == "user-123"
    assert sdk.last_upload_request.created_by == "user-123"
    assert sdk.last_upload_request.metadata == {"team": "platform"}



def test_document_metadata_and_content_endpoints(app_and_sdk):
    app, _ = app_and_sdk

    with TestClient(app) as client:
        metadata_response = client.get("/documents/doc-123/metadata")
        assert metadata_response.status_code == 200, metadata_response.text
        assert metadata_response.json()["storage_key"] == "documents/doc-123/report.pdf"

        content_response = client.get("/documents/doc-123/content")
        assert content_response.status_code == 200, content_response.text
        assert content_response.content == b"payload"
        assert content_response.headers["content-type"] == "application/pdf"
        assert 'filename="report.pdf"' in content_response.headers["content-disposition"]

        stream_response = client.get("/documents/doc-123/stream?chunk_size=4")
        assert stream_response.status_code == 200, stream_response.text
        assert stream_response.content == b"payload"



def test_delete_and_health_endpoints(app_and_sdk):
    app, _ = app_and_sdk

    with TestClient(app) as client:
        delete_response = client.delete("/documents/doc-123?hard_delete=true")
        assert delete_response.status_code == 200, delete_response.text
        assert delete_response.json() == {
            "document_id": "doc-123",
            "deleted": True,
            "hard_deleted": True,
            "status": "deleted",
        }

        health_response = client.get("/documents/health")
        assert health_response.status_code == 200, health_response.text
        assert health_response.json()["ok"] is True
        assert health_response.json()["services"][0]["service"] == "sqlite"



def test_missing_document_maps_to_404(app_and_sdk):
    app, _ = app_and_sdk

    with TestClient(app) as client:
        response = client.get("/documents/missing/metadata")

    assert response.status_code == 404
    detail = response.json()["detail"]
    assert detail["error"]["type"] == "DocumentNotFoundError"
