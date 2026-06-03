from __future__ import annotations

from uuid import UUID, uuid4

import pytest
from fastapi_core.core.config import EnvConfig
from sqlalchemy import create_engine, text

from docmesh_doc.services.metadata import MetadataConflictError, MetadataService


@pytest.fixture(scope="module")
def metadata_service() -> MetadataService:
    config = EnvConfig()
    return MetadataService(config.db)


@pytest.fixture
def cleanup_records() -> list[UUID]:
    created: list[UUID] = []
    yield created

    config = EnvConfig().db
    engine = create_engine(config.sqlalchemy_database_url, future=True)
    with engine.begin() as conn:
        for document_id in created:
            conn.execute(
                text("DELETE FROM document_metadata WHERE document_id = :document_id"),
                {"document_id": str(document_id)},
            )


def test_create_and_get_metadata(metadata_service: MetadataService, cleanup_records: list[UUID]):
    document_id = uuid4()
    cleanup_records.append(document_id)

    created = metadata_service.create(
        username="tester-a",
        document_id=document_id,
        filename="architecture.pdf",
        metadata_value={"category": "architecture", "priority": 1},
    )

    assert created.document_id == document_id
    assert created.filename == "architecture.pdf"
    assert created.uploaded_by == "tester-a"
    assert created.metadata_value == {"category": "architecture", "priority": 1}
    assert created.created_at is not None
    assert created.updated_at is not None

    fetched = metadata_service.get(username="tester-a", document_id=document_id)
    assert fetched is not None
    assert fetched.document_id == document_id
    assert fetched.filename == "architecture.pdf"
    assert fetched.uploaded_by == "tester-a"
    assert fetched.metadata_value == {"category": "architecture", "priority": 1}


def test_create_conflict_raises(metadata_service: MetadataService, cleanup_records: list[UUID]):
    document_id = uuid4()
    cleanup_records.append(document_id)

    metadata_service.create(
        username="tester-b",
        document_id=document_id,
        filename="first.txt",
        metadata_value={"tag": "first"},
    )

    with pytest.raises(MetadataConflictError):
        metadata_service.create(
            username="tester-b",
            document_id=document_id,
            filename="second.txt",
            metadata_value={"tag": "second"},
        )


def test_update_metadata(metadata_service: MetadataService, cleanup_records: list[UUID]):
    document_id = uuid4()
    cleanup_records.append(document_id)

    created = metadata_service.create(
        username="tester-c",
        document_id=document_id,
        filename="priority.txt",
        metadata_value={"priority": 1},
    )

    updated = metadata_service.update(
        username="tester-c",
        document_id=document_id,
        metadata_value={"priority": 2},
    )

    assert updated is not None
    assert updated.document_id == document_id
    assert updated.filename == "priority.txt"
    assert updated.uploaded_by == "tester-c"
    assert updated.metadata_value == {"priority": 2}
    assert updated.updated_at >= created.updated_at


def test_delete_metadata(metadata_service: MetadataService, cleanup_records: list[UUID]):
    document_id = uuid4()

    metadata_service.create(
        username="tester-d",
        document_id=document_id,
        filename="delete.txt",
        metadata_value={"k": "v"},
    )

    deleted = metadata_service.delete(username="tester-d", document_id=document_id)
    assert deleted is True

    fetched = metadata_service.get(username="tester-d", document_id=document_id)
    assert fetched is None

    deleted_again = metadata_service.delete(username="tester-d", document_id=document_id)
    assert deleted_again is False


def test_owner_isolation(metadata_service: MetadataService, cleanup_records: list[UUID]):
    document_id = uuid4()
    cleanup_records.append(document_id)

    metadata_service.create(
        username="owner-1",
        document_id=document_id,
        filename="private.txt",
        metadata_value={"visibility": "private"},
    )

    assert metadata_service.get(username="owner-2", document_id=document_id) is None
    assert (
        metadata_service.update(
            username="owner-2",
            document_id=document_id,
            metadata_value={"visibility": "public"},
        )
        is None
    )
    assert metadata_service.delete(username="owner-2", document_id=document_id) is False
