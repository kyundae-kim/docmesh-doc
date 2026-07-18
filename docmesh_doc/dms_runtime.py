from __future__ import annotations

import os
from collections.abc import Mapping

import dms


def normalize_dms_environment(environment: Mapping[str, str]) -> dict[str, str]:
    normalized = dict(environment)
    normalized.pop("POSTGRES_DSN", None)
    normalized["DMS_METADATA_BACKEND"] = "postgresql"
    normalized["DMS_CONFIGURATION_STRICT"] = "true"
    return normalized


def create_dms_sdk(
    environment: Mapping[str, str] | None = None,
) -> dms.DefaultDocumentManagementSDK:
    source = dict(os.environ) if environment is None else environment
    normalized = normalize_dms_environment(source)
    diagnosis = dms.diagnose_environment(normalized)
    if not diagnosis.valid:
        missing = ", ".join(diagnosis.missing_required_keys)
        detail = f"; missing required keys: {missing}" if missing else ""
        raise dms.ConfigurationError(f"Invalid DMS environment{detail}")
    return dms.create_sdk_from_environment(normalized)


def check_dms_readiness(sdk: dms.DefaultDocumentManagementSDK) -> None:
    if not sdk.check_health().ok:
        raise RuntimeError("DMS dependency unavailable")
