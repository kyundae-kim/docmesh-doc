from __future__ import annotations

import os

import dms
from docmesh_py_core.config import CommonConfig, ServiceConfigs
from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from fastapi.responses import JSONResponse
from fastapi_core import ManagedResource, create_app
from fastapi_core.config import AppConfig

from docmesh_doc.errors import (
    ErrorContract,
    dms_error_handler,
    error_response,
    validation_error_handler,
)
from docmesh_doc.router import router

def _check_dms_readiness(sdk: dms.DefaultDocumentManagementSDK) -> None:
    if not sdk.check_health().ok:
        raise RuntimeError("DMS dependency unavailable")


def sdk_from_environment() -> dms.DefaultDocumentManagementSDK:
    environment = dict(os.environ)
    environment["DMS_METADATA_BACKEND"] = "postgresql"
    return dms.create_sdk_from_environment(environment)


def create_application(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
    *,
    config: AppConfig | None = None,
    settings: ServiceConfigs | None = None,
    include_auth_router: bool = True,
) -> FastAPI:
    if settings is None and sdk is not None:
        settings = ServiceConfigs(common=CommonConfig())

    dms_resource = ManagedResource(
        name="dms",
        factory=lambda _application: sdk if sdk is not None else sdk_from_environment(),
        healthcheck=_check_dms_readiness,
        required=True,
    )
    application = create_app(
        config=config,
        settings=settings,
        include_auth_router=include_auth_router,
        resources=(dms_resource,),
    )

    async def forbidden_handler(request: Request, exc: PermissionError) -> JSONResponse:
        return error_response(request, ErrorContract(403, "FORBIDDEN", "Permission denied."))

    application.add_exception_handler(dms.DmsError, dms_error_handler)
    application.add_exception_handler(RequestValidationError, validation_error_handler)
    application.add_exception_handler(PermissionError, forbidden_handler)
    application.include_router(router)
    return application


app = create_application()
