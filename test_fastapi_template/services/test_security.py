import pytest

from fastapi_template.core.config import EnvSettings, load_config
from fastapi_template.core.security import User
from fastapi_template.services.security import (
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


def test_authenticate(auth_provider):
    """Test that authenticate_user returns a valid token structure."""
    token = authenticate(
        provider=auth_provider,
        username=settings.keycloak_username,
        password=settings.keycloak_password
    )
    assert isinstance(token, Token)
    assert len(token.access_token) > 0


def test_refresh_token(auth_provider, token):
    """Test that refresh_token returns a valid token structure."""
    new_token = refresh_token(provider=auth_provider, token=token.refresh_token)
    assert isinstance(new_token, Token)
    assert len(new_token.access_token) > 0


@pytest.fixture(scope="module")
def token(auth_provider):
    return authenticate(
        provider=auth_provider,
        username=settings.keycloak_username,
        password=settings.keycloak_password
    )


def test_decode_token(token, auth_provider, auth_config):
    """Test that decode_token returns a valid payload structure."""
    payload = decode_token(provider=auth_provider, token=token.access_token, config=auth_config)
    assert isinstance(payload, User)
