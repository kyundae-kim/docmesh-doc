from dataclasses import dataclass
from threading import Lock
from uuid import uuid4


@dataclass(slots=True)
class StoredDocument:
    document_id: str
    filename: str
    content_type: str
    content: bytes
    is_deleted: bool = False


class DocumentService:
    def __init__(self) -> None:
        self._documents: dict[str, StoredDocument] = {}
        self._lock = Lock()

    def upload(
        self,
        *,
        filename: str,
        content_type: str,
        content: bytes,
    ) -> str:
        document_id = str(uuid4())
        document = StoredDocument(
            document_id=document_id,
            filename=filename,
            content_type=content_type,
            content=content,
        )

        with self._lock:
            self._documents[document_id] = document

        return document_id

    def get(self, document_id: str) -> StoredDocument | None:
        with self._lock:
            document = self._documents.get(document_id)
            if document is None:
                return None
            if document.is_deleted:
                return None
            return document

    def soft_delete(self, document_id: str) -> bool:
        with self._lock:
            document = self._documents.get(document_id)
            if document is None:
                return False
            document.is_deleted = True
            return True
