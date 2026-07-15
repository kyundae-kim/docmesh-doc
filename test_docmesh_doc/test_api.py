from __future__ import annotations

import os
from datetime import UTC, datetime
from io import BytesIO

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import get_current_user
from fastapi_core.schemas import UserInfo

from docmesh_doc.main import create_application, sdk_from_environment


NOW = datetime(2026, 7, 11, tzinfo=UTC)


def metadata(document_id: str = "doc-1") -> dms.DocumentMetadata:
    return dms.DocumentMetadata(
        document_id=document_id,
        original_filename="contract.pdf",
        content_type="application/pdf",
        file_size=3,
        storage_key="private/object/key",
        status=dms.DocumentStatus.AVAILABLE,
        created_at=NOW,
        updated_at=NOW,
        created_by="user-1",
        extra_metadata={"category": "contract"},
    )


class FakeSDK:
    def __init__(self) -> None:
        self.closed = False
        self.upload_request = None
        self.upload_stream_request = None
        self.delete_args = None
        self.stream_closed = False

    def upload_document(self, request):
        self.upload_request = request
        item = metadata(request.document_id or "generated-id")
        return dms.UploadDocumentResult(
            document_id=item.document_id,
            storage_key=item.storage_key,
            metadata=item,
        )

    def upload_document_stream(self, request):
        self.upload_stream_request = request
        content = request.stream.read()
        assert len(content) == request.size
        item = metadata(request.document_id or "generated-id")
        return dms.UploadDocumentResult(
            document_id=item.document_id,
            storage_key=item.storage_key,
            metadata=item,
        )

    def get_document_metadata(self, document_id):
        if document_id == "missing":
            raise dms.DocumentNotFoundError(document_id)
        return metadata(document_id)

    def get_document_content(self, document_id):
        return dms.DocumentContent(
            document_id=document_id,
            content=b"pdf",
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
        )

    def get_document_content_stream(self, document_id, *, chunk_size=65536):
        return dms.DocumentContentStream(
            document_id=document_id,
            stream=BytesIO(b"pdf"),
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
            chunk_size=chunk_size,
            _close_callback=lambda: setattr(self, "stream_closed", True),
        )

    def delete_document(self, document_id, *, hard_delete=False):
        self.delete_args = (document_id, hard_delete)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=hard_delete,
            status=dms.DocumentStatus.DELETED,
        )

    def check_health(self):
        return dms.HealthStatus(ok=True, services=[], checked_at=NOW)

    def close(self):
        self.closed = True


def test_sdk_from_environment_passes_an_environment_snapshot(monkeypatch):
    captured_env = None
    sdk = FakeSDK()
    monkeypatch.delenv("DMS_METADATA_BACKEND", raising=False)

    def create_sdk(env):
        nonlocal captured_env
        captured_env = env
        return sdk

    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    assert sdk_from_environment() is sdk
    assert captured_env == {**os.environ, "DMS_METADATA_BACKEND": "postgresql"}
    assert captured_env is not os.environ
    assert os.environ.get("DMS_METADATA_BACKEND") is None


def client_for(sdk: FakeSDK, *, roles: list[str] | None = None) -> TestClient:
    app = create_application(
        sdk,
        config=AppConfig(
            startup_healthcheck=False,
            enabled_services=[],
            required_services=[],
        ),
        include_auth_router=False,
    )
    app.dependency_overrides[get_current_user] = lambda: UserInfo(
        sub="user-1", username="alice", roles=roles or []
    )
    return TestClient(app)


def test_upload_streams_multipart_to_sdk_request_and_hides_storage_key():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"document_id": "doc-1", "metadata": '{"category":"contract"}'},
            headers={"X-Correlation-ID": "request-1"},
        )

    assert response.status_code == 201
    assert response.headers["X-Correlation-ID"] == "request-1"
    assert response.headers["Location"] == "/documents/doc-1"
    assert "storage_key" not in response.json()
    assert sdk.upload_request is None
    assert sdk.upload_stream_request.size == 3
    assert sdk.upload_stream_request.filename == "contract.pdf"
    assert sdk.upload_stream_request.content_type == "application/pdf"
    assert sdk.upload_stream_request.created_by == "user-1"
    assert sdk.upload_stream_request.metadata == {"category": "contract"}


def test_dms_sdk_is_owned_by_the_managed_resource_registry():
    sdk = FakeSDK()
    app = create_application(
        sdk,
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    with TestClient(app):
        assert app.state.resource_registry.require("dms") is sdk
        assert not hasattr(app.state, "dms_sdk")
        assert not hasattr(app.state, "readiness_checks")

    assert sdk.closed is True


def test_sdk_not_found_uses_documented_error_envelope():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get("/documents/missing")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "DOCUMENT_NOT_FOUND"
    assert response.json()["error"]["correlation_id"] == response.headers["X-Correlation-ID"]


def test_invalid_chunk_size_is_normalized_to_400():
    with client_for(FakeSDK()) as client:
        response = client.get("/documents/doc-1/download?chunk_size=0")

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"


def test_stream_is_closed_after_download():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get("/documents/doc-1/download?chunk_size=2")

    assert response.status_code == 200
    assert response.content == b"pdf"
    assert response.headers["Content-Disposition"].startswith("attachment;")
    assert sdk.stream_closed is True


def test_hard_delete_requires_permission_before_sdk_call():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "FORBIDDEN"
    assert sdk.delete_args is None


def test_hard_delete_calls_sdk_for_authorized_user():
    sdk = FakeSDK()
    with client_for(sdk, roles=["document:delete:hard"]) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is True
    assert sdk.delete_args == ("doc-1", True)


def test_lifespan_closes_sdk():
    sdk = FakeSDK()
    with client_for(sdk):
        assert sdk.closed is False

    assert sdk.closed is True


def test_readiness_includes_required_dms_sdk_check():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 200
    assert response.json()["details"]["dms"]["ok"] is True
    assert response.json()["details"]["dms"]["required"] is True


def test_readiness_returns_503_when_dms_sdk_is_unhealthy():
    class UnhealthySDK(FakeSDK):
        def check_health(self):
            return dms.HealthStatus(
                ok=False,
                services=[
                    dms.ServiceHealth(
                        service="postgres",
                        ok=False,
                        latency_ms=1,
                        error="connection failed",
                    )
                ],
                checked_at=NOW,
            )

    with client_for(UnhealthySDK()) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 503
    assert response.json()["status"] == "error"
    assert response.json()["details"]["dms"]["ok"] is False
    assert "connection failed" not in response.text


def test_sdk_environment_failure_aborts_application_startup(monkeypatch):
    def failing_sdk_from_environment():
        raise RuntimeError("SDK startup failed")

    monkeypatch.setattr(
        "docmesh_doc.main.sdk_from_environment", failing_sdk_from_environment
    )
    app = create_application(
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    with pytest.raises(RuntimeError, match="SDK startup failed"):
        with TestClient(app):
            pass


def test_sdk_close_failure_is_reported_during_shutdown():
    class CloseFailingSDK(FakeSDK):
        def close(self):
            self.closed = True
            raise RuntimeError("SDK close failed")

    sdk = CloseFailingSDK()

    with pytest.RaisesGroup(RuntimeError, match="managed resource shutdown failed"):
        with client_for(sdk):
            pass

    assert sdk.closed is True
