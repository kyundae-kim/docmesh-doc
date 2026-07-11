from __future__ import annotations

from dataclasses import dataclass

import dms
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError


@dataclass(frozen=True)
class ErrorContract:
    status: int
    code: str
    message: str


ERRORS = {
    dms.ValidationError: ErrorContract(400, "VALIDATION_ERROR", "The request is invalid."),
    dms.DocumentNotFoundError: ErrorContract(404, "DOCUMENT_NOT_FOUND", "Document was not found."),
    dms.DuplicateDocumentError: ErrorContract(409, "DOCUMENT_ALREADY_EXISTS", "Document already exists."),
    dms.ConfigurationError: ErrorContract(503, "SERVICE_CONFIGURATION_ERROR", "Service configuration is invalid."),
    dms.HealthCheckFailedError: ErrorContract(503, "DEPENDENCY_UNAVAILABLE", "A required dependency is unavailable."),
    dms.StorageError: ErrorContract(503, "OBJECT_STORAGE_ERROR", "Object storage operation failed."),
    dms.MetadataStoreError: ErrorContract(503, "METADATA_STORE_ERROR", "Metadata store operation failed."),
    dms.ConsistencyError: ErrorContract(500, "DOCUMENT_CONSISTENCY_ERROR", "Document consistency could not be guaranteed."),
}


def error_response(request: Request, contract: ErrorContract) -> JSONResponse:
    correlation_id = request.state.correlation_id
    return JSONResponse(
        status_code=contract.status,
        content={"error": {"code": contract.code, "message": contract.message, "correlation_id": correlation_id}},
        headers={"X-Correlation-ID": correlation_id},
    )


async def dms_error_handler(request: Request, exc: dms.DmsError) -> JSONResponse:
    for error_type, contract in ERRORS.items():
        if isinstance(exc, error_type):
            return error_response(request, contract)
    return error_response(request, ErrorContract(500, "INTERNAL_ERROR", "An internal error occurred."))


async def validation_error_handler(request: Request, exc: RequestValidationError) -> JSONResponse:
    return error_response(request, ERRORS[dms.ValidationError])
