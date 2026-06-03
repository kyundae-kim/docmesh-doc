from __future__ import annotations

from io import BytesIO

from docmesh_doc.services import document as document_module
from docmesh_doc.services.document import DocumentService


class _FakeMinioClient:
    def __init__(self):
        self.put_calls: list[dict] = []

    def put_object(self, *args, **kwargs):
        self.put_calls.append({"args": args, "kwargs": kwargs})


def test_upload_omits_filename_from_minio_object_metadata(monkeypatch):
    monkeypatch.setattr(document_module, "ensure_bucket_exists", lambda *_args, **_kwargs: None)
    minio_client = _FakeMinioClient()
    service = DocumentService(minio_client=minio_client, bucket_name="documents")

    document_id = service.upload(
        username="tester",
        filename="한글 파일명.txt",
        content_type="text/plain",
        data_stream=BytesIO(b"hello"),
        content_length=5,
    )

    assert len(minio_client.put_calls) == 1
    assert minio_client.put_calls[0]["kwargs"]["metadata"] == {
        "document_id": str(document_id)
    }
