from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone
from threading import Lock
from uuid import UUID


@dataclass(slots=True)
class MetadataRecord:
    document_id: UUID
    metadata_value: dict
    created_at: datetime
    updated_at: datetime


class MetadataConflictError(Exception):
    pass


class MetadataService:
    def __init__(self) -> None:
        self._lock = Lock()
        self._records: dict[tuple[str, str], MetadataRecord] = {}

    def _key(self, username: str, document_id: UUID) -> tuple[str, str]:
        normalized_username = username.strip().strip("/")
        if not normalized_username:
            raise ValueError("username must not be empty")
        return normalized_username, str(document_id)

    def create(self, *, username: str, document_id: UUID, metadata_value: dict) -> MetadataRecord:
        now = datetime.now(timezone.utc)
        key = self._key(username, document_id)
        with self._lock:
            if key in self._records:
                raise MetadataConflictError("Metadata already exists")

            record = MetadataRecord(
                document_id=document_id,
                metadata_value=metadata_value,
                created_at=now,
                updated_at=now,
            )
            self._records[key] = record
            return record

    def get(self, *, username: str, document_id: UUID) -> MetadataRecord | None:
        key = self._key(username, document_id)
        with self._lock:
            return self._records.get(key)

    def update(self, *, username: str, document_id: UUID, metadata_value: dict) -> MetadataRecord | None:
        key = self._key(username, document_id)
        with self._lock:
            record = self._records.get(key)
            if record is None:
                return None

            record.metadata_value = metadata_value
            record.updated_at = datetime.now(timezone.utc)
            return record

    def delete(self, *, username: str, document_id: UUID) -> bool:
        key = self._key(username, document_id)
        with self._lock:
            return self._records.pop(key, None) is not None
