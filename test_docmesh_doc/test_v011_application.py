from __future__ import annotations

from datetime import UTC, datetime

import dms
import pytest
from fastapi.testclient import TestClient

from docmesh_doc.application import create_application
from docmesh_doc.dms_factory import DmsSettings

APPLICATION_USER = "application-user"
NOW = datetime(2026, 9, 4, tzinfo=UTC)
PARTITION = dms.DocumentPartition.personal(APPLICATION_USER)


def metadata(document_id: str = "doc-1") -> dms.PublicDocumentMetadata:
    return dms.PublicDocumentMetadata(
        document_id=document_id,
        original_filename="document.txt",
        content_type="text/plain",
        file_size=2,
        status=dms.DocumentStatus.AVAILABLE,
        created_at=NOW,
        updated_at=NOW,
        partition=PARTITION,
        extra_metadata={},
    )


class SingleUserSDK:
    def __init__(self) -> None:
        self.list_kwargs: dict[str, object] | None = None
        self.clear_partition_kwargs: dict[str, object] | None = None
        self.initialize_partition_kwargs: dict[str, object] | None = None
        self.clear_all_kwargs: dict[str, object] | None = None
        self.initialize_kwargs: dict[str, object] | None = None

    def list_documents(self, **kwargs):
        self.list_kwargs = kwargs
        return dms.DocumentPage(items=[metadata()], next_cursor=None, has_more=False)

    def clear_partition_data(self, **kwargs):
        self.clear_partition_kwargs = kwargs
        return dms.DataResetResult(
            metadata_deleted=1,
            objects_deleted=1,
            upload_operations_deleted=0,
        )

    def initialize_partition_for_data_load(self, **kwargs):
        self.initialize_partition_kwargs = kwargs
        return dms.DataResetResult(
            metadata_deleted=0,
            objects_deleted=0,
            upload_operations_deleted=0,
        )

    def clear_all_data(self, **kwargs):
        self.clear_all_kwargs = kwargs
        return dms.DataResetResult(
            metadata_deleted=1,
            objects_deleted=1,
            upload_operations_deleted=0,
        )

    def initialize_for_data_load(self, **kwargs):
        self.initialize_kwargs = kwargs
        return dms.DataResetResult(
            metadata_deleted=0,
            objects_deleted=0,
            upload_operations_deleted=0,
        )


def test_application_binds_every_request_to_one_dms_user_partition():
    sdk = SingleUserSDK()
    settings = DmsSettings(application_user_id=APPLICATION_USER)

    with TestClient(create_application(sdk=sdk, settings=settings)) as client:
        response = client.get(
            "/documents",
            headers={"X-User-ID": "attacker", "X-Roles": "none"},
        )

    assert response.status_code == 200
    assert response.json()["items"][0]["partition"] == {
        "kind": "personal",
        "partition_id": APPLICATION_USER,
    }
    assert sdk.list_kwargs is not None
    assert sdk.list_kwargs["partition"] == PARTITION
    assert sdk.list_kwargs["access_context"].user_id == APPLICATION_USER
    assert sdk.list_kwargs["access_context"].roles == frozenset({"admin"})


def test_application_exposes_partition_scoped_reset_operations():
    sdk = SingleUserSDK()

    with TestClient(
        create_application(
            sdk=sdk,
            settings=DmsSettings(application_user_id=APPLICATION_USER),
        )
    ) as client:
        cleared = client.delete("/management/data/partition")
        initialized = client.post("/management/data/partition/initializations")

    assert cleared.status_code == 200
    assert initialized.status_code == 200
    assert sdk.clear_partition_kwargs["partition"] == PARTITION
    assert sdk.initialize_partition_kwargs["partition"] == PARTITION


def test_application_user_id_is_loaded_from_the_host_environment():
    settings = DmsSettings.from_env(
        {
            "DMS_APPLICATION_USER_ID": "  configured-user  ",
        }
    )

    assert settings.application_user_id == "configured-user"


def test_global_reset_routes_remain_partitionless():
    sdk = SingleUserSDK()

    with TestClient(
        create_application(
            sdk=sdk,
            settings=DmsSettings(application_user_id=APPLICATION_USER),
        )
    ) as client:
        cleared = client.delete("/management/data")
        initialized = client.post("/management/data/initializations")

    assert cleared.status_code == 200
    assert initialized.status_code == 200
    assert sdk.clear_all_kwargs is not None
    assert sdk.initialize_kwargs is not None
    assert set(sdk.clear_all_kwargs) == {"access_context"}
    assert set(sdk.initialize_kwargs) == {"access_context"}
    assert sdk.clear_all_kwargs["access_context"].user_id == APPLICATION_USER
    assert sdk.initialize_kwargs["access_context"].user_id == APPLICATION_USER


def test_application_rejects_an_empty_application_user_id():
    with pytest.raises(dms.ConfigurationError, match="DMS_APPLICATION_USER_ID"):
        create_application(sdk=SingleUserSDK(), application_user_id=" ")
