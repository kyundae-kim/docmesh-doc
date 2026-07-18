from __future__ import annotations

from dataclasses import dataclass

import dms
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi_core import ErrorMapping


@dataclass(frozen=True)
class ErrorContract:
    status: int
    code: str
    message: str


ERRORS = {
    dms.ValidationError: ErrorContract(
        400, "VALIDATION_ERROR", "The request is invalid."
    ),
    dms.DocumentNotFoundError: ErrorContract(
        404, "DOCUMENT_NOT_FOUND", "Document was not found."
    ),
    dms.DuplicateDocumentError: ErrorContract(
        409, "DOCUMENT_ALREADY_EXISTS", "Document already exists."
    ),
    dms.ConfigurationError: ErrorContract(
        503, "SERVICE_CONFIGURATION_ERROR", "Service configuration is invalid."
    ),
    dms.HealthCheckFailedError: ErrorContract(
        503, "DEPENDENCY_UNAVAILABLE", "A required dependency is unavailable."
    ),
    dms.StorageError: ErrorContract(
        503, "OBJECT_STORAGE_ERROR", "Object storage operation failed."
    ),
    dms.MetadataStoreError: ErrorContract(
        503, "METADATA_STORE_ERROR", "Metadata store operation failed."
    ),
    dms.ConsistencyError: ErrorContract(
        500,
        "DOCUMENT_CONSISTENCY_ERROR",
        "Document consistency could not be guaranteed.",
    ),
    dms.IdempotencyConflictError: ErrorContract(
        409,
        "IDEMPOTENCY_CONFLICT",
        "The idempotency key conflicts with an existing upload.",
    ),
    dms.IdempotencyInProgressError: ErrorContract(
        409, "IDEMPOTENCY_IN_PROGRESS", "The upload is still in progress."
    ),
    dms.UploadOperationNotFoundError: ErrorContract(
        404, "UPLOAD_OPERATION_NOT_FOUND", "Upload operation was not found."
    ),
}

STATUS_CODES = {
    400: "VALIDATION_ERROR",
    401: "UNAUTHENTICATED",
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    409: "CONFLICT",
    500: "INTERNAL_ERROR",
    503: "DEPENDENCY_UNAVAILABLE",
}


def render_error(request: Request, mapping: ErrorMapping) -> JSONResponse:
    correlation_id = request.state.correlation_id
    return JSONResponse(
        status_code=mapping.status_code,
        content={
            "error": {
                "code": mapping.code
                or STATUS_CODES.get(mapping.status_code, "HTTP_ERROR"),
                "message": mapping.detail,
                "correlation_id": correlation_id,
            }
        },
        headers=mapping.headers,
    )


def map_dms_error(_request: Request, exc: Exception) -> ErrorMapping:
    for error_type, contract in ERRORS.items():
        if isinstance(exc, error_type):
            return ErrorMapping(
                status_code=contract.status,
                detail=contract.message,
                code=contract.code,
            )
    return ErrorMapping(
        status_code=500,
        detail="An internal error occurred.",
        code="INTERNAL_ERROR",
    )


def map_validation_error(_request: Request, _exc: Exception) -> ErrorMapping:
    contract = ERRORS[dms.ValidationError]
    return ErrorMapping(
        status_code=contract.status,
        detail=contract.message,
        code=contract.code,
    )


def map_permission_error(_request: Request, _exc: Exception) -> ErrorMapping:
    return ErrorMapping(
        status_code=403,
        detail="Permission denied.",
        code="FORBIDDEN",
    )