from typing import Literal
from urllib.parse import quote

import dms
from fastapi import UploadFile


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

def content_disposition(
    kind: Literal["inline", "attachment"], filename: str
) -> str:
    return f"{kind}; filename*=UTF-8''{quote(filename, safe='')}"
