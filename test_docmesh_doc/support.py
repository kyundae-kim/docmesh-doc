from __future__ import annotations

from datetime import UTC, datetime
from io import BytesIO

import dms
from fastapi.testclient import TestClient

from docmesh_doc.application import create_application

NOW = datetime(2026, 8, 15, tzinfo=UTC)


def public_metadata(document_id: str = "doc-1") -> dms.PublicDocumentMetadata:
    return dms.PublicDocumentMetadata(
        document_id=document_id,
        original_filename="contract.pdf",
        content_type="application/pdf",
        file_size=3,
        status=dms.DocumentStatus.AVAILABLE,
        created_at=NOW,
        updated_at=NOW,
        created_by="user-1",
        user_id="user-1",
        checksum="checksum",
        extra_metadata={"category": "contract"},
    )


class FakeSDK:
    def __init__(self) -> None:
        self.scoped_contexts = []
        self.upload_request = None
        self.list_args = None
        self.content_stream_calls = 0
        self.stream_closed = False
        self.delete_args = None
        self.closed = False

    def scoped(self, context):
        self.scoped_contexts.append(context)
        return self

    def upload_document_stream(self, request):
        self.upload_request = request
        payload = request.stream.read()
        assert len(payload) == request.size
        item = public_metadata(request.document_id or "generated-id")
        return dms.UploadDocumentResult(document_id=item.document_id, metadata=item)

    def list_documents(self, *, cursor=None, limit=100, status=None, **_kwargs):
        self.list_args = (cursor, limit, status)
        return dms.DocumentPage(
            items=[public_metadata("doc-1"), public_metadata("doc-2")],
            next_cursor="next-page",
            has_more=True,
        )

    def get_document_metadata(self, document_id, **_kwargs):
        return public_metadata(document_id)

    def get_document_content_stream(
        self,
        document_id,
        *,
        chunk_size=64 * 1024,
        **_kwargs,
    ):
        self.content_stream_calls += 1
        return dms.DocumentContentStream(
            document_id=document_id,
            stream=BytesIO(b"pdf"),
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
            checksum="checksum",
            chunk_size=chunk_size,
            _close_callback=lambda: setattr(self, "stream_closed", True),
        )

    def delete_document(self, document_id, *, hard_delete=False, **_kwargs):
        self.delete_args = (document_id, hard_delete)
        return dms.DeleteDocumentResult(
            document_id=document_id,
            deleted=True,
            hard_deleted=hard_delete,
            status=dms.DocumentStatus.DELETED,
        )

    def close(self):
        self.closed = True


def client_for(
    sdk: FakeSDK,
    *,
    root_path: str = "",
) -> TestClient:
    app = create_application(
        sdk,
        root_path=root_path,
    )
    return TestClient(app)
