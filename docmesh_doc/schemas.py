from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

import dms
from pydantic import BaseModel, ConfigDict, Field, field_validator

from docmesh_doc.json_utils import ensure_json_serializable


class DocumentMetadataResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)

    document_id: str
    original_filename: str
    content_type: str
    file_size: int
    status: dms.DocumentStatus
    created_at: datetime
    updated_at: datetime
    deleted_at: datetime | None = None
    created_by: str | None = None
    user_id: str | None = None
    checksum: str | None = None
    metadata: Any = Field(
        default_factory=dict,
        validation_alias="extra_metadata",
    )


class UploadDocumentResponse(DocumentMetadataResponse):
    created: bool


class BytesUploadRequest(BaseModel):
    content_base64: str = Field(min_length=1)
    filename: str = Field(min_length=1)
    content_type: str = Field(min_length=1)
    document_id: str | None = None
    metadata: Any = None
    created_by: str | None = None
    user_id: str | None = None
    checksum: str | None = None
    idempotency_key: str | None = None
    idempotency_scope: str | None = None

    @field_validator("metadata")
    @classmethod
    def validate_metadata_json(cls, value: Any) -> Any:
        try:
            ensure_json_serializable(value)
        except (TypeError, ValueError) as error:
            raise ValueError("metadata must contain valid JSON") from error
        return value


class DocumentPageResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    items: list[DocumentMetadataResponse]
    next_cursor: str | None
    has_more: bool


class DocumentItemsResponse(BaseModel):
    items: list[DocumentMetadataResponse]


class InternalDocumentMetadataResponse(DocumentMetadataResponse):
    storage_key: str


class InternalDocumentItemsResponse(BaseModel):
    items: list[InternalDocumentMetadataResponse]


class UploadOperationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    scope: str
    idempotency_key: str
    document_id: str
    state: Literal["pending", "succeeded", "failed"]
    created_at: datetime
    updated_at: datetime


class DeleteDocumentResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    deleted: bool
    hard_deleted: bool
    status: dms.DocumentStatus


class DataResetResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    metadata_deleted: int
    objects_deleted: int
    upload_operations_deleted: int
    ready_for_data_load: bool
    total_deleted: int


class DocumentInspectionResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    metadata_exists: bool
    object_exists: bool | None
    status: dms.DocumentStatus | None
    consistent: bool
    issue: dms.RecoveryIssue
    storage_key: str | None = None


class ReconciliationResultResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    document_id: str
    action: dms.RecoveryAction
    applied: bool
    inspection: DocumentInspectionResponse | None
    error_type: str | None = None
    error_message: str | None = None


class BatchReconciliationResponse(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    status: dms.DocumentStatus
    action: dms.RecoveryAction
    dry_run: bool
    offset: int
    limit: int
    items: list[ReconciliationResultResponse]
    scanned: int
    failed: int
    eligible: int
    applied: int
    skipped: int


class ReconcileDocumentRequest(BaseModel):
    action: dms.RecoveryAction
    storage_key: str | None = None
    dry_run: bool = False
    actor: str | None = None


class ReconcileDocumentsRequest(BaseModel):
    status: dms.DocumentStatus
    action: dms.RecoveryAction
    offset: int = Field(default=0, ge=0)
    limit: int = Field(default=100, ge=1, le=1000)
    dry_run: bool = False
    actor: str | None = None


class ReconciliationPlanItemRequest(BaseModel):
    document_id: str = Field(min_length=1)
    action: dms.RecoveryAction
    storage_key: str | None = None


class ExecuteReconciliationPlanRequest(BaseModel):
    status: dms.DocumentStatus
    action: dms.RecoveryAction
    items: list[ReconciliationPlanItemRequest]
    actor: str | None = None


class ErrorDetailResponse(BaseModel):
    code: str
    message: str
    correlation_id: str
    category: str | None = None
    retryable: bool | None = None
    document_id: str | None = None


class ErrorResponse(BaseModel):
    error: ErrorDetailResponse
