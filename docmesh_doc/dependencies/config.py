from fastapi import Request

from fastapi_core.core.config import EnvConfig, ServiceSettings


def get_env(request: Request) -> EnvConfig:
    return request.app.state.env_config


def get_config(request: Request) -> ServiceSettings:
    return request.app.state.service_settings
