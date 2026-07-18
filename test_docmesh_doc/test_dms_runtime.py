from __future__ import annotations

import os
from types import SimpleNamespace

import dms
import pytest

from docmesh_doc.dms_runtime import (
    check_dms_readiness,
    create_dms_sdk,
    normalize_dms_environment,
)
from test_docmesh_doc.support import FakeSDK


def test_normalize_dms_environment_copies_and_sanitizes_input():
    environment = {
        "POSTGRES_DSN": "postgresql://user:secret@example.test/database",
        "DMS_METADATA_BACKEND": "memory",
        "DMS_CONFIGURATION_STRICT": "false",
        "MINIO_BUCKET": "documents",
    }
    original = environment.copy()

    normalized = normalize_dms_environment(environment)

    assert normalized == {
        "DMS_METADATA_BACKEND": "postgresql",
        "DMS_CONFIGURATION_STRICT": "true",
        "MINIO_BUCKET": "documents",
    }
    assert normalized is not environment
    assert environment == original


def test_create_dms_sdk_normalizes_explicit_mapping_for_diagnosis_and_factory(
    monkeypatch,
):
    environment = {
        "POSTGRES_DSN": "postgresql://user:secret@example.test/database",
        "DMS_METADATA_BACKEND": "memory",
        "DMS_CONFIGURATION_STRICT": "false",
        "MINIO_BUCKET": "documents",
    }
    original = environment.copy()
    diagnosed_environment = None
    factory_environment = None
    sdk = FakeSDK()

    def diagnose_environment(candidate):
        nonlocal diagnosed_environment
        diagnosed_environment = candidate
        return SimpleNamespace(valid=True, missing_required_keys=(), warnings=())

    def create_sdk(candidate):
        nonlocal factory_environment
        factory_environment = candidate
        return sdk

    monkeypatch.setattr(dms, "diagnose_environment", diagnose_environment)
    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    assert create_dms_sdk(environment) is sdk
    assert diagnosed_environment == {
        "DMS_METADATA_BACKEND": "postgresql",
        "DMS_CONFIGURATION_STRICT": "true",
        "MINIO_BUCKET": "documents",
    }
    assert factory_environment is diagnosed_environment
    assert environment == original


def test_create_dms_sdk_snapshots_process_environment(monkeypatch):
    captured_environment = None
    sdk = FakeSDK()
    monkeypatch.delenv("DMS_METADATA_BACKEND", raising=False)
    monkeypatch.delenv("DMS_CONFIGURATION_STRICT", raising=False)
    monkeypatch.setenv("POSTGRES_DSN", "postgresql://user:secret@example.test/database")

    def diagnose_environment(candidate):
        return SimpleNamespace(valid=True, missing_required_keys=(), warnings=())

    def create_sdk(candidate):
        nonlocal captured_environment
        captured_environment = candidate
        return sdk

    monkeypatch.setattr(dms, "diagnose_environment", diagnose_environment)
    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    assert create_dms_sdk() is sdk
    expected_environment = dict(os.environ)
    expected_environment.pop("POSTGRES_DSN")
    assert captured_environment == {
        **expected_environment,
        "DMS_METADATA_BACKEND": "postgresql",
        "DMS_CONFIGURATION_STRICT": "true",
    }
    assert captured_environment is not os.environ
    assert os.environ.get("DMS_METADATA_BACKEND") is None
    assert os.environ.get("DMS_CONFIGURATION_STRICT") is None


def test_create_dms_sdk_rejects_invalid_diagnosis_without_exposing_values(
    monkeypatch,
):
    assembled = False
    environment = {
        "POSTGRES_PASSWORD": "database-secret",
        "MINIO_SECRET_KEY": "object-store-secret",
    }
    monkeypatch.setattr(
        dms,
        "diagnose_environment",
        lambda _environment: SimpleNamespace(
            valid=False,
            missing_required_keys=("POSTGRES_HOST", "MINIO_BUCKET"),
            warnings=(),
        ),
    )

    def create_sdk(_environment):
        nonlocal assembled
        assembled = True

    monkeypatch.setattr(dms, "create_sdk_from_environment", create_sdk)

    with pytest.raises(dms.ConfigurationError) as exc_info:
        create_dms_sdk(environment)

    message = str(exc_info.value)
    assert "POSTGRES_HOST" in message
    assert "MINIO_BUCKET" in message
    assert "database-secret" not in message
    assert "object-store-secret" not in message
    assert assembled is False


def test_check_dms_readiness_accepts_healthy_sdk():
    sdk = FakeSDK()

    check_dms_readiness(sdk)


def test_check_dms_readiness_rejects_unhealthy_sdk():
    class UnhealthySDK(FakeSDK):
        def check_health(self):
            return SimpleNamespace(ok=False)

    with pytest.raises(RuntimeError, match="^DMS dependency unavailable$"):
        check_dms_readiness(UnhealthySDK())
