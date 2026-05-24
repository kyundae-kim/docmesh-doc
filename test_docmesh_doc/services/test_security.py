import pytest

from fastapi_core.core.auth import KeycloakAuthProvider
from fastapi_core.core.config import EnvConfig, ServiceSettings

from docmesh_doc.services.security import (
    authenticate,
    decode_token,
    get_auth_provider,
    refresh_token,
)


env = EnvConfig()
settings = ServiceSettings.from_yaml(env.config_path)


@pytest.fixture(scope="module")
def keycloak_config():
    return env.keycloak


@pytest.fixture(scope="module")
def auth_config():
    return settings.auth


def test_get_auth_provider(keycloak_config):
    provider = get_auth_provider(config=keycloak_config)
    assert isinstance(provider, KeycloakAuthProvider)


@pytest.fixture(scope="module")
def auth_provider(keycloak_config):
    return KeycloakAuthProvider(
        http_url=str(keycloak_config.http_url),
        realm=keycloak_config.realm,
        client_id=keycloak_config.client_id,
    )
