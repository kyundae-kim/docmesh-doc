from __future__ import annotations

from collections.abc import Callable
import os

import dms
import docmesh_config
import docmesh_py_core
from docmesh_config import Service


_METADATA_BACKENDS = {"postgresql", "sqlite"}


def _environment_value(name: str) -> str | None:
    value = os.environ.get(name)
    if value is None:
        return None
    value = value.strip()
    return value or None


def _metadata_backend() -> str:
    value = (_environment_value("DMS_METADATA_BACKEND") or "postgresql").lower()
    if value not in _METADATA_BACKENDS:
        supported = ", ".join(sorted(_METADATA_BACKENDS))
        raise dms.ConfigurationError(
            f"DMS_METADATA_BACKEND must be one of: {supported}"
        )
    return value


def _strict_configuration() -> bool:
    value = (_environment_value("DMS_CONFIGURATION_STRICT") or "false").lower()
    if value not in {"true", "false"}:
        raise docmesh_config.ConfigError(
            "DMS_CONFIGURATION_STRICT: expected true or false"
        )
    return value == "true"


def _diagnose_strict_configuration() -> None:
    plan = docmesh_config.RuntimePlan(
        services=(Service.POSTGRES, Service.SQLITE, Service.MINIO),
        one_of=((Service.POSTGRES, Service.SQLITE),),
        minio_bucket_required=True,
    )
    diagnosis = docmesh_config.diagnose_services(
        plan=plan,
        selection_mode="strict",
    )
    if diagnosis.ok:
        return

    messages = []
    for issue in diagnosis.issues:
        subject = issue.env_key or issue.service
        messages.append(f"{subject}: {issue.reason}")
    raise docmesh_config.ConfigError("\n".join(messages))


def _close_once(callback: Callable[[], object]) -> Callable[[], object]:
    closed = False

    def close() -> object:
        nonlocal closed
        if closed:
            return None
        result = callback()
        closed = True
        return result

    return close


def _close_on_failure(
    close_callbacks: list[Callable[[], object]],
    error: BaseException,
) -> None:
    failures: list[BaseException] = []
    for close_callback in reversed(close_callbacks):
        try:
            close_callback()
        except BaseException as close_error:  # pragma: no cover - defensive cleanup
            failures.append(close_error)
    if failures:
        error.add_note(
            "DMS client cleanup failed during assembly: "
            + "; ".join(type(item).__name__ for item in failures)
        )


def create_dms_sdk() -> dms.DefaultDocumentManagementSDK:
    """Create the DMS SDK from host-owned configuration and clients.

    ``dms`` deliberately does not read process environment variables. This host
    adapter owns configuration selection, creates the SQLAlchemy and MinIO
    clients through the canonical DocMesh packages, and passes their lifecycle
    callbacks to the DMS client factory.
    """

    backend = _metadata_backend()
    strict = _strict_configuration()
    if _environment_value("POSTGRES_DSN") is not None:
        raise docmesh_config.ConfigError(
            "POSTGRES_DSN is not supported; configure the individual POSTGRES_* fields"
        )
    if strict:
        _diagnose_strict_configuration()

    services = {
        Service.MINIO,
        Service.POSTGRES if backend == "postgresql" else Service.SQLITE,
    }

    configs = docmesh_config.load_service_configs(services=services)
    minio_config = configs.require_minio()
    minio_bucket = docmesh_config.require_minio_bucket(minio_config)
    close_callbacks: list[Callable[[], object]] = []

    try:
        metadata_client = (
            docmesh_py_core.create_postgres_client(configs.require_postgres())
            if backend == "postgresql"
            else docmesh_py_core.create_sqlite_client(configs.require_sqlite())
        )
        close_callbacks.append(_close_once(metadata_client.close))

        minio_client = docmesh_py_core.create_minio_client(minio_config)
        close_callbacks.append(_close_once(minio_client.close))

        plan = dms.DmsAssemblyPlan(
            metadata_backend=backend,
            strict_configuration=strict,
            # FastAPI's required ManagedResource owns the startup/readiness
            # check; do not run a duplicate network check during assembly.
            check_on_startup=False,
        )
        return dms.create_sdk_from_clients(
            engine=metadata_client.client,
            minio_client=minio_client.client,
            bucket_name=minio_bucket,
            close_callbacks=tuple(close_callbacks),
            plan=plan,
        )
    except BaseException as error:
        _close_on_failure(close_callbacks, error)
        raise
