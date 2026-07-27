from typing import Annotated

from dms import DefaultDocumentManagementSDK
from docmesh_py_core import AuthenticatedUser
from fastapi import Depends
from fastapi_core import ResourceKey
from fastapi_core.dependencies import get_current_user, require_permissions


DMS_RESOURCE = ResourceKey[DefaultDocumentManagementSDK]("dms")
DmsSdk = Annotated[DefaultDocumentManagementSDK, Depends(DMS_RESOURCE.dependency)]
CurrentUser = Annotated[AuthenticatedUser, Depends(get_current_user)]

HARD_DELETE_PERMISSION = "document:delete:hard"
require_hard_delete = require_permissions(HARD_DELETE_PERMISSION)
