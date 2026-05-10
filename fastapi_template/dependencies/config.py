from fastapi import Request

from fastapi_template.core.config import ServiceConfig, EnvSettings


def get_env(request: Request) -> EnvSettings:
    """Dependency to access application configuration."""
    return request.app.state.env_settings


def get_config(request: Request) -> ServiceConfig:
    """Dependency to access application configuration."""
    return request.app.state.app_config
