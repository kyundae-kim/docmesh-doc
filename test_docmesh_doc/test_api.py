from __future__ import annotations

import os
from dataclasses import replace
from datetime import UTC, datetime
from io import BytesIO
from types import SimpleNamespace

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
        self.delete_call = None
        self.list_args = None
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

    def list_documents(self, *, offset=0, limit=100, status=None):
        self.list_args = (offset, limit, status)
        return [metadata("doc-1"), metadata("doc-2")]

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

    def soft_delete_document(self, document_id):
        self.delete_call = ("soft", document_id)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=False,
            status=dms.DocumentStatus.DELETED,
        )

    def hard_delete_document(self, document_id):
        self.delete_call = ("hard", document_id)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=True,
            status=dms.DocumentStatus.DELETED,
        )

    def check_health(self):
        return dms.HealthStatus(ok=True, services=[], checked_at=NOW)

    def close(self):
        self.closed = True


def test_sdk_from_environment_passes_an_environment_snapshot(monkeypatch):
    captured_env = None
    diagnosed_env = None
    sdk = FakeSDK()
    monkeypatch.delenv("DMS_METADATA_BACKEND", raising=False)
    monkeypatch.delenv("DMS_CONFIGURATION_STRICT", raising=False)
    monkeypatch.setenv("POSTGRES_DSN", "postgresql+psycopg://legacy.example/test")

    def diagnose_environment(env):
        nonlocal diagnosed_env
        diagnosed_env = env
        return SimpleNamespace(valid=True, missing_required_keys=(), warnings=())

    def create_sdk(env):
        nonlocal captured_env
        captured_env = env
        return sdk

    monkeypatch.setattr(dms, "diagnose_environment", diagnose_environment)
    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    assert sdk_from_environment() is sdk
    expected_environment = dict(os.environ)
    expected_environment.pop("POSTGRES_DSN")
    assert captured_env == {
        **expected_environment,
        "DMS_METADATA_BACKEND": "postgresql",
        "DMS_CONFIGURATION_STRICT": "true",
    }
    assert diagnosed_env is captured_env
    assert captured_env is not os.environ
    assert os.environ.get("DMS_METADATA_BACKEND") is None
    assert os.environ.get("DMS_CONFIGURATION_STRICT") is None


def test_sdk_from_environment_rejects_invalid_diagnosis_before_assembly(monkeypatch):
    assembled = False

    monkeypatch.setattr(
        dms,
        "diagnose_environment",
        lambda _env: SimpleNamespace(
            valid=False,
            missing_required_keys=("POSTGRES_PASSWORD", "MINIO_BUCKET"),
            warnings=(),
        ),
    )

    def create_sdk(_env):
        nonlocal assembled
        assembled = True

    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    with pytest.raises(
        dms.ConfigurationError,
        match="POSTGRES_PASSWORD, MINIO_BUCKET",
    ):
        sdk_from_environment()

    assert assembled is False


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


def test_metadata_responses_use_dms_public_metadata_boundary(monkeypatch):
    calls = []
    public_metadata = dms.public_metadata

    def track_public_metadata(value):
        calls.append(value)
        return public_metadata(value)

    monkeypatch.setattr(dms, "public_metadata", track_public_metadata)

    with client_for(FakeSDK()) as client:
        response = client.get("/documents/doc-1")

    assert response.status_code == 200
    assert len(calls) == 1
    assert calls[0].document_id == "doc-1"
    assert "storage_key" not in response.json()


def test_framework_http_errors_use_documented_error_envelope():
    with client_for(FakeSDK()) as client:
        response = client.get(
            "/route-that-does-not-exist",
            headers={"X-Correlation-ID": "missing-route-1"},
        )

    assert response.status_code == 404
    assert response.headers["Content-Type"].startswith("application/json")
    assert response.json() == {
        "error": {
            "code": "NOT_FOUND",
            "message": "Not Found",
            "correlation_id": "missing-route-1",
        }
    }


def test_list_documents_passes_pagination_and_status_to_sdk():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get(
            "/documents?offset=10&limit=20&status=available",
            headers={"X-Correlation-ID": "list-request-1"},
        )

    assert response.status_code == 200
    assert response.headers["X-Correlation-ID"] == "list-request-1"
    assert [item["document_id"] for item in response.json()] == ["doc-1", "doc-2"]
    assert all("storage_key" not in item for item in response.json())
    assert sdk.list_args == (10, 20, dms.DocumentStatus.AVAILABLE)


@pytest.mark.parametrize(
    "query",
    ["offset=-1", "limit=0", "status=unknown"],
)
def test_list_documents_rejects_invalid_query_parameters(query):
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get(f"/documents?{query}")

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.list_args is None


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
    assert sdk.delete_call is None


def test_hard_delete_calls_sdk_for_authorized_user():
    sdk = FakeSDK()
    with client_for(sdk, roles=["document:delete:hard"]) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is True
    assert sdk.delete_call == ("hard", "doc-1")


def test_soft_delete_calls_explicit_sdk_method():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is False
    assert sdk.delete_call == ("soft", "doc-1")


def test_soft_deleted_documents_are_hidden_from_read_routes():
    sdk = FakeSDK()
    sdk.get_document_metadata = lambda document_id: replace(
        metadata(document_id),
        status=dms.DocumentStatus.DELETED,
        deleted_at=NOW,
    )

    with client_for(sdk) as client:
        responses = (
            client.get("/documents/doc-1"),
            client.get("/documents/doc-1/content"),
            client.get("/documents/doc-1/download"),
        )

    assert [response.status_code for response in responses] == [404, 404, 404]
    assert {
        response.json()["error"]["code"] for response in responses
    } == {"DOCUMENT_NOT_FOUND"}


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
