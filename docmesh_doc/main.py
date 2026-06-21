from __future__ import annotations

from contextlib import asynccontextmanager
from typing import AsyncIterator

from dms.sdk import DocumentManagementSDK
from fastapi import FastAPI
from fastapi_core import EnvConfig, ServiceSettings, create_app as create_fastapi_core_app
from fastapi_core.dependencies.config import set_state_value
from fastapi_core.lifecycle import create_managed_lifespan

from .assembly import SdkFactory, build_dms_sdk
from .router import router as documents_router


def create_app(
    config: EnvConfig | None = None,
    settings: ServiceSettings | None = None,
    *,
    sdk_factory: SdkFactory | None = None,
) -> FastAPI:
    config = config or EnvConfig()
    settings = settings or ServiceSettings.from_yaml(config.config_path)
    host_lifespan = create_managed_lifespan(config, settings)
    sdk_factory = sdk_factory or build_dms_sdk

    @asynccontextmanager
    async def lifespan(app: FastAPI) -> AsyncIterator[None]:
        async with host_lifespan(app):
            sdk = sdk_factory(app, config)
            set_state_value(app, "dms_sdk", sdk)
            try:
                yield
            finally:
                _close_sdk(sdk)

    app = create_fastapi_core_app(
        config=config,
        settings=settings,
        lifespan=lifespan,
    )
    app.include_router(documents_router)
    return app


def _close_sdk(sdk: DocumentManagementSDK) -> None:
    close = getattr(sdk, "close", None)
    if callable(close):
        close()


app = create_app()
