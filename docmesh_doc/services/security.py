import httpx

from fastapi_core.core.auth import KeycloakAuthProvider
from fastapi_core.core.config import AuthSettings, KeycloakConfig

from docmesh_doc.core.exceptions import AuthError
from docmesh_doc.core.security import Token


def get_auth_provider(config: KeycloakConfig) -> KeycloakAuthProvider:
    return KeycloakAuthProvider(
        http_url=str(config.http_url),
        realm=config.realm,
        client_id=config.client_id,
        client_secret=config.client_secret,
    )


def authenticate(
    provider: KeycloakAuthProvider,
    username: str,
    password: str,
) -> dict:
    try:
        return provider.authenticate(username=username, password=password)
    except httpx.HTTPStatusError as exc:
        raise AuthError(
            status_code=401,
            error="invalid_grant",
            error_description="Invalid username or password",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except httpx.TimeoutException as exc:
        raise AuthError(
            status_code=504,
            error="temporarily_unavailable",
            error_description="Authentication provider timeout",
        ) from exc
    except httpx.RequestError as exc:
        raise AuthError(
            status_code=502,
            error="server_error",
            error_description="Authentication provider request failed",
        ) from exc


def decode_token(
    provider: KeycloakAuthProvider,
    token: str,
    config: AuthSettings,
):
    if config.verify_jwt:
        payload = provider.decode_token(token=token)
    else:
        payload = provider.decode_token_insecure(token=token)
    return provider.to_user(payload)


def refresh_token(provider: KeycloakAuthProvider, token: str):
    try:
        return provider.refresh_access_token(refresh_token=token)
    except httpx.HTTPStatusError as exc:
        raise AuthError(
            status_code=401,
            error="invalid_grant",
            error_description="Refresh token is invalid, expired, or revoked",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc
    except httpx.TimeoutException as exc:
        raise AuthError(
            status_code=504,
            error="temporarily_unavailable",
            error_description="Authentication provider timeout",
        ) from exc
    except httpx.RequestError as exc:
        raise AuthError(
            status_code=502,
            error="server_error",
            error_description="Authentication provider request failed",
        ) from exc
