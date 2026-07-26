from datetime import datetime
from typing import Any

import dms
from pydantic import BaseModel, ConfigDict, Field


class DocumentMetadataResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    original_filename: str
    content_type: str
    file_size: int
    status: dms.DocumentStatus
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None
    created_by: str | None
    checksum: str | None
    metadata: dict[str, Any] = Field(validation_alias="extra_metadata")


class DocumentPageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[DocumentMetadataResponse]
    next_cursor: str | None
    has_more: bool


class DeleteDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    deleted: bool
    hard_deleted: bool
    status: dms.DocumentStatus


class ErrorDetailResponse(BaseModel):
    code: str
    message: str
    correlation_id: str


class ErrorResponse(BaseModel):
    error: ErrorDetailResponse
