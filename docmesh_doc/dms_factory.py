from __future__ import annotations

import os
from collections.abc import Mapping
from dataclasses import dataclass, field
from pathlib import Path
from threading import Lock

import dms
from minio import Minio
from sqlalchemy import create_engine
from sqlalchemy.engine import URL, Engine
from sqlalchemy.pool import StaticPool

_METADATA_BACKENDS = frozenset({"postgresql", "sqlite"})


@dataclass(frozen=True, slots=True)
class DmsSettings:
    """Host-owned configuration used to assemble the DMS application."""

    metadata_backend: str = "postgresql"
    postgres_host: str | None = None
    postgres_port: int = 5432
    postgres_database: str | None = None
    postgres_user: str | None = None
    postgres_password: str | None = None
    postgres_sslmode: str | None = None
    sqlite_path: str | None = None
    minio_endpoint: str | None = None
    minio_access_key: str | None = None
    minio_secret_key: str | None = None
    minio_bucket: str | None = None
    minio_secure: bool = False
    minio_region: str | None = None
    max_file_size: int | None = None
    root_path: str = ""
    cors_origins: tuple[str, ...] = ()

    @classmethod
    def from_env(cls, env: Mapping[str, str] | None = None) -> DmsSettings:
        values = env if env is not None else os.environ

        def read(name: str, default: str | None = None) -> str | None:
            raw = values.get(name, default)
            if raw is None:
                return None
            stripped = raw.strip()
            return stripped or None

        def integer(name: str, default: int) -> int:
            raw = read(name)
            if raw is None:
                return default
            try:
                return int(raw)
            except ValueError as error:
                raise dms.ConfigurationError(f"{name} must be an integer") from error

        def boolean(name: str, default: bool) -> bool:
            raw = read(name)
            if raw is None:
                return default
            normalized = raw.lower()
            if normalized in {"true", "1", "yes", "on"}:
                return True
            if normalized in {"false", "0", "no", "off"}:
                return False
            raise dms.ConfigurationError(f"{name} must be a boolean")

        legacy_dsn = read("POSTGRES_DSN")
        if legacy_dsn is not None:
            raise dms.ConfigurationError(
                "POSTGRES_DSN is not supported; configure individual POSTGRES_* fields"
            )

        backend = (read("DMS_METADATA_BACKEND", "postgresql") or "postgresql").lower()
        if backend not in _METADATA_BACKENDS:
            supported = ", ".join(sorted(_METADATA_BACKENDS))
            raise dms.ConfigurationError(
                f"DMS_METADATA_BACKEND must be one of: {supported}"
            )

        root_path = read("ROOT_PATH", "") or ""
        if root_path and not root_path.startswith("/"):
            root_path = "/" + root_path
        if len(root_path) > 1:
            root_path = root_path.rstrip("/")

        origins = tuple(
            origin
            for origin in (
                part.strip()
                for part in (read("CORS_ORIGINS", "") or "").split(",")
            )
            if origin
        )

        max_file_size_raw = read("DMS_MAX_FILE_SIZE")
        max_file_size = None
        if max_file_size_raw is not None:
            try:
                max_file_size = int(max_file_size_raw)
            except ValueError as error:
                raise dms.ConfigurationError(
                    "DMS_MAX_FILE_SIZE must be an integer"
                ) from error
            if max_file_size <= 0:
                raise dms.ConfigurationError("DMS_MAX_FILE_SIZE must be positive")

        return cls(
            metadata_backend=backend,
            postgres_host=read("POSTGRES_HOST"),
            postgres_port=integer("POSTGRES_PORT", 5432),
            postgres_database=read("POSTGRES_DB"),
            postgres_user=read("POSTGRES_USER"),
            postgres_password=read("POSTGRES_PASSWORD"),
            postgres_sslmode=read("POSTGRES_SSLMODE"),
            sqlite_path=read("SQLITE_PATH"),
            minio_endpoint=read("MINIO_ENDPOINT"),
            minio_access_key=read("MINIO_ACCESS_KEY", read("MINIO_ACCESS_KEY_ID")),
            minio_secret_key=read("MINIO_SECRET_KEY"),
            minio_bucket=read("MINIO_BUCKET"),
            minio_secure=boolean("MINIO_SECURE", False),
            minio_region=read("MINIO_REGION"),
            max_file_size=max_file_size,
            root_path=root_path,
            cors_origins=origins,
        )


@dataclass(slots=True)
class DmsRuntime:
    """The host-owned resources and the SDK facade used by the API layer."""

    sdk: dms.DefaultDocumentManagementSDK
    engine: Engine
    minio_client: Minio
    bucket_name: str
    _closed: bool = False
    _close_lock: Lock = field(default_factory=Lock, init=False, repr=False)

    def check_readiness(self) -> dict[str, object]:
        """Check host-owned resources without relying on a DMS health API."""

        details: dict[str, dict[str, bool]] = {}
        try:
            with self.engine.connect():
                pass
        except Exception:
            details["metadata"] = {"ok": False}
        else:
            details["metadata"] = {"ok": True}

        try:
            bucket_exists = self.minio_client.bucket_exists(self.bucket_name)
        except Exception:
            bucket_exists = False
        details["object_store"] = {"ok": bool(bucket_exists)}

        ok = all(bool(item["ok"]) for item in details.values())
        return {
            "status": "ok" if ok else "error",
            "details": details,
            "ok": ok,
        }

    def close(self) -> None:
        """Dispose host-owned resources exactly once; never close the SDK facade."""

        with self._close_lock:
            if self._closed:
                return
            self._closed = True
            self.engine.dispose()


def _required(value: str | None, name: str) -> str:
    if value is None:
        raise dms.ConfigurationError(f"{name} is required")
    return value


def _create_engine(settings: DmsSettings) -> Engine:
    if settings.metadata_backend == "sqlite":
        path = _required(settings.sqlite_path, "SQLITE_PATH")
        if path == ":memory:":
            return create_engine(
                "sqlite:///:memory:",
                connect_args={"check_same_thread": False},
                poolclass=StaticPool,
            )
        sqlite_path = Path(path).expanduser()
        sqlite_path.parent.mkdir(parents=True, exist_ok=True)
        return create_engine(
            f"sqlite:///{sqlite_path}",
            connect_args={"check_same_thread": False},
        )

    if settings.metadata_backend != "postgresql":
        raise dms.ConfigurationError(
            "DMS_METADATA_BACKEND must be one of: postgresql, sqlite"
        )

    query: dict[str, str] = {}
    if settings.postgres_sslmode is not None:
        query["sslmode"] = settings.postgres_sslmode
    url = URL.create(
        "postgresql+psycopg",
        username=_required(settings.postgres_user, "POSTGRES_USER"),
        password=_required(settings.postgres_password, "POSTGRES_PASSWORD"),
        host=_required(settings.postgres_host, "POSTGRES_HOST"),
        port=settings.postgres_port,
        database=_required(settings.postgres_database, "POSTGRES_DB"),
        query=query,
    )
    return create_engine(url, pool_pre_ping=True)


def _create_minio_client(settings: DmsSettings) -> Minio:
    return Minio(
        _required(settings.minio_endpoint, "MINIO_ENDPOINT"),
        access_key=_required(settings.minio_access_key, "MINIO_ACCESS_KEY"),
        secret_key=_required(settings.minio_secret_key, "MINIO_SECRET_KEY"),
        secure=settings.minio_secure,
        region=settings.minio_region,
    )


def create_dms_runtime(settings: DmsSettings | None = None) -> DmsRuntime:
    """Create the host resources and inject them into the v0.9 DMS factory."""

    selected = settings or DmsSettings.from_env()
    engine = _create_engine(selected)
    try:
        minio_client = _create_minio_client(selected)
        bucket_name = _required(selected.minio_bucket, "MINIO_BUCKET")
        sdk = dms.DocumentManagementSDKFactory(
            engine=engine,
            minio_client=minio_client,
            bucket_name=bucket_name,
            max_file_size=selected.max_file_size,
        ).create()
    except BaseException:
        engine.dispose()
        raise
    return DmsRuntime(
        sdk=sdk,
        engine=engine,
        minio_client=minio_client,
        bucket_name=bucket_name,
    )
