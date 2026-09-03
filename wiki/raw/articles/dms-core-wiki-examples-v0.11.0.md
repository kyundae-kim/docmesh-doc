---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/Examples-v0.11.0.md
ingested: 2026-09-03
sha256: 3dbf6aa0f62c737c598b54871dec7a2c5a8b430f2a5c25156f414f8d70365c74
---
# DMS SDK 사용 예제 (v0.11.0)

- 기준 API: [API-Reference-v0.11.0](API-Reference-v0.11.0.md)
- 기준 소스: `1f3325ed914fc970e4e040e161e6de117ede5aeb`
- import 경계: 공개 이름은 `from dms import ...`에서 가져온다.
- `engine`, `minio_client`, storage component, callback 및 `application`은 host가 생성해 전달하는 placeholder다.
- 모든 일반 문서·복구 작업에는 같은 작업 범위의 `partition=`을 전달한다. 전역 reset 작업만 partition 없이 호출한다.
- 각 anchor는 API Reference의 export/facade trace matrix에서 역참조된다.

> **실행 전 확인**
>
> 아래 코드는 API 계약을 보여주는 구조 예제다. 실제 애플리케이션에서는 host가 database engine, MinIO client, bucket, storage component, 접근 정책, callback 및 종료 순서를 관리한다. Wiki에는 credential과 실제 endpoint를 넣지 않는다. SDK는 주입된 client와 component의 lifecycle을 종료하지 않는다.

## 예제 목차

| anchor | 범위 | API trace |
| --- | --- | --- |
| [E-01](#example-e01) | sync factory, partition, bytes upload | `TR-ASM`, `TR-UPL`, `TR-DATA` |
| [E-02](#example-e02) | native async factory와 직접 async 조립 | `TR-ASM`, `TR-ASYNC`, `TR-POLICY` |
| [E-03](#example-e03) | host access policy와 denied operation | `TR-POLICY`, `TR-ERR` |
| [E-04](#example-e04) | bytes/file/known-size stream, idempotency | `TR-UPL`, `TR-ERR` |
| [E-05](#example-e05) | public/internal metadata와 content copy | `TR-DATA`, `TR-READ` |
| [E-06](#example-e06) | cursor page와 iterator | `TR-READ`, `TR-ERR` |
| [E-07](#example-e07) | soft/hard delete와 전체·partition reset | `TR-DEL`, `TR-RESET`, `TR-ERR` |
| [E-08](#example-e08) | inspection, dry-run recovery, plan | `TR-REC`, `TR-OBS` |
| [E-09](#example-e09) | capability protocol, observer, error hierarchy | `TR-CONTRACT`, `TR-OBS`, `TR-ERR` |
| [E-10](#example-e10) | public serialization과 sync/async stream cleanup | `TR-READ`, `TR-ASYNC`, `TR-DATA` |
| [E-11](#example-e11) | v0.11 partition-required boundary 확인 | `TR-DATA`, `TR-ASYNC` |

<a id="example-e01"></a>
## E-01. sync factory, partition, bytes upload

`DocumentManagementSDKFactory`는 host의 SQLAlchemy `Engine`과 동기 MinIO client를 adapter에 연결한다. 문서 작업에는 `DocumentPartition`을 명시한다.

```python
from dms import (
    DocumentManagementSDKFactory,
    DocumentPartition,
    UploadDocumentRequest,
)


def upload_document(application) -> object:
    factory = DocumentManagementSDKFactory(
        engine=application.engine,
        minio_client=application.minio_client,
        bucket_name=application.bucket_name,
    )
    sdk = factory.create()
    partition = DocumentPartition.personal(application.user_id)

    return sdk.upload_document(
        UploadDocumentRequest(
            content=b"hello DMS",
            filename="hello.txt",
            content_type="text/plain",
            document_id="hello-001",
            metadata={"source": "example"},
            created_by=application.user_id,
        ),
        partition=partition,
    )
```

bucket이 없으면 조립 중 생성할 수 있지만 bucket과 client 종료는 host 책임이다. `document_id`를 생략하면 metadata store가 식별자를 할당한다.

### 추적성

- API: `DocumentManagementSDKFactory`, `DefaultDocumentManagementSDK`, `DocumentPartition`, `UploadDocumentRequest`, `UploadDocumentResult`
- source: `dms/sdk/factory.py:85-134`, `dms/sdk/implementation.py:70`, `dms/domain/models.py:29`, `dms/sdk/types.py:21`
- test: `test_dms/test_sdk_factory.py::test_factory_assembles_sdk_from_sqlalchemy_engine_and_minio_client`, `test_dms/test_sdk_behavior.py::test_upload_document_persists_metadata_and_content`

<a id="example-e02"></a>
## E-02. native async factory와 직접 async 조립

native async factory는 `AsyncEngine`과 동기 MinIO client를 받는다. `create()`는 lazy SDK를 반환하고 `await` 또는 `ready()`에서 초기화한다. 이미 준비된 async storage component를 주입하려면 `from_async_components()`를 사용한다.

```python
from dms import (
    AsyncDocumentAccessPolicy,
    AsyncDocumentManagementSDK,
    AsyncDocumentManagementSDKFactory,
    AccessContext,
    DocumentPartition,
    PublicDocumentMetadata,
    UploadDocumentRequest,
)


class AllowAsyncPolicy:
    async def allows(
        self,
        *,
        operation: str,
        context: AccessContext | None,
        metadata: PublicDocumentMetadata | None,
    ) -> bool:
        return True


async_policy: AsyncDocumentAccessPolicy = AllowAsyncPolicy()


async def build_async_sdks(application):
    factory = AsyncDocumentManagementSDKFactory(
        engine=application.async_engine,
        minio_client=application.minio_client,
        bucket_name=application.bucket_name,
        access_policy=async_policy,
    )

    lazy_sdk = factory.create()
    async_sdk = await lazy_sdk
    ready_sdk = await factory.create_async()

    partition = DocumentPartition.group(application.group_id)
    result = await async_sdk.upload_document(
        UploadDocumentRequest(
            content=b"async body",
            filename="async.txt",
            content_type="text/plain",
        ),
        partition=partition,
    )

    native_from_components = AsyncDocumentManagementSDK.from_async_components(
        metadata_store=application.async_metadata_store,
        object_store=application.async_object_store,
        access_policy=async_policy,
    )
    await native_from_components.ready()

    compatibility_sdk = AsyncDocumentManagementSDK(application.sync_sdk)
    await compatibility_sdk.ready()
    return result, ready_sdk, native_from_components, compatibility_sdk
```

`AsyncDocumentManagementSDK`의 native 경로는 async storage component를 사용하고, sync SDK를 감싼 compatibility 경로는 blocking 작업을 event loop 밖에서 실행한다. 두 경로 모두 주입된 자원을 닫지 않는다.

### 추적성

- API: `AsyncDocumentManagementSDKFactory`, `AsyncDocumentManagementSDK`, `AsyncDocumentAccessPolicy`, `AccessContext`, `DocumentPartition`, `UploadDocumentRequest`
- source: `dms/sdk/factory.py:138-197`, `dms/sdk/async_sdk.py:98-159`
- test: `test_dms/test_sdk_native_async_partitions.py::test_async_factory_wires_sync_minio_adapter`, `test_dms/test_sdk_native_async_partitions.py::test_native_async_core_awaits_object_storage_and_preserves_partition`, `test_dms/test_sdk_contract_completion.py::test_async_facade_runs_metadata_list_delete_without_global_lifecycle`

<a id="example-e03"></a>
## E-03. host access policy와 denied operation

DMS는 인증이나 group membership을 수행하지 않는다. host가 확인한 값을 `AccessContext`로 전달하고, `DocumentAccessPolicy`가 작업별 허용 여부를 결정한다. 정책에는 public metadata만 전달된다.

```python
from dms import (
    AccessContext,
    AccessDeniedError,
    AccessPolicy,
    DefaultDocumentManagementSDK,
    DocumentAccessPolicy,
    DocumentPartition,
    PublicDocumentMetadata,
    UploadDocumentRequest,
)


class RolePolicy:
    def __init__(self, required_role: str) -> None:
        self.required_role = required_role

    def allows(
        self,
        *,
        operation: str,
        context: AccessContext | None,
        metadata: PublicDocumentMetadata | None,
    ) -> bool:
        if context is None or self.required_role not in context.roles:
            return False
        return operation == "upload" or metadata is not None


policy: AccessPolicy = RolePolicy("writer")
assert isinstance(policy, DocumentAccessPolicy)
sdk = DefaultDocumentManagementSDK(
    metadata_store=application.metadata_store,
    object_store=application.object_store,
    access_policy=policy,
)
partition = DocumentPartition.personal("host-user-001")
context = AccessContext(user_id="host-user-001", roles=frozenset({"reader"}))

try:
    sdk.upload_document(
        UploadDocumentRequest(
            content=b"protected",
            filename="protected.txt",
            content_type="text/plain",
        ),
        partition=partition,
        access_context=context,
    )
except AccessDeniedError as exc:
    assert exc.code == "access_denied"
    assert exc.category == "authorization"
```

실제 정책 구현에서는 작업별 조건을 명시적으로 작성한다. 정책이 `False`를 반환하거나 오류를 발생시키면 `AccessDeniedError`가 되며, host 정책의 원문 오류는 외부 메시지에 노출되지 않는다.

### 추적성

- API: `AccessContext`, `AccessPolicy`, `DocumentAccessPolicy`, `AccessDeniedError`, `DefaultDocumentManagementSDK`, `DocumentPartition`, `PublicDocumentMetadata`
- source: `dms/sdk/contracts.py:82-153`, `dms/sdk/errors.py:39`, `dms/sdk/implementation.py:70`
- test: `test_dms/test_sdk_access_control.py::test_denied_upload_is_rejected_before_object_storage`, `test_dms/test_sdk_access_control.py::test_policy_protects_public_internal_content_stream_copy_inspection_and_delete`, `test_dms/test_sdk_access_control.py::test_policy_failures_are_mapped_to_access_denied`

<a id="example-e04"></a>
## E-04. bytes/file/known-size stream와 idempotency

현재 공개 upload 입력은 bytes, 파일 경로, 정확한 크기가 선언된 동기 binary stream이다. file은 SDK가 열고 닫으며 caller가 전달한 stream은 SDK가 닫지 않는다.

```python
from io import BytesIO
from pathlib import Path

from dms import (
    DocumentPartition,
    IdempotencyConflictError,
    IdempotencyInProgressError,
    PayloadTooLargeError,
    UploadDocumentRequest,
    UploadDocumentStreamRequest,
    UploadOperationNotFoundError,
    UploadOperationResult,
    ValidationError,
)

partition = DocumentPartition.personal("upload-user")

bytes_result = sdk.upload_document(
    UploadDocumentRequest(
        content=b"bytes payload",
        filename="bytes.txt",
        content_type="text/plain",
    ),
    partition=partition,
)

file_result = sdk.upload_file(
    Path("payload.bin"),
    document_id="file-001",
    content_type="application/octet-stream",
    partition=partition,
)

source = BytesIO(b"stream payload")
stream_result = sdk.upload_document_stream(
    UploadDocumentStreamRequest(
        stream=source,
        size=len(b"stream payload"),
        filename="stream.txt",
        content_type="text/plain",
        document_id="stream-001",
    ),
    partition=partition,
)
assert source.closed is False

idempotent = UploadDocumentRequest(
    content=b"same request",
    filename="same.txt",
    content_type="text/plain",
    idempotency_scope="tenant-a",
    idempotency_key="import-0001",
)
try:
    replay = sdk.upload_document(idempotent, partition=partition)
except IdempotencyInProgressError:
    replay = None
except IdempotencyConflictError:
    raise RuntimeError("same key was used with another request fingerprint")

operation: UploadOperationResult = sdk.get_upload_operation(
    scope="tenant-a",
    idempotency_key="import-0001",
    partition=partition,
)
assert operation.scope == "tenant-a"

try:
    sdk.get_upload_operation(
        scope="tenant-a",
        idempotency_key="missing",
        partition=partition,
    )
except UploadOperationNotFoundError:
    pass

try:
    sdk.upload_file("too-large.bin", partition=partition)
except PayloadTooLargeError as exc:
    print(exc.code, exc.category, exc.retryable)
except ValidationError:
    # File and request validation failures are also public contract errors.
    pass
```

`UploadDocumentStreamRequest.size`는 양수여야 하고 실제 읽은 bytes 수와 일치해야 한다. 불일치하면 object rollback 후 `ValidationError`가 발생한다. `max_file_size`는 factory 또는 직접 조립 시 설정하는 공통 정책이다. unknown-size 및 async input stream upload는 이 버전의 공개 API가 아니다.

### 추적성

- API: `UploadDocumentRequest`, `UploadDocumentStreamRequest`, `UploadDocumentResult`, `UploadOperationResult`, `PayloadTooLargeError`, `IdempotencyConflictError`, `IdempotencyInProgressError`, `UploadOperationNotFoundError`, `ValidationError`
- source: `dms/sdk/types.py:21-67,140-156`, `dms/sdk/errors.py:32,46,118-137`
- test: `test_dms/test_sdk_stream_upload_contract.py::test_stream_upload_enforces_declared_size_and_rolls_back`, `test_dms/test_sdk_metadata.py::test_dictionary_metadata_is_preserved_with_idempotency`, `test_dms/test_sdk_partitions.py::test_storage_and_idempotency_namespaces_include_partition_kind`

<a id="example-e05"></a>
## E-05. public/internal metadata와 content copy

일반 flow에서는 `PublicDocumentMetadata`를 사용한다. 저장 위치가 필요한 관리·복구 flow에서만 `DocumentMetadata`를 요청한다. public projection에는 `storage_key`가 없다.

```python
from io import BytesIO

from dms import (
    DocumentContent,
    DocumentContentStream,
    DocumentCopyResult,
    DocumentMetadata,
    DocumentPartition,
    PublicDocumentMetadata,
    UploadDocumentRequest,
    UploadDocumentResult,
    public_metadata,
)

partition = DocumentPartition.personal("metadata-user")

uploaded: UploadDocumentResult = sdk.upload_document(
    UploadDocumentRequest(
        content=b"content body",
        filename="content.txt",
        content_type="text/plain",
    ),
    partition=partition,
)
public: PublicDocumentMetadata = sdk.get_document_metadata(
    uploaded.document_id,
    partition=partition,
)
internal: DocumentMetadata = sdk.get_internal_document_metadata(
    uploaded.document_id,
    partition=partition,
)
assert not hasattr(public, "storage_key")
assert isinstance(internal.storage_key, str)
assert isinstance(public_metadata(internal), PublicDocumentMetadata)

content: DocumentContent = sdk.get_document_content(
    uploaded.document_id,
    partition=partition,
)
assert content.content == b"content body"

stream: DocumentContentStream = sdk.get_document_content_stream(
    uploaded.document_id,
    chunk_size=1024,
    partition=partition,
)
with stream:
    body = b"".join(stream.iter_chunks())
assert body == content.content
assert stream.closed is True

sink = BytesIO()
copied: DocumentCopyResult = sdk.copy_document_to(
    uploaded.document_id,
    sink,
    chunk_size=1024,
    verify_checksum=True,
    partition=partition,
)
assert sink.closed is False
assert copied.checksum_verified is True
```

`copy_document_to()`는 source stream을 닫지만 caller가 제공한 sink는 닫지 않는다. 일반 metadata 조회·목록에서는 삭제 중이거나 삭제된 문서를 숨기고, internal metadata는 명시적인 관리 경계에서만 사용한다.

### 추적성

- API: `UploadDocumentResult`, `UploadDocumentRequest`, `PublicDocumentMetadata`, `DocumentMetadata`, `public_metadata`, `DocumentContent`, `DocumentContentStream`, `DocumentCopyResult`
- source: `dms/sdk/types.py:21-136,160-222`, `dms/sdk/contracts.py:268-280`
- test: `test_dms/test_sdk_public_contract.py::test_default_metadata_and_upload_results_hide_storage_key`, `test_dms/test_sdk_public_contract.py::test_privileged_metadata_access_is_explicit`, `test_dms/test_sdk_consumer_integration_contracts.py::test_copy_document_to_closes_source_and_keeps_sink_open`

<a id="example-e06"></a>
## E-06. cursor page와 iterator

기본 목록 API는 `DocumentPage`를 반환한다. 다음 페이지에는 같은 partition, status filter 및 limit을 사용하고, `next_cursor`는 opaque 값으로 전달한다.

```python
from dms import (
    AccessContext,
    DocumentPage,
    DocumentPartition,
    DocumentStatus,
    DocumentNotFoundError,
    ValidationError,
)

partition = DocumentPartition.group("group-456")
context = AccessContext(user_id="user-456", groups=frozenset({"group-456"}))
page: DocumentPage = sdk.list_documents(
    partition=partition,
    limit=50,
    status=DocumentStatus.AVAILABLE,
    access_context=context,
)
items = list(page.items)

while page.next_cursor is not None:
    page = sdk.list_documents(
        partition=partition,
        cursor=page.next_cursor,
        limit=50,
        status=DocumentStatus.AVAILABLE,
        access_context=context,
    )
    items.extend(page.items)

for metadata in sdk.iter_documents(
    partition=partition,
    status=DocumentStatus.AVAILABLE,
    page_size=50,
    access_context=context,
):
    consume(metadata.document_id)

try:
    sdk.list_documents(
        partition=partition,
        cursor="opaque-cursor-from-another-query",
        status=DocumentStatus.FAILED,
        access_context=context,
    )
except ValidationError:
    request_a_fresh_cursor()

try:
    sdk.get_document_metadata("missing", partition=partition)
except DocumentNotFoundError:
    request_a_different_document_id()
```

cursor에는 정렬 위치뿐 아니라 partition, status 및 page size가 결합된다. offset 기반 일반 목록은 제공하지 않는다. 접근 정책이 있는 경우 접근 가능한 결과를 page 제한 전에 적용한다.

### 추적성

- API: `DocumentPage`, `DocumentPartition`, `DocumentStatus`, `AccessContext`, `ValidationError`, `DocumentLister`
- source: `dms/sdk/types.py:399-420`, `dms/domain/models.py:9-14`, `dms/sdk/implementation.py:301-396`
- test: `test_dms/test_sdk_pagination.py::test_cursor_page_is_stable_opaque_and_status_bound`, `test_dms/test_sdk_consumer_integration_contracts.py::test_document_and_recovery_iterators_preserve_page_conditions`

<a id="example-e07"></a>
## E-07. soft/hard delete와 전체·partition reset

삭제와 reset은 서로 다른 범위다. logical delete는 본문과 metadata 상태를 관리하고 hard delete는 metadata까지 제거한다. reset 결과에는 저장소별 삭제 count가 포함된다.

```python
from dms import (
    DataResetError,
    DataResetResult,
    DocumentDeletedError,
    DeleteDocumentResult,
    DocumentPartition,
    DocumentStatus,
)

partition = DocumentPartition.personal("reset-user")

soft: DeleteDocumentResult = sdk.soft_delete_document(
    "document-001",
    partition=partition,
)
assert soft.status is DocumentStatus.DELETED
assert soft.hard_deleted is False

try:
    sdk.get_document_content("document-001", partition=partition)
except DocumentDeletedError:
    pass

hard: DeleteDocumentResult = sdk.hard_delete_document(
    "document-002",
    partition=partition,
)
assert hard.hard_deleted is True

partition_result: DataResetResult = sdk.clear_partition_data(
    partition=partition,
)
assert partition_result.ready_for_data_load is True

try:
    all_data = sdk.clear_all_data()
except DataResetError as exc:
    # 다른 store cleanup은 계속되며 부분 결과를 확인한다.
    assert exc.result.ready_for_data_load is False
    print(exc.failed_stores, exc.result.to_dict())
else:
    assert all_data.ready_for_data_load is True

fresh: DataResetResult = sdk.initialize_for_data_load()
assert fresh.ready_for_data_load is True
```

`clear_partition_data()`와 `initialize_partition_for_data_load()`은 선택한 partition만 지운다. `clear_all_data()`와 `initialize_for_data_load()`에는 partition 인자를 넣지 않는다. 빈 범위에서 initialize를 반복 호출해도 성공한다.

### 추적성

- API: `DeleteDocumentResult`, `DataResetResult`, `DataResetError`, `DocumentStatus`, `DocumentPartition`, `DataResetter`
- source: `dms/sdk/types.py:343-390`, `dms/sdk/errors.py:97-115`, `dms/sdk/implementation.py:834-943`
- test: `test_dms/test_sdk_data_reset.py::test_clear_all_data_removes_documents_objects_and_upload_operations`, `test_dms/test_sdk_data_reset.py::test_clear_all_data_reports_partial_cleanup_and_continues_other_stores`, `test_dms/test_sdk_partitions.py::test_clear_partition_data_preserves_other_partitions`, `test_dms/test_sdk_deletion.py::test_explicit_delete_methods_preserve_legacy_dispatch`

<a id="example-e08"></a>
## E-08. inspection, dry-run recovery, plan

recovery는 일반 public metadata flow와 분리된 관리 기능이다. 먼저 `inspect_document()` 또는 bounded candidate listing으로 상태를 확인하고, batch dry-run 결과에서만 immutable plan을 export한다.

```python
from dms import (
    BatchReconciliationResult,
    DocumentInspection,
    DocumentMetadata,
    DocumentPartition,
    DocumentStatus,
    RecoveryAction,
    RecoveryAuditEvent,
    RecoveryIssue,
    ReconciliationPlan,
    ReconciliationPlanItem,
    ReconciliationResult,
)

partition = DocumentPartition.personal("recovery-user")

def audit(event: RecoveryAuditEvent) -> None:
    print(event.document_id, event.action.value, event.succeeded)

inspection: DocumentInspection = sdk.inspect_document(
    "document-001",
    partition=partition,
)
if inspection.issue is RecoveryIssue.OBJECT_MISSING:
    print("object is missing")

candidates: list[DocumentMetadata] = sdk.list_recovery_candidates(
    partition=partition,
    status=DocumentStatus.FAILED,
    offset=0,
    limit=100,
)

preview: BatchReconciliationResult = sdk.reconcile_documents(
    partition=partition,
    status=DocumentStatus.FAILED,
    action=RecoveryAction.MARK_FAILED,
    dry_run=True,
    limit=100,
    actor="operator-42",
)
plan: ReconciliationPlan = preview.to_plan()
if plan.items:
    first_item: ReconciliationPlanItem = plan.items[0]
    assert first_item.action is RecoveryAction.MARK_FAILED

executed: BatchReconciliationResult = sdk.execute_reconciliation_plan(
    plan,
    partition=partition,
    actor="operator-42",
)

single: ReconciliationResult = sdk.reconcile_document(
    "document-001",
    RecoveryAction.COMPLETE_DELETION_SOFT,
    partition=partition,
    dry_run=False,
    actor="operator-42",
)
assert executed.items is not None and single.document_id == "document-001"
```

`RecoveryIssue`는 metadata/object 불일치 종류를 표현하고 `RecoveryAction`은 soft/hard deletion completion, failed 표시 및 orphan purge를 표현한다. recovery candidate의 status는 `FAILED` 또는 `DELETING`으로 제한되고 batch는 bounded다. `execute_reconciliation_plan()`은 실행 시 item을 재검사하며 다른 partition으로 plan을 실행할 수 없다. `recovery_audit_hook`은 best-effort callback이다.

### 추적성

- API: `DocumentInspection`, `RecoveryIssue`, `RecoveryAction`, `DocumentMetadata`, `ReconciliationResult`, `BatchReconciliationResult`, `ReconciliationPlan`, `ReconciliationPlanItem`, `RecoveryAuditEvent`
- source: `dms/sdk/types.py:423-615`, `dms/sdk/implementation.py:398-658`
- test: `test_dms/test_sdk_reconciliation_core.py::test_inspect_missing_metadata_is_a_typed_result_not_not_found`, `test_dms/test_sdk_reconciliation_core.py::test_batch_is_bounded_status_restricted_dry_run_and_preserves_item_errors`, `test_dms/test_sdk_reconciliation.py::test_dry_run_exports_plan_and_execution_revalidates_stale_items_with_best_effort_audit`, `test_dms/test_sdk_reconciliation.py::test_recovery_audit_records_actor_and_time_and_plan_requires_dry_run`

<a id="example-e09"></a>
## E-09. capability protocol, observer, error hierarchy

기능별 capability protocol은 host가 필요한 계약만 주입하거나 type-check할 때 사용한다. `DocumentManagementClient`는 writer, reader, lister, deleter 및 resetter 계약을 합성한다.

```python
from dms import (
    AccessDeniedError,
    ConfigurationError,
    ConsistencyError,
    DataResetError,
    DataResetter,
    DocumentDeleter,
    DocumentLister,
    DocumentManagementClient,
    DocumentReader,
    DocumentWriter,
    DmsError,
    DuplicateDocumentError,
    MetadataStoreError,
    OperationEvent,
    OperationObserver,
    PayloadTooLargeError,
    StorageError,
    ValidationError,
)


def observe(event: OperationEvent) -> object:
    payload = event.to_dict()
    assert "storage_key" not in str(payload)
    return payload


observer: OperationObserver = observe
assert isinstance(sdk, DocumentWriter)
assert isinstance(sdk, DocumentReader)
assert isinstance(sdk, DocumentLister)
assert isinstance(sdk, DocumentDeleter)
assert isinstance(sdk, DataResetter)
assert isinstance(sdk, DocumentManagementClient)

public_errors: tuple[type[DmsError], ...] = (
    AccessDeniedError,
    ConfigurationError,
    ConsistencyError,
    DataResetError,
    DuplicateDocumentError,
    MetadataStoreError,
    PayloadTooLargeError,
    StorageError,
    ValidationError,
)
for error_type in public_errors:
    assert issubclass(error_type, DmsError)

sdk_with_observer = application.build_sdk(operation_observer=observer)
```

`OperationEvent`에는 작업명·성공 여부·시간·조건·error code가 포함되며 observer 오류는 원래 작업 결과를 바꾸지 않는다. 각 public error에는 `code`, `category`, `retryable`이 있다. 오류 분류와 retry 판단은 이 metadata를 기준으로 하고 infrastructure exception 원문을 외부 계약으로 사용하지 않는다.

### 추적성

- API: `DocumentWriter`, `DocumentReader`, `DocumentLister`, `DocumentDeleter`, `DataResetter`, `DocumentManagementClient`, `OperationEvent`, `OperationObserver`, `DmsError` 및 public error classes
- source: `dms/sdk/contracts.py:239-426`, `dms/sdk/errors.py:6-137`
- test: `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols`, `test_dms/test_sdk_consumer_integration_contracts.py::test_operation_observer_receives_safe_success_and_failure_events`, `test_dms/test_sdk_requirement_feedback.py::test_all_public_sdk_errors_expose_structured_contract`

<a id="example-e10"></a>
## E-10. public serialization과 sync/async stream cleanup

public DTO는 `to_dict()`와 필요한 JSON Schema를 제공한다. async facade에서 stream을 사용한 뒤에는 `async with` 또는 `aclose()`를 사용한다.

```python
import json

from dms import (
    AsyncDocumentContentStream,
    AsyncDocumentManagementSDK,
    DeleteDocumentResult,
    DocumentPage,
    PublicDocumentMetadata,
    UploadDocumentResult,
    public_metadata,
)

upload: UploadDocumentResult = sdk.upload_document_result
metadata: PublicDocumentMetadata = public_metadata(upload)
json.dumps(upload.to_dict())
json.dumps(metadata.to_public_dict())
assert "storage_key" not in json.dumps(metadata.json_schema())
assert metadata.model_json_schema() == metadata.json_schema()

page: DocumentPage = sdk.list_documents_page(partition=partition)
json.dumps(page.to_dict())

removed: DeleteDocumentResult = sdk.soft_delete_document(
    upload.document_id,
    partition=partition,
)
json.dumps(removed.to_dict())


async def read_async(async_sdk: AsyncDocumentManagementSDK) -> bytes:
    stream: AsyncDocumentContentStream = await async_sdk.get_document_content_stream(
        upload.document_id,
        chunk_size=1024,
        partition=partition,
    )
    async with stream:
        chunks = [chunk async for chunk in stream.aiter_chunks_closing()]
    assert stream.closed is True
    return b"".join(chunks)
```

`PublicDocumentMetadata.to_dict()`는 호환 필드명 `extra_metadata`를 유지하고 `to_public_dict()`는 외부 표현의 `metadata` 필드로 변환한다. public schema에는 `storage_key`가 없다. sync stream은 `with`/`close()`, async stream은 `async with`/`aclose()`로 source lifecycle을 정리한다.

### 추적성

- API: `UploadDocumentResult`, `PublicDocumentMetadata`, `public_metadata`, `DocumentPage`, `DeleteDocumentResult`, `AsyncDocumentContentStream`, `AsyncDocumentManagementSDK`
- source: `dms/sdk/types.py:53-136,225-340,343-420`, `dms/sdk/async_sdk.py:469-527`
- test: `test_dms/test_sdk_contract_completion.py::test_canonical_public_dtos_dump_with_external_metadata_alias`, `test_dms/test_sdk_contract_completion.py::test_canonical_public_dtos_export_matching_json_schema`, `test_dms/test_sdk_feedback_async_cursor.py::test_async_download_stream_closes_on_context_exit_and_exhaustion`

<a id="example-e11"></a>
## E-11. v0.11 partition-required boundary 확인

v0.11.0의 일반 document method는 `partition`을 생략할 수 없다. partition kind와 identifier는 cursor, storage namespace 및 idempotency namespace에 함께 반영된다.

```python
from dms import DocumentPartition, DocumentStatus, PartitionKind, ValidationError

personal = DocumentPartition.personal("same-id")
group = DocumentPartition.group("same-id")
assert personal.kind is PartitionKind.PERSONAL
assert group.kind is PartitionKind.GROUP
assert personal.to_dict() != group.to_dict()

page = sdk.list_documents(
    partition=personal,
    status=DocumentStatus.AVAILABLE,
)

try:
    sdk.get_document_metadata("document-001")
except TypeError:
    # required keyword-only partition을 생략한 호출이다.
    pass

try:
    sdk.list_documents(partition=group, cursor=page.next_cursor)
except ValidationError:
    # 다른 partition에 cursor를 재사용할 수 없다.
    pass
```

전역 범위가 필요한 작업은 `clear_all_data()`와 `initialize_for_data_load()`처럼 이름이 명시된 관리 API를 사용한다. `partition=None`을 일반 작업이나 partition reset에 전달해 전역 범위로 바꾸지 않는다.

### 추적성

- API: `DocumentPartition`, `PartitionKind`, `DocumentStatus`, `ValidationError`, `list_documents`, `get_document_metadata`
- source: `dms/domain/models.py:9-53`, `dms/sdk/implementation.py:280-343`
- test: `test_dms/test_sdk_partitions.py::test_partition_is_required_and_bound_to_cursor`, `test_dms/test_sdk_partitions.py::test_all_normal_public_operations_require_keyword_only_partition`, `test_dms/test_sdk_partitions.py::test_storage_and_idempotency_namespaces_include_partition_kind`
