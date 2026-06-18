from __future__ import annotations

from dms.sdk import DocumentManagementSDK
from fastapi import HTTPException, Request, status


def get_dms_sdk(request: Request) -> DocumentManagementSDK:
    sdk = getattr(request.app.state, "dms_sdk", None)
    if sdk is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DMS SDK is not initialized",
        )
    return sdk
