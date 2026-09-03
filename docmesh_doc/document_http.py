from __future__ import annotations

import base64
import binascii
import json
from typing import Any, Literal
from urllib.parse import quote

import dms
from fastapi import UploadFile

from docmesh_doc.json_utils import ensure_json_serializable


def _reject_json_constant(_value: str) -> object:
    raise ValueError("non-standard JSON numeric constant")


def parse_json_value(value: str, *, field_name: str) -> object:
    try:
        parsed = json.loads(value, parse_constant=_reject_json_constant)
        return ensure_json_serializable(parsed)
    except (json.JSONDecodeError, TypeError, ValueError) as error:
        raise dms.ValidationError(f"{field_name} must contain valid JSON") from error


def parse_metadata(
    value: str | None,
    *,
    field_name: str = "metadata",
) -> dict[str, Any] | None:
    if value is None or not value.strip():
        return None
    parsed = parse_json_value(value, field_name=field_name)
    if not isinstance(parsed, dict):
        raise dms.ValidationError(f"{field_name} must contain a JSON object")
    return parsed


def decode_base64_content(value: str) -> bytes:
    try:
        content = base64.b64decode(value, validate=True)
    except (binascii.Error, ValueError) as error:
        raise dms.ValidationError("content_base64 must contain valid base64") from error
    if not content:
        raise dms.ValidationError("content must not be empty")
    return content


def validate_upload_file(file: UploadFile) -> tuple[str, str, int]:
    filename = (file.filename or "").strip()
    content_type = (file.content_type or "").strip()
    size = file.size
    if size is None:
        current_position = file.file.tell()
        file.file.seek(0, 2)
        size = file.file.tell()
        file.file.seek(current_position)

    if not filename or filename == "." or not content_type or size <= 0:
        raise dms.ValidationError(
            "file, filename, content type, and content are required"
        )
    return filename, content_type, int(size)


def content_disposition(kind: Literal["inline", "attachment"], filename: str) -> str:
    return f"{kind}; filename*=UTF-8''{quote(filename, safe='')}"
