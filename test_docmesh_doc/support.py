from __future__ import annotations

from datetime import UTC, datetime
from io import BytesIO

import dms
from fastapi.testclient import TestClient
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import get_current_user
from fastapi_core.schemas import UserInfo

from docmesh_doc.application import create_application


NOW = datetime(2026, 7, 11, tzinfo=UTC)


def metadata(document_id: str = "doc-1") -> dms.DocumentMetadata:
    return dms.DocumentMetadata(
        document_id=document_id,
        original_filename="contract.pdf",
        content_type="application/pdf",
        file_size=3,
        storage_key="private/object/key",
        status=dms.DocumentStatus.AVAILABLE,
        created_at=NOW,
        updated_at=NOW,
        created_by="user-1",
        extra_metadata={"category": "contract"},
    )


class FakeSDK:
    def __init__(self) -> None:
        self.closed = False
        self.upload_request = None
        self.upload_stream_request = None
        self.delete_call = None
        self.list_args = None
        self.stream_closed = False

    def upload_document(self, request):
        self.upload_request = request
        item = metadata(request.document_id or "generated-id")
        return dms.UploadDocumentResult(
            document_id=item.document_id,
            storage_key=item.storage_key,
            metadata=item,
        )

    def upload_document_stream(self, request):
        self.upload_stream_request = request
        content = request.stream.read()
        assert len(content) == request.size
        item = metadata(request.document_id or "generated-id")
        return dms.UploadDocumentResult(
            document_id=item.document_id,
            storage_key=item.storage_key,
            metadata=item,
        )

    def get_document_metadata(self, document_id):
        if document_id == "missing":
            raise dms.DocumentNotFoundError(document_id)
        return metadata(document_id)

    def list_documents(self, *, offset=0, limit=100, status=None):
        self.list_args = (offset, limit, status)
        return [metadata("doc-1"), metadata("doc-2")]

    def get_document_content(self, document_id):
        return dms.DocumentContent(
            document_id=document_id,
            content=b"pdf",
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
        )

    def get_document_content_stream(self, document_id, *, chunk_size=65536):
        return dms.DocumentContentStream(
            document_id=document_id,
            stream=BytesIO(b"pdf"),
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
            chunk_size=chunk_size,
            _close_callback=lambda: setattr(self, "stream_closed", True),
        )

    def soft_delete_document(self, document_id):
        self.delete_call = ("soft", document_id)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=False,
            status=dms.DocumentStatus.DELETED,
        )

    def hard_delete_document(self, document_id):
        self.delete_call = ("hard", document_id)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=True,
            status=dms.DocumentStatus.DELETED,
        )

    def check_health(self):
        return dms.HealthStatus(ok=True, services=[], checked_at=NOW)

    def close(self):
        self.closed = True


def client_for(sdk: FakeSDK, *, roles: list[str] | None = None) -> TestClient:
    app = create_application(
        sdk,
        config=AppConfig(
            startup_healthcheck=False,
            enabled_services=[],
            required_services=[],
        ),
        include_auth_router=False,
    )
    app.dependency_overrides[get_current_user] = lambda: UserInfo(
        sub="user-1", username="alice", roles=roles or []
    )
    return TestClient(app)
