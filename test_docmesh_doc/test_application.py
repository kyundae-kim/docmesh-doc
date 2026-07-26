from __future__ import annotations

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.config import AppConfig
from fastapi_core.testing import (
    assert_auth_router_contract,
    assert_health_contract,
    assert_module_contract,
)

from docmesh_doc.application import create_application
from test_docmesh_doc.support import NOW, FakeSDK, client_for


def test_application_delegates_process_environment_loading_to_dms(monkeypatch):
    sdk = FakeSDK()
    create_calls = 0
    monkeypatch.setenv("DMS_METADATA_BACKEND", "postgresql")
    monkeypatch.setenv("DMS_CONFIGURATION_STRICT", "true")
    monkeypatch.delenv("POSTGRES_DSN", raising=False)

    def create_sdk():
        nonlocal create_calls
        create_calls += 1
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

    assert create_calls == 1


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


@pytest.mark.parametrize("included", [False, True])
def test_application_explicitly_controls_the_auth_router(included):
    app = create_application(
        FakeSDK(),
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=included,
        auth_provider=object() if included else None,
    )

    with TestClient(app) as client:
        assert_auth_router_contract(client, included=included)


def test_application_installs_the_document_domain_module():
    app = create_application(
        FakeSDK(),
        config=AppConfig(enabled_services=[], required_services=[]),
        include_auth_router=False,
    )

    assert len(app.state.domain_modules) == 1
    assert app.state.domain_modules[0].name == "documents"
    assert_module_contract(app, app.state.domain_modules[0])


def test_application_preserves_fastapi_core_health_contract():
    with client_for(FakeSDK()) as client:
        assert_health_contract(client)


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
    def failing_create_dms_sdk():
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
