from __future__ import annotations

import json
from typing import Any, BinaryIO, Literal
from urllib.parse import quote

import dms
from fastapi import UploadFile

from docmesh_doc.schemas import DocumentMetadataResponse


def parse_metadata_form(value: str) -> dict[str, Any]:
    try:
        metadata = json.loads(value)
    except json.JSONDecodeError as exc:
        raise dms.ValidationError("metadata must be a JSON object") from exc
    if not isinstance(metadata, dict):
        raise dms.ValidationError("metadata must be a JSON object")
    return metadata


def validate_upload_file(file: UploadFile) -> tuple[str, str, int]:
    filename = (file.filename or "").strip()
    content_type = (file.content_type or "").strip()
    size = file.size
    if size is None:
        file.file.seek(0, 2)
        size = file.file.tell()
    file.file.seek(0)
    if size <= 0 or not filename or filename == "." or not content_type:
        raise dms.ValidationError("invalid upload")
    return filename, content_type, size


def build_upload_request(
    *,
    stream: BinaryIO,
    size: int,
    filename: str,
    content_type: str,
    document_id: str | None,
    metadata: dict[str, Any],
    created_by: str,
    checksum: str | None,
) -> dms.UploadDocumentStreamRequest:
    return dms.UploadDocumentStreamRequest(
        stream=stream,
        size=size,
        filename=filename,
        content_type=content_type,
        document_id=document_id or None,
        metadata=metadata,
        created_by=created_by,
        checksum=checksum or None,
    )


def to_metadata_response(item: dms.DocumentMetadata) -> DocumentMetadataResponse:
    public_item = dms.public_metadata(item)
    return DocumentMetadataResponse(
        document_id=public_item.document_id,
        original_filename=public_item.original_filename,
        content_type=public_item.content_type,
        file_size=public_item.file_size,
        status=public_item.status.value,
        created_at=public_item.created_at,
        updated_at=public_item.updated_at,
        deleted_at=public_item.deleted_at,
        created_by=public_item.created_by,
        checksum=public_item.checksum,
        metadata=public_item.extra_metadata,
    )


def require_readable_document(
    sdk: dms.DefaultDocumentManagementSDK,
    document_id: str,
) -> dms.DocumentMetadata:
    item = sdk.get_document_metadata(document_id)
    if item.status is dms.DocumentStatus.DELETED:
        raise dms.DocumentNotFoundError(document_id)
    return item


def content_disposition(
    kind: Literal["inline", "attachment"], filename: str
) -> str:
    return f"{kind}; filename*=UTF-8''{quote(filename, safe='')}"
