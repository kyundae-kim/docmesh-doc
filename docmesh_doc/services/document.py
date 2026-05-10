from dataclasses import dataclass
from io import BytesIO
from threading import Lock
from uuid import uuid4

from minio import Minio
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
        self._lock = Lock()
        self._bucket_initialized = False

    def _ensure_bucket(self) -> None:
        if self._bucket_initialized:
            return

        with self._lock:
            if self._bucket_initialized:
                return
            if not self._minio_client.bucket_exists(self._bucket_name):
                self._minio_client.make_bucket(self._bucket_name)
            self._bucket_initialized = True

    def upload(
        self,
        *,
        filename: str,
        content_type: str,
        content: bytes,
    ) -> str:
        self._ensure_bucket()

        document_id = str(uuid4())
        data = BytesIO(content)

        self._minio_client.put_object(
            self._bucket_name,
            document_id,
            data,
            length=len(content),
            content_type=content_type,
            metadata={"filename": filename},
            tags={"deleted": "false"},
        )

        return document_id

    def get(self, document_id: str) -> StoredDocument | None:
        self._ensure_bucket()

        try:
            tags = self._minio_client.get_object_tags(self._bucket_name, document_id)
            if tags.get("deleted") == "true":
                return None

            stat_result = self._minio_client.stat_object(self._bucket_name, document_id)
            response = self._minio_client.get_object(self._bucket_name, document_id)
            content = response.read()
            response.close()
            response.release_conn()
        except S3Error as exc:
            if exc.code in {"NoSuchKey", "NoSuchObject", "NoSuchBucket"}:
                return None
            raise

        metadata = getattr(stat_result, "metadata", {}) or {}
        filename = metadata.get("x-amz-meta-filename", document_id)

        return StoredDocument(
            document_id=document_id,
            filename=filename,
            content_type=stat_result.content_type or "application/octet-stream",
            content=content,
            is_deleted=False,
        )

    def soft_delete(self, document_id: str) -> bool:
        self._ensure_bucket()

        try:
            self._minio_client.stat_object(self._bucket_name, document_id)
            tags = self._minio_client.get_object_tags(self._bucket_name, document_id)
            tags["deleted"] = "true"
            self._minio_client.set_object_tags(self._bucket_name, document_id, tags)
        except S3Error as exc:
            if exc.code in {"NoSuchKey", "NoSuchObject", "NoSuchBucket"}:
                return False
            raise

        return True
