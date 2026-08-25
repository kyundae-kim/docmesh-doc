from __future__ import annotations

import dms
import pytest

from docmesh_doc import dms_factory
from docmesh_doc.dms_factory import DmsSettings, create_dms_runtime


def test_sqlite_settings_create_a_host_owned_dms_runtime(monkeypatch):
    class AvailableMinio:
        @staticmethod
        def bucket_exists(_bucket_name):
            return True

    monkeypatch.setattr(
        dms_factory,
        "_create_minio_client",
        lambda _settings: AvailableMinio(),
    )
    settings = DmsSettings(
        metadata_backend="sqlite",
        sqlite_path=":memory:",
        minio_endpoint="localhost:9000",
        minio_access_key="access",
        minio_secret_key="secret",
        minio_bucket="documents",
    )

    runtime = create_dms_runtime(settings)

    try:
        assert runtime.sdk.__class__.__name__ == "DefaultDocumentManagementSDK"
        assert runtime.engine.dialect.name == "sqlite"
        assert runtime.bucket_name == "documents"
        assert not hasattr(runtime.sdk, "close")
    finally:
        runtime.close()


def test_legacy_postgres_dsn_is_rejected(monkeypatch):
    monkeypatch.setenv("POSTGRES_DSN", "postgresql://secret@example.invalid/db")
    monkeypatch.setenv("DMS_METADATA_BACKEND", "sqlite")
    monkeypatch.setenv("SQLITE_PATH", ":memory:")
    monkeypatch.setenv("MINIO_ENDPOINT", "localhost:9000")
    monkeypatch.setenv("MINIO_ACCESS_KEY", "access")
    monkeypatch.setenv("MINIO_SECRET_KEY", "secret")
    monkeypatch.setenv("MINIO_BUCKET", "documents")

    with pytest.raises(Exception, match="POSTGRES_DSN"):
        DmsSettings.from_env()


def test_runtime_creation_disposes_engine_when_minio_assembly_fails(monkeypatch):
    class RecordingEngine:
        def __init__(self):
            self.disposed = False

        def dispose(self):
            self.disposed = True

    engine = RecordingEngine()
    monkeypatch.setattr(dms_factory, "_create_engine", lambda _settings: engine)

    settings = DmsSettings(metadata_backend="sqlite", sqlite_path=":memory:")
    with pytest.raises(dms.ConfigurationError, match="MINIO_ENDPOINT"):
        create_dms_runtime(settings)

    assert engine.disposed is True
