from __future__ import annotations

import threading

import docmesh_doc.router as document_router

from docmesh_doc.dependencies import HARD_DELETE_PERMISSION
from test_docmesh_doc.support import FakeSDK, client_for


def test_hard_delete_requires_permission_before_sdk_call():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 403
    assert response.json()["error"]["code"] == "FORBIDDEN"
    assert sdk.delete_call is None


def test_hard_delete_calls_sdk_for_authorized_user():
    sdk = FakeSDK()
    with client_for(sdk, roles=[HARD_DELETE_PERMISSION]) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is True
    assert sdk.delete_call == ("hard", "doc-1")


def test_hard_delete_accepts_fastapi_core_scope_permission():
    sdk = FakeSDK()
    with client_for(sdk, scopes=[HARD_DELETE_PERMISSION]) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert sdk.delete_call == ("hard", "doc-1")


def test_delete_runs_blocking_sdk_call_outside_event_loop(monkeypatch):
    permission_thread = None

    async def allow_hard_delete(*, current_user):
        nonlocal permission_thread
        permission_thread = threading.current_thread()

    class ThreadRecordingSDK(FakeSDK):
        delete_thread = None

        def hard_delete_document(self, document_id):
            self.delete_thread = threading.current_thread()
            return super().hard_delete_document(document_id)

    monkeypatch.setattr(document_router, "require_hard_delete", allow_hard_delete)
    sdk = ThreadRecordingSDK()

    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert permission_thread is not None
    assert sdk.delete_thread is not permission_thread


def test_soft_delete_calls_explicit_sdk_method():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is False
    assert sdk.delete_call == ("soft", "doc-1")
