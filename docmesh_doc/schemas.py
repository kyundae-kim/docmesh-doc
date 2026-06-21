from __future__ import annotations

from datetime import datetime
from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class ErrorPayload(BaseModel):
    type: str
    message: str


class ErrorResponse(BaseModel):
    error: ErrorPayload


class DocumentMetadataResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    original_filename: str
    content_type: str
    file_size: int
    storage_key: str
    status: str
    created_at: datetime
    updated_at: datetime
    checksum: str | None = None
    deleted_at: datetime | None = None
    created_by: str | None = None
    extra_metadata: dict[str, Any] = Field(default_factory=dict)


class UploadDocumentResponse(BaseModel):
    document_id: str
    storage_key: str
    created: bool
    metadata: DocumentMetadataResponse


class DeleteDocumentResponse(BaseModel):
    document_id: str
    deleted: bool
    hard_deleted: bool
    status: str


class HealthServiceResponse(BaseModel):
    service: str
    ok: bool
    latency_ms: float | None = None
    error: str | None = None


class HealthResponse(BaseModel):
    ok: bool
    checked_at: datetime
    services: list[HealthServiceResponse]
