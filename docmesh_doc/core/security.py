from pydantic import BaseModel, Field

from fastapi_core.core.auth import KeycloakAuthProvider, extract_roles, extract_scopes


class User(BaseModel):
    sub: str
    preferred_username: str | None = None
    username: str | None = None
    email: str | None = None
    name: str | None = None
    roles: list[str] = Field(default_factory=list)
    scopes: list[str] = Field(default_factory=list)


class Token(BaseModel):
    access_token: str
    refresh_token: str | None = None
    token_type: str = "bearer"
    expires_in: int | None = None
    refresh_expires_in: int | None = None
    scope: str | None = None


__all__ = [
    "KeycloakAuthProvider",
    "Token",
    "User",
    "extract_roles",
    "extract_scopes",
]
