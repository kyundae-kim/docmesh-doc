from __future__ import annotations

import os
import time
from collections.abc import Iterator
from uuid import uuid4

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.schemas import UserInfo
from minio import Minio
from sqlalchemy import create_engine, text

from docmesh_doc.main import create_application


pytestmark = pytest.mark.integration

_REQUIRED_ENV = (
    "POSTGRES_DSN",
    "MINIO_ENDPOINT",
    "MINIO_ACCESS_KEY",
    "MINIO_SECRET_KEY",
    "MINIO_BUCKET",
    "KEYCLOAK_URL",
    "KEYCLOAK_REALM",
    "KEYCLOAK_CLIENT_ID",
    "KEYCLOAK_CLIENT_SECRET",
    "KEYCLOAK_TOKEN_USERNAME",
    "KEYCLOAK_TOKEN_PASSWORD",
)


def _wait_for_authenticated_user(client: TestClient) -> UserInfo:
    deadline = time.monotonic() + 10
    while True:
        response = client.get("/user")
        if response.status_code == 200:
            return UserInfo.model_validate(response.json())
        if response.status_code != 401 or time.monotonic() >= deadline:
            response.raise_for_status()
        time.sleep(0.1)


@pytest.fixture(scope="session")
def integration_env() -> dict[str, str]:
    missing = [name for name in _REQUIRED_ENV if not os.getenv(name)]
    if missing:
        pytest.skip(
            "integration services are not configured; missing " + ", ".join(missing)
        )
    return dict(os.environ)


@pytest.fixture(scope="session", autouse=True)
def prepare_integration_services(integration_env: dict[str, str]) -> Iterator[None]:
    engine = create_engine(integration_env["POSTGRES_DSN"])
    with engine.connect() as connection:
        connection.execute(text("SELECT 1"))

    minio = Minio(
        integration_env["MINIO_ENDPOINT"],
        access_key=integration_env["MINIO_ACCESS_KEY"],
        secret_key=integration_env["MINIO_SECRET_KEY"],
        secure=integration_env.get("MINIO_SECURE", "false").lower() == "true",
    )
    bucket = integration_env["MINIO_BUCKET"]
    if not minio.bucket_exists(bucket):
        minio.make_bucket(bucket)

    yield

    engine.dispose()


@pytest.fixture
def document_id() -> str:
    return f"integration-{uuid4()}"


@pytest.fixture
def integration_client(
    integration_env: dict[str, str],
) -> Iterator[tuple[TestClient, dms.DefaultDocumentManagementSDK, UserInfo]]:
    app = create_application()
    with TestClient(app) as client:
        token_response = client.post(
            "/token",
            data={
                "username": integration_env["KEYCLOAK_TOKEN_USERNAME"],
                "password": integration_env["KEYCLOAK_TOKEN_PASSWORD"],
            },
        )
        token_response.raise_for_status()
        client.headers["Authorization"] = (
            f"Bearer {token_response.json()['access_token']}"
        )

        user = _wait_for_authenticated_user(client)

        yield client, app.state.dms_sdk, user
