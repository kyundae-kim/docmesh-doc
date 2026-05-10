from enum import Enum
from pydantic import BaseModel, Field, HttpUrl, field_validator
from pydantic_settings import BaseSettings, YamlConfigSettingsSource
import logging

class LoggingLevel(str, Enum):
    WARNING = "WARNING"
    INFO = "INFO"
    DEBUG = "DEBUG"


class Environment(str, Enum):
    DEV = "dev"
    TEST = "test"
    PROD = "prod"


class MinioConfig(BaseModel):
    endpoint: str = Field(default="localhost:9000")
    access_key: str = Field(default="admin")
    secret_key: str = Field(default="password123")
    bucket_name: str = Field(default="docmesh")
    secure: bool = Field(default=False)
    

class EnvSettings(BaseSettings):
    environment: Environment = Field(default=Environment.DEV)
    config_path: str = Field(default=".devcontainer/config.yaml")

    keycloak_username: str = Field(default="test")
    keycloak_password: str = Field(default="test")

    minio: MinioConfig = Field(default_factory=MinioConfig)


class LoggingConfig(BaseModel):
    level: LoggingLevel = Field(default=LoggingLevel.DEBUG)


class CorsConfig(BaseModel):
    origins: list[str] = Field(default_factory=lambda: ["*"])
    credentials: bool = Field(default=False)

    @field_validator("origins", mode="before")
    @classmethod
    def parse_origins(cls, value: str | list[str]) -> list[str]:
        if isinstance(value, str):
            return [origin.strip() for origin in value.split(",") if origin.strip()]
        return value


class AuthConfig(BaseModel):
    verify_jwt: bool = Field(default=True)
    allow_insecure_jwt_decode: bool = Field(default=False)
    use_introspection: bool = Field(default=False)


class KeycloakConfig(BaseModel):
    http_url: HttpUrl = Field(default="http://keycloak:8080/")
    manage_url: HttpUrl = Field(default="http://keycloak:9000/")
    realm: str = Field(default="restapi")
    client_id: str = Field(default="fastapi")
    client_secret: str | None = Field(default=None)


class ServiceConfig(BaseSettings):
    logging: LoggingConfig = Field(default_factory=LoggingConfig)
    cors: CorsConfig = Field(default_factory=CorsConfig)
    auth: AuthConfig = Field(default_factory=AuthConfig)
    keycloak: KeycloakConfig = Field(default_factory=KeycloakConfig)


logger = logging.getLogger(__name__)


def load_config(path: str) -> ServiceConfig:
    '''Utility function to load configuration from a specific YAML file path.'''

    try:
        yaml_source = YamlConfigSettingsSource(ServiceConfig, yaml_file=path)
        return ServiceConfig.model_validate(yaml_source())
    except Exception as e:
        logger.info("Failed to load config from %s: %s", path, e)
        return ServiceConfig()
