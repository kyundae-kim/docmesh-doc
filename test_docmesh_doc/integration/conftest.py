from __future__ import annotations

import os
from collections.abc import Iterator
from uuid import uuid4

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.dependencies import get_current_user
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
)


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
) -> Iterator[tuple[TestClient, dms.DefaultDocumentManagementSDK]]:
    app = create_application(include_auth_router=False)
    app.dependency_overrides[get_current_user] = lambda: UserInfo(
        sub="integration-user",
        username="integration-user",
        roles=["document:delete:hard"],
    )
    with TestClient(app) as client:
        yield client, app.state.dms_sdk
