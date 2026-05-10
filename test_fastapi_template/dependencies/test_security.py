import pytest

from fastapi_template.core.exceptions import AuthError
from fastapi_template.core.security import User
from fastapi_template.dependencies.security import require_permissions


def _build_user(roles: set[str], scopes: set[str]) -> User:
    return User(
        sub="subject",
        preferred_username="tester",
        email="tester@example.com",
        name="Tester",
        roles=roles,
        scopes=scopes,
    )


def test_require_permissions_role_and_scope_success():
    checker = require_permissions(required_roles=("read",), required_scopes=("profile",))
    user = _build_user(roles={"read", "write"}, scopes={"profile", "email"})

    assert checker(current_user=user) == user


def test_require_permissions_role_and_scope_failure():
    checker = require_permissions(required_roles=("read", "delete"), required_scopes=("profile", "admin"))
    user = _build_user(roles={"read"}, scopes={"profile"})

    with pytest.raises(AuthError) as exc:
        checker(current_user=user)

    assert exc.value.status_code == 403
    assert exc.value.error == "insufficient_scope"
    assert "roles: delete" in exc.value.error_description
    assert "scopes: admin" in exc.value.error_description
