from __future__ import annotations

from hashlib import sha256

import dms
import pytest
from fastapi.testclient import TestClient
from fastapi_core.schemas import UserInfo


PAYLOAD = b"DocMesh integration test payload"


def upload(client: TestClient, document_id: str):
    return client.post(
        "/documents",
        files={"file": ("integration.txt", PAYLOAD, "text/plain")},
        data={
            "document_id": document_id,
            "metadata": '{"suite":"integration"}',
            "checksum": sha256(PAYLOAD).hexdigest(),
        },
        headers={"X-Correlation-ID": f"correlation-{document_id}"},
    )


def test_upload_persists_metadata_and_content_in_postgres_and_minio(
    integration_client: tuple[
        TestClient, dms.DefaultDocumentManagementSDK, UserInfo
    ],
    document_id: str,
):
    client, sdk, user = integration_client

    response = upload(client, document_id)

    assert response.status_code == 201
    assert response.headers["Location"] == f"/documents/{document_id}"
    assert response.headers["X-Correlation-ID"] == f"correlation-{document_id}"
    assert response.json()["document_id"] == document_id
    assert response.json()["created_by"] == user.sub
    assert response.json()["metadata"] == {"suite": "integration"}
    assert "storage_key" not in response.json()

    metadata = sdk.get_document_metadata(document_id)
    content = sdk.get_document_content(document_id)
    assert metadata.status is dms.DocumentStatus.AVAILABLE
    assert metadata.original_filename == "integration.txt"
    assert metadata.extra_metadata == {"suite": "integration"}
    assert content.content == PAYLOAD
    assert content.content_type == "text/plain"

    sdk.hard_delete_document(document_id)


def test_metadata_lookup_and_streaming_download_use_real_stores(
    integration_client: tuple[
        TestClient, dms.DefaultDocumentManagementSDK, UserInfo
    ],
    document_id: str,
):
    client, sdk, _ = integration_client
    assert upload(client, document_id).status_code == 201

    list_response = client.get(
        "/documents", params={"status": "available", "limit": 1000}
    )
    metadata_response = client.get(f"/documents/{document_id}")
    download_response = client.get(
        f"/documents/{document_id}/download", params={"chunk_size": 7}
    )

    assert list_response.status_code == 200
    assert document_id in {item["document_id"] for item in list_response.json()}
    assert all("storage_key" not in item for item in list_response.json())
    assert metadata_response.status_code == 200
    assert metadata_response.json()["status"] == "available"
    assert download_response.status_code == 200
    assert download_response.content == PAYLOAD
    assert download_response.headers["Content-Type"].startswith("text/plain")
    assert download_response.headers["Content-Disposition"].startswith("attachment;")

    sdk.hard_delete_document(document_id)


def test_hard_delete_removes_postgres_metadata_and_minio_object(
    integration_client: tuple[
        TestClient, dms.DefaultDocumentManagementSDK, UserInfo
    ],
    document_id: str,
):
    client, sdk, user = integration_client
    if "document:delete:hard" not in user.roles:
        pytest.skip(
            "integration Keycloak user does not have document:delete:hard role"
        )
    assert upload(client, document_id).status_code == 201

    response = client.delete(f"/documents/{document_id}", params={"hard": "true"})

    assert response.status_code == 200
    assert response.json()["hard_deleted"] is True
    try:
        sdk.get_document_metadata(document_id)
    except dms.DocumentNotFoundError:
        pass
    else:
        raise AssertionError("hard-deleted PostgreSQL metadata still exists")
    with pytest.raises(dms.DocumentNotFoundError):
        sdk.get_document_content(document_id)


def test_sdk_health_checks_real_postgres_and_minio(
    integration_client: tuple[
        TestClient, dms.DefaultDocumentManagementSDK, UserInfo
    ],
):
    _, sdk, _ = integration_client

    health = sdk.check_health()

    assert health.ok is True
    assert {service.service for service in health.services} == {"postgres", "minio"}
    assert all(service.ok for service in health.services)
