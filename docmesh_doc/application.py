from typing import Any

import dms
from fastapi import FastAPI
from fastapi.exceptions import RequestValidationError
from fastapi_core import (
    DomainModule,
    ErrorMapperSpec,
    ResourceBinding,
    TransportPolicy,
    create_app,
)
from fastapi_core.config import AppConfig

from docmesh_doc.dependencies import DMS_RESOURCE
from docmesh_doc.dms_factory import create_dms_sdk
from docmesh_doc.errors import (
    DMS_ERROR_MAPPER,
    map_validation_error,
    render_error,
)
from docmesh_doc.router import router
from docmesh_doc.schemas import ErrorResponse


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
            ResourceBinding(
                key=DMS_RESOURCE,
                factory=lambda _application: (
                    sdk if sdk is not None else create_dms_sdk()
                ),
                healthcheck=lambda current: current.check_health().ok,
                required=True,
            ),
        ),
        error_mappers=(
            DMS_ERROR_MAPPER,
            ErrorMapperSpec(RequestValidationError, map_validation_error),
        ),
        transport_policy=TransportPolicy(
            validation_status=400,
            validation_response_model=ErrorResponse,
            include_synthetic_422=False,
        ),
    )
    return create_app(
        config=config,
        include_auth_router=include_auth_router,
        modules=(documents,),
        error_renderer=render_error,
        auth_provider=auth_provider,
    )
