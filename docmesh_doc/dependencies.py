from __future__ import annotations

from typing import Annotated

import dms
from fastapi import Depends, HTTPException, Request, status


def get_dms_sdk(request: Request) -> dms.DefaultDocumentManagementSDK:
    sdk = getattr(request.app.state, "dms_sdk", None)
    if sdk is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DMS application is not ready",
        )
    return sdk


DmsSdk = Annotated[dms.DefaultDocumentManagementSDK, Depends(get_dms_sdk)]
