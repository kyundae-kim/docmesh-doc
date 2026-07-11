# 소프트웨어 요구사항 정의서 (SRS)

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 대상 릴리스 | MVP |
| 상위 문서 | [제품 요구사항 정의서](prd.md) |

## 1. 목적 및 적용 범위

본 문서는 `dms-core` 문서 관리 SDK를 `fastapi-core` 기반 FastAPI 애플리케이션으로 서빙하는 DocMesh Document Service의 MVP 소프트웨어 요구사항을 정의한다.

서비스는 문서 본문을 MinIO에, 문서 metadata를 PostgreSQL에 저장한다. PostgreSQL과 MinIO는 runtime, 개발, 테스트, 배포의 유일한 저장소 구성이다.

본 문서는 다음을 다룬다.

- FastAPI 애플리케이션 조립과 lifecycle
- 문서 생성·metadata 조회·콘텐츠 조회·streaming download·soft/hard delete
- PostgreSQL·MinIO 저장소 연결과 정합성 처리
- 인증·권한·오류·health/readiness·관측성
- 테스트와 수용 가능한 운영 동작

웹 UI, OCR, 검색, 문서 버전/복구, 비동기 작업 큐, 메시지 event 계약은 MVP 범위 밖이다.

## 2. 용어 및 참조 아키텍처

| 용어 | 정의 |
| --- | --- |
| DMS SDK | `dms-core`의 `DefaultDocumentManagementSDK` 및 SDK factory가 제공하는 문서 도메인 기능 |
| 애플리케이션 계층 | `fastapi-core.create_app(...)` 위에 DMS route, dependency, lifespan을 조립한 FastAPI 서비스 |
| metadata | 문서 ID, 원본 파일명, content type, 크기, 상태, 저장 key, 생성·수정 시각, 작성자, checksum, 사용자 정의 속성 |
| object | MinIO에 저장되는 문서 본문 |
| soft delete | metadata 상태를 `deleted`로 전환하는 삭제 방식 |
| hard delete | object를 삭제하고 metadata 행을 제거하는 삭제 방식 |
| readiness | 필수 외부 의존성의 준비 상태를 나타내는 HTTP 상태 신호 |

```text
HTTP Client
    │ HTTPS / JSON / multipart or binary body
    ▼
FastAPI application
    ├─ fastapi-core: app factory, common health, auth, config, readiness
    ├─ DMS routes: request/response conversion, authorization, error mapping
    └─ dms-core SDK: lifecycle, document operations, storage consistency
          ├─ PostgreSQL: document metadata
          └─ MinIO: document content
```

### 2.1 책임 경계

| 계층 | 책임 | 금지 사항 |
| --- | --- | --- |
| DMS route | HTTP parsing, response serialization, authorization, HTTP error mapping, stream response 종료 처리 | route 내부에서 SDK 또는 저장소 client를 직접 생성 |
| DMS SDK | 문서 lifecycle, metadata/object 정합성, storage protocol 호출, SDK health·close | HTTP request/response 또는 FastAPI exception 직접 처리 |
| `fastapi-core` | FastAPI app factory, 공통 health/auth router, CORS, app state, service-client readiness | DMS 고유 HTTP resource와 SDK 오류 정책 결정 |
| PostgreSQL | document metadata 영속화 | 문서 본문 저장 |
| MinIO | 문서 본문 저장 및 streaming source 제공 | 업무 filename·uploader 같은 document metadata의 저장 |

## 3. 제약 및 의존성

| 항목 | 요구 제약 |
| --- | --- |
| Python | Python 3.11 이상 |
| 앱 factory | `fastapi-core.create_app(...)` 사용 |
| DMS SDK | root package `dms`에서 SDK factory, 모델, 오류 타입 import |
| metadata store | 모든 환경에서 PostgreSQL만 허용 |
| object store | 모든 환경에서 MinIO 필수 |
| SDK 조립 | `create_sdk_from_environment(...)` 또는 PostgreSQL/MinIO 구현체를 전달하는 `create_sdk_from_components(...)` 사용 |
| 저장소 접근 | SQLAlchemy ORM을 사용하며 SQLAlchemy Core 스타일을 사용하지 않음 |
| secret | 환경변수 또는 배포 플랫폼의 secret 주입으로 제공하며 로그·응답에 원문을 노출하지 않음 |
| package version | 배포 전 잠금된 `dms`, `fastapi-core`, `docmesh-py-core` public API를 통합 테스트로 검증 |

## 4. 시스템 구성 요구사항

### 4.1 애플리케이션 조립

| ID | 요구사항 |
| --- | --- |
| SRS-ARC-001 | 애플리케이션은 `fastapi_core.create_app(config=..., settings=..., lifespan=...)`으로 생성해야 한다. |
| SRS-ARC-002 | DMS route는 공통 health router와 충돌하지 않는 별도 router로 등록해야 한다. |
| SRS-ARC-003 | DMS SDK 인스턴스는 FastAPI lifespan 시작 시 한 번 생성하고, route가 전용 dependency를 통해 재사용할 수 있는 `app.state` 경계에 보관해야 한다. |
| SRS-ARC-004 | route, dependency, background callback은 `DefaultDocumentManagementSDK`를 직접 생성해서는 안 된다. |
| SRS-ARC-005 | SDK 생성이 실패하면 애플리케이션은 요청 처리를 시작해서는 안 되며, 오류 원인을 안전하게 기록해야 한다. |
| SRS-ARC-006 | lifespan 종료 시 SDK `close()`를 호출해야 하며, SDK close 실패도 오류로 기록해야 한다. |
| SRS-ARC-007 | `fastapi-core`가 관리하는 service client 종료와 DMS SDK 종료 순서는 custom lifespan과 충돌하지 않도록 보장해야 한다. |

### 4.2 저장소 구성

| ID | 요구사항 |
| --- | --- |
| SRS-STO-001 | 서비스는 모든 환경에서 `POSTGRES_DSN`으로 PostgreSQL metadata store를 구성해야 한다. |
| SRS-STO-002 | `POSTGRES_DSN`이 없거나 PostgreSQL 연결을 구성할 수 없으면 서비스는 startup을 실패해야 한다. |
| SRS-STO-003 | 서비스는 `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`으로 MinIO object store를 구성해야 한다. |
| SRS-STO-004 | MinIO bucket 설정이 없거나 MinIO client를 구성할 수 없으면 서비스는 startup을 실패해야 한다. |
| SRS-STO-005 | PostgreSQL 및 MinIO의 startup health check를 기본 활성화해야 한다. 명시적으로 비활성화하는 개발 설정은 MVP 배포 설정에 포함해서는 안 된다. |
| SRS-STO-006 | 원본 filename, `created_by`, 사용자 정의 metadata는 PostgreSQL document metadata에 보관하고 MinIO object metadata에는 저장하지 않아야 한다. |
| SRS-STO-007 | PostgreSQL metadata에는 MinIO object를 찾기 위한 `storage_key`를 저장해야 한다. |

### 4.3 인증과 권한

| ID | 요구사항 |
| --- | --- |
| SRS-SEC-001 | 문서 생성, metadata 조회, 콘텐츠 조회, streaming download, soft delete, hard delete route는 인증된 사용자만 접근할 수 있어야 한다. |
| SRS-SEC-002 | 인증은 `fastapi-core`의 `get_current_user` dependency 또는 동등한 인증된 사용자 dependency를 사용해야 한다. |
| SRS-SEC-003 | hard delete는 일반 문서 작업보다 강한 역할 기반 권한 검사(`require_permissions(...)` 또는 동등 정책)를 적용해야 한다. |
| SRS-SEC-004 | 업로드 request의 `created_by`가 제공되지 않으면 인증된 사용자의 식별자를 사용해야 한다. 호출자가 제공한 `created_by`를 신뢰할지 여부는 API 계약에서 명시하고 권한 없이 다른 사용자로 위조할 수 없게 해야 한다. |
| SRS-SEC-005 | 인증 실패는 401, 인증은 됐지만 권한이 부족한 경우는 403으로 응답해야 한다. |
| SRS-SEC-006 | 운영 CORS origin은 명시적으로 설정해야 하며 credential을 허용하는 배포에서 wildcard origin을 사용해서는 안 된다. |

## 5. 문서 도메인 및 상태 요구사항

### 5.1 문서 모델

서비스가 외부에 노출하는 metadata는 최소 다음 정보를 포함해야 한다.

| 필드 | 출처/규칙 |
| --- | --- |
| `document_id` | 호출자 지정 또는 SDK 생성 식별자 |
| `original_filename` | 업로드 시 받은 filename |
| `content_type` | 업로드 시 받은 content type |
| `file_size` | 저장된 본문 크기 |
| `status` | `available`, `deleting`, `deleted`, `failed` 중 현재 상태 |
| `created_at`, `updated_at` | 서버가 관리하는 시각 |
| `deleted_at` | soft delete된 경우의 시각, 그 외 `null` |
| `created_by` | 인증된 사용자 또는 허용된 호출자 값 |
| `checksum` | 제공값 또는 SDK가 산출한 SHA-256 checksum |
| `metadata` | 사용자 정의 key/value 정보 |

`storage_key`는 내부 저장소 식별자이므로 일반 API response에 기본 노출해서는 안 된다.

### 5.2 상태 전이

| 현재 상태 | 작업 | 다음 상태/결과 |
| --- | --- | --- |
| 신규 | 업로드 성공 | `available` |
| `available` | soft delete | `deleting`을 거쳐 `deleted` |
| `available` | hard delete | `deleting`을 거쳐 metadata 제거 |
| `deleting` | object 삭제 실패 | best-effort로 `failed` 전환 후 오류 반환 |
| `deleted` | 일반 metadata/content 조회 | not-found 정책에 따라 차단 |
| metadata 존재 + object 없음 | 콘텐츠 조회 | consistency 오류 |

| ID | 요구사항 |
| --- | --- |
| SRS-DOM-001 | 업로드 성공 문서는 `available` 상태의 metadata와 접근 가능한 object를 가져야 한다. |
| SRS-DOM-002 | soft delete는 metadata를 삭제하지 않고 `deleted` 상태 및 `deleted_at`을 남겨야 한다. |
| SRS-DOM-003 | hard delete는 object 삭제 후 metadata 행을 제거해야 한다. |
| SRS-DOM-004 | soft-deleted 문서의 일반 metadata 조회와 콘텐츠 조회는 외부에서 존재 여부를 추론하기 어렵도록 동일한 not-found 정책을 사용해야 한다. |
| SRS-DOM-005 | 문서 목록, 복구, 버전 관리는 MVP에서 제공하지 않아야 한다. |

## 6. HTTP 인터페이스 요구사항

최종 URI, media type, Pydantic schema, OpenAPI 예시 및 오류 payload는 [API Reference](api.md)에서 확정한다. 본 절은 MVP에서 구현해야 할 논리 endpoint와 동작을 정의한다.

### 6.1 논리 endpoint

| 논리 기능 | HTTP method 및 URI | 성공 응답 | 필수 동작 |
| --- | --- | --- | --- |
| 문서 생성 | `POST /documents` | `201 Created` + metadata | filename, content type, 본문 및 선택 metadata를 검증·저장 |
| metadata 조회 | `GET /documents/{document_id}` | `200 OK` + metadata | 삭제되지 않은 문서 metadata 반환 |
| 전체 콘텐츠 조회 | `GET /documents/{document_id}/content` | `200 OK` + bytes | 작은 문서에 한해 구현 가능하며 content type 보존 |
| streaming download | `GET /documents/{document_id}/download` | `200 OK` + streaming body | chunk 단위 body 전송 및 stream close |
| soft delete | `DELETE /documents/{document_id}` | `200 OK` 또는 `204 No Content` | `hard_delete=False`로 SDK 호출 |
| hard delete | `DELETE /documents/{document_id}?hard=true` | `200 OK` 또는 `204 No Content` | 강화된 권한 후 `hard_delete=True`로 SDK 호출 |
| liveness | `GET /health/liveness` | `200 OK` | 공통 FastAPI health router 사용 |
| readiness | `GET /health/readiness` | `200 OK` 또는 `503 Service Unavailable` | PostgreSQL·MinIO 준비 상태 반영 |

| ID | 요구사항 |
| --- | --- |
| SRS-API-001 | `POST /documents`는 multipart/form-data 또는 API Reference에서 확정한 바이너리 request 계약으로 본문, filename, content type, 선택 `document_id`, `metadata`, `checksum`을 받아야 한다. |
| SRS-API-002 | 업로드 route는 입력값을 `UploadDocumentRequest`로 변환해 `sdk.upload_document(...)`를 호출해야 한다. |
| SRS-API-003 | 본문이 비어 있거나 filename/content type이 trim 후 비어 있으면 저장소 호출 전에 validation 오류를 반환해야 한다. |
| SRS-API-004 | 지정된 `document_id`가 이미 존재하면 duplicate 오류를 반환해야 한다. |
| SRS-API-005 | `GET /documents/{document_id}`는 `sdk.get_document_metadata(...)`를 호출하고 외부 계약에 맞게 metadata를 직렬화해야 한다. |
| SRS-API-006 | `GET /documents/{document_id}/content`는 `sdk.get_document_content(...)`를 호출하고 저장된 content type과 안전한 filename disposition을 유지해야 한다. |
| SRS-API-007 | `GET /documents/{document_id}/download`는 `sdk.get_document_content_stream(...)` 결과를 `StreamingResponse`로 변환해야 한다. |
| SRS-API-008 | streaming response는 `DocumentContentStream.iter_chunks()`를 사용하고, 완료·클라이언트 연결 종료·예외 경로 모두에서 `DocumentContentStream.close()`를 호출해야 한다. |
| SRS-API-009 | streaming chunk size를 외부 입력으로 노출하는 경우 양의 정수만 허용하고, 0 이하 값은 validation 오류로 처리해야 한다. |
| SRS-API-010 | soft delete route는 `sdk.delete_document(document_id, hard_delete=False)`를 호출해야 한다. |
| SRS-API-011 | hard delete route는 권한 확인 후 `sdk.delete_document(document_id, hard_delete=True)`를 호출해야 한다. |
| SRS-API-012 | 모든 DMS route는 성공 응답에 request correlation ID를 header 또는 확정된 response envelope로 제공해야 한다. |

## 7. 정합성 및 오류 처리 요구사항

### 7.1 오류 응답 형식

DMS route 오류는 다음 최소 구조를 사용해야 한다. 최종 Pydantic schema와 header는 API Reference에서 확정한다.

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "..."
  }
}
```

- `message`에는 secret, token, DSN, storage key, 내부 stack trace를 포함하지 않는다.
- `correlation_id`는 로그에서 같은 요청을 찾을 수 있어야 한다.
- FastAPI validation 오류도 동일한 상위 오류 envelope 정책과 일관되게 처리한다.

### 7.2 SDK 오류 매핑

| SDK/서비스 오류 | HTTP status | 외부 오류 코드 |
| --- | --- | --- |
| `ValidationError` | 400 Bad Request | `VALIDATION_ERROR` |
| `DocumentNotFoundError` | 404 Not Found | `DOCUMENT_NOT_FOUND` |
| `DuplicateDocumentError` | 409 Conflict | `DOCUMENT_ALREADY_EXISTS` |
| `ConfigurationError` | 503 Service Unavailable | `SERVICE_CONFIGURATION_ERROR` |
| `HealthCheckFailedError` | 503 Service Unavailable | `DEPENDENCY_UNAVAILABLE` |
| `StorageError` | 503 Service Unavailable | `OBJECT_STORAGE_ERROR` |
| `MetadataStoreError` | 503 Service Unavailable | `METADATA_STORE_ERROR` |
| `ConsistencyError` | 500 Internal Server Error | `DOCUMENT_CONSISTENCY_ERROR` |
| 인증 실패 | 401 Unauthorized | `UNAUTHENTICATED` |
| 권한 부족 | 403 Forbidden | `FORBIDDEN` |
| 정의되지 않은 내부 오류 | 500 Internal Server Error | `INTERNAL_ERROR` |

| ID | 요구사항 |
| --- | --- |
| SRS-ERR-001 | DMS SDK 공개 오류 타입을 중앙 FastAPI exception handler 또는 route 공통 mapper로 위 표에 따라 매핑해야 한다. |
| SRS-ERR-002 | 정의되지 않은 예외는 외부에 내부 구현 정보를 노출하지 않고 `INTERNAL_ERROR`로 반환해야 한다. |
| SRS-ERR-003 | object 저장 후 metadata 저장이 실패하면 SDK cleanup 동작을 방해하지 않아야 하며, cleanup까지 실패해 발생한 `ConsistencyError`를 별도 오류 코드와 error-level 로그로 기록해야 한다. |
| SRS-ERR-004 | metadata는 존재하지만 object가 없는 콘텐츠 조회는 `DOCUMENT_CONSISTENCY_ERROR`로 처리해야 한다. |
| SRS-ERR-005 | PostgreSQL 또는 MinIO 장애는 요청 오류와 readiness 상태에 모두 반영해야 한다. |
| SRS-ERR-006 | response body와 로그에는 문서 본문, access token, secret, password, 전체 DSN을 포함해서는 안 된다. |

## 8. Health, readiness 및 관측성 요구사항

### 8.1 Health 및 readiness

| ID | 요구사항 |
| --- | --- |
| SRS-OPS-001 | 서비스는 `fastapi-core`가 제공하는 `GET /health/liveness`를 변경 없이 제공해야 하며 정상 프로세스에서 200 `status=ok`를 반환해야 한다. |
| SRS-OPS-002 | `GET /health/readiness`는 DMS SDK의 `check_health()` 또는 동등한 PostgreSQL·MinIO check를 실행하도록 app state readiness policy에 연결해야 한다. |
| SRS-OPS-003 | PostgreSQL 또는 MinIO가 실패한 경우 두 의존성을 required service로 간주하고 readiness는 503 `status=error`를 반환해야 한다. |
| SRS-OPS-004 | DMS 필수 의존성 외 선택 서비스가 활성화된 경우에만 선택 서비스 실패에 대해 200 `status=degraded`를 반환할 수 있다. |
| SRS-OPS-005 | readiness response의 서비스 오류 상세는 secret과 내부 endpoint를 마스킹해야 한다. |

### 8.2 로깅 및 추적성

| ID | 요구사항 |
| --- | --- |
| SRS-OBS-001 | 모든 DMS 요청은 correlation ID를 생성 또는 전달받아 request scope에 유지해야 한다. |
| SRS-OBS-002 | 업로드, metadata 조회, 콘텐츠 조회, download, soft delete, hard delete, health check 결과를 구조화 로그로 남겨야 한다. |
| SRS-OBS-003 | 구조화 로그에는 최소 `event`, `correlation_id`, `operation`, `outcome`, `document_id`(있는 경우), `status_code`, 오류 코드, latency를 포함해야 한다. |
| SRS-OBS-004 | consistency 오류, startup 실패, shutdown/stream close 실패는 error-level 로그와 운영 알림 대상 이벤트로 기록해야 한다. |
| SRS-OBS-005 | 파일 본문, access token, secret, password, 전체 DSN, MinIO credential은 로그에 기록해서는 안 된다. |

## 9. 설정 요구사항

| 설정 | 필수 여부 | 요구사항 |
| --- | --- | --- |
| `POSTGRES_DSN` | 필수 | PostgreSQL metadata store 연결 문자열 |
| `MINIO_ENDPOINT` | 필수 | MinIO 서버 endpoint |
| `MINIO_ACCESS_KEY` | 필수 | MinIO 접근 키 |
| `MINIO_SECRET_KEY` | 필수 | MinIO 비밀 키 |
| `MINIO_BUCKET` | 필수 | 문서 본문 bucket |
| `MINIO_SECURE` | 선택 | MinIO TLS 사용 여부 |
| `DOCMESH_HEALTHCHECK_ENABLED` | 선택 | 기본 `true`; MVP 배포에서 `false` 사용 금지 |
| `ROOT_PATH` | 선택 | reverse proxy 하위 경로 |
| `TOKEN_URL` | 인증 사용 시 필수 | OpenAPI OAuth2 token URL |
| `CORS_ORIGINS` | 운영 필수 | 허용 origin CSV |
| `CORS_CREDENTIALS` | 선택 | credential 허용 여부 |
| `READINESS_PARALLEL` | 선택 | readiness 병렬 실행 여부 |
| `DOCMESH_SERVICES` | 선택 | `fastapi-core` service client 대상 |
| `READINESS_REQUIRED_SERVICES` | 선택 | `fastapi-core` 필수 서비스 대상 |

| ID | 요구사항 |
| --- | --- |
| SRS-CFG-001 | 서비스는 startup 전에 필수 설정의 누락·공백 여부를 검증해야 한다. |
| SRS-CFG-002 | `POSTGRES_DSN` 및 MinIO credential은 secret provider 또는 환경변수에서 읽어야 하며 source code, 기본값, API response에 하드코딩해서는 안 된다. |
| SRS-CFG-003 | `DOCMESH_SERVICES` 및 `READINESS_REQUIRED_SERVICES`는 DMS SDK의 PostgreSQL·MinIO health 정책을 대체해서는 안 된다. |
| SRS-CFG-004 | 운영 배포에서 `fastapi-core` 개발 fallback 설정을 실제 credential·endpoint·CORS 정책 대신 사용해서는 안 된다. |


## 10. 비기능 요구사항

| ID | 요구사항 |
| --- | --- |
| SRS-NFR-001 | 다운로드는 전체 object를 애플리케이션 메모리에 적재하지 않고 streaming path를 기본으로 지원해야 한다. |
| SRS-NFR-002 | 서비스는 정상 종료, 기동 실패, streaming 완료, streaming 예외, 클라이언트 연결 종료 경로에서 리소스 close를 보장해야 한다. |
| SRS-NFR-003 | API contract test는 성공 응답, 오류 envelope, 인증/권한, content type, `Content-Disposition`, correlation ID를 검증해야 한다. |
| SRS-NFR-004 | 통합 테스트는 실제 PostgreSQL 및 MinIO를 사용해 upload, metadata 조회, download, soft delete, hard delete, health, startup failure를 검증해야 한다. |
| SRS-NFR-005 | 실패 주입 테스트는 metadata 저장 실패 후 object cleanup, cleanup 실패에 따른 consistency 오류, object 누락 consistency 오류를 검증해야 한다. |
| SRS-NFR-006 | API route, dependency, exception mapping, PostgreSQL metadata store, MinIO object store, lifespan은 테스트에서 독립적으로 교체 또는 검증할 수 있어야 한다. |
| SRS-NFR-007 | 서비스는 Python 3.11 이상에서 실행하고 저장소의 lockfile에 고정된 package version 조합에서 테스트를 통과해야 한다. |
| SRS-NFR-008 | OpenAPI 문서에는 보호된 route의 인증 방식, 권한 요구사항, request/response schema, status code, 오류 코드가 포함되어야 한다. |

## 11. PRD 추적성

| PRD 기능 영역 | 이 SRS의 주요 요구사항 |
| --- | --- |
| 앱 조립 및 lifecycle | SRS-ARC-001 ~ SRS-ARC-007 |
| PostgreSQL·MinIO 운영 구성 | SRS-STO-001 ~ SRS-STO-007, SRS-CFG-001 ~ SRS-CFG-004 |
| 인증 및 권한 | SRS-SEC-001 ~ SRS-SEC-006 |
| 문서 lifecycle | SRS-DOM-001 ~ SRS-DOM-005, SRS-API-001 ~ SRS-API-012 |
| 오류 및 정합성 | SRS-ERR-001 ~ SRS-ERR-006 |
| readiness 및 관측성 | SRS-OPS-001 ~ SRS-OPS-005, SRS-OBS-001 ~ SRS-OBS-005 |
| 품질 및 테스트 | SRS-NFR-001 ~ SRS-NFR-008 |

## 12. 구현 전 확인 항목

1. `dms-core` version `v0.2.0`에서 PostgreSQL adapter가 `POSTGRES_DSN`으로 정상 조립되는지 통합 테스트로 확인한다.
2. `fastapi-core` version `v0.1.6`의 custom lifespan이 DMS SDK의 종료 순서와 충돌하지 않는지 확인한다.
3. `fastapi-core` 기본 readiness는 service-client map을 기준으로 하므로, PostgreSQL·MinIO SDK health를 `app.state.readiness_checks`에 연결하는 구체 구현을 설계·테스트한다.
4. upload payload의 최종 형식(multipart/form-data 또는 binary body), hard delete 권한 role, deleted 문서의 HTTP 응답 세부사항은 [API Reference](api.md)에서 확정한다.
5. `docmesh-py-core` 설정 loader가 DMS 이외의 fallback 설정을 요구할 수 있으므로, 운영 배포에서 필요한 최소 설정을 실제 startup 테스트로 확정한다.
