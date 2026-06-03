from fastapi.testclient import TestClient

from docmesh_doc import factory


def test_liveness_probe_uses_fastapi_core_endpoint():
    app = factory.create_app()

    with TestClient(app) as client:
        response = client.get("/health/liveness")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_readiness_probe_uses_fastapi_core_endpoint_when_checks_disabled():
    app = factory.create_app()
    app.state.settings.health.check_keycloak = False
    app.state.settings.health.check_database = False
    app.state.settings.health.check_minio = False

    with TestClient(app) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_legacy_health_endpoints_are_not_exposed():
    app = factory.create_app()

    with TestClient(app) as client:
        live_response = client.get("/health/live")
        ready_response = client.get("/health/ready")

    assert live_response.status_code == 404
    assert ready_response.status_code == 404
