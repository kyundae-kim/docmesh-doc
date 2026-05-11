from collections.abc import Callable
from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jwt import InvalidTokenError
import logging

from docmesh_doc.core.exceptions import AuthError
from docmesh_doc.core.security import User, KeycloakAuthProvider
from docmesh_doc.core.config import Environment
from docmesh_doc.services.security import decode_token
from docmesh_doc.dependencies.config import get_config, ServiceConfig, get_env, EnvSettings


logger = logging.getLogger(__name__)
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/token")


def get_auth_provider(request: Request) -> KeycloakAuthProvider:
    """Retrieve cached KeycloakAuthProvider from application state."""
    return request.app.state.auth_provider


def get_current_user(
    token: str = Depends(oauth2_scheme),
    provider: KeycloakAuthProvider = Depends(get_auth_provider),
    config: ServiceConfig = Depends(get_config),
    settings: EnvSettings = Depends(get_env),
):
    """Extract and validate current user from JWT token."""
    try:
        if settings.env == Environment.DEV:
            logger.debug("Development environment detected, skipping JWT validation and returning dummy user")
            return User(
                sub="dummy-user-id",
                preferred_username="test user",
                email="dummy-user@example.com",
                name="test",
                roles=["user"],
                scopes=["profile"],
             )

        user = decode_token(provider=provider, token=token, config=config.auth)
        return user
    except InvalidTokenError as e:
        logger.warning("JWT validation failed: %s", e)
        raise AuthError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            error="invalid_token",
            error_description="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except KeyError as e:
        logger.warning("JWT payload missing expected claim: %s", e)
        raise AuthError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            error="invalid_token",
            error_description="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from e
    except AuthError:
        raise
    except Exception as exc:
        logger.exception("Unexpected error during JWT validation")
        raise AuthError(
            status_code=status.HTTP_401_UNAUTHORIZED,
            error="invalid_token",
            error_description="Invalid authentication credentials",
            headers={"WWW-Authenticate": "Bearer"},
        ) from exc


def require_permissions(
    *,
    required_roles: tuple[str, ...] = (),
    required_scopes: tuple[str, ...] = (),
) -> Callable:
    """Create a dependency that enforces role and scope checks."""

    def permission_checker(current_user: User = Depends(get_current_user), config: EnvSettings = Depends(get_env)) -> User:
        missing_roles = [role for role in required_roles if role not in current_user.roles]
        missing_scopes = [scope for scope in required_scopes if scope not in current_user.scopes]

        if config.env == Environment.DEV:
            logger.debug("Development environment detected, skipping permission checks")
            return current_user

        if not missing_roles and not missing_scopes:
            return current_user

        missing_parts: list[str] = []
        if missing_roles:
            missing_parts.append(f"roles: {', '.join(missing_roles)}")
        if missing_scopes:
            missing_parts.append(f"scopes: {', '.join(missing_scopes)}")

        raise AuthError(
            status_code=status.HTTP_403_FORBIDDEN,
            error="insufficient_scope",
            error_description=f"Missing required {', '.join(missing_parts)}",
        )

    return permission_checker


def require_roles(*required_roles: str) -> Callable:
    """Create a dependency that enforces realm role checks."""
    return require_permissions(required_roles=tuple(required_roles))


def require_scopes(*required_scopes: str) -> Callable:
    """Create a dependency that enforces scope checks."""
    return require_permissions(required_scopes=tuple(required_scopes))
