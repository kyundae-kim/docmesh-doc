import pytest
from fastapi.testclient import TestClient

# from fastapi_template.core import Token
from fastapi_template.schemas import UserInfo, TokenResponse
from fastapi_template import factory
from fastapi_template.factory import (
    create_app,
)


@pytest.fixture(scope="module")
def app():
    with TestClient(create_app()) as client:
        yield client


def test_get_token(app):
    response = app.post("/token", data={"username": "test", "password": "test"})
    assert response.status_code == 200
    token = TokenResponse(**response.json())
    assert len(token.access_token) > 0
    assert len(token.refresh_token) > 0
    assert token.token_type == "Bearer"


@pytest.fixture(scope="module")
def token(app):
    response = app.post("/token", data={"username": "test", "password": "test"})
    assert response.status_code == 200
    token = TokenResponse(**response.json())
    return token.access_token


@pytest.fixture(scope="module")
def refresh_token(app):
    response = app.post("/token", data={"username": "test", "password": "test"})
    assert response.status_code == 200
    token = TokenResponse(**response.json())
    return token.refresh_token


def test_user_info(app, token):
    headers = {"Authorization": f"Bearer {token}"}
    response = app.get("/user", headers=headers)
    assert response.status_code == 200
    user_info = UserInfo(**response.json())
    assert user_info.name == "test test"


def test_example_create(app, token):
    headers = {"Authorization": f"Bearer {token}"}
    response = app.post("/example", headers=headers)
    assert response.status_code == 403
    assert response.json()["error"] == "insufficient_scope"


def test_example_read(app, token):
    headers = {"Authorization": f"Bearer {token}"}
    response = app.get("/example", headers=headers)
    assert response.status_code == 403
    assert response.json()["error"] == "insufficient_scope"


def test_example_delete(app, token):
    headers = {"Authorization": f"Bearer {token}"}
    response = app.delete("/example", headers=headers)
    assert response.status_code == 403
    assert response.json()["error"] == "insufficient_scope"
