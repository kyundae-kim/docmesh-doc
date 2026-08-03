from typing import Any

import dms
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi_core import DomainModule, ErrorMapperSpec, ManagedResource, create_app
from fastapi_core.config import AppConfig

from docmesh_doc.dependencies import DMS_RESOURCE
from docmesh_doc.dms_factory import create_dms_sdk
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
    auth_provider: Any | None = None,
) -> FastAPI:
    documents = DomainModule(
        name="documents",
        routers=(router,),
        resources=(
            ManagedResource(
                name=DMS_RESOURCE,
                factory=lambda _application: (
                    sdk if sdk is not None else create_dms_sdk()
                ),
                healthcheck=lambda current: current.check_health().ok,
                required=True,
            ),
        ),
        error_mappers=(
            ErrorMapperSpec(dms.DmsError, map_dms_error),
            ErrorMapperSpec(RequestValidationError, map_validation_error),
        ),
    )
    return create_app(
        config=config,
        include_auth_router=include_auth_router,
        modules=(documents,),
        error_renderer=render_error,
        auth_provider=auth_provider,
    )
