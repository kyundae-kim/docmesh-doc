from __future__ import annotations

import os

import pytest
from fastapi.testclient import TestClient
from minio import Minio
from sqlalchemy import create_engine, text

from dms.infrastructure.metadata.postgres import PostgresMetadataStore
from dms.infrastructure.storage.minio import MinioObjectStore
from dms.sdk import UploadDocumentRequest, create_sdk
from docmesh_doc.main import create_app
from fastapi_core import EnvConfig, ServiceSettings, UserInfo

pytestmark = [pytest.mark.integration]


@pytest.fixture
def integration_services() -> dict[str, object]:
    db_host = os.getenv("DB__HOST")
    db_port = int(os.getenv("DB__PORT", "5432"))
    db_name = os.getenv("DB__NAME")
    db_user = os.getenv("DB__USER")
    db_password = os.getenv("DB__PASSWORD")
    minio_endpoint = os.getenv("MINIO__ENDPOINT")
    minio_access_key = os.getenv("MINIO__ACCESS_KEY")
    minio_secret_key = os.getenv("MINIO__SECRET_KEY")
    minio_secure = os.getenv("MINIO__SECURE", "false").lower() == "true"
    minio_bucket = os.getenv("MINIO__BUCKET") or os.getenv("MINIO__BUCKET_NAME")

    missing = [
        name
        for name, value in {
            "DB__HOST": db_host,
            "DB__NAME": db_name,
            "DB__USER": db_user,
            "DB__PASSWORD": db_password,
            "MINIO__ENDPOINT": minio_endpoint,
            "MINIO__ACCESS_KEY": minio_access_key,
            "MINIO__SECRET_KEY": minio_secret_key,
            "MINIO__BUCKET or MINIO__BUCKET_NAME": minio_bucket,
        }.items()
        if not value
    ]
    if missing:
        pytest.skip(f"integration environment variables are missing: {', '.join(missing)}")

    engine = create_engine(
        "postgresql+psycopg://{user}:{password}@{host}:{port}/{name}".format(
            user=db_user,
            password=db_password,
            host=db_host,
            port=db_port,
            name=db_name,
        )
    )
    with engine.begin() as connection:
        rows = connection.execute(
            text(
                """
                select column_name
                from information_schema.columns
                where table_name = 'document_metadata'
                order by ordinal_position
                """
            )
        ).fetchall()
    available_columns = {row[0] for row in rows}
    required_columns = {
        "document_id",
        "original_filename",
        "content_type",
        "file_size",
        "storage_key",
        "status",
        "created_at",
        "updated_at",
        "checksum",
        "deleted_at",
        "created_by",
        "extra_metadata",
    }
    missing_columns = sorted(required_columns - available_columns)
    if missing_columns:
        pytest.skip(
            "integration database schema is incompatible with dms PostgresMetadataStore; "
            f"missing columns: {', '.join(missing_columns)}"
        )

    return {
        "db_host": db_host,
        "db_port": db_port,
        "db_name": db_name,
        "db_user": db_user,
        "db_password": db_password,
        "minio_endpoint": minio_endpoint,
        "minio_access_key": minio_access_key,
        "minio_secret_key": minio_secret_key,
        "minio_secure": minio_secure,
        "minio_bucket": minio_bucket,
    }


def test_sdk_round_trip_with_real_postgres_and_minio(integration_services):
    engine = create_engine(
        "postgresql+psycopg://{user}:{password}@{host}:{port}/{name}".format(
            user=integration_services["db_user"],
            password=integration_services["db_password"],
            host=integration_services["db_host"],
            port=integration_services["db_port"],
            name=integration_services["db_name"],
        )
    )
    minio_client = Minio(
        integration_services["minio_endpoint"],
        access_key=integration_services["minio_access_key"],
        secret_key=integration_services["minio_secret_key"],
        secure=integration_services["minio_secure"],
    )

    sdk = create_sdk(
        metadata_store=PostgresMetadataStore(engine),
        object_store=MinioObjectStore(
            client=minio_client,
            bucket_name=integration_services["minio_bucket"],
        ),
    )

    result = sdk.upload_document(
        UploadDocumentRequest(
            content=b"integration-payload",
            filename="integration.txt",
            content_type="text/plain",
            metadata={"suite": "integration"},
            created_by="sdk-test",
        )
    )

    document_id = result.document_id
    assert sdk.get_document_metadata(document_id).created_by == "sdk-test"
    assert sdk.get_document_content(document_id).content == b"integration-payload"
    sdk.delete_document(document_id, hard_delete=True)



def test_http_api_round_trip_with_real_postgres_and_minio(integration_services):
    config = EnvConfig(
        db={
            "host": integration_services["db_host"],
            "port": integration_services["db_port"],
            "name": integration_services["db_name"],
            "user": integration_services["db_user"],
            "password": integration_services["db_password"],
        },
        minio={
            "endpoint": integration_services["minio_endpoint"],
            "access_key": integration_services["minio_access_key"],
            "secret_key": integration_services["minio_secret_key"],
            "secure": integration_services["minio_secure"],
            "bucket": integration_services["minio_bucket"],
        },
        keycloak={
            "http_url": "http://127.0.0.1:8999",
            "manage_url": "http://127.0.0.1:8999",
            "realm": "docmesh",
            "client_id": "document",
            "client_secret": None,
        },
    )
    settings = ServiceSettings.model_validate(
        {
            "auth": {
                "verify_jwt": False,
                "allow_insecure_jwt_decode": True,
                "use_introspection": False,
            },
            "health": {
                "check_keycloak": False,
                "check_database": True,
                "check_minio": True,
                "check_langfuse": False,
            },
            "lifecycle": {
                "eager_keycloak": False,
                "eager_database": True,
                "eager_minio": True,
                "eager_langfuse": False,
                "eager_milvus": False,
                "eager_async_milvus": False,
                "eager_ollama": False,
                "eager_nats": False,
                "use_docmesh_registry": False,
                "use_docmesh_healthchecks": False,
            },
        }
    )
    app = create_app(config=config, settings=settings)

    from fastapi_core.dependencies.auth import get_current_user

    app.dependency_overrides[get_current_user] = lambda: UserInfo(
        sub="user-123",
        username="alice",
        email="alice@example.com",
        name="Alice",
        roles=["documents:write", "documents:read", "documents:delete", "documents:admin"],
        scopes=[],
    )

    with TestClient(app) as client:
        upload_response = client.post(
            "/documents",
            files={"file": ("report.txt", b"api-payload", "text/plain")},
            data={"metadata": '{"team":"platform"}'},
        )
        assert upload_response.status_code == 201, upload_response.text

        document_id = upload_response.json()["document_id"]
        metadata_response = client.get(f"/documents/{document_id}/metadata")
        assert metadata_response.status_code == 200, metadata_response.text
        assert metadata_response.json()["created_by"] == "user-123"

        content_response = client.get(f"/documents/{document_id}/content")
        assert content_response.status_code == 200, content_response.text
        assert content_response.content == b"api-payload"

        delete_response = client.delete(f"/documents/{document_id}?hard_delete=true")
        assert delete_response.status_code == 200, delete_response.text

        health_response = client.get("/documents/health")
        assert health_response.status_code == 200, health_response.text
        assert health_response.json()["ok"] is True
