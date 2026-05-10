from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from docmesh_doc.core.config import EnvSettings, load_config
from docmesh_doc.core.exceptions import register_exception_handlers
from docmesh_doc.services.security import get_auth_provider
from docmesh_doc.services.document import DocumentService
from docmesh_doc.services.logging import setup_logging
from docmesh_doc.routes import include_routes


def create_app() -> FastAPI:
    env_settings = EnvSettings()
    config = load_config(env_settings.config_path)

    setup_logging(config=config.logging)
    logger = logging.getLogger(__name__)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        logger.info(
            "Application startup",
            extra={"environment": env_settings.environment.value},
        )

        app.state.env_settings = env_settings
        app.state.app_config = config
        app.state.auth_provider = get_auth_provider(config=config.keycloak)
        app.state.document_service = DocumentService()

        yield

        # 앱 종료 동작

    app = FastAPI(lifespan=lifespan)

    app.add_middleware(
        CORSMiddleware,
        allow_origins=config.cors.origins,
        allow_credentials=config.cors.credentials,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    include_routes(app)
    register_exception_handlers(app)
    
    return app
