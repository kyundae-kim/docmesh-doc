from enum import Enum

from pydantic import BaseModel, Field
from pydantic_settings import BaseSettings, SettingsConfigDict

from fastapi_core.core.config import (
    AuthSettings,
    EnvConfig,
    Environment,
    KeycloakConfig,
    ServiceSettings,
)


class LoggingLevel(str, Enum):
    WARNING = "WARNING"
    INFO = "INFO"
    DEBUG = "DEBUG"


class MinioConfig(BaseModel):
    endpoint: str = Field(default="minio:9000")
    access_key: str = Field(default="admin")
    secret_key: str = Field(default="password")
    bucket_name: str = Field(default="default")
    secure: bool = Field(default=False)


class EnvSettings(BaseSettings):
    env: Environment = Field(default=Environment.DEV)
    config_path: str = Field(default=".devcontainer/config.yaml")
    root_path: str = Field(default="/")

    keycloak_username: str = Field(default="test")
    keycloak_password: str = Field(default="test")

    minio: MinioConfig = Field(default_factory=MinioConfig)

    model_config = SettingsConfigDict(env_nested_delimiter="__", populate_by_name=True)


class LoggingConfig(BaseModel):
    level: LoggingLevel = Field(default=LoggingLevel.DEBUG)


class CorsConfig(BaseModel):
    origins: list[str] = Field(default_factory=lambda: ["*"])
    credentials: bool = Field(default=False)


AuthConfig = AuthSettings


class ServiceConfig(BaseModel):
    logging: LoggingConfig = Field(default_factory=LoggingConfig)
    cors: CorsConfig = Field(default_factory=CorsConfig)
    auth: AuthConfig = Field(default_factory=AuthConfig)
    keycloak: KeycloakConfig = Field(default_factory=KeycloakConfig)


def load_config(path: str) -> ServiceConfig:
    env = EnvConfig()
    settings = ServiceSettings.from_yaml(path)

    return ServiceConfig(
        logging=LoggingConfig(level=LoggingLevel(env.logging.level)),
        cors=CorsConfig(
            origins=settings.cors.origins,
            credentials=settings.cors.credentials,
        ),
        auth=settings.auth,
        keycloak=env.keycloak,
    )


__all__ = [
    "AuthConfig",
    "CorsConfig",
    "EnvConfig",
    "Environment",
    "EnvSettings",
    "KeycloakConfig",
    "LoggingConfig",
    "LoggingLevel",
    "MinioConfig",
    "ServiceConfig",
    "ServiceSettings",
    "load_config",
]
