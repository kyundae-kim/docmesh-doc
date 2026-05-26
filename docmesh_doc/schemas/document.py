from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class DocumentUploadResponse(BaseModel):
    document_id: UUID = Field(..., description="Issued UUID for uploaded document")
    filename: str = Field(..., description="Original filename")


class DocumentMetadataRequest(BaseModel):
    metadata_value: dict = Field(..., description="Metadata payload as JSON object")


class DocumentMetadataResponse(BaseModel):
    document_id: UUID
    metadata_value: dict
    created_at: datetime
    updated_at: datetime
