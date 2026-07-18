from __future__ import annotations

import os

import dms
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi_core import ManagedResource, create_app, register_error_mapper
from fastapi_core.config import AppConfig

from docmesh_doc.errors import (
    map_dms_error,
    map_permission_error,
    map_validation_error,
    render_error,
)
from docmesh_doc.router import router

def _check_dms_readiness(sdk: dms.DefaultDocumentManagementSDK) -> None:
    if not sdk.check_health().ok:
        raise RuntimeError("DMS dependency unavailable")


def sdk_from_environment() -> dms.DefaultDocumentManagementSDK:
    environment = dict(os.environ)
    environment.pop("POSTGRES_DSN", None)
    environment["DMS_METADATA_BACKEND"] = "postgresql"
    environment["DMS_CONFIGURATION_STRICT"] = "true"
    diagnosis = dms.diagnose_environment(environment)
    if not diagnosis.valid:
        missing = ", ".join(diagnosis.missing_required_keys)
        detail = f"; missing required keys: {missing}" if missing else ""
        raise dms.ConfigurationError(f"Invalid DMS environment{detail}")
    return dms.create_sdk_from_environment(environment)


def create_application(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
    *,
    config: AppConfig | None = None,
    include_auth_router: bool = True,
) -> FastAPI:
    dms_resource = ManagedResource(
        name="dms",
        factory=lambda _application: sdk if sdk is not None else sdk_from_environment(),
        healthcheck=_check_dms_readiness,
        required=True,
    )
    application = create_app(
        config=config,
        include_auth_router=include_auth_router,
        resources=(dms_resource,),
        error_renderer=render_error,
    )

    register_error_mapper(application, dms.DmsError, map_dms_error)
    register_error_mapper(application, RequestValidationError, map_validation_error)
    register_error_mapper(application, PermissionError, map_permission_error)
    application.include_router(router)
    return application


app = create_application()
