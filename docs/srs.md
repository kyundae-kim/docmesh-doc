# 소프트웨어 요구사항 정의서 (SRS)

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 대상 릴리스 | v0.4.0 |
| 최종 코드 대조일 | 2026-08-04 |
| 상위 문서 | [제품 요구사항 정의서](prd.md) |

## 1. 목적

본 문서는 DocMesh Document Service가 PRD의 제품 목표를 충족하기 위해 갖춰야 할 검증 가능한 소프트웨어 요구사항을 정의한다. 대상은 `dms-core`를 `fastapi-core` 기반 FastAPI 애플리케이션으로 조립한 문서 관리 HTTP 서비스다.

본 문서는 애플리케이션 lifecycle, 저장소 구성, 인증·권한, 문서 상태와 HTTP 동작, 오류·운영 정책, 품질 게이트를 규정한다. 웹 UI, 검색·OCR·변환, 문서 복구·버전, 비동기 업로드 큐와 문서 이벤트 계약은 범위 밖이다.

## 2. 설계 목표와 경계

| 목표 | 설계 원칙 |
| --- | --- |
| 안전한 문서 lifecycle | route는 HTTP 변환·권한·오류 매핑을, DMS SDK는 문서·저장소 정합성을 담당한다. |
| 일관된 운영 | `fastapi-core`가 application factory, 공통 health, 인증, lifecycle, readiness를 관리한다. |
| 내부 정보 보호 | public response는 allowlist schema로 직렬화하며 `storage_key`, secret, DSN, stack trace를 노출하지 않는다. |
| 승인된 배포 구성 | 운영·통합은 PostgreSQL, 로컬 개발은 SQLite를 metadata store로 사용할 수 있고 모든 구성은 MinIO object store를 사용한다. |

## 3. 소프트웨어 요구사항

### 3.1 애플리케이션 구조와 lifecycle

| ID | 요구사항 |
| --- | --- |
| SRS-ARC-001 | 애플리케이션은 `fastapi_core.create_app(config=..., modules=..., error_renderer=..., include_auth_router=...)`으로 생성해야 한다. `fastapi-core` v0.7.0의 auth router 기본값은 `False`지만 제품 `create_application()`은 기본 제품 앱에 `/token`, `/user`를 포함하도록 `True`를 명시해야 한다. 인증 runtime을 조립하지 않는 테스트·embedding 환경은 명시적 `auth_provider`를 주입해야 한다. |
| SRS-ARC-002 | DMS route, managed resource, DMS·validation error mapper는 이름이 `documents`인 `DomainModule`로 묶고 공통 health route와 충돌하지 않아야 한다. |
| SRS-ARC-003 | `ResourceKey[DefaultDocumentManagementSDK]("dms")`를 선언하고 같은 key를 `ManagedResource.name`과 route의 `Depends(key.dependency)`에 사용해야 한다. resource가 준비되지 않은 요청은 503으로 응답해야 한다. |
| SRS-ARC-004 | route, dependency, background callback은 `DefaultDocumentManagementSDK` 또는 저장소 client를 직접 생성해서는 안 된다. host adapter가 `docmesh-config` 설정 loader와 `docmesh-py-core` client factory를 사용해 저장소 client를 만들고, DMS v0.7의 `create_sdk_from_clients(...)`에 주입해야 한다. |
| SRS-ARC-005 | host-owned SDK factory 실패는 애플리케이션 startup을 중단해야 한다. DMS `DmsAssemblyPlan`은 host가 명시한 조립 정책을 받고 `check_on_startup=False`로 중복 network check를 비활성화해야 하며, required managed-resource health check는 FastAPI startup policy에 따라 실행하고 같은 check를 runtime readiness registry에도 등록해야 한다. |
| SRS-ARC-006 | lifespan 종료 시 resource를 역순 close해야 한다. 명시적 `ManagedResource.close`, SDK `aclose()`, SDK `close()` 순서의 지원 계약을 따르고, 하나의 close가 실패해도 나머지 close를 시도한 뒤 종료 오류를 전파·기록해야 한다. |
| SRS-ARC-007 | lifecycle 순서는 service runtime 조립, DMS resource 생성(`check_on_startup=False`), custom lifespan 진입·종료, DMS resource 역순 close, service runtime close여야 한다. |
| SRS-ARC-008 | host adapter는 metadata client와 MinIO client의 close callback을 idempotent wrapper로 DMS assembly에 전달해야 한다. DMS가 assembly rollback에서 callback을 호출한 뒤 host rollback이 다시 호출해도 성공한 client close는 client별 한 번만 실행되어야 한다. |

### 3.2 저장소와 설정

| ID | 요구사항 |
| --- | --- |
| SRS-STO-001 | 기본 배포 template은 `DMS_METADATA_BACKEND=postgresql`과 `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, 선택 `POSTGRES_PORT`로 metadata store를 구성해야 한다. `DMS_METADATA_BACKEND`는 `postgresql` 또는 `sqlite`만 허용하고 미지정 시 `postgresql`을 사용해야 한다. `POSTGRES_DSN`은 dms-core v0.7.0 host assembly에서 지원하지 않으며 발견 시 조립 전에 거부해야 한다. |
| SRS-STO-002 | PostgreSQL backend 선택 시 필수 연결 필드가 없거나 연결을 구성할 수 없으면 SDK 조립 또는 health 단계가 실패해야 한다. |
| SRS-STO-003 | 서비스는 `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`으로 object store를 구성해야 한다. |
| SRS-STO-004 | 제품 host adapter는 `docmesh-config`로 선택·검증한 설정을 `docmesh-py-core` client factory에 전달하고, 생성된 Engine·MinIO client를 `dms.create_sdk_from_clients(...)`에 주입해야 한다. DMS public package는 환경변수에서 client를 만들지 않으며 `MINIO_BUCKET`이 없거나 client를 구성할 수 없으면 host resource factory를 실패시켜야 한다. fastapi-core 서비스 설정에서의 필드 optional 여부와 제품 저장소 요구사항을 혼동해서는 안 된다. |
| SRS-STO-005 | DMS `ManagedResource.healthcheck`는 `sdk.check_health().ok`를 명시적으로 판정하고 required readiness check로 항상 등록해야 한다. DMS assembly의 `check_on_startup`은 `False`로 고정해 network check를 중복 실행하지 않으며, FastAPI managed-resource startup check가 startup/readiness 경계를 소유한다. service-runtime의 failure mode·retry 설정이 DMS check에 자동 적용된다고 가정해서는 안 된다. |
| SRS-STO-006 | 원본 filename, `created_by`, 사용자 정의 metadata는 선택된 document metadata store에 보관하고 MinIO object metadata에는 저장하지 않아야 한다. |
| SRS-STO-007 | 선택된 metadata store는 object를 찾기 위한 내부 `storage_key`를 보관할 수 있으나 일반 API response에 노출해서는 안 된다. |
| SRS-STO-008 | 로컬 개발에서 `DMS_METADATA_BACKEND=sqlite`를 선택할 수 있어야 하며 `SQLITE_PATH`를 필수로, `SQLITE_READONLY`, `SQLITE_ENABLE_WAL`, `SQLITE_BUSY_TIMEOUT_MS`, `SQLITE_CHECK_SAME_THREAD`, `SQLITE_ECHO`를 선택 설정으로 받아야 한다. SQLite는 metadata store만 대체하므로 MinIO는 계속 필수다. 운영·통합 release gate는 PostgreSQL을 사용한다. |
| SRS-STO-009 | PostgreSQL은 `POSTGRES_SSLMODE`, `POSTGRES_CONNECT_TIMEOUT_SECONDS`, `POSTGRES_POOL_SIZE`, `POSTGRES_MAX_OVERFLOW`, `POSTGRES_POOL_PRE_PING`, `POSTGRES_POOL_RECYCLE_SECONDS`, `POSTGRES_ECHO`, `POSTGRES_APPLICATION_NAME`을, MinIO는 `MINIO_SECURE`, `MINIO_CERT_CHECK`, `MINIO_REGION`, `MINIO_REQUEST_TIMEOUT_SECONDS`, `MINIO_MAX_RETRIES`를 환경변수로 조정할 수 있어야 한다. production 보안 모드에서는 `MINIO_SECURE=true`와 `MINIO_CERT_CHECK=true`를 강제해야 하며, 이 검증은 host config layer가 담당한다. |
| SRS-CFG-001 | startup 중 host-owned DMS factory는 선택된 PostgreSQL 또는 SQLite metadata store와 MinIO의 필수 값 누락·공백을 검증하고 실패를 애플리케이션 startup에 전파해야 한다. fastapi-core service runtime은 인증 등 활성 service 구성을 자체 경계에서 검증해야 하며 제품 애플리케이션은 두 검증을 중복 구현해서는 안 된다. |
| SRS-CFG-002 | password, access key, secret key, client secret은 secret provider 또는 환경변수에서 읽어야 하며 source code, 기본값, API response에 하드코딩해서는 안 된다. |
| SRS-CFG-003 | `ROOT_PATH`, `TOKEN_URL`, `CORS_ORIGINS`, `CORS_CREDENTIALS`, `DOCMESH_HEALTHCHECK_ENABLED`, `READINESS_PARALLEL`, `READINESS_TIMEOUT_SECONDS`, `READINESS_OVERALL_TIMEOUT_SECONDS`는 배포 환경별로 명시할 수 있어야 한다. `ROOT_PATH`는 ASGI root path이고 `TOKEN_URL`은 OpenAPI OAuth2 URL이며 실제 `/token` route를 변경하지 않는다. |
| SRS-CFG-004 | DMS SDK의 metadata store·MinIO 조립과 health 정책은 `DOCMESH_SERVICES` 및 `READINESS_REQUIRED_SERVICES`로 대체하거나 중복 조립해서는 안 된다. DMS aggregate health는 managed-resource readiness에, FastAPI service client health는 service-runtime readiness에 연결해야 한다. |
| SRS-CFG-005 | 공통 runtime 보안 판정은 `DOCMESH_ENV`, 선택 `DOCMESH_SECURITY_MODE`, `DOCMESH_PRODUCTION_ALIASES`를 사용해야 한다. 명시한 security mode는 환경 alias 판정보다 우선하며 production 저장소 TLS guardrail을 활성화해야 한다. |
| SRS-CFG-006 | FastAPI service runtime은 `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`, `DOCMESH_SERVICE_ALTERNATIVES`, `DOCMESH_STARTUP_FAILURE_MODE`, `DOCMESH_STARTUP_HEALTHCHECK_ATTEMPTS`, `DOCMESH_STARTUP_HEALTHCHECK_RETRY_DELAY_SECONDS`를 지원해야 한다. required service는 enabled service에 포함되어야 하며 대안 group 형식은 fastapi-core v0.7.0 parser 계약을 따라야 한다. 이 failure/retry 정책은 DMS managed-resource startup check에 자동 적용되지 않는다. |
| SRS-CFG-007 | Keycloak의 `KEYCLOAK_AUDIENCE`, `KEYCLOAK_REQUEST_TIMEOUT_SECONDS`, `KEYCLOAK_MAX_RETRIES`, `KEYCLOAK_JWKS_CACHE_TTL_SECONDS`를 배포별로 조정할 수 있어야 하며 client secret은 외부 secret으로 주입해야 한다. |
| SRS-CFG-008 | `.env.example`은 자동으로 로드되는 설정 파일이 아니라 배포 template이어야 한다. 실행 환경은 해당 값을 process environment 또는 secret mechanism으로 명시적으로 주입해야 한다. |
| SRS-CFG-009 | host adapter는 `DMS_CONFIGURATION_STRICT`를 선택적으로 받아야 하며 기본값은 `false`여야 한다. 값은 `true` 또는 `false`만 허용하고, `true`일 때 `docmesh_config.diagnose_services(..., selection_mode="strict")`로 PostgreSQL·SQLite backend의 동시 선택과 필수 MinIO bucket 누락을 client 생성 전에 진단해야 한다. 진단 실패와 잘못된 boolean 값은 `ConfigError`로 startup에 전파해야 한다. |

### 3.3 인증과 권한

| ID | 요구사항 |
| --- | --- |
| SRS-SEC-001 | 문서 생성, 목록·metadata·콘텐츠 조회, streaming download, soft delete, hard delete route는 인증된 사용자만 접근할 수 있어야 한다. |
| SRS-SEC-002 | 인증은 `fastapi-core`의 `get_current_user` dependency 또는 동등한 인증 사용자 dependency를 사용해야 한다. |
| SRS-SEC-003 | hard delete는 `require_permissions("document:delete:hard")` 또는 동등한 강화 권한 정책을 적용해야 한다. permission은 realm role, 모든 client role과 OAuth scope의 합집합에서 평가하며 요구 permission이 없으면 403을 반환해야 한다. |
| SRS-SEC-004 | 업로드 API는 `created_by` 입력값을 노출하지 않고 인증된 사용자의 `sub`를 SDK 요청에 설정해야 한다. |
| SRS-SEC-005 | 인증 실패는 401, 인증은 되었으나 권한이 부족한 경우는 403으로 응답해야 한다. |
| SRS-SEC-006 | credential을 허용하는 운영 CORS 구성은 명시적 origin을 사용해야 하며 wildcard origin을 사용해서는 안 된다. |

### 3.4 문서 도메인과 상태

HTTP 공개 metadata에는 최소 `document_id`, `original_filename`, `content_type`, `file_size`, `status`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `checksum`, 사용자 `metadata`를 포함해야 한다. SDK의 `extra_metadata`는 HTTP `metadata`로 validation alias 변환하고 `storage_key`는 포함해서는 안 된다. 공개 schema의 `status`는 자유 문자열이 아니라 dms-core v0.7.0 `DocumentStatus` enum이며 wire 값은 `uploaded`, `available`, `deleting`, `deleted`, `failed`다. 정상 업로드 응답은 `available`이고 일반 단건 조회와 상태 filter가 없는 목록 조회에서 `deleting`과 `deleted`는 SDK 정책에 따라 숨겨진다.

| ID | 요구사항 |
| --- | --- |
| SRS-DOM-001 | 업로드 성공 문서는 `available` 상태의 metadata와 접근 가능한 object를 가져야 한다. |
| SRS-DOM-002 | soft delete는 object를 삭제하고 metadata 상태를 `deleted` 및 `deleted_at`으로 갱신해 metadata를 보존해야 한다. |
| SRS-DOM-003 | hard delete는 object 삭제 후 metadata 행을 제거해야 한다. |
| SRS-DOM-004 | soft-deleted 문서의 단건 metadata·콘텐츠·streaming 조회는 존재하지 않는 문서와 같은 not-found 정책으로 차단해야 한다. readability와 삭제 상태 판정의 권위는 DMS SDK에 있으며 route는 이를 위해 별도 metadata/status 조회를 수행해서는 안 된다. 목록은 status filter를 통해 deleted metadata를 반환할 수 있다. |
| SRS-DOM-005 | `deleting` 중 object 삭제에 실패하면 SDK는 가능한 범위에서 `failed` 상태로 전환하고 오류를 반환해야 한다. |
| SRS-DOM-006 | metadata가 존재하지만 object가 없는 콘텐츠 조회는 consistency 오류로 처리해야 한다. |
| SRS-DOM-007 | 문서 복구와 버전 관리는 MVP에서 제공해서는 안 된다. |

### 3.5 HTTP 인터페이스

| 논리 기능 | HTTP method 및 URI | 성공 응답 |
| --- | --- | --- |
| 문서 생성 | `POST /documents` | `201 Created` + public metadata |
| 문서 목록 조회 | `GET /documents` | `200 OK` + cursor page (`items`, `next_cursor`, `has_more`) |
| metadata 조회 | `GET /documents/{document_id}` | `200 OK` + public metadata |
| 전체 콘텐츠 조회 | `GET /documents/{document_id}/content` | `200 OK` + streaming body |
| streaming download | `GET /documents/{document_id}/download` | `200 OK` + streaming body |
| soft delete | `DELETE /documents/{document_id}` | `200 OK` + 삭제 결과 |
| hard delete | `DELETE /documents/{document_id}?hard=true` | `200 OK` + 삭제 결과 |

| ID | 요구사항 |
| --- | --- |
| SRS-API-001 | `POST /documents`는 `multipart/form-data`로 `file`과 선택 `document_id`, JSON object를 직렬화한 text field `metadata`를 받고 filename과 content type은 `UploadFile`에서 읽어야 한다. `metadata` 생략 시 기본값은 `{}`이며 JSON 문법 오류 또는 object가 아닌 값은 framework validation 단계에서 400으로 정규화해야 한다. checksum은 dms-core v0.7.0 stream upload가 본문에서 파생하므로 multipart field로 전달하지 않는다. |
| SRS-API-002 | 업로드 route는 입력을 `UploadDocumentStreamRequest`로 변환해 `sdk.upload_document_stream(...)`을 호출하고 `ROOT_PATH`를 반영한 `Location` header와 public metadata를 반환해야 한다. |
| SRS-API-003 | 빈 본문, trim 후 빈 filename/content type, malformed JSON·배열·문자열·숫자·boolean·null metadata, 0 이하 chunk size 같은 잘못된 입력은 SDK·저장소 작업 전에 `400 VALIDATION_ERROR`로 반환해야 한다. |
| SRS-API-004 | `GET /documents`는 선택 `cursor`, 기본 `limit=100`, 선택 status filter를 SDK `list_documents(cursor=..., limit=..., status=...)`에 전달해야 한다. limit은 1~1000이며 cursor는 불투명하게 취급한다. 응답은 공개 metadata `items`, `next_cursor`, `has_more`를 포함하고 다음 page 요청은 cursor에 결합된 limit과 status를 유지해야 한다. |
| SRS-API-005 | `GET /documents/{document_id}`는 SDK의 readability 판정을 그대로 위임하고 반환된 공개 안전 metadata를 response allowlist schema로 직렬화해야 한다. route는 soft-delete 판정을 위한 중복 metadata 조회를 수행해서는 안 된다. |
| SRS-API-006 | `GET /documents/{document_id}/content`는 공개 `chunk_size` query를 노출하지 않고 SDK stream 기본값을 사용해야 한다. `DocumentContentStream.iter_chunks()`를 `StreamingResponse`로 전달하고 저장된 content type, `Content-Length`와 RFC 5987 방식의 안전한 inline `Content-Disposition`을 유지해야 한다. |
| SRS-API-007 | `GET /documents/{document_id}/download`는 `DocumentContentStream.iter_chunks()`를 `StreamingResponse`로 전달하고 `Content-Length`와 RFC 5987 방식의 attachment `Content-Disposition`을 설정해야 한다. 공개 `chunk_size` 기본값은 65,536 bytes이며 1 byte 이상 8 MiB 이하에서만 허용해야 한다. |
| SRS-API-008 | inline 및 attachment streaming response는 response 실행의 `finally` 경로에서 완료, 예외, 클라이언트 연결 종료 여부와 관계없이 `DocumentContentStream.close()`를 thread pool에서 호출해야 한다. |
| SRS-API-009 | soft delete route는 `sdk.soft_delete_document(document_id)`를, hard delete route는 권한 검사 후 `sdk.hard_delete_document(document_id)`를 호출해야 한다. async route는 동기 SDK 삭제 I/O를 thread pool에서 실행해 event loop를 차단하지 않아야 한다. 응답은 `document_id`, `deleted`, `hard_deleted`, `DocumentStatus` enum의 `status`만 공개해야 한다. |
| SRS-API-010 | 모든 HTTP 응답은 `X-Correlation-ID` header를 제공해야 하며 제품 오류 envelope는 같은 correlation ID를 포함해야 한다. 유효한 입력 ID는 보존하고 형식이 잘못된 입력 ID는 안전한 새 ID로 교체해야 한다. |

### 3.6 오류, health 및 관측성

오류 응답은 최소 다음 형태를 사용해야 한다.

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "..."
  }
}
```

| ID | 요구사항 |
| --- | --- |
| SRS-ERR-001 | validation, payload too large, document not found 또는 deleted, duplicate, configuration, storage, consistency 오류는 `DomainModule.error_mappers`의 `ErrorMapperSpec`으로 안정된 HTTP status와 기계 판독 가능한 code에 매핑하고, `create_app(error_renderer=...)`에 전달한 제품 renderer로 아래 envelope를 생성해야 한다. 크기 초과는 413, 진행 중인 멱등 요청은 425를 사용하며 fastapi-core 기본 Problem Detail renderer에 의존해서는 안 된다. |
| SRS-ERR-002 | `map_dms_error`는 예외 type의 MRO에서 가장 구체적인 매핑을 선택해야 하며, 등록되지 않은 `dms.DmsError` 하위 예외는 base `dms.DmsError` 매핑을 통해 내부 구현 정보를 노출하지 않고 `INTERNAL_ERROR`로 반환해야 한다. DMS 계층 밖의 정의되지 않은 예외도 같은 안전한 제품 오류로 반환해야 한다. |
| SRS-ERR-003 | object 저장 후 metadata 저장이 실패하면 SDK cleanup을 방해해서는 안 되며 cleanup 실패의 `ConsistencyError`는 별도 오류 code와 error-level log로 기록해야 한다. |
| SRS-ERR-004 | response body와 로그에는 문서 본문, access token, secret, password, 전체 DSN, `storage_key`, 내부 stack trace를 포함해서는 안 된다. |
| SRS-OPS-001 | 서비스는 `GET /health/liveness`에서 정상 프로세스에 200과 `status=ok`를 반환해야 한다. |
| SRS-OPS-002 | `GET /health/readiness`는 DMS SDK `HealthStatus.ok`를 판정하는 check에 연결해야 한다. check가 없거나 모두 정상이면 200 `ok`를 반환해야 한다. |
| SRS-OPS-003 | 선택된 PostgreSQL 또는 SQLite metadata store나 MinIO 장애는 required DMS dependency 실패로 간주하여 readiness 503과 `status=error`로 반환해야 한다. overall timeout도 503 `error`로 처리해야 한다. |
| SRS-OPS-004 | 선택 service만 실패한 경우 200과 `status=degraded`를 반환할 수 있으며, 외부 오류 상세는 `redact_errors` 정책에 따라 secret과 내부 endpoint를 마스킹해야 한다. |
| SRS-OPS-005 | correlation ID는 request state와 response header에 유지되고 오류 응답에서 같은 요청을 추적할 수 있어야 한다. |
| SRS-OPS-006 | `DOCMESH_LOG_LEVEL`, `APP_LOG_PATH`, `APP_LOG_JSON`, `APP_LOG_FORCE`로 application logging을 구성하고 `ACCESS_LOG_ENABLED`, `ACCESS_LOG_HEALTH_ENABLED`로 일반 access log와 health probe access log를 독립적으로 제어할 수 있어야 한다. 로그는 credential, DSN, `storage_key`와 문서 본문을 노출해서는 안 된다. |

### 3.7 품질 게이트

| ID | 요구사항 |
| --- | --- |
| SRS-NFR-001 | 기본 다운로드 경로는 전체 object를 애플리케이션 메모리에 적재하지 않는 streaming을 지원해야 한다. |
| SRS-NFR-002 | 서비스는 정상 종료, resource factory 실패 rollback, 역순 shutdown, streaming 완료·예외·연결 종료에서 resource close를 보장해야 한다. resource close 실패가 있어도 service runtime close를 시도해야 하며, DMS rollback과 host rollback의 중복 close 호출은 client별 한 번으로 수렴해야 한다. |
| SRS-NFR-003 | API contract test는 성공 응답, custom 오류 envelope, 인증·권한, auth router opt-in/out, content type, `Content-Disposition`, 유효·무효 correlation ID, required/optional readiness 상태를 검증해야 한다. |
| SRS-NFR-004 | integration test는 실제 PostgreSQL 및 MinIO를 사용해 upload, metadata 조회, download, soft/hard delete, health, startup failure를 검증해야 한다. |
| SRS-NFR-005 | 실패 주입 test는 metadata 저장 실패 뒤 object cleanup, cleanup 실패에 따른 consistency 오류, object 누락 consistency 오류를 검증해야 한다. |
| SRS-NFR-006 | route, dependency, exception mapper, metadata·object store, lifespan은 테스트에서 독립적으로 교체 또는 검증할 수 있어야 한다. |
| SRS-NFR-007 | 서비스는 Python 3.11 이상과 저장소에 고정된 `dms`, `docmesh-config`, `fastapi-core`, `docmesh-py-core` 조합에서 테스트를 통과해야 한다. |
| SRS-NFR-008 | OpenAPI 문서는 보호된 route의 인증 방식, 권한 요구사항, request/response schema, status code, 오류 code를 포함해야 한다. |

### 3.8 현재 자동화 검증 상태

아래 항목은 요구사항을 완화하지 않는 현재 저장소의 compliance gap이다. 릴리스 완료로 판단하기 전에 테스트를 보강해야 한다.

| 관련 요구사항 | 현재 검증 상태 | 미검증 범위 |
| --- | --- | --- |
| SRS-NFR-002 | 부분 충족 | DMS factory rollback에서 metadata·MinIO client의 중복 close 방지와 streaming 정상 완료·client disconnect close는 검증하지만 chunk iterator 자체 예외 경로의 close는 별도 테스트가 없다. |
| SRS-NFR-004 | 부분 충족 | 실제 PostgreSQL·MinIO integration test는 upload, metadata/download, hard delete, health를 검증한다. 실제 저장소 soft delete와 startup failure는 검증하지 않으며 startup factory failure는 unit/API 수준에서만 검증한다. |
| SRS-NFR-005 | 미충족 | metadata 저장 실패 뒤 object cleanup, cleanup 실패 consistency 오류, object 누락 consistency 오류의 application-level 실패 주입 테스트가 없다. |

## 4. PRD 추적성

| PRD 영역 | SRS 요구사항 |
| --- | --- |
| 애플리케이션 및 보안 | SRS-ARC-001 ~ SRS-ARC-007, SRS-SEC-001 ~ SRS-SEC-006 |
| 문서 lifecycle | SRS-DOM-001 ~ SRS-DOM-007, SRS-API-001 ~ SRS-API-010 |
| 오류 및 정합성 | SRS-ERR-001 ~ SRS-ERR-004 |
| 저장소·설정·운영 | SRS-STO-001 ~ SRS-STO-009, SRS-CFG-001 ~ SRS-CFG-008, SRS-OPS-001 ~ SRS-OPS-006 |
| 품질 및 검증 | SRS-NFR-001 ~ SRS-NFR-008 |