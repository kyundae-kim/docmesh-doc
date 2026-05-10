from fastapi import APIRouter, Depends
import httpx
import logging

from docmesh_doc.dependencies.config import get_config, ServiceConfig
from docmesh_doc.schemas import HealthCheckResponse


logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/health/live", tags=["Health"], response_model=HealthCheckResponse)
def liveness_probe():
    """
    Liveness probe: Checks if the FastAPI server is running.
    """
    logger.info("Get /health/live")

    logger.info("Get /health/live - server is alive")
    return HealthCheckResponse(status="live")

@router.get("/health/ready", tags=["Health"], response_model=HealthCheckResponse)
def readiness_probe(config: ServiceConfig = Depends(get_config)):
    """
    Readiness probe: Checks if dependencies are available.
    Add actual dependency checks as needed.
    """
    logger.info("Get /health/ready")

    try:
        response = httpx.get(
            f"{config.keycloak.manage_url}health/ready",
            timeout=5.0,
        )
        if response.status_code != 200:
            logger.info(f"Keycloak readiness check failed with status code {response.status_code}")
            return HealthCheckResponse(status="not ready", reason="Keycloak is not healthy")
    except Exception as e:
        logger.info(f"Keycloak readiness check failed with exception: {str(e)}")
        logger.info(
            "Keycloak readiness check keycloak url: %shealth/ready",
            config.keycloak.manage_url,
        )
        return HealthCheckResponse(status="not ready", reason=f"Keycloak check failed")

    logger.info("Get /health/ready - all checks passed")
    return HealthCheckResponse(status="ready")
