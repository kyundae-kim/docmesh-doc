from pydantic import BaseModel, Field


class HealthCheckResponse(BaseModel):
    status: str = Field(..., description="The health status of the application")
    reason: str | None = Field(None, description="Optional reason for unhealthy status")
