from __future__ import annotations

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
    with client_for(sdk, roles=["document:delete:hard"]) as client:
        response = client.delete("/documents/doc-1?hard=true")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is True
    assert sdk.delete_call == ("hard", "doc-1")


def test_soft_delete_calls_explicit_sdk_method():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.delete("/documents/doc-1")

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is False
    assert sdk.delete_call == ("soft", "doc-1")
