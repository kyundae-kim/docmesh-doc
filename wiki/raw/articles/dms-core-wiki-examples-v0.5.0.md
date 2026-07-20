---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/Examples-v0.5.0.md
ingested: 2026-07-20
sha256: e79a382fe3c4ee60d5cdc7c78e601693547c3e1491a5b4c462e97b78e57ba8de
---
# 사용 예제

모든 예제는 package root의 공개 이름만 사용한다. 실제 secret은 코드·저장소에 넣지 말고 환경 또는 배포 비밀 관리로 제공한다.

## 1. 환경 조립, 등록, 조회

```python
from dms import UploadDocumentRequest, create_sdk_from_environment

with create_sdk_from_environment() as sdk:
    result = sdk.upload_document(UploadDocumentRequest(
        document_id="invoice-42", content=b"invoice", filename="invoice.txt",
        content_type="text/plain", metadata={"schema_version": "1"},
        idempotency_key="request-42", idempotency_scope="billing:tenant-a",
    ))
    metadata = sdk.get_document_metadata(result.document_id)
    body = sdk.get_document_content(result.document_id)
    print(metadata.original_filename, body.size, result.created)
```

## 2. 구성요소 조립과 명시적 종료

```python
from dms import create_sdk_from_components

# metadata_store와 object_store는 애플리케이션의 어댑터다.
sdk = create_sdk_from_components(
    metadata_store=metadata_store,
    object_store=object_store,
    max_file_size=10 * 1024 * 1024,
    service_checks={"metadata": metadata_store.health_check},
    close_callbacks=[metadata_store.close, object_store.close],
)
try:
    print(sdk.check_health().ok)
finally:
    sdk.close()
```

## 3. 멱등성 상태 확인과 오류 처리

```python
from dms import (
    IdempotencyConflictError, IdempotencyInProgressError,
    UploadOperationNotFoundError,
)

try:
    operation = sdk.get_upload_operation(
        scope="billing:tenant-a", idempotency_key="request-42"
    )
    print(operation.state, operation.document_id)
except IdempotencyInProgressError:
    # 같은 범위·키의 등록이 아직 끝나지 않았다. 나중에 재시도한다.
    pass
except IdempotencyConflictError:
    # 같은 키가 다른 요청에 사용되었다. 새 키로 요청한다.
    pass
except UploadOperationNotFoundError:
    pass
```

## 4. 알려진 길이와 미지 길이 스트림

```python
from hashlib import sha256
from io import BytesIO
from dms import UploadDocumentStreamRequest, UploadDocumentUnknownSizeStreamRequest

payload = b"streamed document"
known = sdk.upload_document_stream(UploadDocumentStreamRequest(
    stream=BytesIO(payload), size=len(payload), filename="report.bin",
    content_type="application/octet-stream", checksum=sha256(payload).hexdigest(),
))

unknown = sdk.upload_document_unknown_size_stream(UploadDocumentUnknownSizeStreamRequest(
    stream=source_stream, max_size=50 * 1024 * 1024, filename="import.dat",
    content_type="application/octet-stream", chunk_size=64 * 1024,
))
```

SDK는 호출자가 제공한 입력 스트림을 닫지 않는다. 알려진 길이 요청의 `size`와 checksum은 실제 바이트와 일치해야 한다.

## 5. 메타데이터 스키마 정책 주입

```python
from dms import StructuredMetadataValidator, create_sdk_from_components

def parse_metadata(value):
    if "customer_id" not in value:
        raise ValueError("customer_id is required")
    return value

validator = StructuredMetadataValidator(
    parser=parse_metadata, schema_version="2026-01"
)
sdk = create_sdk_from_components(
    metadata_store=metadata_store, object_store=object_store,
    metadata_validator=validator,
)
```

기본 정책은 JSON 가능 값, 문자열 키, 크기·깊이 제한 및 민감 키 차단을 적용한다. 스키마 버전 오류는 필드별 `MetadataSchemaValidationError.issues`로 확인한다.

## 6. 본문 스트림과 cursor 목록

```python
with sdk.get_document_content_stream("invoice-42") as response:
    with open("invoice.txt", "wb") as target:
        for chunk in response.iter_chunks():
            target.write(chunk)

page = sdk.list_documents_page(limit=100)
while True:
    for item in page.items:
        print(item.document_id)
    if not page.has_more:
        break
    page = sdk.list_documents_page(cursor=page.next_cursor, limit=100)
```

cursor는 불투명하며 생성 시각·문서 ID 내림차순이다. status를 지정했다면 다음 페이지에도 같은 status를 제공한다.

## 7. 삭제와 dry-run 복구 계획

```python
from dms import DocumentStatus, RecoveryAction

sdk.soft_delete_document("invoice-42")

preview = sdk.reconcile_documents(
    status=DocumentStatus.DELETING,
    action=RecoveryAction.COMPLETE_DELETION_SOFT,
    dry_run=True,
    limit=100,
)
plan = preview.to_plan()
result = sdk.execute_reconciliation_plan(plan, actor="maintenance-job")
print(result.scanned, result.applied, result.failed)
```

단일 orphan 본문 제거는 정보 없는 상태를 확인한 뒤 `RecoveryAction.PURGE_ORPHAN_OBJECT`와 관리 경로에서 얻은 `storage_key`를 명시하여 수행한다. 저장 위치는 외부 응답에 노출하지 않는다.

## 8. 설정 진단과 예외 분기

```python
import os
from dms import (
    ConfigurationError, create_sdk_from_environment, diagnose_environment,
    format_environment_diagnosis,
)

diagnosis = diagnose_environment(dict(os.environ))
if not diagnosis.valid:
    print(format_environment_diagnosis(diagnosis))

try:
    sdk = create_sdk_from_environment()
except ConfigurationError as exc:
    # exc.diagnosis는 구조화된 secret-safe 진단 결과다.
    print(format_environment_diagnosis(exc.diagnosis))
    raise
```

자세한 환경 변수와 선택 우선순위는 [설정 참조](configuration.md)를, 전체 시그니처·모델·오류는 [공개 API 참조](api-reference.md)를 참고한다.
