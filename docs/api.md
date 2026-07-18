# API Reference

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 상위 문서 | [PRD](prd.md), [SRS](srs.md) |

## 1. 개요

DocMesh Document Service는 `dms-core` 문서 lifecycle을 HTTP API로 제공한다. 문서 metadata는 PostgreSQL에, 본문은 MinIO에 저장한다.

모든 URI는 `ROOT_PATH`가 설정된 경우 해당 경로를 앞에 붙인다. 예를 들어 `ROOT_PATH=/api`이면 `GET /documents/{document_id}`의 실제 공개 URI는 `GET /api/documents/{document_id}`다.

### 1.1 API 표기 규칙

- 본문 요청과 JSON 응답은 UTF-8을 사용한다.
- timestamp는 UTC ISO 8601/RFC 3339 형식(예: `2026-07-11T09:30:00Z`)이다.
- 모든 DMS 응답은 `X-Correlation-ID` header를 포함한다.
  - 요청자가 같은 header를 보내면 서비스는 유효한 값을 재사용할 수 있다.
  - 없거나 유효하지 않으면 서비스가 새 값을 생성한다.
- 인증이 필요한 요청은 `Authorization: Bearer <access-token>` header를 포함해야 한다.
- 내부 `storage_key`, secret, credential, access token, 전체 DSN, 파일 본문은 JSON metadata·오류 response·로그에 노출하지 않는다.

### 1.2 Endpoint 요약

| 기능 | Method | Path | 인증 | 성공 상태 |
| --- | --- | --- | --- | --- |
| access token 발급 | `POST` | `/token` | 불필요 | 200 |
| 현재 사용자 조회 | `GET` | `/user` | 필요 | 200 |
| 문서 생성 | `POST` | `/documents` | 필요 | 201 |
| 문서 목록 조회 | `GET` | `/documents` | 필요 | 200 |
| 문서 metadata 조회 | `GET` | `/documents/{document_id}` | 필요 | 200 |
| 문서 전체 콘텐츠 조회 | `GET` | `/documents/{document_id}/content` | 필요 | 200 |
| 문서 streaming download | `GET` | `/documents/{document_id}/download` | 필요 | 200 |
| soft delete | `DELETE` | `/documents/{document_id}` | 필요 | 200 |
| hard delete | `DELETE` | `/documents/{document_id}?hard=true` | 필요 + `document:delete:hard` 권한 | 200 |
| liveness | `GET` | `/health/liveness` | 불필요 | 200 |
| readiness | `GET` | `/health/readiness` | 불필요 | 200 또는 503 |

## 2. 공통 계약

### 2.1 인증 및 권한

문서 route는 bearer token 인증을 사용한다. 기본 인증 dependency는 `fastapi-core`의 `get_current_user`를 사용한다.

| 권한 | 대상 route |
| --- | --- |
| 인증된 사용자 | 생성, 목록·metadata 조회, 콘텐츠 조회, download, soft delete |
| `document:delete:hard` | hard delete |

인증되지 않은 요청은 `401 UNAUTHENTICATED`, 인증은 되었지만 요구 권한이 없는 요청은 `403 FORBIDDEN`을 반환한다. `401` 응답에는 `WWW-Authenticate: Bearer` header를 포함한다.

### 2.2 공통 오류 response

오류 response content type은 `application/json`이며 다음 schema를 사용한다.

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "01J..."
  }
}
```

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `error.code` | string | 안정적인 기계 판독용 오류 코드 |
| `error.message` | string | 사용자에게 노출 가능한 안전한 설명 |
| `error.correlation_id` | string | `X-Correlation-ID`와 동일한 요청 추적 값 |

FastAPI request validation 오류를 포함한 입력 검증 오류는 공통 오류 envelope와 `400 VALIDATION_ERROR`로 정규화한다.

### 2.3 공통 오류 코드

| HTTP 상태 | 코드 | 발생 조건 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | 잘못된 form field, JSON metadata, query parameter, 비어 있는 파일/filename/content type |
| 401 | `UNAUTHENTICATED` | bearer token 누락·검증 실패 |
| 403 | `FORBIDDEN` | hard delete 등 권한 부족 |
| 404 | `DOCUMENT_NOT_FOUND` | 존재하지 않거나 soft-deleted 문서 |
| 409 | `DOCUMENT_ALREADY_EXISTS` | 지정한 `document_id`가 이미 존재 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | metadata와 MinIO object 상태 불일치 또는 cleanup 실패 |
| 500 | `INTERNAL_ERROR` | 정의되지 않은 내부 오류 |
| 503 | `SERVICE_CONFIGURATION_ERROR` | 서비스 구성 오류 |
| 503 | `DEPENDENCY_UNAVAILABLE` | PostgreSQL 또는 MinIO health check 실패 |
| 503 | `METADATA_STORE_ERROR` | PostgreSQL metadata store 작업 실패 |
| 503 | `OBJECT_STORAGE_ERROR` | MinIO object store 작업 실패 |

### 2.4 DocumentMetadata schema

문서 생성과 metadata 조회의 성공 response에서 사용한다.

```json
{
  "document_id": "doc-01J123456789ABCDEFG",
  "original_filename": "contract.pdf",
  "content_type": "application/pdf",
  "file_size": 24576,
  "status": "available",
  "created_at": "2026-07-11T09:30:00Z",
  "updated_at": "2026-07-11T09:30:00Z",
  "deleted_at": null,
  "created_by": "user-123",
  "checksum": "0f343b0931126a20f133d67c2b018a3b...",
  "metadata": {
    "category": "contract",
    "retention_policy": "standard"
  }
}
```

| 필드 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `document_id` | string | 예 | 문서의 고유 식별자 |
| `original_filename` | string | 예 | 업로드된 원본 파일명 |
| `content_type` | string | 예 | 저장된 MIME type |
| `file_size` | integer | 예 | 본문 크기(byte), 1 이상 |
| `status` | string | 예 | `uploaded`, `available`, `deleting`, `deleted`, `failed` 중 하나 |
| `created_at` | datetime | 예 | 생성 시각 |
| `updated_at` | datetime | 예 | 최종 수정 시각 |
| `deleted_at` | datetime/null | 예 | soft delete 시각, 없으면 `null` |
| `created_by` | string/null | 예 | 생성한 인증 주체 식별자 |
| `checksum` | string/null | 예 | SHA-256 checksum 또는 업로드 시 검증된 checksum |
| `metadata` | object | 예 | 호출자 제공 사용자 정의 metadata |

`storage_key`는 내부 MinIO 접근용 필드로 어떤 일반 API response에서도 반환하지 않는다.

## 3. 인증 API

`/token`과 `/user`는 `fastapi-core`가 제공하는 공통 route다. 실제 인증 provider 설정과 token lifecycle은 배포 환경의 Keycloak 설정을 따른다.

### 3.1 `POST /token`

OAuth2 password grant form을 받아 access token을 발급한다.

#### Request

- Content-Type: `application/x-www-form-urlencoded`

| Field | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `username` | string | 예 | 사용자 이름 |
| `password` | string | 예 | 비밀번호 |
| `scope` | string | 아니오 | 공백으로 구분한 OAuth2 scope |

```bash
curl -X POST "$BASE_URL/token" \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'username=alice' \
  --data-urlencode 'password=[REDACTED]'
```

#### 200 response

```json
{
  "access_token": "[REDACTED]",
  "refresh_token": "[REDACTED]",
  "token_type": "bearer"
}
```

#### 오류

| 상태 | 코드/설명 |
| --- | --- |
| 401 | 인증 provider가 사용자 인증을 거부 |
| 500 | 인증 provider 설정 오류 |
| 502 | 인증 provider 처리 오류 |
| 503 | 인증 provider 일시적 장애 |

### 3.2 `GET /user`

현재 bearer token의 사용자 정보를 반환한다.

#### 200 response

```json
{
  "sub": "user-123",
  "username": "alice",
  "email": "alice@example.com",
  "name": "Alice Example",
  "roles": ["document:delete:hard"],
  "scopes": ["documents:read", "documents:write"]
}
```

## 4. 문서 API

### 4.1 `POST /documents` — 문서 생성

파일 본문과 metadata를 저장한다. 파일 본문은 MinIO에 먼저 저장되고, 이어 PostgreSQL에 metadata가 저장된다. metadata 저장 실패 시 SDK는 object cleanup을 시도한다.

#### Request

- Content-Type: `multipart/form-data`
- Authorization: `Bearer <access-token>` 필요

| Form field | 타입 | 필수 | 제약 및 설명 |
| --- | --- | --- | --- |
| `file` | binary file | 예 | 비어 있지 않아야 한다. filename은 trim 후 빈 문자열 또는 `.`일 수 없다. |
| `document_id` | string | 아니오 | 호출자가 지정하는 문서 ID. 생략 시 SDK가 생성한다. |
| `metadata` | string | 아니오 | JSON object 문자열. 생략 시 `{}`. JSON array·원시값·잘못된 JSON은 거부한다. |
| `checksum` | string | 아니오 | 호출자가 알고 있는 SHA-256 checksum. 생략 시 SDK가 본문 checksum을 계산한다. |

`created_by`는 외부 form field가 아니다. 서비스는 인증된 사용자의 `sub`를 `created_by`로 기록한다.

```bash
curl -X POST "$BASE_URL/documents" \
  -H 'Authorization: Bearer [REDACTED]' \
  -H 'X-Correlation-ID: upload-20260711-001' \
  -F 'file=@./contract.pdf;type=application/pdf' \
  -F 'document_id=contract-2026-0001' \
  -F 'metadata={"category":"contract","retention_policy":"standard"}'
```

#### 201 response

- Content-Type: `application/json`
- Location: `/documents/{document_id}`
- Body: [DocumentMetadata schema](#24-documentmetadata-schema)

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
  "checksum": "[SHA-256]",
  "metadata": {
    "category": "contract",
    "retention_policy": "standard"
  }
}
```

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | file 누락/빈 본문, 잘못된 filename/content type, 잘못된 metadata JSON |
| 401 | `UNAUTHENTICATED` | bearer token 없음 또는 유효하지 않음 |
| 409 | `DOCUMENT_ALREADY_EXISTS` | `document_id` 중복 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | metadata 저장과 object cleanup이 모두 실패 |
| 503 | `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | PostgreSQL 또는 MinIO 작업 실패 |

### 4.2 `GET /documents` — 문서 목록 조회

문서 metadata 목록을 반환한다. 응답은 `DocumentMetadata` 객체의 JSON 배열이며 각 항목에서 내부 `storage_key`를 제외한다.

#### Query parameter

| 이름 | 타입 | 필수 | 기본값 | 제약 및 설명 |
| --- | --- | --- | --- | --- |
| `offset` | integer | 아니오 | `0` | 0 이상 |
| `limit` | integer | 아니오 | `100` | 1 이상 |
| `status` | string | 아니오 | 없음 | `uploaded`, `available`, `deleting`, `deleted`, `failed` 중 하나. 생략하면 모든 상태를 조회한다. |

#### 200 response

- Content-Type: `application/json`
- Body: [DocumentMetadata schema](#24-documentmetadata-schema) 배열

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | 잘못된 offset, limit 또는 status |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 503 | `METADATA_STORE_ERROR` | PostgreSQL 조회 실패 |

### 4.3 `GET /documents/{document_id}` — metadata 조회

문서 metadata를 반환한다. soft-deleted 문서는 존재하지 않는 문서와 동일하게 404로 처리한다.

#### Path parameter

| 이름 | 타입 | 필수 | 설명 |
| --- | --- | --- | --- |
| `document_id` | string | 예 | 조회할 문서 ID |

#### 200 response

- Content-Type: `application/json`
- Body: [DocumentMetadata schema](#24-documentmetadata-schema)

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 404 | `DOCUMENT_NOT_FOUND` | 문서가 없거나 soft-deleted 상태 |
| 503 | `METADATA_STORE_ERROR` | PostgreSQL 조회 실패 |

### 4.4 `GET /documents/{document_id}/content` — 전체 콘텐츠 조회

문서 본문을 단일 HTTP response body로 반환한다. 대용량 문서는 [streaming download](#45-get-documentsdocument_iddownload--streaming-download)를 사용해야 한다.

#### 200 response headers

| Header | 값 |
| --- | --- |
| `Content-Type` | 저장된 `content_type` |
| `Content-Length` | 저장된 `file_size` |
| `Content-Disposition` | `inline; filename*=UTF-8''<RFC5987-encoded-original_filename>` |
| `X-Correlation-ID` | 요청 correlation ID |

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 404 | `DOCUMENT_NOT_FOUND` | 문서가 없거나 soft-deleted 상태 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | PostgreSQL metadata는 있으나 MinIO object가 없음 |
| 503 | `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | 저장소 작업 실패 |

### 4.5 `GET /documents/{document_id}/download` — streaming download

문서 본문을 chunk 단위로 내려받는다. route는 SDK `get_document_content_stream(...)`과 `DocumentContentStream.iter_chunks()`를 사용하며 response 종료·오류·연결 해제 시 stream을 close한다.

#### Query parameter

| 이름 | 타입 | 필수 | 기본값 | 제약 |
| --- | --- | --- | --- | --- |
| `chunk_size` | integer | 아니오 | `65536` | 1 이상 |

#### 200 response headers

| Header | 값 |
| --- | --- |
| `Content-Type` | 저장된 `content_type` |
| `Content-Length` | 저장된 `file_size` |
| `Content-Disposition` | `attachment; filename*=UTF-8''<RFC5987-encoded-original_filename>` |
| `X-Correlation-ID` | 요청 correlation ID |

```bash
curl --fail --location \
  -H 'Authorization: Bearer [REDACTED]' \
  "$BASE_URL/documents/contract-2026-0001/download?chunk_size=65536" \
  --output contract.pdf
```

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 400 | `VALIDATION_ERROR` | `chunk_size`가 0 이하이거나 정수가 아님 |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 404 | `DOCUMENT_NOT_FOUND` | 문서가 없거나 soft-deleted 상태 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | PostgreSQL metadata는 있으나 MinIO object가 없음 |
| 503 | `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | 저장소 작업 실패 |

### 4.6 `DELETE /documents/{document_id}` — soft delete

MinIO object를 삭제하고 PostgreSQL metadata는 상태를 `deleted`로, `deleted_at`을 삭제 시각으로 갱신해 보존한다.

#### Query parameter

| 이름 | 타입 | 필수 | 기본값 | 허용값 |
| --- | --- | --- | --- | --- |
| `hard` | boolean | 아니오 | `false` | `false` 또는 생략 |

`hard=true`은 이 endpoint의 hard delete 동작을 사용한다. 권한이 없을 때는 문서의 존재 여부와 관계없이 먼저 403을 반환할 수 있다.

#### 200 response

```json
{
  "document_id": "contract-2026-0001",
  "deleted": true,
  "hard_deleted": false,
  "status": "deleted"
}
```

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 404 | `DOCUMENT_NOT_FOUND` | 문서가 없거나 이미 soft-deleted 상태 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | 삭제 과정의 정합성 오류 |
| 503 | `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | 저장소 작업 실패 |

### 4.7 `DELETE /documents/{document_id}?hard=true` — hard delete

문서 본문을 삭제하고 PostgreSQL metadata 행을 제거한다. `document:delete:hard` 권한이 필요하다.

#### Query parameter

| 이름 | 타입 | 필수 | 값 |
| --- | --- | --- | --- |
| `hard` | boolean | 예 | `true` |

#### 200 response

```json
{
  "document_id": "contract-2026-0001",
  "deleted": true,
  "hard_deleted": true,
  "status": "deleted"
}
```

`status`는 SDK의 삭제 결과를 나타낸다. hard delete 성공 후에는 metadata 행이 존재하지 않으며 이후 조회는 `404 DOCUMENT_NOT_FOUND`를 반환한다.

#### 오류

| 상태 | 코드 | 조건 |
| --- | --- | --- |
| 401 | `UNAUTHENTICATED` | 인증 실패 |
| 403 | `FORBIDDEN` | `document:delete:hard` 권한 없음 |
| 404 | `DOCUMENT_NOT_FOUND` | 문서가 없거나 이미 soft-deleted 상태 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` | 삭제 과정의 정합성 오류 |
| 503 | `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | 저장소 작업 실패 |

## 5. Health API

Health API는 인증 없이 호출 가능해야 하며 `fastapi-core` 공통 health router를 사용한다.

### 5.1 `GET /health/liveness`

프로세스가 HTTP 요청을 처리할 수 있는지 확인한다. PostgreSQL과 MinIO의 상태는 검사하지 않는다.

#### 200 response

```json
{
  "status": "ok",
  "details": null
}
```

### 5.2 `GET /health/readiness`

필수 `dms` check가 DMS SDK를 통해 PostgreSQL과 MinIO를 검사한다. `DOCMESH_SERVICES`에서 PostgreSQL·MinIO service client도 활성화한 환경에서는 개별 check가 추가될 수 있으며, 선택 외부 서비스 상태도 `details`에 포함할 수 있다.

#### 200 response: 모든 필수 의존성 정상

```json
{
  "status": "ok",
  "details": {
    "postgres": {
      "ok": true,
      "latency_ms": 4,
      "error": null,
      "required": true,
      "enabled": true
    },
    "minio": {
      "ok": true,
      "latency_ms": 6,
      "error": null,
      "required": true,
      "enabled": true
    }
  }
}
```

#### 200 response: 선택 의존성 장애

```json
{
  "status": "degraded",
  "details": {
    "postgres": {
      "ok": true,
      "latency_ms": 4,
      "error": null,
      "required": true,
      "enabled": true
    },
    "minio": {
      "ok": true,
      "latency_ms": 6,
      "error": null,
      "required": true,
      "enabled": true
    },
    "optional-service": {
      "ok": false,
      "latency_ms": null,
      "error": "masked error",
      "required": false,
      "enabled": true
    }
  }
}
```

#### 503 response: 필수 의존성 장애

```json
{
  "status": "error",
  "details": {
    "postgres": {
      "ok": false,
      "latency_ms": null,
      "error": "masked error",
      "required": true,
      "enabled": true
    },
    "minio": {
      "ok": true,
      "latency_ms": 6,
      "error": null,
      "required": true,
      "enabled": true
    }
  }
}
```

| 필드 | 타입 | 설명 |
| --- | --- | --- |
| `status` | `ok` / `degraded` / `error` | 집계된 readiness 상태 |
| `details.<service>.ok` | boolean | 개별 서비스 health 결과 |
| `details.<service>.latency_ms` | integer/null | health check 지연 시간 |
| `details.<service>.error` | string/null | 마스킹된 실패 정보 |
| `details.<service>.required` | boolean | 실패 시 readiness 503을 유발하는지 여부 |
| `details.<service>.enabled` | boolean | 현재 서비스 활성화 여부 |

## 6. 상태 코드 호환성 표

| Route | 200 | 201 | 400 | 401 | 403 | 404 | 409 | 500 | 503 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `POST /documents` |  | 생성 없음 | 입력 오류 | 인증 실패 |  |  | ID 중복 | 정합성/내부 오류 | 저장소 오류 |
| `GET /documents` | 목록 |  | pagination/filter 오류 | 인증 실패 |  |  |  | 내부 오류 | PostgreSQL 오류 |
| `GET /documents/{id}` | metadata |  |  | 인증 실패 |  | 문서 없음 |  | 내부 오류 | PostgreSQL 오류 |
| `GET /documents/{id}/content` | bytes |  |  | 인증 실패 |  | 문서 없음 |  | 정합성 오류 | 저장소 오류 |
| `GET /documents/{id}/download` | stream |  | chunk 오류 | 인증 실패 |  | 문서 없음 |  | 정합성 오류 | 저장소 오류 |
| `DELETE /documents/{id}` | 삭제 결과 |  |  | 인증 실패 | hard delete 권한 없음 | 문서 없음 |  | 정합성 오류 | 저장소 오류 |
| `GET /health/liveness` | 프로세스 정상 |  |  |  |  |  |  |  |  |
| `GET /health/readiness` | 정상/degraded |  |  |  |  |  |  |  | 필수 의존성 장애 |

## 7. 구현 및 테스트 준수 사항

1. `POST /documents`는 `UploadDocumentRequest`로 변환한 뒤 `sdk.upload_document(...)`를 호출한다.
2. 목록/metadata/content/download route는 각각 SDK의 `list_documents(...)`, `get_document_metadata(...)`, `get_document_content(...)`, `get_document_content_stream(...)`를 호출하며 외부 metadata는 `public_metadata(...)`로 변환한다.
3. soft/hard delete route는 각각 `soft_delete_document(...)`, `hard_delete_document(...)`를 명시적으로 호출한다.
4. DMS SDK 오류는 `fastapi-core`의 error mapper/renderer를 통해 [공통 오류 코드](#23-공통-오류-코드)에 정의한 상태와 code로 변환한다.
5. download route는 stream의 정상 완료, 예외, 클라이언트 연결 종료에서 `close()`가 호출되는지 테스트한다.
6. 통합 테스트는 PostgreSQL과 MinIO를 사용해 upload, 목록·metadata 조회, content/download, soft delete, hard delete, readiness, storage 장애를 검증한다.
7. OpenAPI 생성 결과에는 이 문서의 route, request/response schema, security requirement, status code를 반영한다.
