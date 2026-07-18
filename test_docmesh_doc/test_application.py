from __future__ import annotations

import os

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.config import AppConfig

from docmesh_doc.application import create_application
from test_docmesh_doc.support import NOW, FakeSDK, client_for


def test_application_creates_dms_sdk_from_process_environment_at_startup(monkeypatch):
    sdk = FakeSDK()
    captured_environment = None
    monkeypatch.setenv("DMS_METADATA_BACKEND", "postgresql")
    monkeypatch.setenv("DMS_CONFIGURATION_STRICT", "true")
    monkeypatch.delenv("POSTGRES_DSN", raising=False)

    def create_sdk(environment):
        nonlocal captured_environment
        captured_environment = environment
        return sdk

    monkeypatch.setattr(
        dms,
        "diagnose_environment",
        lambda _environment: pytest.fail("application must delegate diagnosis to DMS"),
    )
    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)
    app = create_application(
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    with TestClient(app):
        assert app.state.resource_registry.require("dms") is sdk

    assert captured_environment == dict(os.environ)
    assert captured_environment is not os.environ


def test_dms_sdk_is_owned_by_the_managed_resource_registry():
    sdk = FakeSDK()
    app = create_application(
        sdk,
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    with TestClient(app):
        assert app.state.resource_registry.require("dms") is sdk
        assert not hasattr(app.state, "dms_sdk")
        assert not hasattr(app.state, "readiness_checks")

    assert sdk.closed is True


def test_lifespan_closes_sdk():
    sdk = FakeSDK()
    with client_for(sdk):
        assert sdk.closed is False

    assert sdk.closed is True


def test_readiness_includes_required_dms_sdk_check():
    sdk = FakeSDK()

    with client_for(sdk) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 200
    assert response.json()["details"]["dms"]["ok"] is True
    assert response.json()["details"]["dms"]["required"] is True


def test_readiness_returns_503_when_dms_sdk_is_unhealthy():
    class UnhealthySDK(FakeSDK):
        def check_health(self):
            return dms.HealthStatus(
                ok=False,
                services=[
                    dms.ServiceHealth(
                        service="postgres",
                        ok=False,
                        latency_ms=1,
                        error="connection failed",
                    )
                ],
                checked_at=NOW,
            )

    with client_for(UnhealthySDK()) as client:
        response = client.get("/health/readiness")

    assert response.status_code == 503
    assert response.json()["status"] == "error"
    assert response.json()["details"]["dms"]["ok"] is False
    assert "connection failed" not in response.text


def test_sdk_environment_failure_aborts_application_startup(monkeypatch):
    def failing_create_dms_sdk(_environment):
        raise RuntimeError("SDK startup failed")

    monkeypatch.setattr(dms, "create_sdk_from_environment", failing_create_dms_sdk)
    app = create_application(
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    with pytest.raises(RuntimeError, match="SDK startup failed"):
        with TestClient(app):
            pass


def test_sdk_close_failure_is_reported_during_shutdown():
    class CloseFailingSDK(FakeSDK):
        def close(self):
            self.closed = True
            raise RuntimeError("SDK close failed")

    sdk = CloseFailingSDK()

    with pytest.RaisesGroup(RuntimeError, match="managed resource shutdown failed"):
        with client_for(sdk):
            pass

    assert sdk.closed is True
