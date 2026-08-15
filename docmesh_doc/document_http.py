from __future__ import annotations

import json
from typing import Any, Literal
from urllib.parse import quote

import dms
from fastapi import UploadFile


def parse_metadata(raw: str | None) -> dict[str, Any]:
    if raw is None or not raw.strip():
        return {}
    try:
        value = json.loads(raw)
    except json.JSONDecodeError as error:
        raise dms.ValidationError("metadata must be valid JSON") from error
    if not isinstance(value, dict):
        raise dms.ValidationError("metadata must be a JSON object")
    return value


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


def content_disposition(
    kind: Literal["inline", "attachment"], filename: str
) -> str:
    return f"{kind}; filename*=UTF-8''{quote(filename, safe='')}"
