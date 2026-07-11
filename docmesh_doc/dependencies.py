from __future__ import annotations

from typing import Annotated

from dms import DefaultDocumentManagementSDK
from fastapi import Depends, Request
from fastapi_core.dependencies import get_current_user
from fastapi_core.schemas import UserInfo


def get_dms_sdk(request: Request) -> DefaultDocumentManagementSDK:
    return request.app.state.dms_sdk


DmsSdk = Annotated[DefaultDocumentManagementSDK, Depends(get_dms_sdk)]
CurrentUser = Annotated[UserInfo, Depends(get_current_user)]
