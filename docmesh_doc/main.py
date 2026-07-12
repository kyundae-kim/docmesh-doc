from __future__ import annotations

import os
from collections.abc import Callable
from contextlib import asynccontextmanager
from uuid import uuid4

import dms
from docmesh_py_core.config import CommonConfig, ServiceConfigs
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi_core import create_app
from fastapi_core.config import AppConfig

from docmesh_doc.errors import (
    ErrorContract,
    dms_error_handler,
    error_response,
    validation_error_handler,
)
from docmesh_doc.router import router

SdkFactory = Callable[[], dms.DefaultDocumentManagementSDK]


def _check_dms_readiness(sdk: dms.DefaultDocumentManagementSDK) -> None:
    if not sdk.check_health().ok:
        raise RuntimeError("DMS dependency unavailable")


def sdk_from_environment() -> dms.DefaultDocumentManagementSDK:
    return dms.create_sdk_from_environment(os.environ)


def create_application(
    *,
    sdk_factory: SdkFactory = sdk_from_environment,
    config: AppConfig | None = None,
    settings: ServiceConfigs | None = None,
    include_auth_router: bool = True,
) -> FastAPI:
    @asynccontextmanager
    async def lifespan(application: FastAPI):
        sdk = sdk_factory()
        application.state.dms_sdk = sdk
        application.state.readiness_checks["dms"] = lambda: _check_dms_readiness(sdk)
        application.state.readiness_services["dms"] = {
            "enabled": True,
            "required": True,
        }
        application.state.required_services.add("dms")
        try:
            yield
        finally:
            sdk.close()

    if settings is None and sdk_factory is not sdk_from_environment:
        settings = ServiceConfigs(common=CommonConfig())

    application = create_app(
        config=config,
        settings=settings,
        lifespan=lifespan,
        include_auth_router=include_auth_router,
    )

    @application.middleware("http")
    async def correlation_id(request: Request, call_next):
        supplied = request.headers.get("X-Correlation-ID", "").strip()
        request.state.correlation_id = supplied[:128] if supplied else str(uuid4())
        response = await call_next(request)
        response.headers["X-Correlation-ID"] = request.state.correlation_id
        return response

    async def forbidden_handler(request: Request, exc: PermissionError) -> JSONResponse:
        return error_response(request, ErrorContract(403, "FORBIDDEN", "Permission denied."))

    application.add_exception_handler(dms.DmsError, dms_error_handler)
    application.add_exception_handler(RequestValidationError, validation_error_handler)
    application.add_exception_handler(PermissionError, forbidden_handler)
    application.include_router(router)
    return application


app = create_application()
