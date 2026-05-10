from functools import lru_cache
import httpx

from fastapi_template.core.config import KeycloakConfig, AuthConfig
from fastapi_template.core.exceptions import AuthError
from fastapi_template.core.security import KeycloakAuthProvider, Token


# @lru_cache(maxsize=1)
def get_auth_provider(config: KeycloakConfig) -> KeycloakAuthProvider:
    return KeycloakAuthProvider(
        url=str(config.http_url),
        realm=config.realm,
        client_id=config.client_id,
        client_secret=config.client_secret,
    )


def authenticate(provider: KeycloakAuthProvider, username: str, password: str) -> Token:
    """Authenticate user with Keycloak and return token payload.
    
    This is the high-level service function that orchestrates authentication:
    1. Requests token from Keycloak (core.security.get_token_from_keycloak)
    2. Decodes and validates the token (core.security.decode_token)
    
    Args:
        username: Keycloak username
        password: Keycloak password
    
    Returns:
        Dictionary with token and metadata:
        - access_token: JWT access token string
        - token_type: Token type (Bearer)
    
    Raises:
        HTTPException: 401 for invalid credentials, 502/504 for service errors
    """
    if not isinstance(provider, KeycloakAuthProvider):
        raise ValueError("Invalid auth provider instance")
    if not isinstance(username, str) or not username:
        raise ValueError("Username must be a non-empty string")
    if not isinstance(password, str) or not password:
        raise ValueError("Password must be a non-empty string")

    try:
        token = provider.authenticate(username=username, password=password)
        return token
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
    except Exception as e:
        raise AuthError(
            status_code=500,
            error="internal_error",
            error_description="An unexpected error occurred during authentication",
        )


def refresh_token(provider: KeycloakAuthProvider, token: str):
    '''Refresh access token using Keycloak refresh token.

    Args:
        provider: KeycloakAuthProvider instance
        token: Refresh token string

    Returns:
        New access token string
    '''
    if not isinstance(provider, KeycloakAuthProvider):
        raise ValueError("Invalid auth provider instance")
    if not isinstance(token, str) or not token:
        raise ValueError("Token must be a non-empty string")

    try:
        token = provider.refresh_access_token(token=token)
        return token
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
    except Exception as e:
        raise AuthError(
            status_code=500,
            error="internal_error",
            error_description="An unexpected error occurred during token refresh",
        ) from e


def decode_token(provider: KeycloakAuthProvider, token: str, config: AuthConfig):
    """Decode and validate JWT token based on configured security policy.

    Args:
        provider: AuthProvider instance to use for decoding
        token: JWT token string
        config: AuthConfig with security settings

    Returns:
        User: User object with claims from the token
    """
    if not isinstance(provider, KeycloakAuthProvider):
        raise ValueError("Invalid auth provider instance")
    if not isinstance(token, str) or not token:
        raise ValueError("Token must be a non-empty string")
    if not isinstance(config, AuthConfig):
        raise ValueError("Invalid auth config instance")

    if config.verify_jwt:
        return provider.decode_token(token=token)
    else:
        return provider.decode_token_insecure(token=token)
