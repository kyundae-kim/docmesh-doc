from __future__ import annotations

import dms
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi_core import ManagedResource, create_app, register_error_mapper
from fastapi_core.config import AppConfig

from docmesh_doc import dms_runtime
from docmesh_doc.errors import (
    map_dms_error,
    map_permission_error,
    map_validation_error,
    render_error,
)
from docmesh_doc.router import router


def build_dms_resource(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
) -> ManagedResource[dms.DefaultDocumentManagementSDK]:
    return ManagedResource(
        name="dms",
        factory=lambda _application: (
            sdk if sdk is not None else dms_runtime.create_dms_sdk()
        ),
        healthcheck=dms_runtime.check_dms_readiness,
        required=True,
    )


def create_application(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
    *,
    config: AppConfig | None = None,
    include_auth_router: bool = True,
) -> FastAPI:
    application = create_app(
        config=config,
        include_auth_router=include_auth_router,
        resources=(build_dms_resource(sdk),),
        error_renderer=render_error,
    )

    register_error_mapper(application, dms.DmsError, map_dms_error)
    register_error_mapper(application, RequestValidationError, map_validation_error)
    register_error_mapper(application, PermissionError, map_permission_error)
    application.include_router(router)
    return application
