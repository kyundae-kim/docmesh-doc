import logging

from fastapi import APIRouter

from docmesh_doc.schemas import HealthCheckResponse


logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/health/live", tags=["Health"], response_model=HealthCheckResponse)
def liveness_probe():
    logger.info("Get /health/live")
    return HealthCheckResponse(status="live")


@router.get("/health/ready", tags=["Health"], response_model=HealthCheckResponse)
def readiness_probe():
    logger.info("Get /health/ready")
    return HealthCheckResponse(status="ready")
