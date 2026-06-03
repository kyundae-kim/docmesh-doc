from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class DocumentUploadResponse(BaseModel):
    document_id: UUID = Field(..., description="Issued UUID for uploaded document")
    filename: str = Field(..., description="Original filename")
    metadata_value: dict | None = Field(
        default=None,
        description="Metadata payload saved together with the uploaded document",
    )


class DocumentMetadataRequest(BaseModel):
    metadata_value: dict = Field(..., description="Metadata payload as JSON object")


class DocumentMetadataResponse(BaseModel):
    document_id: UUID
    filename: str
    uploaded_by: str
    metadata_value: dict
    created_at: datetime
    updated_at: datetime
