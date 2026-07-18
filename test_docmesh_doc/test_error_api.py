from __future__ import annotations

from test_docmesh_doc.support import FakeSDK, client_for


def test_sdk_not_found_uses_documented_error_envelope():
    sdk = FakeSDK()
    with client_for(sdk) as client:
        response = client.get("/documents/missing")

    assert response.status_code == 404
    assert response.json()["error"]["code"] == "DOCUMENT_NOT_FOUND"
    assert response.json()["error"]["correlation_id"] == response.headers["X-Correlation-ID"]


def test_framework_http_errors_use_documented_error_envelope():
    with client_for(FakeSDK()) as client:
        response = client.get(
            "/route-that-does-not-exist",
            headers={"X-Correlation-ID": "missing-route-1"},
        )

    assert response.status_code == 404
    assert response.headers["Content-Type"].startswith("application/json")
    assert response.json() == {
        "error": {
            "code": "NOT_FOUND",
            "message": "Not Found",
            "correlation_id": "missing-route-1",
        }
    }
