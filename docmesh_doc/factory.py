from contextlib import asynccontextmanager

from fastapi import FastAPI

from fastapi_core.core.config import EnvConfig, ServiceSettings
from fastapi_core.dependencies.auth import set_auth_provider
from fastapi_core.dependencies.storage import set_minio_client
from fastapi_core.factory import create_app as create_core_app

from docmesh_doc.core.exceptions import register_exception_handlers
from docmesh_doc.routes import include_routes
from docmesh_doc.services.metadata import MetadataService


def create_app() -> FastAPI:
    config = EnvConfig()
    settings = ServiceSettings.from_yaml(config.config_path)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        app.state.env_config = config
        app.state.service_settings = settings
        app.state.metadata_service = MetadataService(config.db)

        set_auth_provider(app, config=config)
        set_minio_client(app, config=config)
        yield

    app = create_core_app(
        config=config,
        settings=settings,
        lifespan=lifespan,
        include_auth_router=True,
    )

    include_routes(app)
    register_exception_handlers(app)
    return app
