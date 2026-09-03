from __future__ import annotations

import base64
from pathlib import Path
from types import SimpleNamespace

import dms

import docmesh_doc.router as router_module
from test_docmesh_doc.support import NOW, FakeSDK, client_for, public_metadata


class FakeAsyncContentStream:
    def __init__(self, document_id: str) -> None:
        self.document_id = document_id
        self.content_type = "application/pdf"
        self.filename = "contract.pdf"
        self.size = 3
        self.checksum = "checksum"
        self.closed = False

    async def aiter_chunks_closing(self):
        try:
            yield b"p"
            yield b"df"
        finally:
            await self.aclose()

    async def aclose(self) -> None:
        self.closed = True


class FullFakeSDK(FakeSDK):
    def __init__(self) -> None:
        super().__init__()
        self.bytes_upload_request = None
        self.file_upload_args = None
        self.file_upload_path = None
        self.file_upload_content = None
        self.upload_operation_args = None
        self.page_args = None
        self.iterator_args = None
        self.eager_content_calls = 0
        self.async_stream = None
        self.chunk_args = None
        self.copy_args = None
        self.copy_sink = None
        self.internal_metadata_calls = []
        self.inspection_calls = []
        self.recovery_candidate_args = None
        self.recovery_iterator_args = None
        self.reconcile_document_args = None
        self.reconcile_documents_args = None
        self.plan_args = None
        self.special_delete_args = None
        self.clear_calls = 0
        self.initialize_calls = 0

    def upload_document(self, request, **_kwargs):
        self.bytes_upload_request = request
        item = public_metadata(request.document_id or "generated-bytes-id")
        return dms.UploadDocumentResult(
            document_id=item.document_id,
            metadata=item,
            created=False,
        )

    def upload_file(
        self,
        path,
        *,
        filename=None,
        content_type=None,
        document_id=None,
        metadata=None,
        created_by=None,
        **_kwargs,
    ):
        self.file_upload_path = str(path)
        self.file_upload_content = Path(path).read_bytes()
        self.file_upload_args = (
            filename,
            content_type,
            document_id,
            metadata,
            created_by,
        )
        item = public_metadata(document_id or "generated-file-id")
        return dms.UploadDocumentResult(document_id=item.document_id, metadata=item)

    def get_upload_operation(
        self,
        *,
        idempotency_key,
        scope=None,
        **_kwargs,
    ):
        self.upload_operation_args = (scope, idempotency_key)
        return SimpleNamespace(
            scope=scope or "context-scope",
            idempotency_key=idempotency_key,
            document_id="doc-1",
            state="succeeded",
            created_at=NOW,
            updated_at=NOW,
        )

    def get_internal_document_metadata(self, document_id, **_kwargs):
        self.internal_metadata_calls.append(document_id)
        public = public_metadata(document_id)
        return dms.DocumentMetadata(
            document_id=public.document_id,
            original_filename=public.original_filename,
            content_type=public.content_type,
            file_size=public.file_size,
            storage_key=f"private/{document_id}",
            status=public.status,
            created_at=public.created_at,
            updated_at=public.updated_at,
            checksum=public.checksum,
            deleted_at=public.deleted_at,
            created_by=public.created_by,
            partition=public.partition,
            extra_metadata=public.extra_metadata,
        )

    def list_documents_page(
        self,
        *,
        cursor=None,
        limit=100,
        status=None,
        **_kwargs,
    ):
        self.page_args = (cursor, limit, status)
        return dms.DocumentPage(
            items=[public_metadata("page-doc")],
            next_cursor=None,
            has_more=False,
        )

    def iter_documents(self, *, status=None, page_size=100, **_kwargs):
        self.iterator_args = (status, page_size)
        yield public_metadata("iter-doc-1")
        yield public_metadata("iter-doc-2")

    def get_document_content(self, document_id, **_kwargs):
        self.eager_content_calls += 1
        return dms.DocumentContent(
            document_id=document_id,
            content=b"pdf",
            content_type="application/pdf",
            filename="contract.pdf",
            size=3,
            checksum="checksum",
        )

    async def get_document_content_async_stream(
        self,
        document_id,
        *,
        chunk_size=64 * 1024,
        **_kwargs,
    ):
        del chunk_size
        self.async_stream = FakeAsyncContentStream(document_id)
        return self.async_stream

    def iter_document_chunks(
        self,
        document_id,
        *,
        chunk_size=64 * 1024,
        **_kwargs,
    ):
        self.chunk_args = (document_id, chunk_size)
        yield b"p"
        yield b"df"

    def copy_document_to(
        self,
        document_id,
        sink,
        *,
        chunk_size=64 * 1024,
        verify_checksum=True,
        **_kwargs,
    ):
        self.copy_args = (document_id, chunk_size, verify_checksum)
        self.copy_sink = sink
        sink.write(b"pdf")
        return dms.DocumentCopyResult(
            document_id=document_id,
            bytes_copied=3,
            checksum="checksum",
            checksum_verified=verify_checksum,
        )

    def inspect_document(self, document_id, **_kwargs):
        self.inspection_calls.append(document_id)
        return dms.DocumentInspection(
            document_id=document_id,
            metadata_exists=True,
            object_exists=False,
            status=dms.DocumentStatus.FAILED,
            consistent=False,
            issue=dms.RecoveryIssue.OBJECT_MISSING,
            storage_key=f"private/{document_id}",
        )

    def list_recovery_candidates(
        self,
        *,
        status,
        offset=0,
        limit=100,
        **_kwargs,
    ):
        self.recovery_candidate_args = (status, offset, limit)
        return [self.get_internal_document_metadata("failed-doc")]

    def iter_recovery_candidates(
        self,
        *,
        status,
        page_size=100,
        **_kwargs,
    ):
        self.recovery_iterator_args = (status, page_size)
        yield self.get_internal_document_metadata("iter-failed-doc")

    @staticmethod
    def _reconciliation_result(document_id, action, *, applied=True):
        return dms.ReconciliationResult(
            document_id=document_id,
            action=action,
            applied=applied,
            inspection=dms.DocumentInspection(
                document_id=document_id,
                metadata_exists=True,
                object_exists=False,
                status=dms.DocumentStatus.FAILED,
                consistent=False,
                issue=dms.RecoveryIssue.OBJECT_MISSING,
                storage_key=f"private/{document_id}",
            ),
        )

    def reconcile_document(
        self,
        document_id,
        action,
        *,
        storage_key=None,
        dry_run=False,
        actor=None,
        **_kwargs,
    ):
        self.reconcile_document_args = (
            document_id,
            action,
            storage_key,
            dry_run,
            actor,
        )
        return self._reconciliation_result(
            document_id,
            action,
            applied=not dry_run,
        )

    def reconcile_documents(
        self,
        *,
        status,
        action,
        offset=0,
        limit=100,
        dry_run=False,
        actor=None,
        **_kwargs,
    ):
        self.reconcile_documents_args = (
            status,
            action,
            offset,
            limit,
            dry_run,
            actor,
        )
        return dms.BatchReconciliationResult(
            partition=_kwargs["partition"],
            status=status,
            action=action,
            dry_run=dry_run,
            offset=offset,
            limit=limit,
            items=[
                self._reconciliation_result(
                    "failed-doc",
                    action,
                    applied=not dry_run,
                )
            ],
        )

    def execute_reconciliation_plan(self, plan, *, actor=None, **_kwargs):
        self.plan_args = (plan, actor)
        return dms.BatchReconciliationResult(
            partition=plan.partition,
            status=plan.status,
            action=plan.action,
            dry_run=False,
            offset=0,
            limit=len(plan.items),
            items=[
                self._reconciliation_result(item.document_id, item.action)
                for item in plan.items
            ],
        )

    def soft_delete_document(self, document_id, **_kwargs):
        self.special_delete_args = ("soft", document_id)
        return super().delete_document(document_id, hard_delete=False)

    def hard_delete_document(self, document_id, **_kwargs):
        self.special_delete_args = ("hard", document_id)
        return super().delete_document(document_id, hard_delete=True)

    def clear_all_data(self, **_kwargs):
        self.clear_calls += 1
        return dms.DataResetResult(
            metadata_deleted=2,
            objects_deleted=2,
            upload_operations_deleted=1,
        )

    def initialize_for_data_load(self, **_kwargs):
        self.initialize_calls += 1
        return dms.DataResetResult(
            metadata_deleted=0,
            objects_deleted=0,
            upload_operations_deleted=0,
        )


def test_request_headers_cannot_override_the_fixed_application_identity():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        response = client.get(
            "/documents",
            headers={
                "X-Subject": "attacker",
                "X-User-ID": "attacker",
                "X-Tenant-ID": "attacker-tenant",
                "X-Roles": "none",
            },
        )

    assert response.status_code == 200
    assert sdk.list_args == (None, 100, None)


def test_bytes_and_file_upload_variants_delegate_to_their_dms_operations():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        bytes_response = client.post(
            "/documents/bytes",
            json={
                "content_base64": base64.b64encode(b"pdf").decode("ascii"),
                "filename": "bytes.pdf",
                "content_type": "application/pdf",
                "document_id": "bytes-doc",
                "metadata": {"source": "bytes"},
                "created_by": "author-1",
                "checksum": "bytes-checksum",
                "idempotency_key": "upload-1",
                "idempotency_scope": "scope-1",
            },
        )
        file_response = client.post(
            "/documents/file",
            files={"file": ("file.pdf", b"pdf", "application/pdf")},
            data={
                "document_id": "file-doc",
                "metadata": '{"source":"file"}',
                "created_by": "author-2",
            },
        )

    assert bytes_response.status_code == 200
    assert bytes_response.json()["created"] is False
    assert sdk.bytes_upload_request.content == b"pdf"
    assert sdk.bytes_upload_request.idempotency_key == "upload-1"
    assert not hasattr(sdk.bytes_upload_request, "user_id")
    assert sdk.bytes_upload_request.checksum == "bytes-checksum"
    assert file_response.status_code == 201
    assert sdk.file_upload_content == b"pdf"
    assert sdk.file_upload_args == (
        "file.pdf",
        "application/pdf",
        "file-doc",
        {"source": "file"},
        "author-2",
    )
    assert not Path(sdk.file_upload_path).exists()


def test_bytes_upload_rejects_non_standard_json_metadata():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        response = client.post(
            "/documents/bytes",
            content=(
                '{"content_base64":"cGRm","filename":"bytes.pdf",'
                '"content_type":"application/pdf","metadata":NaN}'
            ),
            headers={"Content-Type": "application/json"},
        )

    assert response.status_code == 400
    assert response.json()["error"]["code"] == "VALIDATION_ERROR"
    assert sdk.bytes_upload_request is None


def test_upload_operation_and_all_document_listing_forms_are_exposed():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        operation = client.get("/upload-operations/upload-1?scope=scope-1")
        page = client.get("/documents/page?cursor=opaque&limit=10&status=available")
        iterator = client.get("/documents/iterator?page_size=25&status=available")

    assert operation.status_code == 200
    assert operation.json()["state"] == "succeeded"
    assert sdk.upload_operation_args == ("scope-1", "upload-1")
    assert page.status_code == 200
    assert page.json()["items"][0]["document_id"] == "page-doc"
    assert sdk.page_args == ("opaque", 10, dms.DocumentStatus.AVAILABLE)
    assert iterator.status_code == 200
    assert [item["document_id"] for item in iterator.json()["items"]] == [
        "iter-doc-1",
        "iter-doc-2",
    ]
    assert sdk.iterator_args == (dms.DocumentStatus.AVAILABLE, 25)


def test_all_content_read_and_copy_forms_are_exposed():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        eager = client.get("/documents/doc-1/content/eager")
        async_stream = client.get("/documents/doc-1/content/async?chunk_size=2")
        chunks = client.get("/documents/doc-1/chunks?chunk_size=2")
        copied = client.get("/documents/doc-1/copy?chunk_size=2&verify_checksum=true")

    assert eager.status_code == 200
    assert eager.content == b"pdf"
    assert eager.headers["X-Document-Checksum"] == "checksum"
    assert sdk.eager_content_calls == 1
    assert async_stream.status_code == 200
    assert async_stream.content == b"pdf"
    assert sdk.async_stream.closed is True
    assert chunks.status_code == 200
    assert chunks.content == b"pdf"
    assert sdk.chunk_args == ("doc-1", 2)
    assert copied.status_code == 200
    assert copied.content == b"pdf"
    assert copied.headers["X-Checksum-Verified"] == "true"
    assert sdk.copy_args == ("doc-1", 2, True)
    assert sdk.copy_sink.closed is True


def test_copy_uses_a_bounded_in_memory_spool(monkeypatch):
    options = {}
    original = router_module.tempfile.SpooledTemporaryFile

    def recording_spool(*args, **kwargs):
        options.update(kwargs)
        return original(*args, **kwargs)

    monkeypatch.setattr(
        router_module.tempfile,
        "SpooledTemporaryFile",
        recording_spool,
    )

    with client_for(FullFakeSDK()) as client:
        response = client.get("/documents/doc-1/copy")

    assert response.status_code == 200
    assert options["max_size"] > 0


def test_internal_metadata_inspection_and_recovery_candidate_forms_are_exposed():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        internal = client.get("/management/documents/doc-1/metadata")
        inspection = client.get("/management/documents/doc-1/inspection")
        candidates = client.get(
            "/management/recovery-candidates?status=failed&offset=4&limit=5"
        )
        iterator = client.get(
            "/management/recovery-candidates/iterator?status=failed&page_size=20"
        )

    assert internal.status_code == 200
    assert internal.json()["storage_key"] == "private/doc-1"
    assert inspection.status_code == 200
    assert inspection.json()["issue"] == "object_missing"
    assert candidates.status_code == 200
    assert candidates.json()["items"][0]["storage_key"] == "private/failed-doc"
    assert sdk.recovery_candidate_args == (dms.DocumentStatus.FAILED, 4, 5)
    assert iterator.status_code == 200
    assert iterator.json()["items"][0]["document_id"] == "iter-failed-doc"
    assert sdk.recovery_iterator_args == (dms.DocumentStatus.FAILED, 20)


def test_single_batch_and_plan_reconciliation_forms_are_exposed():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        single = client.post(
            "/management/documents/doc-1/reconciliations",
            json={
                "action": "mark_failed",
                "storage_key": "private/doc-1",
                "dry_run": True,
                "actor": "operator-1",
            },
        )
        batch = client.post(
            "/management/reconciliations",
            json={
                "status": "failed",
                "action": "mark_failed",
                "offset": 2,
                "limit": 10,
                "dry_run": True,
                "actor": "operator-2",
            },
        )
        plan = client.post(
            "/management/reconciliation-plans/executions",
            json={
                "status": "failed",
                "action": "mark_failed",
                "items": [
                    {
                        "document_id": "doc-1",
                        "action": "mark_failed",
                        "storage_key": "private/doc-1",
                    }
                ],
                "actor": "operator-3",
            },
        )

    assert single.status_code == 200
    assert single.json()["applied"] is False
    assert sdk.reconcile_document_args == (
        "doc-1",
        dms.RecoveryAction.MARK_FAILED,
        "private/doc-1",
        True,
        "operator-1",
    )
    assert batch.status_code == 200
    assert batch.json()["dry_run"] is True
    assert sdk.reconcile_documents_args == (
        dms.DocumentStatus.FAILED,
        dms.RecoveryAction.MARK_FAILED,
        2,
        10,
        True,
        "operator-2",
    )
    assert plan.status_code == 200
    recorded_plan, actor = sdk.plan_args
    assert actor == "operator-3"
    assert recorded_plan.items[0].storage_key == "private/doc-1"


def test_explicit_delete_and_data_reset_operations_are_exposed():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        soft = client.delete("/documents/doc-1/soft")
        assert sdk.special_delete_args == ("soft", "doc-1")
        hard = client.delete("/documents/doc-1/hard")
        assert sdk.special_delete_args == ("hard", "doc-1")
        cleared = client.delete("/management/data")
        initialized = client.post("/management/data/initializations")

    assert soft.status_code == 200
    assert soft.json()["hard_deleted"] is False
    assert hard.status_code == 200
    assert hard.json()["hard_deleted"] is True
    assert cleared.status_code == 200
    assert cleared.json()["upload_operations_deleted"] == 1
    assert initialized.status_code == 200
    assert initialized.json()["ready_for_data_load"] is True
    assert sdk.clear_calls == 1
    assert sdk.initialize_calls == 1


def test_openapi_exposes_every_dms_operation_boundary():
    sdk = FullFakeSDK()

    with client_for(sdk) as client:
        schema = client.get("/openapi.json").json()

    expected = {
        ("/documents", "get"),
        ("/documents", "post"),
        ("/documents/bytes", "post"),
        ("/documents/file", "post"),
        ("/documents/page", "get"),
        ("/documents/iterator", "get"),
        ("/documents/{document_id}", "get"),
        ("/documents/{document_id}", "delete"),
        ("/documents/{document_id}/content", "get"),
        ("/documents/{document_id}/content/eager", "get"),
        ("/documents/{document_id}/content/async", "get"),
        ("/documents/{document_id}/chunks", "get"),
        ("/documents/{document_id}/copy", "get"),
        ("/documents/{document_id}/download", "get"),
        ("/documents/{document_id}/soft", "delete"),
        ("/documents/{document_id}/hard", "delete"),
        ("/upload-operations/{idempotency_key}", "get"),
        ("/management/documents/{document_id}/metadata", "get"),
        ("/management/documents/{document_id}/inspection", "get"),
        ("/management/recovery-candidates", "get"),
        ("/management/recovery-candidates/iterator", "get"),
        ("/management/documents/{document_id}/reconciliations", "post"),
        ("/management/reconciliations", "post"),
        ("/management/reconciliation-plans/executions", "post"),
        ("/management/data", "delete"),
        ("/management/data/partition", "delete"),
        ("/management/data/initializations", "post"),
        ("/management/data/partition/initializations", "post"),
    }
    actual = {
        (path, method)
        for path, path_item in schema["paths"].items()
        for method in path_item
        if method in {"get", "post", "put", "patch", "delete"}
    }

    assert expected <= actual
    for path, method in expected:
        responses = schema["paths"][path][method]["responses"]
        assert "400" in responses
        assert "422" not in responses


def test_openapi_describes_document_content_as_binary():
    with client_for(FullFakeSDK()) as client:
        schema = client.get("/openapi.json").json()

    paths = {
        "/documents/{document_id}/content",
        "/documents/{document_id}/content/eager",
        "/documents/{document_id}/content/async",
        "/documents/{document_id}/chunks",
        "/documents/{document_id}/copy",
        "/documents/{document_id}/download",
    }
    for path in paths:
        response = schema["paths"][path]["get"]["responses"]["200"]
        assert set(response["content"]) == {"application/octet-stream"}
        binary = response["content"]["application/octet-stream"]["schema"]
        assert binary == {"type": "string", "format": "binary"}
        assert "Content-Disposition" in response["headers"]


def test_openapi_constrains_upload_operation_states():
    with client_for(FullFakeSDK()) as client:
        schema = client.get("/openapi.json").json()

    state = schema["components"]["schemas"]["UploadOperationResponse"]["properties"][
        "state"
    ]
    assert state["enum"] == ["pending", "succeeded", "failed"]


def test_openapi_error_schema_does_not_advertise_internal_diagnostics():
    with client_for(FullFakeSDK()) as client:
        schema = client.get("/openapi.json").json()

    properties = schema["components"]["schemas"]["ErrorDetailResponse"]["properties"]
    assert "details" not in properties
