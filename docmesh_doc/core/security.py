import abc
from datetime import time
import logging
import uuid
import httpx
import jwt
from pydantic import BaseModel


class User(BaseModel):
    sub: str
    preferred_username: str | None = None
    email: str | None = None
    name: str | None = None
    roles: set[str] = set()
    scopes: set[str] = set()


class Token(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "Bearer"
    expires_in: int
    refresh_expires_in: int
    scope: str


class TokenRequest(BaseModel):
    client_id: str
    client_secret: str | None = None
    grant_type: str | None = None
    username: str | None = None
    password: str | None = None
    refresh_token: str | None = None


logger = logging.getLogger(__name__)


def extract_roles(payload: dict) -> set[str]:
    realm_access = payload.get("realm_access") or {}
    roles = realm_access.get("roles") or []
    if isinstance(roles, list):
        return {str(role) for role in roles}
    return set()


def extract_scopes(payload: dict) -> set[str]:
    scope = payload.get("scope")
    if isinstance(scope, str):
        return {token for token in scope.split(" ") if token}

    scp = payload.get("scp")
    if isinstance(scp, list):
        return {str(token) for token in scp}

    return set()


class AuthProvider(abc.ABC):
    @abc.abstractmethod
    def decode_token(self, token: str, jwk_client: jwt.PyJWKClient) -> User:
        raise NotImplementedError

    @abc.abstractmethod
    def decode_token_insecure(self, token: str) -> User:
        raise NotImplementedError

    @abc.abstractmethod
    def authenticate(self, username: str, password: str) -> Token:
        raise NotImplementedError
    
    @abc.abstractmethod
    def dummy_authenticate(self, username: str, password: str) -> Token:
        raise NotImplementedError

    @abc.abstractmethod
    def refresh_access_token(self, refresh_token: str) -> Token:
        raise NotImplementedError


class KeycloakAuthProvider(AuthProvider):
    def __init__(self, url: str, realm: str, client_id: str, client_secret: str | None = None):
        if not isinstance(url, str) or not url:
            raise ValueError("Keycloak URL must be a non-empty string")
        if not (url.startswith("http://") or url.startswith("https://")):
            raise ValueError("Keycloak URL must start with http:// or https://")
        if not url.endswith("/"):
            raise ValueError("Keycloak URL must end with a slash")
        if not isinstance(realm, str) or not realm:
            raise ValueError("Keycloak realm must not be empty")
        if not isinstance(client_id, str) or not client_id:
            raise ValueError("Keycloak client_id must not be empty")

        self.url = url
        self.realm = realm
        self.client_id = client_id
        self.client_secret = client_secret
        self.jwk_client = jwt.PyJWKClient(uri=f"{self.url}realms/{self.realm}/protocol/openid-connect/certs")
        self.issuer = f"{self.url}realms/{self.realm}"

    @property
    def token_url(self) -> str:
        return f"{self.url}realms/{self.realm}/protocol/openid-connect/token"
    
    @property
    def introspection_url(self) -> str:
        return f"{self.url}realms/{self.realm}/protocol/openid-connect/token/introspect"
    
    def to_user(self, payload: dict) -> User:
        return User(
            sub=payload["sub"],
            preferred_username=payload.get("preferred_username") or payload.get("username"),
            email=payload.get("email"),
            name=payload.get("name"),
            roles=extract_roles(payload),
            scopes=extract_scopes(payload),
        )

    def _request_token(self, form: TokenRequest) -> Token:
        response = httpx.post(self.token_url, data=form.model_dump(exclude_unset=True), timeout=5.0)
        response.raise_for_status()
        return Token(**response.json())

    def decode_token(self, token: str) -> User:
        """Decode and validate JWT token based on configured security policy.

        Args:
            token: JWT token string

        Returns:
            User: User object with claims from the token

        Raises:
            InvalidTokenError: if the token is malformed or missing expected claims
            KeyError: if expected claims are missing from the token
        """
        if not isinstance(token, str) or not token:
            raise ValueError("Token must be a non-empty string")

        signing_key = self.jwk_client.get_signing_key_from_jwt(token)
        payload = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            audience=self.client_id,
            issuer=self.issuer,
        )
        return self.to_user(payload)

    def decode_token_insecure(self, token: str) -> User:
        """Decode JWT without signature verification.

        Args:
            token: JWT token string

        Returns:
            User object with claims from the token

        Raises:
            InvalidTokenError: if the token is malformed or missing expected claims
            KeyError: if expected claims are missing from the token
            ValueError: if token is not a string
        """
        if not isinstance(token, str) or not token:
            raise ValueError("Token must be a non-empty string")
        
        payload = jwt.decode(token, options={"verify_signature": False})
        return self.to_user(payload)

    def authenticate(self, username: str, password: str):
        """Authenticate user and retrieve access token from Keycloak.

        Args:
                username: Keycloak username
                password: Keycloak password

        Returns:
                Token object

        Raises:
                HTTPException: 401 for invalid credentials, 502/504 for service errors
                httpx.TimeoutException: if the request to Keycloak times out
                httpx.RequestError: if there is a network error communicating with Keycloak
                httpx.HTTPStatusError: if Keycloak returns an unexpected HTTP status code
        """
        if not isinstance(username, str) or not username:
            raise ValueError("Username must be a non-empty string")
        if not isinstance(password, str) or not password:
            raise ValueError("Password must be a non-empty string")
        
        form = TokenRequest(client_id=self.client_id, client_secret=self.client_secret, grant_type="password", username=username, password=password)
        return self._request_token(form=form)

    def dummy_authenticate(self, username: str, password: str) -> Token:
        """Return a dummy token for development/testing purposes without authenticating against Keycloak.

        Args:
            username: Ignored, can be any string
            password: Ignored, can be any string

        Returns:
            Token: Dummy token object

        """
        now = int(time.time())
        payload = {
            "jti": str(uuid.uuid4()),
            "iss": "https://auth.example.com/realms/my-realm",
            "sub": "f81d4fae-7dec-11d0-a765-00a0c91e6bf6",    
            "aud": "my-api",
            "azp": "my-client-id",
            "typ": "Bearer",
            "iat": now,
            "nbf": now,
            "exp": now + 300,
            "realm_access": {"roles": ["user", "admin"]},
            "resource_access": {
                "my-api": {"roles": ["read", "write"]}
            },
        }

        token = jwt.encode(payload, key="dummy-secret", algorithm="HS256")

        return Token(access_token=token, token_type="Bearer")

    def refresh_access_token(self, token: str):
        if not isinstance(token, str) or not token:
            raise ValueError("Token must be a non-empty string")
        
        form = TokenRequest(client_id=self.client_id, client_secret=self.client_secret, grant_type="refresh_token", refresh_token=token)
        return self._request_token(form=form)
