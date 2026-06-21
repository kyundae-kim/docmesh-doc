from __future__ import annotations

from dms.sdk import AuthenticationError, ConfigurationError
from docmesh_py_core.keycloak import AccessTokenResult, AuthenticatedUser
from fastapi_core import KeycloakAuthProvider


class FastapiCoreAuthAdapter:
    """Adapt fastapi-core's auth provider to the DMS auth service contract."""

    def __init__(self, provider: KeycloakAuthProvider | None) -> None:
        self.provider = provider

    def fetch_access_token(self, *, scope: str | None = None) -> AccessTokenResult:
        if self.provider is None:
            raise ConfigurationError("Auth provider is not configured")

        try:
            token_payload = self.provider.authenticate("", "")
        except Exception as exc:  # pragma: no cover - exercised with fakes/tests
            raise AuthenticationError("Failed to fetch access token") from exc

        access_token = token_payload.get("access_token")
        token_type = token_payload.get("token_type", "Bearer")
        expires_in = int(token_payload.get("expires_in", 0))
        refresh_token = token_payload.get("refresh_token")
        payload_scope = token_payload.get("scope") or scope

        if not access_token:
            raise AuthenticationError("Auth provider returned no access_token")

        return AccessTokenResult(
            access_token=access_token,
            token_type=token_type,
            expires_in=expires_in,
            refresh_token=refresh_token,
            scope=payload_scope,
        )

    def extract_user_info(self, token: str) -> AuthenticatedUser:
        if self.provider is None:
            raise ConfigurationError("Auth provider is not configured")

        try:
            payload = self.provider.decode_token(token)
            user = self.provider.to_user(payload)
        except Exception as exc:  # pragma: no cover - exercised with fakes/tests
            raise AuthenticationError("Failed to authenticate user token") from exc

        return AuthenticatedUser(
            sub=user.sub,
            preferred_username=user.username,
            email=user.email,
            given_name=None,
            family_name=None,
            name=user.name,
            realm_roles=list(user.roles),
            client_roles={},
            claims=payload,
        )
