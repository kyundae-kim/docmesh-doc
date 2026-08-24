from __future__ import annotations

import logging
from dataclasses import dataclass
from uuid import uuid4

import dms
from fastapi import HTTPException, Request, status
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse


logger = logging.getLogger(__name__)


@dataclass(frozen=True, slots=True)
class ErrorMapping:
    status_code: int
    code: str
    message: str


_ERROR_MAPPINGS: dict[type[BaseException], ErrorMapping] = {
    dms.AccessDeniedError: ErrorMapping(403, "FORBIDDEN", "Access was denied."),
    dms.PayloadTooLargeError: ErrorMapping(
        413,
        "DOCUMENT_TOO_LARGE",
        "The document exceeds the configured size limit.",
    ),
    dms.ValidationError: ErrorMapping(
        400,
        "VALIDATION_ERROR",
        "The request is invalid.",
    ),
    dms.DocumentNotFoundError: ErrorMapping(
        404,
        "DOCUMENT_NOT_FOUND",
        "Document was not found.",
    ),
    dms.DocumentDeletedError: ErrorMapping(
        404,
        "DOCUMENT_NOT_FOUND",
        "Document was not found.",
    ),
    dms.UploadOperationNotFoundError: ErrorMapping(
        404,
        "UPLOAD_OPERATION_NOT_FOUND",
        "Upload operation was not found.",
    ),
    dms.DuplicateDocumentError: ErrorMapping(
        409,
        "DOCUMENT_ALREADY_EXISTS",
        "Document already exists.",
    ),
    dms.IdempotencyConflictError: ErrorMapping(
        409,
        "IDEMPOTENCY_CONFLICT",
        "The idempotency key conflicts with an existing upload.",
    ),
    dms.IdempotencyInProgressError: ErrorMapping(
        425,
        "IDEMPOTENCY_IN_PROGRESS",
        "The upload is still in progress.",
    ),
    dms.ConfigurationError: ErrorMapping(
        503,
        "SERVICE_CONFIGURATION_ERROR",
        "Service configuration is invalid.",
    ),
    dms.StorageError: ErrorMapping(
        503,
        "OBJECT_STORAGE_ERROR",
        "Object storage operation failed.",
    ),
    dms.MetadataStoreError: ErrorMapping(
        503,
        "METADATA_STORE_ERROR",
        "Metadata store operation failed.",
    ),
    dms.ConsistencyError: ErrorMapping(
        500,
        "DOCUMENT_CONSISTENCY_ERROR",
        "Document consistency could not be guaranteed.",
    ),
    dms.DataResetError: ErrorMapping(
        500,
        "DATA_RESET_ERROR",
        "The data reset did not complete.",
    ),
    dms.DmsError: ErrorMapping(
        500,
        "INTERNAL_ERROR",
        "An internal error occurred.",
    ),
}


_HTTP_MAPPINGS = {
    403: ErrorMapping(403, "FORBIDDEN", "Access was denied."),
    404: ErrorMapping(404, "NOT_FOUND", "The requested resource was not found."),
    405: ErrorMapping(405, "METHOD_NOT_ALLOWED", "The method is not allowed."),
    503: ErrorMapping(503, "SERVICE_UNAVAILABLE", "The service is unavailable."),
}


def _correlation_id(request: Request) -> str:
    value = getattr(request.state, "correlation_id", None)
    return value or str(uuid4())


def _response(
    request: Request,
    mapping: ErrorMapping,
    *,
    error: dms.DmsError | None = None,
) -> JSONResponse:
    correlation_id = _correlation_id(request)
    detail: dict[str, object] = {
        "code": mapping.code,
        "message": mapping.message,
        "correlation_id": correlation_id,
    }
    if error is not None:
        detail["category"] = error.category
        detail["retryable"] = error.retryable
        document_id = getattr(error, "document_id", None)
        if document_id is not None:
            detail["document_id"] = document_id
    response = JSONResponse(
        status_code=mapping.status_code,
        content={"error": detail},
    )
    response.headers["X-Correlation-ID"] = correlation_id
    return response


def mapping_for_dms_error(error: dms.DmsError) -> ErrorMapping:
    for error_type in type(error).__mro__:
        mapping = _ERROR_MAPPINGS.get(error_type)
        if mapping is not None:
            return mapping
    return _ERROR_MAPPINGS[dms.DmsError]


async def dms_error_handler(request: Request, error: dms.DmsError) -> JSONResponse:
    return _response(request, mapping_for_dms_error(error), error=error)


async def validation_error_handler(
    request: Request,
    _error: RequestValidationError,
) -> JSONResponse:
    return _response(
        request,
        ErrorMapping(400, "VALIDATION_ERROR", "The request is invalid."),
    )


async def http_error_handler(request: Request, error: HTTPException) -> JSONResponse:
    mapping = _HTTP_MAPPINGS.get(
        error.status_code,
        ErrorMapping(
            error.status_code,
            "HTTP_ERROR",
            "The request could not be completed.",
        ),
    )
    return _response(request, mapping)


async def unhandled_error_handler(request: Request, error: Exception) -> JSONResponse:
    logger.exception("Unhandled application error: %s", type(error).__name__)
    return _response(
        request,
        ErrorMapping(
            status.HTTP_500_INTERNAL_SERVER_ERROR,
            "INTERNAL_ERROR",
            "An internal error occurred.",
        ),
    )
