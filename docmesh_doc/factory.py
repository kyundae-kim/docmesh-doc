from contextlib import asynccontextmanager

from fastapi import FastAPI

from fastapi_core.core.config import EnvConfig, ServiceSettings
from fastapi_core.dependencies.auth import set_auth_provider
from fastapi_core.dependencies.database import set_db_engine
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

        set_auth_provider(app, config=config)
        set_db_engine(app, config=config)
        set_minio_client(app, config=config)
        app.state.metadata_service = MetadataService(engine=app.state.db_engine)
        try:
            yield
        finally:
            app.state.db_engine.dispose()

    app = create_core_app(
        config=config,
        settings=settings,
        lifespan=lifespan,
        include_auth_router=True,
    )

    include_routes(app)
    register_exception_handlers(app)
    return app
