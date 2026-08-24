from __future__ import annotations

from typing import Annotated

import dms
from fastapi import Depends, Header, HTTPException, Request, status

from docmesh_doc.document_http import parse_metadata


def get_dms_sdk(request: Request) -> dms.DefaultDocumentManagementSDK:
    sdk = getattr(request.app.state, "dms_sdk", None)
    if sdk is None:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="DMS application is not ready",
        )
    return sdk


RawDmsSdk = Annotated[dms.DefaultDocumentManagementSDK, Depends(get_dms_sdk)]


def get_dms_operation_context(
    subject: Annotated[str | None, Header(alias="X-Subject")] = None,
    user_id: Annotated[str | None, Header(alias="X-User-ID")] = None,
    tenant: Annotated[str | None, Header(alias="X-Tenant-ID")] = None,
    roles: Annotated[str | None, Header(alias="X-Roles")] = None,
    created_by: Annotated[str | None, Header(alias="X-Created-By")] = None,
    idempotency_scope: Annotated[
        str | None,
        Header(alias="X-Idempotency-Scope"),
    ] = None,
    audit_actor: Annotated[str | None, Header(alias="X-Audit-Actor")] = None,
    default_metadata: Annotated[
        str | None,
        Header(alias="X-Default-Metadata"),
    ] = None,
) -> dms.DmsOperationContext:
    """Build the transport-neutral DMS scope from trusted request headers.

    Deployments with an authentication provider can override this dependency
    and construct the same context from verified claims instead.
    """

    normalized_roles = frozenset(
        role
        for role in (
            item.strip() for item in (roles or "").split(",")
        )
        if role
    )
    access = None
    if subject or user_id or tenant or normalized_roles:
        access = dms.AccessContext(
            subject=subject,
            user_id=user_id,
            tenant=tenant,
            roles=normalized_roles,
        )
    return dms.DmsOperationContext(
        access=access,
        user_id=user_id,
        created_by=created_by or subject,
        idempotency_scope=idempotency_scope,
        audit_actor=audit_actor or subject,
        default_metadata=parse_metadata(
            default_metadata,
            field_name="X-Default-Metadata",
        ),
    )


DmsContext = Annotated[
    dms.DmsOperationContext,
    Depends(get_dms_operation_context),
]


def get_scoped_dms_sdk(
    sdk: RawDmsSdk,
    context: DmsContext,
) -> dms.ScopedDocumentManagementSDK:
    return sdk.scoped(context)


DmsSdk = Annotated[dms.ScopedDocumentManagementSDK, Depends(get_scoped_dms_sdk)]
