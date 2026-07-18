---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/Examples-v0.4.0.md
ingested: 2026-07-18
sha256: e0b0f2f0d4061d6a2e2fed0b8209d9fbf9b842c38c04b675e2c96fa5460be875
---
# SDK 사용 예시

모든 예시는 `from dms import ...` 공개 API만 사용합니다. 환경 변수와 선택 규칙은 `docs/config.md`, 전체 타입·오류 계약은 `docs/api.md`를 참고하십시오.

## 환경 기반 빠른 시작

```python
from os import environ
from dms import UploadDocumentRequest, create_sdk_from_environment, public_metadata

with create_sdk_from_environment(environ) as sdk:
    result = sdk.upload_document(UploadDocumentRequest(
        content=b"hello",
        filename="hello.txt",
        content_type="text/plain",
        metadata={"category": "sample"},
    ))
    response_payload = public_metadata(result)
    print(response_payload.document_id)
```

`storage_key`는 내부 필드입니다. HTTP 응답, 외부 URL, 영구 공개 식별자로 사용하지 말고 `public_metadata()` 결과를 외부에 전달합니다.

## 명시 구성요소 조립과 수명 관리

```python
from dms import create_sdk_from_components

sdk = create_sdk_from_components(
    metadata_store=application_metadata_store,
    object_store=application_object_store,
    max_file_size=20 * 1024 * 1024,
    service_checks={
        "metadata": application_metadata_store.check_health,
        "object": application_object_store.check_health,
    },
    close_callbacks=[application_metadata_store.close, application_object_store.close],
)
try:
    health = sdk.check_health()
    if not health.ok:
        raise RuntimeError(health.services)
finally:
    sdk.close()
```

사용자 제공 저장소 객체가 상태 확인 또는 종료 메서드를 제공하지 않으면 해당 callback을 전달하지 않습니다. `close()`는 callback을 한 번만 실행합니다.

## 바이트 등록과 멱등 재시도

```python
from dms import UploadDocumentRequest

request = UploadDocumentRequest(
    content=b"contract",
    filename="contract.txt",
    content_type="text/plain",
    idempotency_key="upload-2026-001",
    idempotency_scope="tenant-a",
)
first = sdk.upload_document(request)
second = sdk.upload_document(request)
assert first.created is True
assert second.created is False
```

같은 범위·키에는 같은 요청만 사용합니다. `IdempotencyInProgressError`면 잠시 기다렸다가 작업 상태를 조회하거나 같은 요청을 재시도하고, `IdempotencyConflictError`면 새 키를 사용합니다.

## 업로드 작업 상태 조회

```python
from dms import UploadOperationNotFoundError

try:
    operation = sdk.get_upload_operation(
        scope="tenant-a",
        idempotency_key="upload-2026-001",
    )
except UploadOperationNotFoundError:
    operation = None

if operation is not None:
    print(operation.state, operation.document_id, operation.updated_at)
```

이 기능은 `operation_store`가 구성돼야 합니다. 환경 기반 SDK는 이를 구성하며, 구성요소 기반 SDK에서는 호출자가 제공합니다.

## 크기를 아는 스트림 등록

```python
from hashlib import sha256
from io import BytesIO
from dms import UploadDocumentStreamRequest

payload = b"streamed document"
result = sdk.upload_document_stream(UploadDocumentStreamRequest(
    stream=BytesIO(payload),
    size=len(payload),
    filename="stream.txt",
    content_type="text/plain",
    checksum=sha256(payload).hexdigest(),
    idempotency_key="stream-001",
    idempotency_scope="tenant-a",
))
```

실제 스트림은 선언한 크기와 정확히 일치해야 합니다. 멱등 스트림 등록은 checksum이 필수입니다. SDK는 입력 스트림을 닫지 않으므로 호출자가 소유권을 유지합니다.

## 크기를 모르는 스트림 등록

```python
from dms import UploadDocumentUnknownSizeStreamRequest

result = sdk.upload_document_unknown_size_stream(
    UploadDocumentUnknownSizeStreamRequest(
        stream=incoming_stream,
        max_size=20 * 1024 * 1024,
        filename="incoming.pdf",
        content_type="application/pdf",
        idempotency_key="unknown-size-001",
        idempotency_scope="tenant-a",
    )
)
```

SDK가 임시 spool로 크기와 SHA-256을 계산합니다. `max_size`는 양수이며 SDK의 `max_file_size`를 초과할 수 없습니다. 초과 입력은 저장 전에 `ValidationError`가 발생합니다.

## 메타데이터 스키마 연결

```python
from dms import StructuredMetadataValidator, create_sdk_from_components

validator = StructuredMetadataValidator(
    schema_version="1",
    parser=ArticleModel.parse,
    projector=lambda model: model.to_dict(),
)
sdk = create_sdk_from_components(
    metadata_store=metadata_store,
    object_store=object_store,
    metadata_validator=validator,
)
```

parser 또는 projector의 최종 mapping은 기본 정책을 다시 통과합니다. 스키마 오류를 세부 항목으로 처리하려면 `MetadataSchemaValidationError.issues`를 확인합니다.

## 문서 조회와 본문 스트림 닫기

```python
metadata = sdk.get_document_metadata("doc-1")
content = sdk.get_document_content("doc-1")
print(metadata.original_filename, content.size)

with sdk.get_document_content_stream("doc-1", chunk_size=64 * 1024) as stream:
    for chunk in stream.iter_chunks():
        consume(chunk)
```

전체 본문이 필요할 때만 `get_document_content()`를 사용합니다. 큰 문서는 `get_document_content_stream()`을 사용하고 `with`로 연결을 닫습니다.

## 커서 페이지 순회

```python
from dms import DocumentStatus

cursor = None
while True:
    page = sdk.list_documents_page(
        cursor=cursor,
        limit=50,
        status=DocumentStatus.AVAILABLE,
    )
    for metadata in page.items:
        print(metadata.document_id)
    if not page.has_more:
        break
    cursor = page.next_cursor
```

`next_cursor`는 불투명 값입니다. 해석·수정하지 말고 다음 요청에 동일한 `status`와 전달합니다. 기존 offset API가 필요하면 `sdk.list_documents(offset=0, limit=100, status=None)`을 사용합니다.

## 명시적 삭제

```python
soft_result = sdk.soft_delete_document("doc-1")
hard_result = sdk.hard_delete_document("doc-2")

# 호환용 통합 API
legacy_result = sdk.delete_document("doc-3", hard_delete=True)
```

soft delete는 본문을 지우고 `DELETED` 메타데이터를 남깁니다. hard delete는 둘 다 지웁니다. `ConsistencyError`가 나면 삭제가 부분 완료됐을 수 있으므로 복구 전에 점검합니다.

## 점검, dry-run 복구 계획, 실제 실행

```python
from dms import DocumentStatus, RecoveryAction

def audit(event):
    audit_sink.write(event)  # 예외가 나도 복구 결과에는 영향 없음

preview = sdk.reconcile_documents(
    status=DocumentStatus.FAILED,
    action=RecoveryAction.MARK_FAILED,
    dry_run=True,
    actor="operator-42",
)
plan = preview.to_plan()
result = sdk.execute_reconciliation_plan(plan, actor="operator-42")
print(result.scanned, result.applied, result.failed)
```

계획 실행은 각 항목의 현재 상태를 다시 점검합니다. preview 뒤 상태가 바뀐 stale 항목은 항목별 오류가 되며 다른 항목은 계속 처리합니다. 감사가 필요하면 SDK 조립 때 `recovery_audit_hook=audit`을 전달합니다.

## 환경 진단과 오류 분기

```python
from os import environ
from dms import ConfigurationError, diagnose_environment

report = diagnose_environment(environ)
if not report.valid:
    raise ConfigurationError(", ".join(report.missing_required_keys))
if report.warnings:
    print("configuration warnings:", report.warnings)
```

등록 입력 오류는 `ValidationError`, 없는 문서는 `DocumentNotFoundError`, 저장소 접근 실패는 `StorageError` 또는 `MetadataStoreError`, 본문·메타데이터 불일치는 `ConsistencyError`로 구분해 처리합니다.
