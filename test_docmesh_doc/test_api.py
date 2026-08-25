from __future__ import annotations

import dms
import pytest
from fastapi.testclient import TestClient

from docmesh_doc import application
from docmesh_doc.application import create_application
from docmesh_doc.dms_factory import DmsRuntime, DmsSettings
from test_docmesh_doc.support import FakeSDK, client_for


def test_upload_parses_metadata_and_returns_creation_state():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={
                "document_id": "doc-1",
                "metadata": '{"source":"api"}',
                "created_by": "author-1",
            },
            headers={"X-User-ID": "user-1", "X-Correlation-ID": "request-1"},
        )

    assert response.status_code == 201
    assert response.headers["X-Correlation-ID"] == "request-1"
    assert response.headers["Location"] == "/documents/doc-1"
    assert "storage_key" not in response.json()
    assert response.json()["created"] is True
    assert response.json()["metadata"] == {"category": "contract"}
    assert sdk.upload_request.size == 3
    assert sdk.upload_request.created_by == "author-1"
    assert sdk.upload_request.metadata == {"source": "api"}
    assert sdk.scoped_contexts[-1].user_id == "user-1"


def test_upload_location_respects_root_path():
    with client_for(FakeSDK(), root_path="/dms") as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
        )

    assert response.status_code == 201
    assert response.headers["Location"] == "/dms/documents/generated-id"


@pytest.mark.parametrize(
    "metadata",
    ["NaN", "Infinity", "-Infinity", "1e9999", '{"value":NaN}'],
)
def test_upload_rejects_non_standard_json_metadata(metadata):
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"metadata": metadata},
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.upload_request is None


def test_context_rejects_non_standard_json_default_metadata():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get(
            "/documents",
            headers={"X-Default-Metadata": "NaN"},
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.list_args is None


def test_list_passes_opaque_cursor_limit_and_status_to_dms():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get(
            "/documents?cursor=opaque&limit=20&status=available",
            headers={"X-Correlation-ID": "list-1"},
        )

    assert response.status_code == 200
    assert response.headers["X-Correlation-ID"] == "list-1"
    assert sdk.list_args == ("opaque", 20, dms.DocumentStatus.AVAILABLE)
    assert response.json()["next_cursor"] == "next-page"
    assert all("storage_key" not in item for item in response.json()["items"])


@pytest.mark.parametrize("query", ["limit=0", "limit=1001", "status=unknown"])
def test_invalid_query_is_a_product_400_error(query):
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get(f"/documents?{query}")

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.list_args is None


def test_streaming_download_closes_dms_stream():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get("/documents/doc-1/download?chunk_size=2")

    assert response.status_code == 200
    assert response.content == b"pdf"
    assert response.headers["Content-Disposition"].startswith("attachment;")
    assert sdk.stream_closed is True


def test_inline_content_uses_streaming_response():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get("/documents/doc-1/content")

    assert response.status_code == 200
    assert response.content == b"pdf"
    assert response.headers["Content-Disposition"].startswith("inline;")
    assert response.headers["X-Document-Checksum"] == "checksum"
    assert sdk.stream_closed is True


def test_dms_not_found_is_mapped_without_leaking_exception_text():
    class MissingSDK(FakeSDK):
        def get_document_metadata(self, document_id, **_kwargs):
            raise dms.DocumentNotFoundError(
                "private storage details",
                document_id=document_id,
            )

    with client_for(MissingSDK()) as client:
        response = client.get("/documents/missing")

    assert response.status_code == 404
    error = response.json()["error"]
    assert error["code"] == "DOCUMENT_NOT_FOUND"
    assert error["category"] == "not_found"
    assert error["retryable"] is False
    assert error["document_id"] == "missing"
    assert "private storage details" not in response.text


def test_hard_delete_is_not_gated_by_user_permission():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.delete(
            "/documents/doc-1?hard=true",
            headers={"X-User-Permissions": "ignored"},
        )

    assert response.status_code == 200
    assert sdk.delete_args == ("doc-1", True)


def test_lifespan_does_not_close_host_owned_dms_sdk():
    sdk = FakeSDK()

    with client_for(sdk):
        pass

    assert sdk.closed is False


def test_lifespan_does_not_close_injected_host_owned_runtime():
    class RecordingEngine:
        disposed = False

        def dispose(self):
            self.disposed = True

    engine = RecordingEngine()
    runtime = DmsRuntime(
        sdk=FakeSDK(),
        engine=engine,
        minio_client=object(),
        bucket_name="documents",
    )

    with TestClient(create_application(runtime=runtime)):
        pass

    assert engine.disposed is False


def test_lifespan_closes_runtime_assembled_by_application(monkeypatch):
    class RecordingEngine:
        disposed = False

        def dispose(self):
            self.disposed = True

    engine = RecordingEngine()
    runtime = DmsRuntime(
        sdk=FakeSDK(),
        engine=engine,
        minio_client=object(),
        bucket_name="documents",
    )
    monkeypatch.setattr(application, "create_dms_runtime", lambda _settings: runtime)

    settings = DmsSettings(metadata_backend="sqlite", sqlite_path=":memory:")
    with TestClient(create_application(settings=settings)):
        pass

    assert engine.disposed is True


def test_document_openapi_uses_400_for_validation_errors():
    from docmesh_doc.application import create_application

    schema = create_application(FakeSDK()).openapi()

    for path, path_item in schema["paths"].items():
        if not path.startswith("/documents"):
            continue
        for operation in path_item.values():
            if not isinstance(operation, dict) or "responses" not in operation:
                continue
            assert "400" in operation["responses"]
            assert "422" not in operation["responses"]


def test_liveness_and_injected_sdk_readiness_are_available_without_dms_health_api():
    with client_for(FakeSDK()) as client:
        liveness = client.get("/health/liveness")
        readiness = client.get("/health/readiness")

    assert liveness.status_code == 200
    assert liveness.json() == {"status": "ok"}
    assert readiness.status_code == 200
    assert readiness.json()["details"]["dms"]["ok"] is True


def test_application_version_matches_the_distribution_version():
    app = create_application(FakeSDK())

    assert app.version == "0.5.0"


def test_host_readiness_check_can_return_service_unavailable():
    from docmesh_doc.application import create_application

    app = create_application(FakeSDK(), readiness_check=lambda: False)

    with TestClient(app) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 503
    assert response.json()["status"] == "error"
