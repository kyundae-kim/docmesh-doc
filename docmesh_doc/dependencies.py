from __future__ import annotations

from typing import Annotated

from dms import DefaultDocumentManagementSDK
from fastapi import Depends
from fastapi_core.dependencies import get_current_user, get_resource
from fastapi_core.schemas import UserInfo


DmsSdk = Annotated[DefaultDocumentManagementSDK, Depends(get_resource("dms"))]
CurrentUser = Annotated[UserInfo, Depends(get_current_user)]
