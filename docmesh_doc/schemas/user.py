from pydantic import BaseModel, Field

class UserInfo(BaseModel):
    sub: str = Field(..., description="The unique identifier of the user")
    name: str | None = Field(None, description="The full name of the user")
    email: str | None = Field(None, description="The email address of the user")


class TokenResponse(BaseModel):
    access_token: str = Field(..., description="The JWT access token")
    refresh_token: str = Field(..., description="The JWT refresh token")
    token_type: str = Field(..., description="The type of the token, typically 'Bearer'")
    expires_in: int = Field(..., description="The number of seconds until the access token expires")
    refresh_expires_in: int = Field(..., description="The number of seconds until the refresh token expires")
    scope: str = Field(..., description="The scopes associated with the access token")
