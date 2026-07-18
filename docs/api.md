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

공개 API는 아래의 안정 ID로 추적한다. 같은 method/path를 공유해도 계약이 다른 soft/hard delete는 별도 ID를 사용한다. `ROOT_PATH`는 배포 prefix이며 표의 application path에는 포함하지 않는다.

| API ID | 기능 | Method | Path | 인증 | 성공 상태 | 예시 | 주요 설정 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `API-AUTH-001` | access token | `POST` | `/token` | 불필요 | 200 | `EX-AUTH-001` | `CFG-AUTH`, `CFG-HTTP` |
| `API-AUTH-002` | 현재 사용자 | `GET` | `/user` | 필요 | 200 | `EX-AUTH-002` | `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-001` | 문서 생성 | `POST` | `/documents` | 필요 | 201 | `EX-DOC-001` ~ `EX-DOC-003` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-002` | 문서 목록 | `GET` | `/documents` | 필요 | 200 | `EX-DOC-004` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-003` | metadata 조회 | `GET` | `/documents/{document_id}` | 필요 | 200 | `EX-DOC-005` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-004` | 전체 콘텐츠 | `GET` | `/documents/{document_id}/content` | 필요 | 200 | `EX-DOC-006` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-005` | streaming download | `GET` | `/documents/{document_id}/download` | 필요 | 200 | `EX-DOC-007` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-006` | soft delete | `DELETE` | `/documents/{document_id}` | 필요 | 200 | `EX-DOC-008` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-007` | hard delete | `DELETE` | `/documents/{document_id}?hard=true` | `document:delete:hard` role | 200 | `EX-DOC-009` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-OPS-001` | liveness | `GET` | `/health/liveness` | 불필요 | 200 | `EX-OPS-001` | `CFG-HTTP` |
| `API-OPS-002` | readiness | `GET` | `/health/readiness` | 불필요 | 200 또는 503 | `EX-OPS-002` | `CFG-DMS`, `CFG-STORAGE`, `CFG-READINESS` |

`/token`, `/user`, health route는 `fastapi-core`가 제공한다. 이 저장소가 직접 구현하는 route는 `/documents*`다.

### 2.1 API 문서 지원 endpoint

아래 route는 업무 API가 아니라 FastAPI가 기본 제공하는 문서 지원 표면이다. 인증 없이 노출되므로 운영에서의 공개 여부는 reverse proxy 정책으로 통제한다. 현재 애플리케이션 코드는 이 기본값을 비활성화하거나 경로를 변경하지 않는다.

| API ID | Method | Path | 용도 | 예시/소비자 |
| --- | --- | --- | --- | --- |
| `API-SYS-001` | `GET` | `/openapi.json` | OpenAPI schema | `EX-SYS-001` |
| `API-SYS-002` | `GET` | `/docs` | Swagger UI | `EX-SYS-002` |
| `API-SYS-003` | `GET` | `/docs/oauth2-redirect` | Swagger UI OAuth2 redirect callback | Swagger UI가 간접 호출 |
| `API-SYS-004` | `GET` | `/redoc` | ReDoc UI | `EX-SYS-003` |

### 2.2 Python hosting surface

HTTP route 외에 host/deployment가 사용하는 공개 진입점은 다음 두 개다.

| API ID | Symbol | 계약 |
| --- | --- | --- |
| `API-HOST-001` | `docmesh_doc.application.create_application(sdk=None, *, config=None, include_auth_router=True)` | FastAPI 앱을 조립한다. `sdk`는 테스트/host 주입용이며 생략하면 lifespan 시작 시 process environment에서 DMS SDK를 생성한다. `config`는 `fastapi_core.config.AppConfig`, `include_auth_router=False`는 `/token`·`/user`를 제외한다. |
| `API-HOST-002` | `docmesh_doc.main:app` | ASGI server가 import하는 기본 배포 객체다. |

`docmesh_doc.router`, `document_http`, `schemas`, `errors`, `dependencies`의 symbol은 HTTP adapter 구현 세부사항이며 독립적인 호환성 보장 대상이 아니다.

### 2.3 인증 API 상세

#### `POST /token` (`API-AUTH-001`)

`application/x-www-form-urlencoded` OAuth2 password form을 받는다. `username`과 `password`가 필수이고 `grant_type=password`, `scope`, `client_id`, `client_secret`은 선택이다. 현재 전역 validation mapper가 malformed form을 `400 VALIDATION_ERROR`로 정규화하지만 생성 OpenAPI에는 framework 기본 422가 남는다.

성공 response는 다음 `TokenResponse`다. `access_token`이 필수이고 `refresh_token`은 없으면 `null`, `token_type` 기본값은 `bearer`다.

```json
{
  "access_token": "<access-token>",
  "refresh_token": null,
  "token_type": "bearer"
}
```

#### `GET /user` (`API-AUTH-002`)

OAuth2 bearer token이 필요하다. 성공 response는 인증 provider가 해석한 `UserInfo`다.

```json
{
  "sub": "user-123",
  "username": "alice",
  "email": "alice@example.com",
  "name": "Alice",
  "roles": ["document:delete:hard"],
  "scopes": []
}
```

`sub`와 `username`만 필수다. `email`, `name`은 `null`일 수 있고 `roles`, `scopes`는 문자열 배열이다. 보호 route는 동일한 사용자 dependency를 사용하며 업로드의 `created_by`는 이 `sub`에서 결정된다.

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

### 4.1 `POST /documents` (`API-DOC-001`)

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

### 4.2 `GET /documents` (`API-DOC-002`)

| Query | 타입 | 기본값 | 검증 |
| --- | --- | --- | --- |
| `offset` | integer | `0` | 0 이상 |
| `limit` | integer | `100` | 1 이상; 구현상 상한 없음 |
| `status` | DocumentStatus | 없음 | `uploaded`, `available`, `deleting`, `deleted`, `failed` |

`sdk.list_documents(...)` 결과 각각을 `dms.public_metadata(...)`로 변환한다. soft-deleted 항목도 SDK 목록 결과에 포함될 수 있으며 `status` filter로 조회할 수 있다.

### 4.3 `GET /documents/{document_id}` (`API-DOC-003`)

`sdk.get_document_metadata(document_id)`를 호출한다. 반환 상태가 `deleted`이면 `DOCUMENT_NOT_FOUND`로 변환하고, 그 외 상태는 공개 metadata로 반환한다.

### 4.4 `GET /documents/{document_id}/content` (`API-DOC-004`)

읽기 가능한 metadata인지 먼저 확인한 다음 `sdk.get_document_content(...)`의 bytes를 한 번에 반환한다.

- `Content-Type`: SDK content type
- `Content-Length`: SDK size
- `Content-Disposition`: `inline; filename*=UTF-8''<percent-encoded-filename>`

### 4.5 `GET /documents/{document_id}/download` (`API-DOC-005`)

읽기 가능한 metadata인지 먼저 확인한 다음 `sdk.get_document_content_stream(document_id, chunk_size=...)`을 호출한다.

| Query | 기본값 | 검증 |
| --- | --- | --- |
| `chunk_size` | `65536` | 1 이상의 integer |

response generator는 `item.iter_chunks()`를 전달하고 `finally`에서 `item.close()`를 호출한다.

- `Content-Type`: SDK content type
- `Content-Length`: SDK size
- `Content-Disposition`: `attachment; filename*=UTF-8''<percent-encoded-filename>`

### 4.6 `DELETE /documents/{document_id}` (`API-DOC-006`, `API-DOC-007`)

`hard`의 기본값은 `false`다.

- `hard=false`: `sdk.soft_delete_document(document_id)`
- `hard=true`: 사용자 role에 `document:delete:hard`가 있는지 먼저 검사한 뒤 `sdk.hard_delete_document(document_id)`
- boolean으로 해석할 수 없는 `hard` 값: `400 VALIDATION_ERROR`
- 권한 없는 hard delete: `403 FORBIDDEN`

현재 DMS SDK의 soft delete는 object를 삭제하고 metadata 상태와 `deleted_at`을 보존한다. hard delete는 object와 metadata 행을 제거한다.

## 5. Health API

### 5.1 `GET /health/liveness` (`API-OPS-001`)

프로세스 생존만 나타내며 DMS store를 검사하지 않는다.

```json
{"status":"ok","details":null}
```

### 5.2 `GET /health/readiness` (`API-OPS-002`)

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

## 7. 공개 API 추적성

`구현`은 계약을 소유하거나 조립하는 현재 source이고, `자동화 근거`는 해당 API를 직접 호출하거나 조립 계약을 확인하는 테스트다. `fastapi-core` 제공 route는 이 저장소가 schema를 재정의하지 않으므로 dependency의 현재 OpenAPI/실행 결과도 함께 확인해야 한다.

| API ID | 요구사항 | 구현 | 예시 | 설정 | 자동화 근거 |
| --- | --- | --- | --- | --- | --- |
| `API-AUTH-001` | SRS-SEC-001, SRS-SEC-002 | `fastapi-core` auth router, `application.py` | `EX-AUTH-001` | `CFG-AUTH`, `CFG-HTTP` | 현재 저장소 직접 token 발급 테스트 없음 |
| `API-AUTH-002` | SRS-SEC-001, SRS-SEC-002 | `fastapi-core` auth router, `application.py` | `EX-AUTH-002` | `CFG-AUTH`, `CFG-HTTP` | document API 테스트에서 사용자 dependency override만 검증 |
| `API-DOC-001` | SRS-API-001 ~ SRS-API-004 | `router.py:21`, `document_http.py`, `schemas.py` | `EX-DOC-001` ~ `EX-DOC-003` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_upload_api.py`, `test_document_http.py` |
| `API-DOC-002` | SRS-API-013 | `router.py:48`, `schemas.py` | `EX-DOC-004` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_read_api.py`, `test_document_http.py` |
| `API-DOC-003` | SRS-API-005 | `router.py:60`, `document_http.py`, `schemas.py` | `EX-DOC-005` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_read_api.py`, `test_error_api.py` |
| `API-DOC-004` | SRS-API-006 | `router.py:65`, `document_http.py` | `EX-DOC-006` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | deleted-state guard만 `test_read_api.py`; 정상 body/header 직접 테스트 없음 |
| `API-DOC-005` | SRS-API-007 ~ SRS-API-009 | `router.py:75`, `document_http.py` | `EX-DOC-007` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_read_api.py`, `test_document_http.py` |
| `API-DOC-006` | SRS-API-010 | `router.py:97` | `EX-DOC-008` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_delete_api.py` |
| `API-DOC-007` | SRS-API-011 | `router.py:97` | `EX-DOC-009` | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` | `test_delete_api.py`; 실제 저장소 통합 경로는 role에 따라 skip 가능 |
| `API-OPS-001` | SRS-OPS-001 | `fastapi-core` health router, `application.py` | `EX-OPS-001` | `CFG-HTTP` | route 존재는 생성 OpenAPI로 확인; 전용 response 테스트 없음 |
| `API-OPS-002` | SRS-OPS-002 ~ SRS-OPS-005 | `fastapi-core` health router, `application.py:29` | `EX-OPS-002` | `CFG-DMS`, `CFG-STORAGE`, `CFG-READINESS` | `test_application.py` |
| `API-SYS-001` ~ `API-SYS-004` | SRS-NFR-008 | FastAPI 기본 route, `fastapi-core.create_app` | `EX-SYS-001` ~ `EX-SYS-003` | `CFG-HTTP`, `CFG-AUTH` | 생성된 route/OpenAPI 수동 대조; 전용 테스트 없음 |
| `API-HOST-001` | SRS-ARC-001 ~ SRS-ARC-007 | `application.py:19` | `EX-HOST-001`, `EX-HOST-002` | 모든 설정 그룹 | `test_application.py` |
| `API-HOST-002` | SRS-ARC-001 | `main.py:3`, `pyproject.toml` `tool.fastapi.entrypoint` | `EX-HOST-003` | 모든 설정 그룹 | import/서버 기동 전용 테스트 없음 |

역방향 추적은 [API 사용 예시 §9](examples.md#9-공개-api-예시-추적성)와 [설정 정의서 §10](config.md#10-공개-api-설정-추적성)에서 제공한다.
