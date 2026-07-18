# API Reference

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | 구현 기준 |
| 버전 | 0.2 |
| 최종 코드 대조일 | 2026-07-18 |
| 상위 문서 | [PRD](prd.md), [SRS](srs.md) |

## 1. 구현 기준과 공통 규칙

이 문서는 `docmesh_doc/application.py`, `router.py`, `document_http.py`, `schemas.py`, `errors.py`의 현재 동작을 기술한다. 문서 본문은 DMS SDK가 구성한 object store에, metadata는 SDK가 구성한 metadata store에 저장한다.

- ASGI 배포 경로에는 `ROOT_PATH`가 적용된다. 단, 현재 업로드 응답의 `Location`은 `ROOT_PATH`를 조합하지 않고 `/documents/{document_id}`로 생성된다.
- 보호 route는 `fastapi-core`의 bearer 인증 dependency를 사용한다.
- 요청 middleware가 `X-Correlation-ID`를 관리하며 오류 body의 `correlation_id`에도 같은 값을 사용한다.
- 내부 `storage_key`는 `DocumentMetadataResponse`에 포함되지 않는다.
- timestamp는 JSON datetime 문자열로 직렬화된다.

## 2. Endpoint 요약

| 기능 | Method | Path | 인증 | 성공 상태 |
| --- | --- | --- | --- | --- |
| access token | `POST` | `/token` | 불필요 | 200 |
| 현재 사용자 | `GET` | `/user` | 필요 | 200 |
| 문서 생성 | `POST` | `/documents` | 필요 | 201 |
| 문서 목록 | `GET` | `/documents` | 필요 | 200 |
| metadata 조회 | `GET` | `/documents/{document_id}` | 필요 | 200 |
| 전체 콘텐츠 | `GET` | `/documents/{document_id}/content` | 필요 | 200 |
| streaming download | `GET` | `/documents/{document_id}/download` | 필요 | 200 |
| soft delete | `DELETE` | `/documents/{document_id}` | 필요 | 200 |
| hard delete | `DELETE` | `/documents/{document_id}?hard=true` | `document:delete:hard` role | 200 |
| liveness | `GET` | `/health/liveness` | 불필요 | 200 |
| readiness | `GET` | `/health/readiness` | 불필요 | 200 또는 503 |

`/token`, `/user`, health route는 `fastapi-core`가 제공한다. 이 저장소가 직접 구현하는 route는 `/documents*`다.

## 3. 공통 schema

### 3.1 DocumentMetadataResponse

```json
{
  "document_id": "contract-2026-0001",
  "original_filename": "contract.pdf",
  "content_type": "application/pdf",
  "file_size": 24576,
  "status": "available",
  "created_at": "2026-07-11T09:30:00Z",
  "updated_at": "2026-07-11T09:30:00Z",
  "deleted_at": null,
  "created_by": "user-123",
  "checksum": "<sha256>",
  "metadata": {"category": "contract"}
}
```

| 필드 | 타입 | 비고 |
| --- | --- | --- |
| `document_id` | string | 호출자 지정 또는 SDK 생성 ID |
| `original_filename` | string | trim된 upload filename |
| `content_type` | string | upload MIME type |
| `file_size` | integer | byte 수 |
| `status` | string | `uploaded`, `available`, `deleting`, `deleted`, `failed` |
| `created_at`, `updated_at` | datetime | SDK metadata 시각 |
| `deleted_at` | datetime/null | soft delete 전에는 `null` |
| `created_by` | string/null | 현재 route에서는 인증 사용자 `sub` |
| `checksum` | string/null | 요청값 또는 SDK 계산값 |
| `metadata` | object | SDK의 `extra_metadata`를 alias로 직렬화 |

### 3.2 DeleteDocumentResponse

```json
{
  "document_id": "contract-2026-0001",
  "deleted": true,
  "hard_deleted": false,
  "status": "deleted"
}
```

### 3.3 오류 envelope

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "01J..."
  }
}
```

FastAPI request validation 오류도 `400 VALIDATION_ERROR`로 정규화한다.

| HTTP | 코드 | 구현 매핑 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | DMS validation 또는 FastAPI request validation |
| 401 | `UNAUTHENTICATED` | 인증 실패 HTTP 오류 |
| 403 | `FORBIDDEN` | 권한 부족 HTTP 오류 |
| 404 | `NOT_FOUND` | 등록되지 않은 일반 경로 |
| 404 | `DOCUMENT_NOT_FOUND` | DMS document 없음 또는 읽기 시 soft-deleted 상태 |
| 404 | `UPLOAD_OPERATION_NOT_FOUND` | DMS upload operation 없음 |
| 409 | `DOCUMENT_ALREADY_EXISTS` | 중복 document ID |
| 409 | `IDEMPOTENCY_CONFLICT` | DMS idempotency 충돌 |
| 409 | `IDEMPOTENCY_IN_PROGRESS` | DMS idempotency 작업 진행 중 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | metadata/object 정합성 오류 |
| 500 | `INTERNAL_ERROR` | 매핑되지 않은 DMS/HTTP 500 오류 |
| 503 | `SERVICE_CONFIGURATION_ERROR` | DMS 구성 오류 |
| 503 | `DEPENDENCY_UNAVAILABLE` | DMS health 또는 일반 503 오류 |
| 503 | `METADATA_STORE_ERROR` | metadata store 오류 |
| 503 | `OBJECT_STORAGE_ERROR` | object store 오류 |

현재 HTTP document route는 idempotency key나 upload-operation endpoint를 노출하지 않지만 전역 DMS mapper에는 해당 오류가 등록되어 있다.

## 4. 문서 API

### 4.1 `POST /documents`

`multipart/form-data`를 받아 `dms.UploadDocumentStreamRequest`를 만들고 `sdk.upload_document_stream(request)`를 호출한다.

| Form field | 타입 | 필수 | 규칙 |
| --- | --- | --- | --- |
| `file` | file | 예 | size > 0, trim된 filename이 비어 있지 않고 `.`이 아니며 content type이 필요 |
| `document_id` | string | 아니오 | 빈 값이면 SDK 생성 |
| `metadata` | JSON string | 아니오 | 기본 `{}`; JSON object만 허용 |
| `checksum` | string | 아니오 | 빈 값이면 SDK에 `None` 전달 |

`created_by` form field는 없다. 항상 인증 사용자의 `user.sub`를 사용한다. 성공 body는 `DocumentMetadataResponse`이며 `Location: /documents/{document_id}`를 반환한다.

```bash
curl --request POST "$BASE_URL/documents" \
  --oauth2-bearer TOKEN_VALUE \
  --form "file=@./contract.pdf;type=application/pdf" \
  --form 'document_id=contract-2026-0001' \
  --form-string 'metadata={"category":"contract"}'
```

### 4.2 `GET /documents`

| Query | 타입 | 기본값 | 검증 |
| --- | --- | --- | --- |
| `offset` | integer | `0` | 0 이상 |
| `limit` | integer | `100` | 1 이상; 구현상 상한 없음 |
| `status` | DocumentStatus | 없음 | `uploaded`, `available`, `deleting`, `deleted`, `failed` |

`sdk.list_documents(...)` 결과 각각을 `dms.public_metadata(...)`로 변환한다. soft-deleted 항목도 SDK 목록 결과에 포함될 수 있으며 `status` filter로 조회할 수 있다.

### 4.3 `GET /documents/{document_id}`

`sdk.get_document_metadata(document_id)`를 호출한다. 반환 상태가 `deleted`이면 `DOCUMENT_NOT_FOUND`로 변환하고, 그 외 상태는 공개 metadata로 반환한다.

### 4.4 `GET /documents/{document_id}/content`

읽기 가능한 metadata인지 먼저 확인한 다음 `sdk.get_document_content(...)`의 bytes를 한 번에 반환한다.

- `Content-Type`: SDK content type
- `Content-Length`: SDK size
- `Content-Disposition`: `inline; filename*=UTF-8''<percent-encoded-filename>`

### 4.5 `GET /documents/{document_id}/download`

읽기 가능한 metadata인지 먼저 확인한 다음 `sdk.get_document_content_stream(document_id, chunk_size=...)`을 호출한다.

| Query | 기본값 | 검증 |
| --- | --- | --- |
| `chunk_size` | `65536` | 1 이상의 integer |

response generator는 `item.iter_chunks()`를 전달하고 `finally`에서 `item.close()`를 호출한다.

- `Content-Type`: SDK content type
- `Content-Length`: SDK size
- `Content-Disposition`: `attachment; filename*=UTF-8''<percent-encoded-filename>`

### 4.6 `DELETE /documents/{document_id}`

`hard`의 기본값은 `false`다.

- `hard=false`: `sdk.soft_delete_document(document_id)`
- `hard=true`: 사용자 role에 `document:delete:hard`가 있는지 먼저 검사한 뒤 `sdk.hard_delete_document(document_id)`
- boolean으로 해석할 수 없는 `hard` 값: `400 VALIDATION_ERROR`
- 권한 없는 hard delete: `403 FORBIDDEN`

현재 DMS SDK의 soft delete는 object를 삭제하고 metadata 상태와 `deleted_at`을 보존한다. hard delete는 object와 metadata 행을 제거한다.

## 5. Health API

### 5.1 `GET /health/liveness`

프로세스 생존만 나타내며 DMS store를 검사하지 않는다.

```json
{"status":"ok","details":null}
```

### 5.2 `GET /health/readiness`

애플리케이션은 다음 resource를 등록한다.

- 이름: `dms`
- 필수 여부: `true`
- check: `sdk.check_health().ok`

따라서 기본 응답은 PostgreSQL·MinIO 개별 detail이 아니라 `details.dms`를 포함한다.

```json
{
  "status": "ok",
  "details": {
    "dms": {
      "ok": true,
      "latency_ms": 4,
      "error": null,
      "required": true,
      "enabled": true
    }
  }
}
```

필수 `dms` check가 실패하면 503/`error`다. `fastapi-core`의 선택 service check가 별도로 등록되고 그것만 실패하면 200/`degraded`가 될 수 있다.

## 6. OpenAPI와 테스트의 현재 한계

- OpenAPI는 보호 route의 security requirement와 JSON 성공 response model을 생성한다.
- 런타임 validation은 400이지만 생성된 OpenAPI에는 FastAPI 기본 422 response가 남는다.
- 공통 오류 response와 binary/streaming media schema는 endpoint별 OpenAPI response로 선언되어 있지 않다.
- 현재 자동화 테스트는 정상 streaming 소비 후 `close()`를 검증한다. iterator 예외와 client disconnect는 별도 테스트하지 않는다.
- 현재 저장소 통합 테스트는 upload, 목록·metadata, streaming download, SDK health를 검증한다. HTTP hard delete는 test user에게 `document:delete:hard` role이 있을 때만 실행되고 없으면 skip된다. HTTP `/content`, soft delete, HTTP readiness, 저장소 장애 주입은 아직 통합 테스트하지 않는다.
