from dataclasses import dataclass
from typing import BinaryIO
from threading import Lock

from minio import Minio
from minio.commonconfig import Tags
from minio.error import S3Error


@dataclass(slots=True)
class StoredDocument:
    document_id: str
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

    def _normalize_file_path(self, file_path: str) -> str:
        normalized = file_path.strip().strip("/")
        if not normalized:
            raise ValueError("file_path must not be empty")
        if normalized.startswith(".") or ".." in normalized.split("/"):
            raise ValueError("file_path contains invalid path traversal")
        return normalized

    def _object_key(self, username: str, file_path: str) -> str:
        normalized_file_path = self._normalize_file_path(file_path)
        normalized_username = username.strip().strip("/")
        if not normalized_username:
            raise ValueError("username must not be empty")
        return f"{normalized_username}/{normalized_file_path}"

    def upload(
        self,
        *,
        username: str,
        file_path: str,
        filename: str,
        content_type: str,
        data_stream: BinaryIO,
        content_length: int,
    ) -> str:
        object_key = self._object_key(username, file_path)
        tags = Tags(for_object=True)
        tags["deleted"] = "false"

        self._minio_client.put_object(
            self._bucket_name,
            object_key,
            data_stream,
            length=content_length,
            content_type=content_type,
            metadata={"filename": filename, "file_path": self._normalize_file_path(file_path)},
            tags=tags,
        )

        return object_key

    def get(self, username: str, file_path: str) -> StoredDocument | None:
        object_key = self._object_key(username, file_path)

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
        filename = metadata.get("x-amz-meta-filename", object_key)

        return StoredDocument(
            document_id=object_key,
            filename=filename,
            content_type=stat_result.content_type or "application/octet-stream",
            content=content,
            is_deleted=False,
        )

    def soft_delete(self, username: str, file_path: str) -> bool:
        object_key = self._object_key(username, file_path)

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
