from __future__ import annotations

import os

import dms
import docmesh_config
import pytest

import docmesh_doc.dms_factory as dms_factory


def _set_minio_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("MINIO_ENDPOINT", "localhost:9000")
    monkeypatch.setenv("MINIO_ACCESS_KEY", "access")
    monkeypatch.setenv("MINIO_SECRET_KEY", "secret")
    monkeypatch.setenv("MINIO_BUCKET", "documents")
    monkeypatch.setenv("MINIO_SECURE", "false")


def _set_sqlite_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    for name in tuple(os.environ):
        if name.startswith("POSTGRES_"):
            monkeypatch.delenv(name, raising=False)
    monkeypatch.setenv("DMS_METADATA_BACKEND", "sqlite")
    monkeypatch.setenv("DMS_CONFIGURATION_STRICT", "true")
    monkeypatch.setenv("SQLITE_PATH", ":memory:")
    _set_minio_environment(monkeypatch)


def test_factory_assembles_sqlite_clients_and_injects_them_into_dms(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _set_sqlite_environment(monkeypatch)

    captured: dict[str, object] = {}

    def create_sdk_from_clients(**kwargs):
        captured.update(kwargs)
        return object()

    monkeypatch.setattr(dms, "create_sdk_from_clients", create_sdk_from_clients)

    sdk = dms_factory.create_dms_sdk()

    assert sdk is not None
    assert captured["engine"].dialect.name == "sqlite"
    assert captured["bucket_name"] == "documents"
    plan = captured["plan"]
    assert plan.metadata_backend == "sqlite"
    assert plan.strict_configuration is True
    assert plan.check_on_startup is False
    assert len(captured["close_callbacks"]) == 2

    for callback in captured["close_callbacks"]:
        callback()


def test_factory_can_create_and_close_the_real_dms_sdk_without_network_healthcheck(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _set_sqlite_environment(monkeypatch)

    sdk = dms_factory.create_dms_sdk()

    assert isinstance(sdk, dms.DefaultDocumentManagementSDK)
    sdk.close()


def test_factory_rejects_legacy_postgres_dsn(monkeypatch: pytest.MonkeyPatch) -> None:
    _set_sqlite_environment(monkeypatch)
    monkeypatch.setenv("POSTGRES_DSN", "postgresql://user:password@host/db")

    with pytest.raises(docmesh_config.ConfigError, match="POSTGRES_DSN"):
        dms_factory.create_dms_sdk()


def test_factory_strict_mode_rejects_both_metadata_backends(
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    _set_sqlite_environment(monkeypatch)
    monkeypatch.setenv("POSTGRES_HOST", "localhost")
    monkeypatch.setenv("POSTGRES_DB", "docmesh")
    monkeypatch.setenv("POSTGRES_USER", "docmesh")
    monkeypatch.setenv("POSTGRES_PASSWORD", "password")

    with pytest.raises(docmesh_config.ConfigError, match="Ambiguous service alternative"):
        dms_factory.create_dms_sdk()


def test_factory_requires_minio_bucket(monkeypatch: pytest.MonkeyPatch) -> None:
    _set_sqlite_environment(monkeypatch)
    monkeypatch.delenv("MINIO_BUCKET")

    with pytest.raises(docmesh_config.ConfigError, match="MINIO_BUCKET"):
        dms_factory.create_dms_sdk()


def test_factory_rejects_unknown_backend(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("DMS_METADATA_BACKEND", "mysql")

    with pytest.raises(dms.ConfigurationError, match="DMS_METADATA_BACKEND"):
        dms_factory.create_dms_sdk()
