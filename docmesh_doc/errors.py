import dms
from fastapi import Request
from fastapi_core import (
    ErrorMapperSpec,
    ErrorMapping,
    ExceptionMappingTable,
    create_error_renderer,
)


def _error(status: int, code: str, detail: str) -> ErrorMapping:
    return ErrorMapping(status_code=status, detail=detail, code=code)


ERRORS = {
    dms.DmsError: _error(500, "INTERNAL_ERROR", "An internal error occurred."),
    dms.PayloadTooLargeError: _error(
        413, "DOCUMENT_TOO_LARGE", "The document exceeds the configured size limit."
    ),
    dms.ValidationError: _error(400, "VALIDATION_ERROR", "The request is invalid."),
    dms.DocumentNotFoundError: _error(
        404, "DOCUMENT_NOT_FOUND", "Document was not found."
    ),
    dms.DocumentDeletedError: _error(
        404, "DOCUMENT_NOT_FOUND", "Document was not found."
    ),
    dms.DuplicateDocumentError: _error(
        409, "DOCUMENT_ALREADY_EXISTS", "Document already exists."
    ),
    dms.ConfigurationError: _error(
        503, "SERVICE_CONFIGURATION_ERROR", "Service configuration is invalid."
    ),
    dms.HealthCheckFailedError: _error(
        503, "DEPENDENCY_UNAVAILABLE", "A required dependency is unavailable."
    ),
    dms.StorageError: _error(
        503, "OBJECT_STORAGE_ERROR", "Object storage operation failed."
    ),
    dms.MetadataStoreError: _error(
        503, "METADATA_STORE_ERROR", "Metadata store operation failed."
    ),
    dms.ConsistencyError: _error(
        500,
        "DOCUMENT_CONSISTENCY_ERROR",
        "Document consistency could not be guaranteed.",
    ),
    dms.IdempotencyConflictError: _error(
        409,
        "IDEMPOTENCY_CONFLICT",
        "The idempotency key conflicts with an existing upload.",
    ),
    dms.IdempotencyInProgressError: _error(
        425, "IDEMPOTENCY_IN_PROGRESS", "The upload is still in progress."
    ),
    dms.UploadOperationNotFoundError: _error(
        404, "UPLOAD_OPERATION_NOT_FOUND", "Upload operation was not found."
    ),
}

STATUS_CODES = {
    400: "VALIDATION_ERROR",
    401: "UNAUTHENTICATED",
    403: "FORBIDDEN",
    404: "NOT_FOUND",
    409: "CONFLICT",
    413: "PAYLOAD_TOO_LARGE",
    425: "TOO_EARLY",
    500: "INTERNAL_ERROR",
    503: "DEPENDENCY_UNAVAILABLE",
}


def _error_envelope(
    _request: Request,
    mapping: ErrorMapping,
    correlation_id: str,
) -> dict[str, dict[str, str]]:
    return {
        "error": {
            "code": mapping.code or "HTTP_ERROR",
            "message": mapping.detail,
            "correlation_id": correlation_id,
        }
    }


render_error = create_error_renderer(
    envelope_builder=_error_envelope,
    fallback_codes=STATUS_CODES,
    problem_details=False,
)


DMS_ERROR_MAPPING_TABLE = ExceptionMappingTable(ERRORS)


async def map_dms_error(_request: Request, exc: Exception) -> ErrorMapping:
    mapping = await DMS_ERROR_MAPPING_TABLE.resolve(_request, exc)
    if mapping is None:  # pragma: no cover - DmsError is always in the table
        raise LookupError(f"No DMS error mapping for {type(exc).__name__}")
    return mapping


DMS_ERROR_MAPPER = ErrorMapperSpec(dms.DmsError, map_dms_error)


def map_validation_error(_request: Request, _exc: Exception) -> ErrorMapping:
    return ERRORS[dms.ValidationError]