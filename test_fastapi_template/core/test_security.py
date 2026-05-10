import pytest

from fastapi_template.core.config import EnvSettings, load_config
from fastapi_template.core.security import (
    User,
    KeycloakAuthProvider,
    Token
)


settings = EnvSettings()
config = load_config(settings.config_path)


@pytest.fixture(scope="module")
def auth_provider():
    return KeycloakAuthProvider(
        url=str(config.keycloak.http_url),
        realm=config.keycloak.realm,
        client_id=config.keycloak.client_id
    )


@pytest.fixture(scope="module")
def token(auth_provider):
    token = auth_provider.authenticate(username=settings.keycloak_username, password=settings.keycloak_password)
    assert isinstance(token, Token)
    assert len(token.access_token) > 0

    return token


def test_authenticate(auth_provider):
    token = auth_provider.authenticate(username=settings.keycloak_username, password=settings.keycloak_password)
    assert isinstance(token, Token)
    assert len(token.access_token) > 0


def test_decode_token_insecure(auth_provider, token):
    user = auth_provider.decode_token_insecure(token.access_token)
    assert isinstance(user, User)


def test_decode_token(auth_provider, token):
    user = auth_provider.decode_token(token.access_token)
    assert isinstance(user, User)


def test_refresh_access_token(auth_provider, token):
    new_token = auth_provider.refresh_access_token(token.refresh_token)
    assert isinstance(new_token, Token)
    assert len(new_token.access_token) > 0
