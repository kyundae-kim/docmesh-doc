from __future__ import annotations

import json
from typing import Any, Literal
from urllib.parse import quote

import dms
from fastapi import UploadFile


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
