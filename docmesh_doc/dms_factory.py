from __future__ import annotations

import os

import dms
import docmesh_config
import docmesh_py_core
from docmesh_config import Service
from minio import Minio
from sqlalchemy.engine import Engine


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

    metadata_service = (
        Service.POSTGRES if backend == "postgresql" else Service.SQLITE
    )
    bundle = docmesh_py_core.assemble_services(
        plan=docmesh_config.RuntimePlan(
            services=(metadata_service.required(), Service.MINIO.required()),
            healthcheck=docmesh_config.HealthcheckPolicy(on_startup=False),
            minio_bucket_required=True,
        )
    )
    try:
        minio_bucket = docmesh_config.require_minio_bucket(
            bundle.configs.require_minio()
        )
        plan = dms.DmsAssemblyPlan(
            metadata_backend=backend,
            strict_configuration=strict,
            # FastAPI's required ManagedResource owns the startup/readiness
            # check; do not run a duplicate network check during assembly.
            check_on_startup=False,
        )
        return dms.create_sdk_from_clients(
            engine=bundle.require_client(metadata_service, Engine),
            minio_client=bundle.require_client(Service.MINIO, Minio),
            bucket_name=minio_bucket,
            close_callbacks=(bundle.close,),
            plan=plan,
        )
    except BaseException as error:
        try:
            bundle.close()
        except BaseException as close_error:  # pragma: no cover - defensive cleanup
            error.add_note(
                "DMS client cleanup failed during assembly: "
                + type(close_error).__name__
            )
        raise
