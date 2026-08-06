from __future__ import annotations

import dms
import pytest

from test_docmesh_doc.support import FakeSDK, client_for


def test_upload_streams_multipart_to_sdk_request_and_hides_storage_key():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={
                "document_id": "doc-1",
                "metadata": '{"category":"contract"}',
            },
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
    assert sdk.upload_stream_request.document_id == "doc-1"
    assert sdk.upload_stream_request.created_by == "user-1"
    assert sdk.upload_stream_request.metadata == {"category": "contract"}


def test_upload_location_includes_configured_root_path():
    with client_for(FakeSDK(), root_path="/dms") as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"document_id": "doc-1"},
        )

    assert response.status_code == 201
    assert response.headers["Location"] == "/dms/documents/doc-1"


def test_upload_normalizes_empty_optional_fields():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"document_id": ""},
        )

    assert response.status_code == 201
    assert sdk.upload_stream_request.document_id is None


def test_upload_uses_authenticated_subject_not_caller_created_by():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"created_by": "attacker"},
        )

    assert response.status_code == 201
    assert sdk.upload_stream_request.created_by == "user-1"


@pytest.mark.parametrize("metadata", ["{", "[]", '"text"', "1", "true", "null"])
def test_upload_validation_happens_before_sdk_call(metadata):
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.post(
            "/documents",
            files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            data={"metadata": metadata},
        )

    assert response.status_code == 400
    assert sdk.upload_stream_request is None


def test_upload_maps_v060_payload_limit_error_to_413():
    class SizeLimitedSDK(FakeSDK):
        def upload_document_stream(self, request):
            raise dms.PayloadTooLargeError("secret backend limit 7 exceeded")

    with client_for(SizeLimitedSDK()) as client:
        response = client.post(
            "/documents",
            files={"file": ("large.pdf", b"pdf", "application/pdf")},
        )

    assert response.status_code == 413
    assert response.json()["error"]["code"] == "DOCUMENT_TOO_LARGE"
    assert "secret backend limit" not in response.text
