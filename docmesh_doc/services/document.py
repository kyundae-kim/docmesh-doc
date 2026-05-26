from __future__ import annotations

from dataclasses import dataclass
from typing import BinaryIO
from uuid import UUID, uuid4

from minio import Minio
from minio.commonconfig import Tags
from minio.error import S3Error


@dataclass(slots=True)
class StoredDocument:
    document_id: UUID
    filename: str
    content_type: str
    content: bytes
    is_deleted: bool = False


class DocumentService:
    def __init__(self, *, minio_client: Minio, bucket_name: str) -> None:
        self._minio_client = minio_client
        self._bucket_name = bucket_name
        self._ensure_bucket()

    def _ensure_bucket(self) -> None:
        if not self._minio_client.bucket_exists(self._bucket_name):
            self._minio_client.make_bucket(self._bucket_name)

    def _normalize_username(self, username: str) -> str:
        normalized_username = username.strip().strip("/")
        if not normalized_username:
            raise ValueError("username must not be empty")
        return normalized_username

    def _object_key(self, username: str, document_id: UUID) -> str:
        return f"{self._normalize_username(username)}/{document_id}"

    def upload(
        self,
        *,
        username: str,
        filename: str,
        content_type: str,
        data_stream: BinaryIO,
        content_length: int,
    ) -> UUID:
        document_id = uuid4()
        object_key = self._object_key(username, document_id)
        tags = Tags(for_object=True)
        tags["deleted"] = "false"

        self._minio_client.put_object(
            self._bucket_name,
            object_key,
            data_stream,
            length=content_length,
            content_type=content_type,
            metadata={"filename": filename, "document_id": str(document_id)},
            tags=tags,
        )

        return document_id

    def get(self, username: str, document_id: UUID) -> StoredDocument | None:
        object_key = self._object_key(username, document_id)

        try:
            tags = self._minio_client.get_object_tags(self._bucket_name, object_key)
            if tags is not None and tags.get("deleted") == "true":
                return None

            stat_result = self._minio_client.stat_object(self._bucket_name, object_key)
            response = self._minio_client.get_object(self._bucket_name, object_key)
            content = response.read()
            response.close()
            response.release_conn()
        except S3Error as exc:
            if exc.code in {"NoSuchKey", "NoSuchObject", "NoSuchBucket"}:
                return None
            raise

        metadata = getattr(stat_result, "metadata", {}) or {}
        filename = metadata.get("x-amz-meta-filename", str(document_id))

        return StoredDocument(
            document_id=document_id,
            filename=filename,
            content_type=stat_result.content_type or "application/octet-stream",
            content=content,
            is_deleted=False,
        )

    def soft_delete(self, username: str, document_id: UUID) -> bool:
        object_key = self._object_key(username, document_id)

        try:
            self._minio_client.stat_object(self._bucket_name, object_key)
            tags = self._minio_client.get_object_tags(self._bucket_name, object_key)
            if tags is None:
                tags = Tags(for_object=True)
            tags["deleted"] = "true"
            self._minio_client.set_object_tags(self._bucket_name, object_key, tags)
        except S3Error as exc:
            if exc.code in {"NoSuchKey", "NoSuchObject", "NoSuchBucket"}:
                return False
            raise

        return True
