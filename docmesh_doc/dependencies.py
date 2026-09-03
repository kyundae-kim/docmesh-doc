from __future__ import annotations

from dataclasses import dataclass
from typing import Annotated

import dms
from fastapi import Depends, HTTPException, Request, status


@dataclass(frozen=True, slots=True)
class DmsApplicationContext:
    """The one DMS identity and partition owned by this application."""

    user_id: str
    partition: dms.DocumentPartition
    access_context: dms.AccessContext


def build_dms_application_context(user_id: str) -> DmsApplicationContext:
    normalized_user_id = user_id.strip()
    if not normalized_user_id:
        raise dms.ConfigurationError(
            "DMS_APPLICATION_USER_ID must be a non-empty string"
        )
    return DmsApplicationContext(
        user_id=normalized_user_id,
        partition=dms.DocumentPartition.personal(normalized_user_id),
        access_context=dms.AccessContext(
            subject=normalized_user_id,
            user_id=normalized_user_id,
            roles=frozenset({"admin"}),
        ),
    )


def get_dms_sdk(request: Request) -> dms.DefaultDocumentManagementSDK:
    sdk = getattr(request.app.state, "dms_sdk", None)
    if sdk is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DMS application is not ready",
        )
    return sdk


def get_dms_application_context(request: Request) -> DmsApplicationContext:
    context = getattr(request.app.state, "dms_context", None)
    if context is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DMS application is not ready",
        )
    return context


RawDmsSdk = Annotated[dms.DefaultDocumentManagementSDK, Depends(get_dms_sdk)]
DmsSdk = RawDmsSdk
DmsContext = Annotated[
    DmsApplicationContext,
    Depends(get_dms_application_context),
]
