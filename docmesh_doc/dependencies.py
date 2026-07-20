from __future__ import annotations

from typing import Annotated

from dms import DefaultDocumentManagementSDK
from fastapi import Depends
from fastapi_core import ResourceKey
from fastapi_core.dependencies import get_current_user
from fastapi_core.schemas import UserInfo


DMS_RESOURCE = ResourceKey[DefaultDocumentManagementSDK]("dms")
DmsSdk = Annotated[DefaultDocumentManagementSDK, Depends(DMS_RESOURCE.dependency)]
CurrentUser = Annotated[UserInfo, Depends(get_current_user)]
