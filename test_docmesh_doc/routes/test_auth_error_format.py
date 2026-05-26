from fastapi import FastAPI
from fastapi.testclient import TestClient

from docmesh_doc.core.exceptions import AuthError, register_exception_handlers


def test_auth_error_response_payload():
    app = FastAPI()
    register_exception_handlers(app)

    @app.get("/protected")
    def protected_route():
        raise AuthError(
            status_code=403,
            error="insufficient_scope",
            error_description="Missing required roles: admin, scopes: profile",
        )

    with TestClient(app) as client:
        response = client.get("/protected")

    assert response.status_code == 403
    assert response.json() == {
        "error": "insufficient_scope",
        "error_description": "Missing required roles: admin, scopes: profile",
    }
