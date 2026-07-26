from __future__ import annotations

from dataclasses import replace

import dms
import pytest

from test_docmesh_doc.support import NOW, FakeSDK, client_for, metadata


def test_metadata_response_uses_dms_public_metadata_boundary():
    with client_for(FakeSDK()) as client:
        response = client.get("/documents/doc-1")

    assert response.status_code == 200
    assert "storage_key" not in response.json()


def test_list_documents_passes_pagination_and_status_to_sdk():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get(
            "/documents?cursor=current-page&limit=20&status=available",
            headers={"X-Correlation-ID": "list-request-1"},
        )

    assert response.status_code == 200
    assert response.headers["X-Correlation-ID"] == "list-request-1"
    assert [item["document_id"] for item in response.json()["items"]] == [
        "doc-1",
        "doc-2",
    ]
    assert all("storage_key" not in item for item in response.json()["items"])
    assert response.json()["next_cursor"] == "next-page"
    assert response.json()["has_more"] is True
    assert sdk.list_args == ("current-page", 20, dms.DocumentStatus.AVAILABLE)


@pytest.mark.parametrize(
    "query",
    ["limit=0", "limit=1001", "status=unknown"],
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


def test_oversized_chunk_is_rejected_before_sdk_call():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get(
            "/documents/doc-1/download?chunk_size=8388609"
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.content_stream_calls == 0


def test_stream_is_closed_after_download():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get("/documents/doc-1/download?chunk_size=2")

    assert response.status_code == 200
    assert response.content == b"pdf"
    assert response.headers["Content-Disposition"].startswith("attachment;")
    assert sdk.stream_closed is True


def test_inline_content_is_streamed_and_closed():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get("/documents/doc-1/content")

    assert response.status_code == 200
    assert response.content == b"pdf"
    assert response.headers["Content-Disposition"].startswith("inline;")
    assert sdk.content_calls == 0
    assert sdk.content_stream_calls == 1
    assert sdk.stream_closed is True


def test_content_routes_delegate_readability_check_to_sdk_without_duplicate_metadata_lookup():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        content_response = client.get("/documents/doc-1/content")
        download_response = client.get("/documents/doc-1/download")

    assert content_response.status_code == 200
    assert download_response.status_code == 200
    assert sdk.metadata_calls == 0
    assert sdk.content_calls == 0
    assert sdk.content_stream_calls == 2


def test_soft_deleted_documents_are_hidden_from_read_routes():
    sdk = FakeSDK()
    sdk.get_document_metadata = lambda document_id: replace(
        metadata(document_id),
        status=dms.DocumentStatus.DELETED,
        deleted_at=NOW,
    )

    def deleted_content(document_id, **_kwargs):
        raise dms.DocumentDeletedError(
            "document is deleted",
            document_id=document_id,
        )

    sdk.get_document_content = deleted_content
    sdk.get_document_content_stream = deleted_content

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
