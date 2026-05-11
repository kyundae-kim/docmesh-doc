import pytest
from fastapi.testclient import TestClient

from docmesh_doc import factory
from docmesh_doc.schemas import HealthCheckResponse


@pytest.fixture(scope="module")
def app():
    with TestClient(factory.create_app()) as client:
        yield client


def test_liveness_probe(app):
    response = app.get("/health/live")
    assert response.status_code == 200
    assert response.json() == HealthCheckResponse(status="live").model_dump()


def test_readiness_probe(app):
    response = app.get("/health/ready")
    assert response.status_code == 200
    assert response.json() == HealthCheckResponse(status="ready").model_dump()
