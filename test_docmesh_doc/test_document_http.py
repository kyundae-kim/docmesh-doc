from __future__ import annotations

from dataclasses import replace
from io import BytesIO
from typing import Literal, get_type_hints

import dms
import pytest
from fastapi import UploadFile
from starlette.datastructures import Headers

from docmesh_doc.document_http import (
    build_upload_request,
    content_disposition,
    parse_metadata_form,
    require_readable_document,
    to_metadata_response,
    validate_upload_file,
)
from test_docmesh_doc.support import FakeSDK, client_for, metadata


class _PrivateMetadataSentinel:
    @property
    def storage_key(self):
        raise AssertionError("HTTP serialization must not access storage_key")


def _upload_file(
    content: bytes,
    *,
    filename: str | None = " contract.pdf ",
    content_type: str = " application/pdf ",
    size: int | None = None,
) -> UploadFile:
    return UploadFile(
        BytesIO(content),
        size=size,
        filename=filename,
        headers=Headers({"content-type": content_type}),
    )


def test_parse_metadata_form_accepts_json_object():
    assert parse_metadata_form('{"category": "contract", "revision": 2}') == {
        "category": "contract",
        "revision": 2,
    }


@pytest.mark.parametrize("value", ["{", "[]", '"text"', "1", "true", "null"])
def test_parse_metadata_form_rejects_invalid_json_and_non_objects(value):
    with pytest.raises(dms.ValidationError, match="metadata must be a JSON object"):
        parse_metadata_form(value)


def test_validate_upload_file_trims_fields_uses_reported_size_and_rewinds_stream():
    file = _upload_file(b"pdf", size=3)
    file.file.seek(2)

    assert validate_upload_file(file) == ("contract.pdf", "application/pdf", 3)
    assert file.file.tell() == 0


def test_validate_upload_file_measures_missing_size_and_rewinds_stream():
    file = _upload_file(b"content", size=None)
    file.file.seek(3)

    assert validate_upload_file(file) == ("contract.pdf", "application/pdf", 7)
    assert file.file.tell() == 0


@pytest.mark.parametrize(
    ("content", "filename", "content_type", "size"),
    [
        (b"", "file.pdf", "application/pdf", 0),
        (b"", "file.pdf", "application/pdf", None),
        (b"pdf", "   ", "application/pdf", 3),
        (b"pdf", " . ", "application/pdf", 3),
        (b"pdf", "file.pdf", "   ", 3),
    ],
)
def test_validate_upload_file_rejects_invalid_upload_and_rewinds(
    content, filename, content_type, size
):
    file = _upload_file(
        content, filename=filename, content_type=content_type, size=size
    )
    file.file.seek(len(content))

    with pytest.raises(dms.ValidationError, match="invalid upload"):
        validate_upload_file(file)
    assert file.file.tell() == 0


def test_build_upload_request_maps_all_fields():
    stream = BytesIO(b"pdf")
    request = build_upload_request(
        stream=stream,
        size=3,
        filename="contract.pdf",
        content_type="application/pdf",
        document_id="doc-1",
        metadata={"category": "contract"},
        created_by="authenticated-user",
        checksum="sha256:abc",
    )

    assert isinstance(request, dms.UploadDocumentStreamRequest)
    assert request.stream is stream
    assert request.size == 3
    assert request.filename == "contract.pdf"
    assert request.content_type == "application/pdf"
    assert request.document_id == "doc-1"
    assert request.metadata == {"category": "contract"}
    assert request.created_by == "authenticated-user"
    assert request.checksum == "sha256:abc"


def test_build_upload_request_normalizes_empty_optional_fields():
    request = build_upload_request(
        stream=BytesIO(b"pdf"),
        size=3,
        filename="contract.pdf",
        content_type="application/pdf",
        document_id="",
        metadata={},
        created_by="authenticated-user",
        checksum="",
    )

    assert request.document_id is None
    assert request.checksum is None


def test_to_metadata_response_uses_public_projection_and_maps_extra_metadata(monkeypatch):
    private_item = _PrivateMetadataSentinel()
    public_item = dms.public_metadata(metadata())
    calls = []

    def project(item):
        calls.append(item)
        return replace(public_item, extra_metadata={"projected": True})

    monkeypatch.setattr(dms, "public_metadata", project)

    response = to_metadata_response(private_item)

    assert calls == [private_item]
    assert response.metadata == {"projected": True}
    assert "storage_key" not in response.model_dump()


@pytest.mark.parametrize("kind", ["inline", "attachment"])
def test_content_disposition_rfc5987_encodes_unicode_apostrophes_and_unsafe_chars(kind):
    assert content_disposition(kind, "Kim's 계약 #1.pdf") == (
        f"{kind}; filename*=UTF-8''Kim%27s%20%EA%B3%84%EC%95%BD%20%231.pdf"
    )


def test_content_disposition_kind_has_literal_type():
    assert get_type_hints(content_disposition)["kind"] == Literal["inline", "attachment"]


def test_require_readable_document_returns_visible_metadata_and_hides_deleted():
    sdk = FakeSDK()
    assert require_readable_document(sdk, "doc-1").document_id == "doc-1"

    sdk.get_document_metadata = lambda document_id: replace(
        metadata(document_id), status=dms.DocumentStatus.DELETED
    )
    with pytest.raises(dms.DocumentNotFoundError):
        require_readable_document(sdk, "doc-1")


@pytest.mark.parametrize("route", ["upload", "list", "single"])
def test_all_metadata_routes_apply_public_projection(monkeypatch, route):
    original_public_metadata = dms.public_metadata
    calls = []

    def project(item):
        calls.append(item)
        return replace(
            original_public_metadata(item), extra_metadata={"projected": route}
        )

    monkeypatch.setattr(dms, "public_metadata", project)
    with client_for(FakeSDK()) as client:
        if route == "upload":
            response = client.post(
                "/documents",
                files={"file": ("contract.pdf", b"pdf", "application/pdf")},
            )
        elif route == "list":
            response = client.get("/documents")
        else:
            response = client.get("/documents/doc-1")

    assert response.status_code in (200, 201)
    payload = response.json()
    items = payload if isinstance(payload, list) else [payload]
    assert len(calls) == len(items)
    assert all(item["metadata"] == {"projected": route} for item in items)
    assert all("storage_key" not in item for item in items)
