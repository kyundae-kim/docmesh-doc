from collections.abc import Callable

from fastapi import Depends, status

from fastapi_core.dependencies.auth import (
    get_auth_provider as core_get_auth_provider,
)
from fastapi_core.dependencies.auth import (
    get_current_user as core_get_current_user,
)
from fastapi_core.schemas.user import UserInfo

from docmesh_doc.core.exceptions import AuthError


# Backward-compatible alias used by existing routes/tests
User = UserInfo


def get_auth_provider(*args, **kwargs):
    return core_get_auth_provider(*args, **kwargs)


def get_current_user(current_user: UserInfo = Depends(core_get_current_user)) -> UserInfo:
    return current_user


def require_permissions(
    *,
    required_roles: tuple[str, ...] = (),
    required_scopes: tuple[str, ...] = (),
) -> Callable:
    def permission_checker(current_user: User = Depends(get_current_user)) -> User:
        user_roles = set(getattr(current_user, "roles", []) or [])
        user_scopes = set(getattr(current_user, "scopes", []) or [])

        missing_roles = [role for role in required_roles if role not in user_roles]
        missing_scopes = [scope for scope in required_scopes if scope not in user_scopes]

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
    return require_permissions(required_roles=tuple(required_roles))


def require_scopes(*required_scopes: str) -> Callable:
    return require_permissions(required_scopes=tuple(required_scopes))
