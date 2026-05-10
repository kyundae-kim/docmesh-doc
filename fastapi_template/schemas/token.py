from pydantic import BaseModel, Field


class TokenResponse(BaseModel):
    access_token: str = Field(..., description="The access token issued by Keycloak")
    token_type: str = Field("Bearer", description="The type of the token, typically 'Bearer'")
    refresh_token: str | None = Field(None, description="The refresh token used to obtain new access tokens")
    expires_in: int | None = Field(None, description="Access token expiration time in seconds")
    refresh_expires_in: int | None = Field(None, description="Refresh token expiration time in seconds")
    scope: str | None = Field(None, description="OAuth2 scopes granted for the token")
