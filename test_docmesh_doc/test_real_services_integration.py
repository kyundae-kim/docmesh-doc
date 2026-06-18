from __future__ import annotations


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


def test_sdk_round_trip_with_real_postgres_and_minio(docker_services):
    engine = create_engine(
        f"postgresql+psycopg://postgres:postgres@{docker_services['postgres_host']}:5432/docmesh"
    )
    minio_client = Minio(
        f"{docker_services['minio_host']}:9000",
        access_key="admin",
        secret_key="password",
        secure=False,
    )

    sdk = create_sdk(
        metadata_store=PostgresMetadataStore(engine),
        object_store=MinioObjectStore(client=minio_client, bucket_name="documents"),
    )

    result = sdk.upload_document(
        UploadDocumentRequest(
            content=b"integration-payload",
            filename="integration.txt",
            content_type="text/plain",
            document_id="integration-sdk-doc",
            metadata={"suite": "integration"},
            created_by="sdk-test",
        )
    )

    assert result.document_id == "integration-sdk-doc"
    assert sdk.get_document_metadata("integration-sdk-doc").created_by == "sdk-test"
    assert sdk.get_document_content("integration-sdk-doc").content == b"integration-payload"



def test_http_api_round_trip_with_real_postgres_and_minio(docker_services):
    config = EnvConfig(
        db={
            "host": docker_services["postgres_host"],
            "port": 5432,
            "name": "docmesh",
            "user": "postgres",
            "password": "postgres",
        },
        minio={
            "endpoint": f"{docker_services['minio_host']}:9000",
            "access_key": "admin",
            "secret_key": "password",
            "secure": False,
            "bucket": "documents",
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
            data={"document_id": "integration-api-doc", "metadata": '{"team":"platform"}'},
        )
        assert upload_response.status_code == 201, upload_response.text

        metadata_response = client.get("/documents/integration-api-doc/metadata")
        assert metadata_response.status_code == 200, metadata_response.text
        assert metadata_response.json()["created_by"] == "user-123"

        content_response = client.get("/documents/integration-api-doc/content")
        assert content_response.status_code == 200, content_response.text
        assert content_response.content == b"api-payload"

        delete_response = client.delete("/documents/integration-api-doc?hard_delete=true")
        assert delete_response.status_code == 200, delete_response.text

        health_response = client.get("/documents/health")
        assert health_response.status_code == 200, health_response.text
        assert health_response.json()["ok"] is True
