---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/API-Reference-v0.5.0.md
ingested: 2026-07-20
sha256: fd34c99bc5d358026662d10522fd4bf0a04d2d9cd002de0340c2ad0c4b5f4f63
---
# 공개 API 참조

## 1. 범위와 추적 기준

이 문서는 `from dms import ...`로 가져올 수 있는 모든 공개 이름의 계약을 설명한다. 공개 이름의 기준은 package root의 `__all__`이며, SDK 작업의 기준은 `DefaultDocumentManagementSDK`의 공개 메서드이다. 설정은 [설정 참조](configuration.md), 조합 가능한 사용 흐름은 [사용 예제](examples.md)를 참고한다.

### 1.1 공개 이름 색인

| 영역 | 공개 이름 |
| --- | --- |
| 조립·진단 | `create_sdk_from_components`, `create_sdk_from_environment`, `create_sdk_from_service_configs`, `diagnose_environment`, `format_environment_diagnosis`, `EnvironmentDiagnosis` |
| SDK | `DefaultDocumentManagementSDK` |
| 등록·조회 모델 | `UploadDocumentRequest`, `UploadDocumentStreamRequest`, `UploadDocumentUnknownSizeStreamRequest`, `UploadDocumentResult`, `UploadOperationResult`, `DocumentContent`, `DocumentContentStream`, `DocumentPage`, `PublicDocumentMetadata`, `DocumentMetadata`, `DocumentStatus`, `public_metadata` |
| 삭제·복구 모델 | `DeleteDocumentResult`, `DocumentInspection`, `RecoveryIssue`, `RecoveryAction`, `ReconciliationResult`, `BatchReconciliationResult`, `ReconciliationPlanItem`, `ReconciliationPlan`, `RecoveryAuditEvent` |
| 상태·메타데이터 정책 | `ServiceHealth`, `HealthStatus`, `MetadataValidator`, `MetadataNormalizer`, `MetadataValidationIssue`, `MetadataSchemaValidationError`, `StructuredMetadataValidator`, `DefaultMetadataPolicy` |
| 오류 | `DmsError`, `ConfigurationError`, `ValidationError`, `DocumentNotFoundError`, `DocumentDeletedError`, `DuplicateDocumentError`, `StorageError`, `MetadataStoreError`, `ConsistencyError`, `HealthCheckFailedError`, `IdempotencyConflictError`, `IdempotencyInProgressError`, `UploadOperationNotFoundError` |

## 2. SDK 조립과 수명주기

- `create_sdk_from_environment(*, logger=None, metadata_validator=None, metadata_max_serialized_bytes=16384, metadata_max_depth=8, recovery_audit_hook=None) -> DefaultDocumentManagementSDK`
  - 현재 프로세스 환경에서 PostgreSQL 또는 SQLite와 MinIO를 조립한다. 기본적으로 시작 상태를 확인한다. 환경은 호출 전 준비해야 하며, 진단·선택 규칙은 설정 참조를 따른다.
- `create_sdk_from_service_configs(configs, *, logger=None, metadata_validator=None, metadata_max_serialized_bytes=16384, metadata_max_depth=8, recovery_audit_hook=None, check_on_startup=False) -> DefaultDocumentManagementSDK`
  - 이미 검증된 `docmesh_py_core.ServiceConfigs`를 사용한다. 프로세스 환경을 읽거나 변경하지 않는다. PostgreSQL/SQLite 정확히 하나와 버킷이 지정된 MinIO가 필요하다.
- `create_sdk_from_components(*, metadata_store, object_store, logger=None, id_generator=None, service_checks=None, close_callbacks=None, max_file_size=None, operation_store=None, metadata_validator=None, metadata_max_serialized_bytes=16384, metadata_max_depth=8, recovery_audit_hook=None) -> DefaultDocumentManagementSDK`
  - 애플리케이션이 저장소 어댑터와 수명주기 callback을 직접 제공하는 조립 방식이다. `max_file_size`는 양수여야 한다. callback 기반 상태 점검·종료 책임의 예는 [사용 예제](examples.md#2-구성요소-조립과-명시적-종료)에 있다.
- `DefaultDocumentManagementSDK`는 context manager를 지원한다. `with` 블록 종료 또는 `close()`가 정리 callback을 실행하며, 반복 `close()`는 안전하다.
- `check_health() -> HealthStatus`는 구성 요소별 상태를 반환한다.
- `close() -> None`은 SDK가 소유한 종료 자원을 정리한다.

## 3. 등록 API

### 3.1 요청과 결과

- `UploadDocumentRequest(content, filename, content_type, document_id=None, metadata={}, created_by=None, checksum=None, idempotency_key=None, idempotency_scope=None)`
  - 메모리 바이트 등록 요청이다. `checksum`은 본문의 SHA-256 hex 값이다.
- `UploadDocumentStreamRequest(stream, size, filename, content_type, document_id=None, metadata={}, created_by=None, checksum=None, chunk_size=65536, idempotency_key=None, idempotency_scope=None)`
  - 길이를 아는 이진 스트림 등록 요청이다. 실제 읽은 바이트 수는 `size`와 일치해야 하며 입력 스트림은 SDK가 닫지 않는다.
- `UploadDocumentUnknownSizeStreamRequest(stream, max_size, filename, content_type, document_id=None, metadata={}, created_by=None, chunk_size=65536, idempotency_key=None, idempotency_scope=None)`
  - 길이를 모르는 스트림을 양수 `max_size`로 제한된 임시 spool에 복사하여 등록한다. 입력 스트림은 닫지 않는다.
- `UploadDocumentResult(document_id, metadata, created=True)`의 `metadata`는 저장 위치를 포함하지 않는 `PublicDocumentMetadata`다. 멱등성 재사용 결과는 `created=False`다.
- `UploadOperationResult(scope, idempotency_key, document_id, state, created_at, updated_at)`의 상태는 `pending`, `succeeded`, `failed`다.

### 3.2 작업

- `upload_document(request: UploadDocumentRequest) -> UploadDocumentResult`
- `upload_document_stream(request: UploadDocumentStreamRequest) -> UploadDocumentResult`
- `upload_document_unknown_size_stream(request: UploadDocumentUnknownSizeStreamRequest) -> UploadDocumentResult`
  - 파일명·콘텐츠 유형·크기·청크·메타데이터를 영속화 전에 검증한다. 제공한 checksum은 본문과 일치해야 한다. 본문 저장 뒤 정보 저장에 실패하면 본문 정리를 시도하고, 정리 실패는 `ConsistencyError`로 구분한다.
  - 멱등성 키는 동일 범위와 동일 요청의 완료 결과를 재사용한다. 다른 요청에 재사용하면 `IdempotencyConflictError`, 진행 중이면 `IdempotencyInProgressError`가 발생한다. 스트림 멱등성에는 checksum이 필요하다. 범위를 생략하는 기존 방식은 경고와 함께 작성자 또는 익명 범위를 사용하므로 새 코드에서는 `idempotency_scope`를 제공해야 한다.
- `get_upload_operation(*, scope: str, idempotency_key: str) -> UploadOperationResult`
  - 정확한 범위·키의 작업 상태를 조회한다. 없으면 `UploadOperationNotFoundError`가 발생한다.

## 4. 문서 조회 API

- `get_document_metadata(document_id) -> PublicDocumentMetadata`: 외부 전달 가능한 문서 정보만 반환한다.
- `get_internal_document_metadata(document_id) -> DocumentMetadata`: `storage_key`를 포함하는 관리·복구 전용 정보다. 일반 응답이나 업무 메타데이터에 전달하면 안 된다.
- `get_document_content(document_id) -> DocumentContent`: 전체 본문 바이트와 `document_id`, `content_type`, `filename`, `size`, `checksum`을 반환한다.
- `get_document_content_stream(document_id, *, chunk_size=65536) -> DocumentContentStream`: 스트림 반환 API다. `chunk_size`는 양수여야 한다. `DocumentContentStream`은 `iter_chunks(chunk_size=None)`과 `close()`를 제공하며 context manager로 닫아야 한다.
- `list_documents(*, offset=0, limit=100, status=None) -> list[PublicDocumentMetadata]`: 기존 offset 목록이다. `offset >= 0`, `limit > 0`이 필요하다.
- `list_documents_page(*, cursor=None, limit=100, status=None) -> DocumentPage`: 생성 시각·문서 ID 내림차순의 불투명 cursor 목록이다. 제한은 1~1000이며 cursor와 상태 필터는 반드시 일치해야 한다. `DocumentPage(items, next_cursor, has_more)`를 반환한다.
- 존재하지 않는 정보는 `DocumentNotFoundError`, 삭제 진행/완료 문서의 본문 요청은 `DocumentDeletedError`, 정보만 있고 본문이 없으면 `ConsistencyError`다.

### 4.1 문서 모델

- `PublicDocumentMetadata`: `document_id`, `original_filename`, `content_type`, `file_size`, `status`, `created_at`, `updated_at`, 선택 `checksum`, `deleted_at`, `created_by`, `extra_metadata`를 제공한다. `storage_key`는 의도적으로 없다.
- `DocumentMetadata`: 위 필드와 관리 전용 `storage_key`를 포함한다.
- `DocumentStatus`: `uploaded`(과거 호환용), `available`, `deleting`, `deleted`, `failed` 값이다. 새 정상 등록은 `available`을 사용한다. 현재 `uploaded` 사용 자체에 대한 런타임 폐기 경고는 발생하지 않는다.
- `DocumentContent`: 메모리 본문 결과다. `DocumentContentStream`은 같은 설명 필드와 소유 스트림을 제공한다.
- `public_metadata(value) -> PublicDocumentMetadata`: `DocumentMetadata`, `PublicDocumentMetadata` 또는 `UploadDocumentResult`를 공개 안전 투영으로 변환하고 메타데이터 사본을 만든다.

## 5. 삭제·점검·복구 API

- `soft_delete_document(document_id) -> DeleteDocumentResult`: 본문을 제거하고 정보는 삭제 상태로 보존한다.
- `hard_delete_document(document_id) -> DeleteDocumentResult`: 본문과 정보를 제거한다.
- `delete_document(document_id, *, hard_delete=False) -> DeleteDocumentResult`: 논리/완전 삭제를 선택하는 통합 API다. `soft_delete_document()`과 `hard_delete_document()`은 의도를 명확히 하는 동등한 편의 API이며, 현재 이 통합 API는 런타임 폐기 경고를 발생시키지 않는다.
- `DeleteDocumentResult(document_id, deleted, hard_deleted, status)`는 적용된 삭제 형태와 최종 상태를 반환한다. 본문 삭제 실패는 `StorageError`와 실패 상태, 본문 삭제 뒤 정보 처리 실패는 `ConsistencyError`와 삭제 진행 상태를 남긴다.
- `inspect_document(document_id) -> DocumentInspection`: 정보 없음도 오류가 아닌 점검 결과로 반환한다. 결과는 `metadata_exists`, `object_exists`, `status`, `consistent`, `issue`, 그리고 관리·복구 전용 선택 `storage_key`를 제공한다.
- `list_recovery_candidates(*, status, offset=0, limit=100) -> list[DocumentMetadata]`: `failed` 또는 `deleting` 상태만 허용하며 제한은 1~1000이다.
- `reconcile_document(document_id, action, *, storage_key=None, dry_run=False, actor=None) -> ReconciliationResult`: 단일 불일치를 점검·복구하거나 dry run한다.
- `reconcile_documents(*, status, action, offset=0, limit=100, dry_run=False, actor=None) -> BatchReconciliationResult`: 후보 일괄 처리 결과를 반환한다.
- `execute_reconciliation_plan(plan, *, actor=None) -> BatchReconciliationResult`: dry run으로 내보낸 계획을 실행하며 각 항목 직전에 재점검한다.
- `RecoveryIssue`: `none`, `metadata_missing`, `object_missing`, `deletion_incomplete`, `failed_status`.
- `RecoveryAction`: `complete_deletion_soft`, `complete_deletion_hard`, `mark_failed`, `purge_orphan_object`.
- `ReconciliationResult`: 대상, action, 적용 여부, 재점검 결과 및 선택 오류 유형·메시지를 제공한다.
- `BatchReconciliationResult`: `status`, `action`, `dry_run`, `offset`, `limit`, `items`와 계산 속성 `scanned`, `failed`, `eligible`, `applied`, `skipped`를 제공한다. `to_plan()`은 dry run 결과에서만 `ReconciliationPlan`을 만든다.
- `ReconciliationPlanItem(document_id, action, storage_key=None)`, `ReconciliationPlan(status, action, items)`: 실행 가능한 계획이다. 모든 항목 action은 계획 action과 같아야 한다.
- `RecoveryAuditEvent`: audit hook에 전달되는 `document_id`, `action`, `dry_run`, `succeeded`, `applied`, `occurred_at`, 선택 `actor`, `error_type`, `error_message`다. hook 실패는 복구 결과를 가리지 않고 로그로만 남긴다.

## 6. 메타데이터 정책 API

- `MetadataValidator`: `Mapping[str, Any]`를 받아 새 `dict`를 반환하는 호출 가능 계약이다. 입력을 변경하면 안 된다.
- `MetadataNormalizer`: 위와 동일한 normalizer callable 타입 별칭이다.
- `DefaultMetadataPolicy(max_serialized_bytes=16384, max_depth=8, blocked_keys=...)`: JSON 직렬화 가능성, 문자열 키, 깊이, 직렬화 크기 및 민감 키를 검사한 표준 정책이다. 양수 크기와 최소 깊이 1이 필요하다.
- `MetadataValidationIssue(path, code, message)`: 필드 단위 문제다.
- `MetadataSchemaValidationError(issues)`: `ValidationError`의 하위 오류이며 불변 `issues`를 제공한다.
- `StructuredMetadataValidator(parser, schema_version, version_field="schema_version", projector=None, policy=DefaultMetadataPolicy())`: 버전 필드를 확인하고 parser 결과를 mapping으로 투영한 뒤 정책을 적용한다.

## 7. 설정 진단 API

- `diagnose_environment(env) -> EnvironmentDiagnosis`: 연결이나 데이터 변경 없이 전달된 mapping을 검사한다.
- `format_environment_diagnosis(diagnosis) -> str`: secret을 포함하지 않는 운영자용 문자열을 만든다.
- `EnvironmentDiagnosis`: `metadata_backend`, `object_backend`, `healthcheck_enabled`, `missing_required_keys`, `warnings`, `unsupported_keys`, `valid`를 제공한다.

## 8. 오류 계약

모든 SDK 오류는 `DmsError`의 하위 클래스이며 `code`, `retryable`, 선택 `document_id`, 선택 `diagnosis`를 제공한다. `ConfigurationError`는 설정 오류, `ValidationError`는 요청·정책 오류, `DuplicateDocumentError`는 ID 중복, `StorageError`/`MetadataStoreError`는 각 저장소 실패, `ConsistencyError`는 두 저장소 불일치다. `DocumentNotFoundError`와 `DocumentDeletedError`는 조회 상태를 구분한다. `HealthCheckFailedError`는 `service`, `reason`, `retryable=True`을 추가한다. 멱등성 오류와 작업 없음 오류는 3절의 의미를 따른다.
