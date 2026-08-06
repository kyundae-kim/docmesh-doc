from __future__ import annotations

from contextlib import ExitStack
import os
import time
from collections.abc import Iterator
from uuid import uuid4

import dms
import docmesh_config
import docmesh_py_core
import pytest
from fastapi.testclient import TestClient
from fastapi_core.config import AppConfig
from fastapi_core.schemas import UserInfo
from docmesh_config import Service
from sqlalchemy import text

from docmesh_doc.application import create_application
from docmesh_doc.dependencies import DMS_RESOURCE


_REQUIRED_ENV = (
    "POSTGRES_HOST",
    "POSTGRES_PORT",
    "POSTGRES_DB",
    "POSTGRES_USER",
    "POSTGRES_PASSWORD",
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
    configs = docmesh_config.load_service_configs(
        services=(Service.POSTGRES, Service.MINIO)
    )
    postgres_config = configs.require_postgres()
    minio_config = configs.require_minio()
    bucket = docmesh_config.require_minio_bucket(minio_config)

    with ExitStack() as stack:
        postgres = docmesh_py_core.create_postgres_client(postgres_config)
        stack.callback(postgres.close)
        minio = docmesh_py_core.create_minio_client(minio_config)
        stack.callback(minio.close)

        with postgres.client.connect() as connection:
            connection.execute(text("SELECT 1"))

        if not minio.client.bucket_exists(bucket):
            minio.client.make_bucket(bucket)

        yield


@pytest.fixture
def document_id(
    integration_client: tuple[
        TestClient, dms.DefaultDocumentManagementSDK, UserInfo
    ],
) -> Iterator[str]:
    value = f"integration-{uuid4()}"
    yield value

    _, sdk, _ = integration_client
    try:
        sdk.hard_delete_document(value)
    except dms.DocumentNotFoundError:
        pass


@pytest.fixture
def integration_client(
    integration_env: dict[str, str],
) -> Iterator[tuple[TestClient, dms.DefaultDocumentManagementSDK, UserInfo]]:
    app = create_application(
        config=AppConfig(
            startup_healthcheck=True,
            enabled_services=["keycloak"],
            required_services=["keycloak"],
        )
    )
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

        yield client, app.state.resource_registry.require(DMS_RESOURCE.name), user
