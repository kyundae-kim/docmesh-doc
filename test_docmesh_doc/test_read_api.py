from __future__ import annotations

from dataclasses import replace

import dms
import pytest

from test_docmesh_doc.support import NOW, FakeSDK, client_for, metadata


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
