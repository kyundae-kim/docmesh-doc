---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/API-Reference-v0.4.0.md
ingested: 2026-07-18
sha256: 1fb7094ec67b80fe202e8ac3557a42c930343149ea5fd4e7a1af93397fb8609b
---
# 공개 API 계약

이 문서는 `from dms import ...`로 가져올 수 있는 공개 심볼과 `DefaultDocumentManagementSDK`의 공개 메서드를 추적합니다. 저장소 어댑터 구현, `storage_key`, 커서 내부 형식 및 내부 요청 객체는 공개 계약이 아닙니다.

## 공개 진입점

| 구분 | 공개 심볼 | 계약 및 상세 문서 |
| --- | --- | --- |
| SDK 조립 | `create_sdk_from_environment`, `create_sdk_from_components`, `diagnose_environment`, `DefaultDocumentManagementSDK` | [설정과 조립](#설정-조립-상태-확인-종료), `docs/config.md` |
| 등록 | `UploadDocumentRequest`, `UploadDocumentStreamRequest`, `UploadDocumentUnknownSizeStreamRequest`, `UploadDocumentResult`, `UploadOperationResult` | [등록과 멱등성](#등록과-멱등성) |
| 조회 | `DocumentMetadata`, `PublicDocumentMetadata`, `DocumentContent`, `DocumentContentStream`, `DocumentPage`, `public_metadata` | [조회와 목록](#조회와-목록) |
| 삭제 | `DeleteDocumentResult` | [삭제](#삭제) |
| 복구 | `DocumentInspection`, `RecoveryIssue`, `RecoveryAction`, `ReconciliationResult`, `BatchReconciliationResult`, `ReconciliationPlan`, `ReconciliationPlanItem`, `RecoveryAuditEvent` | [점검과 복구](#점검과-복구) |
| 메타데이터 정책 | `MetadataValidator`, `MetadataNormalizer`, `DefaultMetadataPolicy`, `StructuredMetadataValidator`, `MetadataValidationIssue`, `MetadataSchemaValidationError` | [메타데이터 검증](#메타데이터-검증) |
| 상태 | `DocumentStatus`, `HealthStatus`, `ServiceHealth` | [상태 모델](#상태-모델) |
| 오류 | `DmsError` 및 하위 타입 | [오류](#오류) |

## 상태 모델

`DocumentStatus`는 `UPLOADED`, `AVAILABLE`, `DELETING`, `DELETED`, `FAILED`를 갖습니다. `UPLOADED`는 역직렬화 호환용 legacy 값이며 정상 등록은 `AVAILABLE`을 만듭니다. `HealthStatus`는 전체 `ok`, 서비스별 `ServiceHealth` 목록, `checked_at`을 제공하며 서비스 항목은 서비스명, 정상 여부, 선택 지연 시간과 오류를 갖습니다.

## 등록과 멱등성

### 요청과 결과

| 타입 | 필수 필드 | 선택 필드 | 반환/제약 |
| --- | --- | --- | --- |
| `UploadDocumentRequest` | `content: bytes`, `filename`, `content_type` | `document_id`, `metadata`, `created_by`, `checksum`, `idempotency_key`, `idempotency_scope` | `upload_document(request) -> UploadDocumentResult`; 빈 본문은 허용하지 않으며 checksum을 생략하면 SDK가 SHA-256을 계산합니다. |
| `UploadDocumentStreamRequest` | `stream`, 양수 `size`, `filename`, `content_type` | 위 선택 필드와 양수 `chunk_size`(기본 65,536) | `upload_document_stream(request) -> UploadDocumentResult`; 실제 읽은 바이트가 `size`와 다르거나 제공 checksum과 다르면 `ValidationError`이며 업로드된 본문을 롤백합니다. 입력 스트림은 호출자가 닫습니다. |
| `UploadDocumentUnknownSizeStreamRequest` | `stream`, 양수 `max_size`, `filename`, `content_type` | `document_id`, `metadata`, `created_by`, 양수 `chunk_size`, 멱등 필드 | `upload_document_unknown_size_stream(request) -> UploadDocumentResult`; 최대 크기까지 임시 spool에 복사해 크기와 SHA-256을 계산합니다. `max_size`는 구성된 `max_file_size` 이하여야 하며 초과 시 저장 전에 실패합니다. 입력 스트림은 호출자가 닫습니다. |
| `UploadDocumentResult` | - | - | `document_id`, 내부 `storage_key`, `metadata: DocumentMetadata`, `created`를 제공합니다. 공개 응답에는 `public_metadata()`를 사용합니다. |

파일명과 `content_type`은 비어 있으면 안 됩니다. 파일명은 내부 저장 키를 만들 때 경로 구분자와 `..`가 정규화되며, 정규화 결과가 빈 값이나 `.`이면 거부됩니다. 명시 `document_id`가 이미 있으면 `DuplicateDocumentError`입니다. 본문 저장 뒤 메타데이터 기록이 실패하면 SDK는 본문 롤백을 시도하고, 롤백 불가 또는 일관성 실패는 `ConsistencyError`입니다.

### 멱등 등록과 작업 조회

세 등록 요청은 `idempotency_key`와 `idempotency_scope`를 지원합니다. 키를 쓸 때는 테넌트·사용자 등 재시도 충돌 경계를 `idempotency_scope`에 명시해야 합니다. 범위를 생략하면 호환을 위해 `created_by`, 그마저 없으면 `anonymous`를 사용하며 `DeprecationWarning`이 발생합니다. 스트림 멱등 등록은 SHA-256 `checksum`이 필수입니다.

완료된 동일 요청은 기존 문서 정보와 `created=False`를 반환합니다. 같은 범위와 키를 다른 요청에 쓰면 `IdempotencyConflictError`, 진행 중인 요청이면 `IdempotencyInProgressError`입니다. 실패 요청은 같은 요청으로 재시도할 수 있고 최초에 확보한 문서 식별자를 재사용합니다.

`get_upload_operation(scope=..., idempotency_key=...) -> UploadOperationResult`는 정확한 범위·키의 `PENDING`/`SUCCEEDED`/`FAILED` 상태, 문서 ID, 생성·갱신 시각을 반환합니다. 빈 값은 `ValidationError`, 영속 작업 저장소가 없으면 `ValidationError`, 대상이 없으면 `UploadOperationNotFoundError`입니다. fingerprint는 공개하지 않습니다.

## 조회와 목록

| 메서드/함수 | 반환 | 계약 |
| --- | --- | --- |
| `get_document_metadata(document_id)` | `DocumentMetadata` | 문서 정보와 내부 `storage_key`를 반환합니다. 대상 없음은 `DocumentNotFoundError`입니다. |
| `get_document_content(document_id)` | `DocumentContent` | 메모리의 본문 bytes, 파일명, MIME 타입, 크기, checksum을 반환합니다. 메타데이터는 있으나 본문이 없으면 `ConsistencyError`입니다. |
| `get_document_content_stream(document_id, chunk_size=65536)` | `DocumentContentStream` | 스트리밍 본문입니다. `chunk_size`는 양수여야 하며 반환값을 닫아야 합니다. |
| `list_documents(offset=0, limit=100, status=None)` | `list[DocumentMetadata]` | 기존 offset 목록입니다. `offset >= 0`, `limit > 0`입니다. |
| `list_documents_page(cursor=None, limit=100, status=None)` | `DocumentPage` | 안정적인 cursor 목록입니다. limit은 1~1000입니다. |
| `public_metadata(value)` | `PublicDocumentMetadata` | `DocumentMetadata` 또는 `UploadDocumentResult`를 독립 복사해 `storage_key` 없이 반환합니다. |

`DocumentMetadata`는 `document_id`, 원본 파일명, 콘텐츠 타입, 파일 크기, 내부 `storage_key`, 상태, 생성·갱신 시각, 선택 checksum·삭제 시각·생성자·부가 메타데이터를 제공합니다. `PublicDocumentMetadata`는 이 중 `storage_key`를 제외합니다. `storage_key`는 어댑터와 복구용 내부 필드이므로 외부 URL·영구 공개 식별자로 노출, 저장, 조합하지 마십시오.

`DocumentContentStream`은 `iter_chunks(chunk_size=None)`과 `close()`를 제공하고 컨텍스트 관리자로 사용할 수 있습니다. 커서 목록 정렬은 `created_at DESC, document_id DESC`입니다. `next_cursor`는 다음 페이지가 있을 때만 있는 불투명 문자열입니다. 호출자는 이를 해석·변경하지 말고 다음 요청에 같은 `status`와 함께 전달해야 합니다. 너무 길거나 잘못된 커서, 다른 상태 필터로의 재사용은 `ValidationError`입니다.

## 삭제

| 메서드 | 반환 | 효과 |
| --- | --- | --- |
| `soft_delete_document(document_id)` | `DeleteDocumentResult` | 본문을 제거하고 메타데이터를 `DELETED`로 보존합니다. |
| `hard_delete_document(document_id)` | `DeleteDocumentResult` | 본문과 메타데이터를 제거합니다. |
| `delete_document(document_id, hard_delete=False)` | `DeleteDocumentResult` | 호환용 통합 API입니다. |

삭제는 먼저 상태를 `DELETING`으로 바꾼 뒤 본문을 지웁니다. 본문 삭제 실패 시 최선 노력으로 `FAILED`를 기록하고 `StorageError`를 냅니다. 본문은 삭제됐으나 메타데이터 완료가 실패하면 `DELETING` 상태를 남기고 `ConsistencyError`를 냅니다. 이 상태는 복구 API로 처리합니다.

## 점검과 복구

| 메서드 | 반환 | 계약 |
| --- | --- | --- |
| `inspect_document(document_id)` | `DocumentInspection` | 메타데이터/본문 존재, 상태, 일관성 및 `RecoveryIssue`를 반환합니다. 메타데이터가 없어도 결과(`METADATA_MISSING`)이며 not-found 예외가 아닙니다. |
| `list_recovery_candidates(status, offset=0, limit=100)` | `list[DocumentMetadata]` | `FAILED` 또는 `DELETING` 상태만 허용합니다. limit은 1~1000입니다. |
| `reconcile_document(document_id, action, storage_key=None, dry_run=False, actor=None)` | `ReconciliationResult` | 한 건을 점검·복구하거나 dry-run합니다. |
| `reconcile_documents(status, action, offset=0, limit=100, dry_run=False, actor=None)` | `BatchReconciliationResult` | 후보 묶음을 처리하며 개별 오류는 `items`에 구조화해 나머지를 계속 처리합니다. |
| `execute_reconciliation_plan(plan, actor=None)` | `BatchReconciliationResult` | dry-run에서 만든 계획을 실제 실행합니다. 각 항목 직전에 다시 점검합니다. |

`RecoveryAction`은 `COMPLETE_DELETION_SOFT`, `COMPLETE_DELETION_HARD`, `MARK_FAILED`, `PURGE_ORPHAN_OBJECT`입니다. 고아 본문 제거는 메타데이터가 없고 명시 `storage_key`에 본문이 있을 때만 가능합니다. 삭제 완료는 `DELETING` 메타데이터와 없는 본문을, 실패 표시는 기존 메타데이터와 없는 본문을 요구합니다.

`BatchReconciliationResult`는 `scanned`, `eligible`, `applied`, `skipped`, `failed` 요약 속성을 제공합니다. dry-run 결과만 `to_plan() -> ReconciliationPlan`을 호출할 수 있고, 계획 항목은 불변 tuple입니다. 실행은 preview 결과를 신뢰하지 않아 stale 항목을 항목별 오류로 반환합니다. 시도마다 `RecoveryAuditEvent`가 생성되며 factory의 `recovery_audit_hook`은 best-effort입니다. hook 예외는 로그만 남기고 복구 결과를 바꾸지 않습니다.

## 메타데이터 검증

모든 등록의 `metadata`는 등록 전에 `MetadataValidator` callable로 정규화됩니다. 기본 `DefaultMetadataPolicy`는 JSON 직렬화 가능 여부, 문자열 키, 깊이(기본 8), 직렬화 바이트(기본 16,384), 대소문자 비구분 민감 키를 검사하고 독립 JSON 호환 사본을 만듭니다. 차단 키에는 `password`, `passwd`, `secret`, `token`, `api_key`, `access_token`, `authorization`, `credential`, `private_key` 등이 포함됩니다. 위반은 `ValidationError`입니다.

`StructuredMetadataValidator(parser, schema_version, version_field="schema_version", projector=None, policy=...)`는 의존성 없는 스키마 어댑터입니다. version field를 먼저 확인하고 parser/projector의 mapping 결과도 policy에 통과시킵니다. 구조화된 실패는 `MetadataSchemaValidationError.issues`의 `MetadataValidationIssue(path, code, message)`로 제공합니다.

## 설정 조립 상태 확인 종료

- `diagnose_environment(env) -> EnvironmentDiagnosis`: 외부 연결·데이터 변경 없이 선택된 저장소, 상태 확인 활성 여부, 누락 필수 키, 경고, 유효성을 반환합니다.
- `create_sdk_from_environment(env, logger=None, metadata_validator=None, metadata_max_serialized_bytes=16384, metadata_max_depth=8, recovery_audit_hook=None)`: PostgreSQL 또는 SQLite 문서 정보 저장소와 MinIO 본문 저장소를 환경에서 조립합니다.
- `create_sdk_from_components(metadata_store, object_store, ..., id_generator=None, service_checks=None, close_callbacks=None, max_file_size=None, operation_store=None, metadata_validator=None, metadata_max_serialized_bytes=16384, metadata_max_depth=8, recovery_audit_hook=None)`: 호출자가 제공한 저장소 어댑터로 SDK를 조립합니다. `metadata_store`와 `object_store`는 필수입니다.
- `check_health() -> HealthStatus`: 구성된 서비스별 `ServiceHealth(service, ok, latency_ms, error)` 및 전체 `ok`, `checked_at`을 반환합니다. 빈 검사 집합은 정상입니다.
- `close()`: 정리 callback을 한 번만 실행합니다. callback 실패는 `MetadataStoreError`입니다. SDK도 `with` 컨텍스트 관리자를 지원합니다.

환경 변수, 자동 선택, 상태 확인 세부 사항은 `docs/config.md`를 따르십시오.

## 오류

모든 공개 오류의 기반은 `DmsError`입니다.

| 오류 | 의미 및 호출자 조치 |
| --- | --- |
| `ConfigurationError` | 설정 선택 또는 조립이 유효하지 않습니다. 환경/구성요소를 수정합니다. |
| `ValidationError` | 요청, 페이지, 메타데이터 또는 복구 조건이 잘못됐습니다. 수정 후 새 호출을 합니다. |
| `MetadataSchemaValidationError` | 구조화된 메타데이터 스키마 오류입니다. `issues`를 사용자 입력 오류로 매핑합니다. |
| `DocumentNotFoundError` | 문서 ID가 없습니다. 이미 삭제됐는지 포함해 처리합니다. |
| `DuplicateDocumentError` | 명시 문서 ID가 이미 있습니다. 다른 ID 또는 멱등 키 흐름을 사용합니다. |
| `IdempotencyInProgressError` | 같은 키 작업이 진행 중입니다. 지연 뒤 상태 조회 또는 재시도합니다. |
| `IdempotencyConflictError` | 같은 범위·키가 다른 요청에 사용됐습니다. 새 키를 사용합니다. |
| `UploadOperationNotFoundError` | 정확한 범위·키의 작업이 없습니다. |
| `StorageError` / `MetadataStoreError` | 저장소 접근이 실패했습니다. 상태 확인 후 백오프 재시도합니다. |
| `ConsistencyError` | 본문과 메타데이터가 어긋났습니다. 재시도 전 점검·복구 API로 확인합니다. |
| `HealthCheckFailedError` | 환경 기반 시작 상태 확인이 실패했습니다. 의존 서비스를 복구하거나 설정을 검토합니다. |
