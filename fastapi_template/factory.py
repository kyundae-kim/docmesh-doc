from contextlib import asynccontextmanager
import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from fastapi_template.core.config import EnvSettings, load_config
from fastapi_template.core.exceptions import register_exception_handlers
from fastapi_template.services.security import get_auth_provider
from fastapi_template.services.logging import setup_logging
from fastapi_template.routes import include_routes


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
