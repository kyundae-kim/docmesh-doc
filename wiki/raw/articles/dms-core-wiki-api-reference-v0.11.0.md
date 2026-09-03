---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/API-Reference-v0.11.0.md
ingested: 2026-09-03
sha256: 2a7a44f49fbb9d79ed0e0bb524a6d51de0ec36f6d57fad78f9612588fbb0cf99
---
# DMS SDK 공개 API 레퍼런스 (v0.11.0)

- 기준 버전: `0.11.0`
- 기준 소스: `dms-core` commit `1f3325ed914fc970e4e040e161e6de117ede5aeb` (`pyproject.toml` 버전 `0.11.0`)
- 대상: 다른 Python 애플리케이션에서 `import`하여 사용하는 SDK
- 권장 import 경계: `dms` package root
- 사용 예제: [Examples-v0.11.0](Examples-v0.11.0.md)
- 추적 규칙: `source path:line`, `test path::test_function`, `E-xx` 예제 anchor

이 문서는 기준 checkout의 `dms.__all__` 56개 이름과 공개 facade의 모든 public member를 기록한다. `dms.sdk.__all__`은 55개이고 package root는 여기에 `DocumentStatus`를 추가한다. 각 export와 작업은 실제 source, 테스트 근거, 실행 예제 anchor 및 기능별 trace ID로 연결한다. `v0.10.0` 이하 Wiki 페이지는 당시 release 기록으로 보존하며 이 페이지가 현재 checkout의 계약이다.

> **현재 버전의 핵심 경계**
>
> DMS는 독립 실행형 API 서버가 아니라 host 애플리케이션에 주입되어 사용하는 Python SDK다. SQLAlchemy engine, MinIO client 또는 storage component의 생성·readiness·종료는 host가 담당한다. 일반 문서 작업에는 `partition=`을 반드시 keyword로 전달해야 하며, 전역 데이터 초기화 작업만 partition 없이 호출한다.

## 1. 공개 import 경계

소비 프로젝트는 기본적으로 다음 경계에서 import한다.

```python
from dms import DocumentManagementSDKFactory, DocumentPartition, UploadDocumentRequest
```

`dms.sdk`도 같은 SDK export를 재-export하지만 안정적인 소비자 계약은 `from dms import ...`다. 내부 adapter, 저장소 port, persistence model 및 환경변수 조립 helper는 package root 공개 API가 아니다.

### 1.1 package root public names

아래 56개 이름은 모두 `from dms import ...`로 접근할 수 있다. `source`는 기준 commit의 실제 정의 또는 alias 위치다. 테스트 근거가 멤버 존재·구조 계약만 검증하는 경우에는 그 범위를 표에 표시한다. `source-only`는 해당 세부 동작을 직접 실행하는 focused test가 현재 checkout에 없다는 뜻이다.

| 공개 이름 | 종류 | source | 테스트 근거 | example | trace |
| --- | --- | --- | --- | --- | --- |
| `AccessContext` | host caller context | `dms/sdk/contracts.py:82` | `test_dms/test_sdk_access_control.py::test_access_contract_exports_host_context_policy_and_denied_error` | [E-03](Examples-v0.11.0.md#example-e03) | `TR-POLICY` |
| `AccessDeniedError` | authorization exception | `dms/sdk/errors.py:39` | `test_dms/test_sdk_access_control.py::test_policy_failures_are_mapped_to_access_denied` | [E-03](Examples-v0.11.0.md#example-e03), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `AccessPolicy` | sync/async policy type alias | `dms/sdk/contracts.py:153` | `test_dms/test_sdk_factory.py::test_sdk_accepts_observer_and_access_policy_surface` | [E-03](Examples-v0.11.0.md#example-e03) | `TR-POLICY` |
| `AsyncDocumentAccessPolicy` | native async policy protocol | `dms/sdk/contracts.py:141` | `test_dms/test_sdk_access_control.py::test_native_async_policy_supports_async_host_callback` | [E-02](Examples-v0.11.0.md#example-e02), [E-03](Examples-v0.11.0.md#example-e03) | `TR-POLICY` |
| `AsyncDocumentContentStream` | async content stream | `dms/sdk/types.py:225` | `test_dms/test_sdk_feedback_async_cursor.py::test_async_download_stream_closes_on_context_exit_and_exhaustion` | [E-10](Examples-v0.11.0.md#example-e10) | `TR-ASYNC` |
| `AsyncDocumentManagementSDK` | awaitable async facade | `dms/sdk/async_sdk.py:98` | `test_dms/test_sdk_contract_completion.py::test_async_facade_exposes_all_public_async_sdk_operations`, `test_dms/test_sdk_contract_completion.py::test_async_facade_runs_metadata_list_delete_without_global_lifecycle` | [E-02](Examples-v0.11.0.md#example-e02), [E-10](Examples-v0.11.0.md#example-e10) | `TR-ASYNC` |
| `AsyncDocumentManagementSDKFactory` | native async factory | `dms/sdk/factory.py:138` | `test_dms/test_sdk_native_async_partitions.py::test_async_factory_wires_sync_minio_adapter` | [E-02](Examples-v0.11.0.md#example-e02) | `TR-ASM` |
| `BatchReconciliationResult` | batch recovery result | `dms/sdk/types.py:483` | `test_dms/test_sdk_reconciliation.py::test_batch_summary_properties_are_stable` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `ConfigurationError` | configuration exception | `dms/sdk/errors.py:25` | `test_dms/test_sdk_factory.py::test_factory_rejects_blank_bucket_before_adapter_assembly` | [E-01](Examples-v0.11.0.md#example-e01), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `ConsistencyError` | consistency exception | `dms/sdk/errors.py:90` | `test_dms/test_sdk_behavior.py::test_upload_document_cleans_up_object_when_metadata_save_fails` | [E-04](Examples-v0.11.0.md#example-e04), [E-08](Examples-v0.11.0.md#example-e08) | `TR-ERR` |
| `DataResetError` | partial reset exception | `dms/sdk/errors.py:97` | `test_dms/test_sdk_data_reset.py::test_clear_all_data_reports_partial_cleanup_and_continues_other_stores` | [E-07](Examples-v0.11.0.md#example-e07), [E-09](Examples-v0.11.0.md#example-e09) | `TR-RESET` |
| `DataResetResult` | reset result | `dms/sdk/types.py:363` | `test_dms/test_sdk_data_reset.py::test_data_reset_result_exposes_json_schema` | [E-07](Examples-v0.11.0.md#example-e07), [E-10](Examples-v0.11.0.md#example-e10) | `TR-RESET` |
| `DataResetter` | reset capability protocol | `dms/sdk/contracts.py:389` | `test_dms/test_sdk_data_reset.py::test_default_sdk_satisfies_data_resetter_contract` | [E-07](Examples-v0.11.0.md#example-e07), [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DefaultDocumentManagementSDK` | sync facade | `dms/sdk/implementation.py:70` | `test_dms/test_sdk_factory.py::test_sdk_accepts_injected_storage_ports` | [E-01](Examples-v0.11.0.md#example-e01), [E-03](Examples-v0.11.0.md#example-e03) | `TR-ASM` |
| `DeleteDocumentResult` | delete result | `dms/sdk/types.py:343` | `test_dms/test_sdk_requirement_feedback.py::test_public_models_have_stable_json_serialization` | [E-07](Examples-v0.11.0.md#example-e07), [E-10](Examples-v0.11.0.md#example-e10) | `TR-DEL` |
| `DmsError` | base SDK exception | `dms/sdk/errors.py:6` | `test_dms/test_sdk_requirement_feedback.py::test_all_public_sdk_errors_expose_structured_contract` | [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `DocumentAccessPolicy` | host authorization protocol | `dms/sdk/contracts.py:123` | `test_dms/test_sdk_access_control.py::test_policy_covers_all_public_document_operation_categories` | [E-03](Examples-v0.11.0.md#example-e03) | `TR-POLICY` |
| `DocumentContent` | eager content result | `dms/sdk/types.py:160` | `test_dms/test_sdk_behavior.py::test_upload_document_persists_metadata_and_content` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) | `TR-READ` |
| `DocumentContentStream` | sync content stream | `dms/sdk/types.py:170` | `test_dms/test_sdk_lifecycle_and_conflicts.py::test_document_content_stream_context_manager_closes_idempotently` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) | `TR-READ` |
| `DocumentCopyResult` | sink copy result | `dms/sdk/contracts.py:268` | `test_dms/test_sdk_consumer_integration_contracts.py::test_copy_document_to_closes_source_and_keeps_sink_open` | [E-05](Examples-v0.11.0.md#example-e05) | `TR-READ` |
| `DocumentDeletedError` | deleted-content exception | `dms/sdk/errors.py:60` | `test_dms/test_sdk_public_contract.py::test_deleted_document_content_and_stream_raise_deleted_error` | [E-07](Examples-v0.11.0.md#example-e07), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `DocumentDeleter` | delete capability protocol | `dms/sdk/contracts.py:377` | `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols` | [E-07](Examples-v0.11.0.md#example-e07), [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DocumentInspection` | consistency inspection result | `dms/sdk/types.py:439` | `test_dms/test_sdk_reconciliation_core.py::test_inspect_missing_metadata_is_a_typed_result_not_not_found` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `DocumentLister` | list capability protocol | `dms/sdk/contracts.py:355` | `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols` | [E-06](Examples-v0.11.0.md#example-e06), [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DocumentManagementClient` | composed capability protocol | `dms/sdk/contracts.py:418` | `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols` | [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DocumentManagementSDKFactory` | sync client factory | `dms/sdk/factory.py:85` | `test_dms/test_sdk_factory.py::test_factory_assembles_sdk_from_sqlalchemy_engine_and_minio_client` | [E-01](Examples-v0.11.0.md#example-e01) | `TR-ASM` |
| `DocumentMetadata` | storage-bearing management metadata | `dms/domain/models.py:74` | `test_dms/test_sdk_public_contract.py::test_privileged_metadata_access_is_explicit` | [E-05](Examples-v0.11.0.md#example-e05), [E-08](Examples-v0.11.0.md#example-e08) | `TR-DATA` |
| `DocumentNotFoundError` | missing/hidden document exception | `dms/sdk/errors.py:53` | `test_dms/test_sdk_behavior.py::test_get_document_metadata_raises_document_not_found_for_missing_id` | [E-06](Examples-v0.11.0.md#example-e06), [E-07](Examples-v0.11.0.md#example-e07) | `TR-ERR` |
| `DocumentPage` | cursor page result | `dms/sdk/types.py:400` | `test_dms/test_sdk_pagination.py::test_cursor_page_is_stable_opaque_and_status_bound` | [E-06](Examples-v0.11.0.md#example-e06), [E-10](Examples-v0.11.0.md#example-e10) | `TR-READ` |
| `DocumentPartition` | personal/group partition value | `dms/domain/models.py:29` | `test_dms/test_sdk_partitions.py::test_public_contract_exposes_partitions_and_access_control_types` | [E-01](Examples-v0.11.0.md#example-e01), [E-03](Examples-v0.11.0.md#example-e03) | `TR-DATA` |
| `DocumentReader` | read capability protocol | `dms/sdk/contracts.py:316` | `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols` | [E-05](Examples-v0.11.0.md#example-e05), [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DocumentWriter` | upload capability protocol | `dms/sdk/contracts.py:284` | `test_dms/test_sdk_consumer_integration_contracts.py::test_default_sdk_satisfies_public_capability_protocols` | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-CONTRACT` |
| `DuplicateDocumentError` | duplicate-ID exception | `dms/sdk/errors.py:67` | `test_dms/test_sdk_lifecycle_and_conflicts.py::test_upload_document_maps_database_conflict_to_duplicate_and_rolls_back_object` | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `IdempotencyConflictError` | idempotency fingerprint conflict | `dms/sdk/errors.py:118` | source-only: fingerprint-conflict focused test is not present in this checkout | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `IdempotencyInProgressError` | pending idempotency exception | `dms/sdk/errors.py:125` | `test_dms/test_sdk_requirement_feedback.py::test_all_public_sdk_errors_expose_structured_contract` (contract) | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `MetadataStoreError` | metadata persistence exception | `dms/sdk/errors.py:82` | `test_dms/test_sdk_behavior.py::test_get_document_metadata_raises_metadata_store_error_for_backend_failure` | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `OperationEvent` | observer event model | `dms/sdk/contracts.py:239` | `test_dms/test_sdk_consumer_integration_contracts.py::test_operation_observer_receives_safe_success_and_failure_events` | [E-09](Examples-v0.11.0.md#example-e09) | `TR-OBS` |
| `OperationObserver` | observer callback protocol | `dms/sdk/contracts.py:263` | `test_dms/test_sdk_consumer_integration_contracts.py::test_operation_observer_receives_safe_success_and_failure_events` | [E-09](Examples-v0.11.0.md#example-e09) | `TR-OBS` |
| `PartitionKind` | partition kind enum | `dms/domain/models.py:23` | `test_dms/test_sdk_partitions.py::test_public_contract_exposes_partitions_and_access_control_types` | [E-01](Examples-v0.11.0.md#example-e01), [E-03](Examples-v0.11.0.md#example-e03) | `TR-DATA` |
| `PayloadTooLargeError` | size-policy exception | `dms/sdk/errors.py:46` | `test_dms/test_sdk_feedback_async_cursor.py::test_configured_file_size_limit_has_distinct_public_error` | [E-04](Examples-v0.11.0.md#example-e04), [E-09](Examples-v0.11.0.md#example-e09) | `TR-ERR` |
| `PublicDocumentMetadata` | storage-safe metadata projection | `dms/sdk/types.py:71` | `test_dms/test_sdk_public_contract.py::test_default_metadata_and_upload_results_hide_storage_key` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) | `TR-DATA` |
| `ReconciliationPlan` | immutable recovery plan | `dms/sdk/types.py:568` | `test_dms/test_sdk_reconciliation.py::test_dry_run_exports_plan_and_execution_revalidates_stale_items_with_best_effort_audit` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `ReconciliationPlanItem` | recovery plan item | `dms/sdk/types.py:554` | `test_dms/test_independent_review_regressions.py::test_plan_is_immutable_action_bound_and_preserves_empty_batch_origin` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `ReconciliationResult` | single recovery result | `dms/sdk/types.py:461` | `test_dms/test_sdk_reconciliation.py::test_batch_summary_properties_are_stable` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `RecoveryAction` | recovery action enum | `dms/sdk/types.py:431` | `test_dms/test_sdk_reconciliation_core.py::test_complete_deletion_requires_deleting_and_absent_object_then_soft_or_hard` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `RecoveryAuditEvent` | best-effort recovery audit event | `dms/sdk/types.py:591` | `test_dms/test_sdk_reconciliation.py::test_recovery_audit_records_actor_and_time_and_plan_requires_dry_run` | [E-08](Examples-v0.11.0.md#example-e08), [E-09](Examples-v0.11.0.md#example-e09) | `TR-OBS` |
| `RecoveryIssue` | consistency issue enum | `dms/sdk/types.py:423` | `test_dms/test_sdk_reconciliation_core.py::test_inspect_missing_metadata_is_a_typed_result_not_not_found` | [E-08](Examples-v0.11.0.md#example-e08) | `TR-REC` |
| `StorageError` | object-storage exception | `dms/sdk/errors.py:74` | `test_dms/test_sdk_behavior.py::test_delete_document_storage_failure_marks_metadata_failed` | [E-04](Examples-v0.11.0.md#example-e04), [E-08](Examples-v0.11.0.md#example-e08) | `TR-ERR` |
| `UploadDocumentRequest` | bytes upload request | `dms/sdk/types.py:21` | `test_dms/test_sdk_behavior.py::test_upload_document_persists_metadata_and_content` | [E-01](Examples-v0.11.0.md#example-e01), [E-04](Examples-v0.11.0.md#example-e04) | `TR-UPL` |
| `UploadDocumentResult` | upload result | `dms/sdk/types.py:53` | `test_dms/test_sdk_public_contract.py::test_default_metadata_and_upload_results_hide_storage_key` | [E-01](Examples-v0.11.0.md#example-e01), [E-05](Examples-v0.11.0.md#example-e05) | `TR-UPL` |
| `UploadDocumentStreamRequest` | known-size sync stream request | `dms/sdk/types.py:34` | `test_dms/test_sdk_stream_upload_contract.py::test_stream_request_is_public_and_uploads_without_buffering_as_bytes` | [E-04](Examples-v0.11.0.md#example-e04) | `TR-UPL` |
| `UploadOperationNotFoundError` | missing operation exception | `dms/sdk/errors.py:133` | `test_dms/test_sdk_native_async_partitions.py::test_native_async_partition_reset_clears_operation_records_in_scope` | [E-04](Examples-v0.11.0.md#example-e04), [E-07](Examples-v0.11.0.md#example-e07) | `TR-ERR` |
| `UploadOperationResult` | idempotency operation result | `dms/sdk/types.py:140` | `test_dms/test_sdk_partitions.py::test_storage_and_idempotency_namespaces_include_partition_kind` | [E-04](Examples-v0.11.0.md#example-e04) | `TR-UPL` |
| `ValidationError` | input/partition/cursor exception | `dms/sdk/errors.py:32` | `test_dms/test_sdk_partitions.py::test_partition_is_required_and_bound_to_cursor` | [E-03](Examples-v0.11.0.md#example-e03), [E-04](Examples-v0.11.0.md#example-e04), [E-06](Examples-v0.11.0.md#example-e06), [E-08](Examples-v0.11.0.md#example-e08) | `TR-ERR` |
| `public_metadata` | public projection function | `dms/sdk/types.py:118` | `test_dms/test_sdk_metadata.py::test_public_metadata_projection_accepts_metadata_and_upload_result_without_storage_key` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) | `TR-DATA` |
| `DocumentStatus` | document lifecycle enum; root-only addition | `dms/domain/models.py:9` | `test_dms/test_sdk_pagination.py::test_cursor_page_is_stable_opaque_and_status_bound` | [E-06](Examples-v0.11.0.md#example-e06), [E-07](Examples-v0.11.0.md#example-e07), [E-08](Examples-v0.11.0.md#example-e08) | `TR-DATA` |

Package-root 조립은 `dms/__init__.py:1-5`와 `dms/sdk/__init__.py:1-119`에 정의되어 있다. export-membership 테스트는 이름이 노출되는지 확인하는 계약 테스트이며, 실제 동작 보장은 각 행의 focused test와 아래 facade 표를 함께 확인해야 한다.

### 1.2 공개하지 않는 이름과 기능

현재 package root 공개 API에는 다음이 포함되지 않는다.

- 환경변수에서 client를 생성하는 factory와 환경 진단 helper
- `MetadataStore`, `ObjectStore`, `UploadOperationStore` 및 async storage port의 구체 구현·내부 import 경로
- `UploadOperationState`와 내부 persistence model
- SDK가 자체 관리하는 인증·권한 정책 저장소
- readiness endpoint, HTTP response/error model 및 운영용 health API
- SDK 전역 resource `close()`/`aclose()` lifecycle
- 검색·일반 metadata filtering, presigned URL, message broker API
- unknown-size 또는 async input stream 직접 upload
- 독립 실행형 API 서버

`AsyncDocumentManagementSDK.from_async_components()`는 host가 이미 준비한 async storage component를 전달하는 고급 조립 경계지만, 그 component type 자체는 package root public export가 아니다. 이 버전에는 scoped facade 또는 context 객체도 package root public export로 포함되지 않는다.

## 2. 조립 API와 소유권

### 2.1 동기 client factory

`DocumentManagementSDKFactory`는 host가 만든 SQLAlchemy `Engine`과 동기 MinIO client를 storage adapter에 연결한다. 정의 위치는 `dms/sdk/factory.py:85-134`다.

```text
DocumentManagementSDKFactory(
    *,
    engine: Engine,
    minio_client: Minio,
    bucket_name: str,
    logger: logging.Logger | None = None,
    max_file_size: int | None = None,
    recovery_audit_hook: Callable[[RecoveryAuditEvent], object] | None = None,
    access_policy: AccessPolicy | None = None,
    operation_observer: OperationObserver | None = None,
) -> None

factory.create() -> DefaultDocumentManagementSDK
```

- `engine.dialect.name`은 `postgresql` 또는 `sqlite`여야 한다. 그 밖의 dialect는 `ConfigurationError`다.
- 공백만 있는 `bucket_name`은 factory 생성 시 `ConfigurationError`다.
- `max_file_size`가 지정되면 양수여야 하며, 위반은 factory 생성 시 `ValueError`다.
- bucket이 없으면 adapter 조립 중 생성할 수 있지만, 주입된 client와 bucket의 삭제·종료 lifecycle은 host가 소유한다.
- sync factory에는 `create_async()`가 없다. native async 조립에는 `AsyncDocumentManagementSDKFactory`를 사용한다.
- factory 경로는 engine 기반 operation store를 자동 조립하므로 idempotency operation 조회를 지원한다.

### 2.2 native async factory

`AsyncDocumentManagementSDKFactory`는 `AsyncEngine`과 **동기** MinIO client를 받는다. blocking MinIO 호출은 async adapter가 event loop 밖에서 실행한다. 정의 위치는 `dms/sdk/factory.py:138-197`이다.

```text
AsyncDocumentManagementSDKFactory(
    *,
    engine: AsyncEngine,
    minio_client: Minio,
    bucket_name: str,
    logger: logging.Logger | None = None,
    max_file_size: int | None = None,
    recovery_audit_hook: Callable[[RecoveryAuditEvent], object] | None = None,
    access_policy: AccessPolicy | None = None,
    operation_observer: OperationObserver | None = None,
) -> None

factory.create() -> AsyncDocumentManagementSDK
await factory.create_async() -> AsyncDocumentManagementSDK
```

- `engine`은 `AsyncEngine`이어야 하며, 잘못된 engine 또는 필요한 MinIO surface가 없는 client는 `ConfigurationError`다.
- `create()`는 lazy async SDK를 반환한다. 첫 `await` 또는 `ready()`에서 초기화 callback이 실행된다.
- `create_async()`는 생성 후 `ready()`까지 기다린 SDK를 반환한다.
- `AsyncDocumentManagementSDK(sync_sdk)`는 기존 sync SDK를 awaitable compatibility facade로 감싼다. native async storage assembly와 같은 경계로 취급하지 않는다.
- async facade도 주입된 engine/client/component의 전역 lifecycle을 소유하지 않는다.

### 2.3 component 직접 조립

이미 adapter된 component를 host가 전달할 때는 다음 생성자를 사용한다. component protocol은 내부 import 경계이므로 일반 소비자는 factory를 우선 사용한다. 정의 위치는 `dms/sdk/implementation.py:70-123`, `dms/sdk/async_sdk.py:132-157`이다.

```text
DefaultDocumentManagementSDK(
    *,
    metadata_store: MetadataStore,
    object_store: ObjectStore,
    logger: logging.Logger | None = None,
    max_file_size: int | None = None,
    operation_store: UploadOperationStore | None = None,
    recovery_audit_hook: Callable[[RecoveryAuditEvent], object] | None = None,
    access_policy: AccessPolicy | None = None,
    operation_observer: OperationObserver | None = None,
) -> None

AsyncDocumentManagementSDK.from_async_components(
    *,
    metadata_store: AsyncMetadataStore,
    object_store: AsyncObjectStore,
    operation_store: AsyncUploadOperationStore | None = None,
    logger=None,
    max_file_size: int | None = None,
    recovery_audit_hook=None,
    access_policy: AccessPolicy | None = None,
    operation_observer=None,
    initialize: Callable[[], Awaitable[object] | object] | None = None,
) -> AsyncDocumentManagementSDK
```

`metadata_store`, `object_store`, `operation_store`는 host가 준비한 구조적 component 계약이다. SDK는 이 자원을 생성하거나 종료하지 않는다. 직접 sync 조립에서 `max_file_size <= 0`은 `ValidationError`이고, factory 조립에서는 `ValueError`다. `operation_store`를 생략하면 persistent idempotency upload와 operation 조회는 사용할 수 없다.

### 2.4 facade 생성과 자원 경계

```text
AsyncDocumentManagementSDK(
    sdk: DefaultDocumentManagementSDK | None = None,
    *,
    async_core: AsyncDocumentManagementCore | None = None,
    initialize: Callable[[], Awaitable[object] | object] | None = None,
) -> None
```

`sdk`와 `async_core` 중 정확히 하나를 전달해야 한다. async facade의 `ready()`는 자신을 반환하며 facade 자체는 awaitable이다. SDK가 upload 중 직접 연 local file과 SDK가 반환한 content stream은 SDK가 정리하고, caller가 제공한 input stream과 `copy_document_to()` sink는 caller가 닫는다. 공개 facade에는 전역 `close()`, `aclose()`, `check_health()`가 없다.

## 3. 공개 facade member 전체 coverage

기준 checkout의 `DefaultDocumentManagementSDK`는 27개 public operation, `AsyncDocumentManagementSDK`는 29개 public member를 가진다. async 표의 `from_async_components`는 classmethod이고 `ready`를 포함한 나머지는 awaitable method다. 두 facade에는 scoped facade가 없으며 일반 document operation의 `partition`은 항상 keyword-only required parameter다.

| member | sync source | async source | 결과/형태 | 테스트 근거 | example |
| --- | --- | --- | --- | --- | --- |
| `create` | `dms/sdk/factory.py:110` | `dms/sdk/factory.py:160` | SDK facade; async는 lazy | `test_dms/test_sdk_factory.py::test_factory_assembles_sdk_from_sqlalchemy_engine_and_minio_client`, `test_dms/test_sdk_native_async_partitions.py::test_async_factory_wires_sync_minio_adapter` | [E-01](Examples-v0.11.0.md#example-e01), [E-02](Examples-v0.11.0.md#example-e02) |
| `create_async` | - | `dms/sdk/factory.py:195` | ready async SDK | `test_dms/test_sdk_factory_integration.py::test_async_factory_round_trips_document_through_postgres_and_minio` (integration) | [E-02](Examples-v0.11.0.md#example-e02) |
| `from_async_components` | - | `dms/sdk/async_sdk.py:132` | async SDK classmethod | `test_dms/test_sdk_native_async_partitions.py::test_native_async_core_awaits_object_storage_and_preserves_partition` | [E-02](Examples-v0.11.0.md#example-e02) |
| `ready` | - | `dms/sdk/async_sdk.py:159` | `AsyncDocumentManagementSDK` itself | `test_dms/test_sdk_contract_completion.py::test_async_facade_exposes_all_public_async_sdk_operations` (member/awaitable contract) | [E-02](Examples-v0.11.0.md#example-e02) |
| `upload_document` | `dms/sdk/implementation.py:125` | `dms/sdk/async_sdk.py:195` | `UploadDocumentResult` | `test_dms/test_sdk_behavior.py::test_upload_document_persists_metadata_and_content` | [E-01](Examples-v0.11.0.md#example-e01), [E-04](Examples-v0.11.0.md#example-e04) |
| `upload_file` | `dms/sdk/implementation.py:142` | `dms/sdk/async_sdk.py:209` | `UploadDocumentResult` | `test_dms/test_sdk_consumer_integration_contracts.py::test_upload_file_and_known_size_stream_own_only_internally_opened_resources` | [E-04](Examples-v0.11.0.md#example-e04) |
| `upload_document_stream` | `dms/sdk/implementation.py:188` | `dms/sdk/async_sdk.py:233` | `UploadDocumentResult` | `test_dms/test_sdk_stream_upload_contract.py::test_stream_upload_enforces_declared_size_and_rolls_back` | [E-04](Examples-v0.11.0.md#example-e04) |
| `get_upload_operation` | `dms/sdk/implementation.py:208` | `dms/sdk/async_sdk.py:247` | `UploadOperationResult` | `test_dms/test_sdk_partitions.py::test_storage_and_idempotency_namespaces_include_partition_kind` | [E-04](Examples-v0.11.0.md#example-e04) |
| `get_internal_document_metadata` | `dms/sdk/implementation.py:253` | `dms/sdk/async_sdk.py:263` | `DocumentMetadata` | `test_dms/test_sdk_public_contract.py::test_privileged_metadata_access_is_explicit` | [E-05](Examples-v0.11.0.md#example-e05), [E-08](Examples-v0.11.0.md#example-e08) |
| `get_document_metadata` | `dms/sdk/implementation.py:280` | `dms/sdk/async_sdk.py:277` | `PublicDocumentMetadata` | `test_dms/test_sdk_behavior.py::test_get_document_metadata_raises_document_not_found_for_missing_id` | [E-05](Examples-v0.11.0.md#example-e05), [E-07](Examples-v0.11.0.md#example-e07) |
| `list_documents` | `dms/sdk/implementation.py:301` | `dms/sdk/async_sdk.py:291` | `DocumentPage` | `test_dms/test_sdk_behavior.py::test_list_documents_returns_cursor_paginated_metadata_filtered_by_status` | [E-06](Examples-v0.11.0.md#example-e06) |
| `list_documents_page` | `dms/sdk/implementation.py:335` | `dms/sdk/async_sdk.py:309` | `DocumentPage` | `test_dms/test_sdk_pagination.py::test_cursor_page_is_stable_opaque_and_status_bound` | [E-06](Examples-v0.11.0.md#example-e06) |
| `iter_documents` | `dms/sdk/implementation.py:376` | `dms/sdk/async_sdk.py:327` | sync/async iterator of `PublicDocumentMetadata` | `test_dms/test_sdk_consumer_integration_contracts.py::test_document_and_recovery_iterators_preserve_page_conditions` | [E-06](Examples-v0.11.0.md#example-e06), [E-10](Examples-v0.11.0.md#example-e10) |
| `inspect_document` | `dms/sdk/implementation.py:398` | `dms/sdk/async_sdk.py:344` | `DocumentInspection` | `test_dms/test_sdk_reconciliation_core.py::test_inspect_missing_metadata_is_a_typed_result_not_not_found` | [E-08](Examples-v0.11.0.md#example-e08) |
| `list_recovery_candidates` | `dms/sdk/implementation.py:446` | `dms/sdk/async_sdk.py:358` | `list[DocumentMetadata]` | `test_dms/test_sdk_reconciliation_core.py::test_batch_is_bounded_status_restricted_dry_run_and_preserves_item_errors` | [E-08](Examples-v0.11.0.md#example-e08) |
| `iter_recovery_candidates` | `dms/sdk/implementation.py:474` | `dms/sdk/async_sdk.py:376` | sync/async iterator of `DocumentMetadata` | `test_dms/test_sdk_consumer_integration_contracts.py::test_document_and_recovery_iterators_preserve_page_conditions` | [E-08](Examples-v0.11.0.md#example-e08), [E-10](Examples-v0.11.0.md#example-e10) |
| `reconcile_document` | `dms/sdk/implementation.py:498` | `dms/sdk/async_sdk.py:393` | `ReconciliationResult` | `test_dms/test_sdk_reconciliation_core.py::test_complete_deletion_requires_deleting_and_absent_object_then_soft_or_hard` | [E-08](Examples-v0.11.0.md#example-e08) |
| `execute_reconciliation_plan` | `dms/sdk/implementation.py:546` | `dms/sdk/async_sdk.py:415` | `BatchReconciliationResult` | `test_dms/test_sdk_reconciliation.py::test_dry_run_exports_plan_and_execution_revalidates_stale_items_with_best_effort_audit` | [E-08](Examples-v0.11.0.md#example-e08) |
| `reconcile_documents` | `dms/sdk/implementation.py:608` | `dms/sdk/async_sdk.py:431` | `BatchReconciliationResult` | `test_dms/test_sdk_reconciliation_core.py::test_batch_is_bounded_status_restricted_dry_run_and_preserves_item_errors` | [E-08](Examples-v0.11.0.md#example-e08) |
| `get_document_content` | `dms/sdk/implementation.py:674` | `dms/sdk/async_sdk.py:455` | `DocumentContent` | `test_dms/test_sdk_behavior.py::test_upload_document_persists_metadata_and_content` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) |
| `get_document_content_stream` | `dms/sdk/implementation.py:698` | `dms/sdk/async_sdk.py:469` | sync `DocumentContentStream`; async `AsyncDocumentContentStream` | `test_dms/test_sdk_behavior.py::test_get_document_content_stream_returns_chunked_stream`, `test_dms/test_sdk_feedback_async_cursor.py::test_async_download_stream_closes_on_context_exit_and_exhaustion` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) |
| `iter_document_chunks` | `dms/sdk/implementation.py:728` | `dms/sdk/async_sdk.py:509` | sync/async bytes iterator | `test_dms/test_sdk_contract_completion.py::test_sync_closing_iterator_closes_on_exhaustion_and_explicit_early_stop`, `test_dms/test_sdk_contract_completion.py::test_async_closing_iterator_closes_on_exhaustion_and_explicit_early_stop` | [E-10](Examples-v0.11.0.md#example-e10) |
| `copy_document_to` | `dms/sdk/implementation.py:747` | `dms/sdk/async_sdk.py:529` | `DocumentCopyResult` | `test_dms/test_sdk_consumer_integration_contracts.py::test_copy_document_to_closes_source_and_keeps_sink_open` | [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) |
| `get_document_content_async_stream` | `dms/sdk/implementation.py:807` | `dms/sdk/async_sdk.py:494` | `AsyncDocumentContentStream` | `test_dms/test_sdk_feedback_async_cursor.py::test_async_download_stream_closes_on_context_exit_and_exhaustion`, `test_dms/test_sdk_contract_completion.py::test_async_facade_exposes_all_public_async_sdk_operations` | [E-10](Examples-v0.11.0.md#example-e10) |
| `delete_document` | `dms/sdk/implementation.py:834` | `dms/sdk/async_sdk.py:549` | `DeleteDocumentResult` | `test_dms/test_sdk_deletion.py::test_explicit_delete_methods_preserve_legacy_dispatch` | [E-07](Examples-v0.11.0.md#example-e07) |
| `soft_delete_document` | `dms/sdk/implementation.py:865` | `dms/sdk/async_sdk.py:565` | `DeleteDocumentResult` | `test_dms/test_sdk_deletion.py::test_explicit_delete_methods_preserve_legacy_dispatch` | [E-07](Examples-v0.11.0.md#example-e07) |
| `hard_delete_document` | `dms/sdk/implementation.py:879` | `dms/sdk/async_sdk.py:579` | `DeleteDocumentResult` | `test_dms/test_sdk_deletion.py::test_explicit_delete_methods_preserve_legacy_dispatch` | [E-07](Examples-v0.11.0.md#example-e07) |
| `clear_all_data` | `dms/sdk/implementation.py:893` | `dms/sdk/async_sdk.py:593` | `DataResetResult` | `test_dms/test_sdk_data_reset.py::test_clear_all_data_removes_documents_objects_and_upload_operations` | [E-07](Examples-v0.11.0.md#example-e07) |
| `clear_partition_data` | `dms/sdk/implementation.py:904` | `dms/sdk/async_sdk.py:603` | `DataResetResult` | `test_dms/test_sdk_partitions.py::test_clear_partition_data_preserves_other_partitions` | [E-07](Examples-v0.11.0.md#example-e07) |
| `initialize_for_data_load` | `dms/sdk/implementation.py:918` | `dms/sdk/async_sdk.py:615` | `DataResetResult` | `test_dms/test_sdk_data_reset.py::test_initialize_for_data_load_is_idempotent_and_leaves_empty_store` | [E-07](Examples-v0.11.0.md#example-e07) |
| `initialize_partition_for_data_load` | `dms/sdk/implementation.py:930` | `dms/sdk/async_sdk.py:625` | `DataResetResult` | `test_dms/test_sdk_partitions.py::test_partition_reset_rejects_none_without_clearing_all_data` | [E-07](Examples-v0.11.0.md#example-e07) |

### 3.1 facade signature

#### sync facade

```text
sdk.upload_document(
    request: UploadDocumentRequest,
    *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> UploadDocumentResult
sdk.upload_file(
    path: str | Path,
    *, filename: str | None = None, content_type: str | None = None,
    document_id: str | None = None, metadata: dict[str, Any] | None = None,
    created_by: str | None = None, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> UploadDocumentResult
sdk.upload_document_stream(
    request: UploadDocumentStreamRequest,
    *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> UploadDocumentResult
sdk.get_upload_operation(
    *, scope: str, idempotency_key: str, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> UploadOperationResult

sdk.get_internal_document_metadata(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DocumentMetadata
sdk.get_document_metadata(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> PublicDocumentMetadata
sdk.list_documents(
    *, partition: DocumentPartition, cursor: str | None = None,
    limit: int = 100, status: DocumentStatus | None = None,
    access_context: AccessContext | None = None,
) -> DocumentPage
sdk.list_documents_page(
    *, partition: DocumentPartition, cursor: str | None = None,
    limit: int = 100, status: DocumentStatus | None = None,
    access_context: AccessContext | None = None,
) -> DocumentPage
sdk.iter_documents(
    *, partition: DocumentPartition, status: DocumentStatus | None = None,
    page_size: int = 100, access_context: AccessContext | None = None,
) -> Iterator[PublicDocumentMetadata]

sdk.inspect_document(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DocumentInspection
sdk.list_recovery_candidates(
    *, partition: DocumentPartition, status: DocumentStatus,
    offset: int = 0, limit: int = 100,
    access_context: AccessContext | None = None,
) -> list[DocumentMetadata]
sdk.iter_recovery_candidates(
    *, partition: DocumentPartition, status: DocumentStatus,
    page_size: int = 100, access_context: AccessContext | None = None,
) -> Iterator[DocumentMetadata]
sdk.reconcile_document(
    document_id: str, action: RecoveryAction, *, storage_key: str | None = None,
    dry_run: bool = False, actor: str | None = None,
    partition: DocumentPartition, access_context: AccessContext | None = None,
) -> ReconciliationResult
sdk.execute_reconciliation_plan(
    plan: ReconciliationPlan, *, partition: DocumentPartition,
    actor: str | None = None, access_context: AccessContext | None = None,
) -> BatchReconciliationResult
sdk.reconcile_documents(
    *, status: DocumentStatus, action: RecoveryAction, offset: int = 0,
    limit: int = 100, dry_run: bool = False, actor: str | None = None,
    partition: DocumentPartition, access_context: AccessContext | None = None,
) -> BatchReconciliationResult

sdk.get_document_content(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DocumentContent
sdk.get_document_content_stream(
    document_id: str, *, chunk_size: int = 65536, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DocumentContentStream
sdk.iter_document_chunks(
    document_id: str, *, chunk_size: int = 65536, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> Iterator[bytes]
sdk.copy_document_to(
    document_id: str, sink: BinaryIO, *, chunk_size: int = 65536,
    verify_checksum: bool = True, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DocumentCopyResult
sdk.get_document_content_async_stream(
    document_id: str, *, chunk_size: int = 65536, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> AsyncDocumentContentStream

sdk.delete_document(
    document_id: str, *, partition: DocumentPartition, hard_delete: bool = False,
    access_context: AccessContext | None = None,
) -> DeleteDocumentResult
sdk.soft_delete_document(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DeleteDocumentResult
sdk.hard_delete_document(
    document_id: str, *, partition: DocumentPartition,
    access_context: AccessContext | None = None,
) -> DeleteDocumentResult
sdk.clear_all_data(
    *, access_context: AccessContext | None = None,
) -> DataResetResult
sdk.clear_partition_data(
    *, partition: DocumentPartition, access_context: AccessContext | None = None,
) -> DataResetResult
sdk.initialize_for_data_load(
    *, access_context: AccessContext | None = None,
) -> DataResetResult
sdk.initialize_partition_for_data_load(
    *, partition: DocumentPartition, access_context: AccessContext | None = None,
) -> DataResetResult
```

#### async facade

`AsyncDocumentManagementSDK`는 위 작업 이름을 동일하게 제공하고 `await`한다. `iter_documents()`, `iter_recovery_candidates()`, `iter_document_chunks()`는 async iterator다. async facade의 `get_document_content_stream()`과 `get_document_content_async_stream()`은 `AsyncDocumentContentStream`을 반환한다.

- native async factory 경로는 async SQLAlchemy component와 async object-store adapter를 사용한다.
- `AsyncDocumentManagementSDK(sync_sdk)` compatibility 경로는 blocking sync 작업을 event loop 밖 thread에서 실행한다.
- async facade의 `from_async_components()`는 이미 준비된 async storage component와 선택적 `initialize` callback을 받는다.
- sync/async 양쪽에서 모든 일반 문서·복구 작업은 `partition`을 요구한다. `clear_all_data()`와 `initialize_for_data_load()`만 전역 범위이므로 partition을 받지 않는다.

## 4. 입력·결과 모델

### 4.1 partition과 lifecycle enum

`PartitionKind` 값은 `PERSONAL = "personal"`, `GROUP = "group"`이다. `DocumentPartition`은 non-empty `partition_id`를 가진 불변 값이며 다음 classmethod를 제공한다.

```text
DocumentPartition(
    *, kind: PartitionKind, partition_id: str,
) -> DocumentPartition
DocumentPartition.personal(partition_id: str) -> DocumentPartition
DocumentPartition.group(partition_id: str) -> DocumentPartition
document_partition.to_dict() -> dict[str, str]
```

정의는 `dms/domain/models.py:23-53`이다. `DocumentStatus` 값은 `uploaded`, `available`, `deleting`, `deleted`, `failed`이며 `UploadOperationState`는 내부 모델이므로 public export가 아니다.

### 4.2 upload 입력과 결과

```text
UploadDocumentRequest(
    *,
    content: bytes,
    filename: str,
    content_type: str,
    document_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    created_by: str | None = None,
    checksum: str | None = None,
    idempotency_key: str | None = None,
    idempotency_scope: str | None = None,
)

UploadDocumentStreamRequest(
    *,
    stream: BinaryIO,
    size: int,
    filename: str,
    content_type: str,
    document_id: str | None = None,
    metadata: dict[str, Any] | None = None,
    created_by: str | None = None,
)
```

`UploadDocumentRequest`는 bytes, `UploadDocumentStreamRequest`는 정확한 양수 `size`가 선언된 동기 binary stream을 표현한다. 두 입력의 공통 field validation은 storage write, stream read 및 idempotency claim보다 먼저 수행된다. `metadata`는 `dict` 또는 `None`이어야 하고 JSON-serializable 값이어야 한다. 업무 schema와 secret 정책은 caller 책임이다.

`upload_file()`은 SDK가 연 파일을 SDK가 닫고, caller가 전달한 stream은 SDK가 닫지 않는다. bytes/file/known-size stream만 현재 공개 upload 입력이며 unknown-size, async input stream, 요청별 max size·chunk 조절은 지원하지 않는다. 조립 시 `max_file_size`가 있으면 세 경로에 공통 적용된다.

`UploadDocumentResult`는 `document_id`, public `metadata`, `created`를 가진다. `created=False`는 idempotency replay 결과다. `UploadOperationResult`는 `scope`, `idempotency_key`, `document_id`, `state`, `created_at`, `updated_at`를 가진다.

### 4.3 공개·관리 metadata

`PublicDocumentMetadata`는 다음 필드를 가진 frozen public projection이다.

| 필드 | 설명 |
| --- | --- |
| `document_id` | 문서 식별자 |
| `original_filename` | 원본 파일명 |
| `content_type` | MIME type |
| `file_size` | bytes 크기 |
| `status` | `DocumentStatus` |
| `created_at`, `updated_at` | datetime |
| `partition` | `DocumentPartition` |
| `checksum` | 선택적 checksum |
| `deleted_at` | 선택적 삭제 시각 |
| `created_by` | 선택적 생성자 |
| `extra_metadata` | caller가 제공한 JSON object |

`PublicDocumentMetadata`에는 `storage_key`가 없다. `to_dict()`는 `extra_metadata` 키를 유지하는 호환 표현을 반환하고 `to_public_dict()`는 canonical 외부 표현에서 이를 `metadata` 키로 바꾼다. `json_schema()`와 `model_json_schema()`는 `storage_key`가 없는 JSON Schema를 반환한다. `public_metadata(value)`는 `DocumentMetadata`, `PublicDocumentMetadata` 또는 `UploadDocumentResult`를 public projection으로 복사한다.

`DocumentMetadata`는 `storage_key`를 포함하는 관리·복구용 domain model이다. 일반 metadata/list/content 응답에 storage locator를 노출하지 말고, `get_internal_document_metadata()`와 명시적인 recovery 흐름에서만 사용한다.

### 4.4 content와 stream

```text
DocumentContent(
    *, document_id: str, content: bytes, content_type: str,
    filename: str, size: int, checksum: str | None = None,
)

DocumentContentStream(
    *, document_id: str, stream: BinaryIO, content_type: str,
    filename: str, size: int, checksum: str | None = None,
    chunk_size: int = 65536,
)

AsyncDocumentContentStream(
    *, document_id: str, ...
)
```

`DocumentContentStream`은 `with`와 `close()`를 제공하며 `iter_chunks()` 또는 `iter_chunks_closing()`으로 읽는다. close는 idempotent다. `AsyncDocumentContentStream`은 `async with`, `aclose()`, `aiter_chunks_closing()`을 제공하고 성공·오류·취소 시 SDK가 소유한 source를 정리한다. `iter_document_chunks()`는 facade에 맞는 sync/async iterator를 반환한다.

`copy_document_to()`는 source stream을 닫고 caller sink는 닫지 않는다. 기본값 `verify_checksum=True`일 때 저장 checksum이 있으면 검증하며, 결과는 `DocumentCopyResult(document_id, bytes_copied, checksum, checksum_verified)`다.

### 4.5 page, delete, reset 결과

`DocumentPage`는 `items: list[PublicDocumentMetadata]`, `next_cursor: str | None`, `has_more: bool`를 가진다. `__iter__()`는 `items`를 순회한다.

`DeleteDocumentResult`는 `document_id`, `deleted`, `hard_deleted`, `status`를 가진다. `DataResetResult`는 `metadata_deleted`, `objects_deleted`, `upload_operations_deleted`, `ready_for_data_load` 및 계산 property `total_deleted`를 가진다. 모든 공식 결과 model의 `to_dict()` 결과는 JSON serialization을 위한 구조를 제공하며 public DTO의 schema에는 `storage_key`가 없다.

## 5. 접근 정책과 관찰 callback

### 5.1 AccessContext와 policy

`AccessContext`는 host가 인증과 membership 해석을 끝낸 뒤 전달하는 frozen context다.

```text
AccessContext(
    *,
    subject: str | None = None,
    user_id: str | None = None,
    tenant: str | None = None,
    groups: frozenset[str] = frozenset(),
    roles: frozenset[str] = frozenset(),
)

DocumentAccessPolicy.allows(
    *, operation: str,
    context: AccessContext | None,
    metadata: PublicDocumentMetadata | None,
) -> bool

AsyncDocumentAccessPolicy.allows(
    *, operation: str,
    context: AccessContext | None,
    metadata: PublicDocumentMetadata | None,
) -> Awaitable[bool]
```

DMS는 context 값의 진위를 재검증하지 않는다. 정책에 전달되는 `metadata`는 항상 public projection이고, partition-wide 또는 metadata-independent operation에서는 `None`이다. 정책이 `False`를 반환하거나 오류를 일으키면 `AccessDeniedError`로 매핑하며 host 정책의 상세 오류를 외부 메시지에 노출하지 않는다. native async 경로에서는 async policy를 await하고 sync policy는 event loop 밖에서 실행한다.

### 5.2 observer

`OperationEvent`는 `operation`, `succeeded`, `started_at`, `completed_at`, 선택적 `document_id`, `conditions`, `error_code`를 가진다. `OperationObserver`는 `OperationEvent`를 받는 callback protocol이다.

```text
OperationObserver(event: OperationEvent) -> object
OperationEvent.to_dict() -> dict[str, object]
```

observer callback 실패는 원래 문서 작업 결과를 바꾸지 않는다. event의 외부 serialization에는 storage key가 포함되지 않는다. recovery에는 별도의 best-effort `recovery_audit_hook(RecoveryAuditEvent)`를 사용할 수 있다.

## 6. 목록, 삭제, 초기화, 복구 계약

### 6.1 partition과 cursor page

- `personal`과 `group`은 같은 `partition_id`를 사용해도 서로 다른 namespace다.
- 일반 문서 등록·조회·목록·본문·삭제·복구는 `partition: DocumentPartition`을 required keyword parameter로 받는다.
- 문서 ID는 partition을 넘어 metadata store에서 globally unique해야 한다.
- `list_documents()`와 `list_documents_page()`는 cursor 방식만 사용하며 `offset` 인자를 제공하지 않는다.
- cursor는 opaque하게 취급해야 한다. 기준 checkout cursor는 version 4이며 정렬 위치, status, page size, partition kind 및 partition id에 묶인다.
- 다른 partition, status 또는 page size로 cursor를 재사용하거나 변조하면 `ValidationError`다.
- 일반 public list와 `get_document_metadata()`는 `DELETING`, `DELETED` 상태를 숨긴다. 삭제된 본문 요청은 `DocumentDeletedError`, 숨겨진 metadata 요청은 `DocumentNotFoundError`다.

```text
sdk.list_documents(
    *, partition: DocumentPartition, cursor: str | None = None,
    limit: int = 100, status: DocumentStatus | None = None,
    access_context: AccessContext | None = None,
) -> DocumentPage
```

### 6.2 삭제와 reset

- `delete_document(hard_delete=False)`와 `soft_delete_document()`은 logical delete를 수행한다.
- `hard_delete_document()` 또는 `delete_document(hard_delete=True)`는 metadata까지 제거한다.
- `clear_all_data()`와 `initialize_for_data_load()`는 DMS가 관리하는 모든 metadata, `documents/` object prefix 및 upload operation 기록을 대상으로 한다.
- `clear_partition_data(partition=...)`와 `initialize_partition_for_data_load(partition=...)`는 지정 partition만 대상으로 한다. `partition=None`을 전달해 전역 삭제로 우회할 수 없다.
- reset은 저장소별 작업을 계속 시도한다. 하나라도 실패하면 부분 count와 `failed_stores`를 가진 `DataResetError`를 발생시키고 `result.ready_for_data_load`는 `False`다.
- 이미 빈 범위에서 `initialize_*_for_data_load()`를 호출해도 성공하는 멱등 작업이다.

### 6.3 consistency inspection과 recovery

`inspect_document()`은 정확한 partition 안에서 metadata와 object 존재를 비교하고 `DocumentInspection`을 반환한다. `RecoveryIssue`는 `NONE`, `METADATA_MISSING`, `OBJECT_MISSING`, `DELETION_INCOMPLETE`, `FAILED_STATUS`다. `list_recovery_candidates()`와 `iter_recovery_candidates()`는 `FAILED` 또는 `DELETING` status만 받고 bounded offset/page size를 사용한다.

`RecoveryAction`은 다음 네 가지다.

- `COMPLETE_DELETION_SOFT`
- `COMPLETE_DELETION_HARD`
- `MARK_FAILED`
- `PURGE_ORPHAN_OBJECT`

`reconcile_document()`은 한 문서를 처리하고 `ReconciliationResult`를 반환한다. `reconcile_documents()`는 bounded batch를 처리하며 `dry_run=True`일 때만 `BatchReconciliationResult.to_plan()`으로 immutable `ReconciliationPlan`을 export할 수 있다. `execute_reconciliation_plan()`은 실행 시 각 item을 다시 inspect하고 plan의 partition이 요청 partition과 다르면 `ValidationError`다. `RecoveryAuditEvent` callback은 best-effort이며 callback 실패가 recovery 결과를 대신하지 않는다.

## 7. 오류 계약

모든 public `DmsError` subclass는 안정적인 `code`, `category`, `retryable` class attribute를 제공한다. 문서 대상 오류는 가능한 경우 `document_id`를 보유한다. 외부 응답 계층에서 infrastructure exception의 원문이나 storage locator를 그대로 노출하지 않는다.

| 오류 | code | category | retryable |
| --- | --- | --- | --- |
| `DmsError` | `dms_error` | `internal` | `False` |
| `ConfigurationError` | `configuration_invalid` | `configuration` | `False` |
| `ValidationError` | `validation_invalid` | `validation` | `False` |
| `AccessDeniedError` | `access_denied` | `authorization` | `False` |
| `PayloadTooLargeError` | `document_too_large` | `validation` | `False` |
| `DocumentNotFoundError` | `document_not_found` | `not_found` | `False` |
| `DocumentDeletedError` | `document_deleted` | `unavailable` | `False` |
| `DuplicateDocumentError` | `document_duplicate` | `conflict` | `False` |
| `StorageError` | `object_storage_failed` | `storage` | `True` |
| `MetadataStoreError` | `metadata_store_failed` | `storage` | `True` |
| `ConsistencyError` | `document_inconsistent` | `consistency` | `False` |
| `DataResetError` | `data_reset_failed` | `consistency` | `True` |
| `IdempotencyConflictError` | `idempotency_conflict` | `conflict` | `False` |
| `IdempotencyInProgressError` | `idempotency_in_progress` | `conflict` | `True` |
| `UploadOperationNotFoundError` | `upload_operation_not_found` | `not_found` | `False` |

`DmsError(message, *, document_id=None, diagnosis=None)`의 `diagnosis`는 현재 configuration diagnosis를 전달할 수 있는 확장 slot이며 모든 error가 사용하는 것은 아니다. `DataResetError`는 추가로 `result`, `errors`, `failed_stores`를 보유한다.

## 8. 기능별 trace ID

trace ID는 source/test/example를 묶기 위한 문서 식별자이며 runtime API 이름이 아니다.

| trace ID | 범위 | 예제 |
| --- | --- | --- |
| `TR-ASM` | factory, 직접 조립, 소유권 | [E-01](Examples-v0.11.0.md#example-e01), [E-02](Examples-v0.11.0.md#example-e02) |
| `TR-UPL` | bytes/file/stream upload, idempotency | [E-01](Examples-v0.11.0.md#example-e01), [E-04](Examples-v0.11.0.md#example-e04) |
| `TR-READ` | metadata, content, pagination, stream | [E-05](Examples-v0.11.0.md#example-e05), [E-06](Examples-v0.11.0.md#example-e06), [E-10](Examples-v0.11.0.md#example-e10) |
| `TR-DEL` | logical/hard delete | [E-07](Examples-v0.11.0.md#example-e07) |
| `TR-RESET` | 전체·partition reset | [E-07](Examples-v0.11.0.md#example-e07) |
| `TR-REC` | inspection, reconciliation, plan | [E-08](Examples-v0.11.0.md#example-e08) |
| `TR-POLICY` | access context와 host policy | [E-03](Examples-v0.11.0.md#example-e03) |
| `TR-OBS` | operation observer와 recovery audit | [E-08](Examples-v0.11.0.md#example-e08), [E-09](Examples-v0.11.0.md#example-e09) |
| `TR-CONTRACT` | capability protocols | [E-09](Examples-v0.11.0.md#example-e09) |
| `TR-DATA` | public projection, partition, schema | [E-03](Examples-v0.11.0.md#example-e03), [E-05](Examples-v0.11.0.md#example-e05), [E-10](Examples-v0.11.0.md#example-e10) |
| `TR-ERR` | structured errors와 boundary | [E-04](Examples-v0.11.0.md#example-e04), [E-07](Examples-v0.11.0.md#example-e07), [E-09](Examples-v0.11.0.md#example-e09) |
| `TR-ASYNC` | native/compat async와 stream cleanup | [E-02](Examples-v0.11.0.md#example-e02), [E-10](Examples-v0.11.0.md#example-e10) |

## 9. 버전별 사용 주의

- 이 페이지의 모든 일반 document method signature에는 `partition`이 포함된다. `v0.10.0` 페이지의 partition 없는 예제를 현재 코드에 복사하지 않는다.
- 현재 root export에는 scoped facade, operation context 및 환경변수 자동 조립 helper가 없다.
- `storage_key`가 필요한 관리 작업은 public metadata 대신 `get_internal_document_metadata()`를 사용한다.
- 예제의 `engine`, `minio_client`, storage component 및 callback은 host가 생성·관리하는 placeholder다. Wiki에는 credential이나 실제 endpoint를 넣지 않는다.
