from __future__ import annotations

import os

import dms
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi_core import ManagedResource, create_app, register_error_mapper
from fastapi_core.config import AppConfig

from docmesh_doc.errors import (
    map_dms_error,
    map_validation_error,
    render_error,
)
from docmesh_doc.router import router


def create_application(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
    *,
    config: AppConfig | None = None,
    include_auth_router: bool = True,
) -> FastAPI:
    application = create_app(
        config=config,
        include_auth_router=include_auth_router,
        resources=(
            ManagedResource(
                name="dms",
                factory=lambda _application: (
                    sdk
                    if sdk is not None
                    else dms.create_sdk_from_environment(dict(os.environ))
                ),
                healthcheck=lambda current: current.check_health().ok,
                required=True,
            ),
        ),
        error_renderer=render_error,
    )

    register_error_mapper(application, dms.DmsError, map_dms_error)
    register_error_mapper(application, RequestValidationError, map_validation_error)
    application.include_router(router)
    return application
