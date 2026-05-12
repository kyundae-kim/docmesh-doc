import pytest

from docmesh_doc.core.config import EnvSettings, load_config
from docmesh_doc.core.security import User
from docmesh_doc.services.security import (
    KeycloakAuthProvider,
    get_auth_provider,
    authenticate,
    decode_token,
    refresh_token,
    Token
)


settings = EnvSettings()


@pytest.fixture(scope="module")
def keycloak_config():
    config = load_config(settings.config_path)
    return config.keycloak


@pytest.fixture(scope="module")
def auth_config():
    config = load_config(settings.config_path)
    return config.auth


def test_get_auth_provider(keycloak_config):
    provider = get_auth_provider(config=keycloak_config)
    assert isinstance(provider, KeycloakAuthProvider)


@pytest.fixture(scope="module")
def auth_provider(keycloak_config):
    return KeycloakAuthProvider(
        url=str(keycloak_config.http_url),
        realm=keycloak_config.realm,
        client_id=keycloak_config.client_id,
    )
