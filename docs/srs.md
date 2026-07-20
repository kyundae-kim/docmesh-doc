# 소프트웨어 요구사항 정의서 (SRS)

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 대상 릴리스 | MVP |
| 최종 코드 대조일 | 2026-07-20 |
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
| 승인된 배포 구성 | 배포 template은 PostgreSQL metadata store와 MinIO object store를 사용한다. |

## 3. 소프트웨어 요구사항

### 3.1 애플리케이션 구조와 lifecycle

| ID | 요구사항 |
| --- | --- |
| SRS-ARC-001 | 애플리케이션은 `fastapi_core.create_app(config=..., resources=..., error_renderer=..., include_auth_router=...)`으로 생성해야 한다. `fastapi-core` v0.5.0의 auth router 기본값은 `False`지만 제품 `create_application()`은 기본 제품 앱에 `/token`, `/user`를 포함하도록 `True`를 명시해야 한다. |
| SRS-ARC-002 | DMS route는 공통 health route와 충돌하지 않는 별도 router로 등록해야 한다. |
| SRS-ARC-003 | `ResourceKey[DefaultDocumentManagementSDK]("dms")`를 선언하고 같은 key를 `ManagedResource.name`과 route의 `Depends(key.dependency)`에 사용해야 한다. resource가 준비되지 않은 요청은 503으로 응답해야 한다. |
| SRS-ARC-004 | route, dependency, background callback은 `DefaultDocumentManagementSDK` 또는 저장소 client를 직접 생성해서는 안 된다. SDK는 DMS의 공개 environment, service-config 또는 component factory 중 제품이 선택한 factory로 생성해야 한다. |
| SRS-ARC-005 | SDK factory 실패는 애플리케이션 startup을 중단해야 한다. required managed-resource startup health check는 `DOCMESH_HEALTHCHECK_ENABLED=true`일 때 실행하며, 비활성화되어도 같은 check를 runtime readiness registry에는 등록해야 한다. |
| SRS-ARC-006 | lifespan 종료 시 resource를 역순 close해야 한다. 명시적 `ManagedResource.close`, SDK `aclose()`, SDK `close()` 순서의 지원 계약을 따르고, 하나의 close가 실패해도 나머지 close를 시도한 뒤 종료 오류를 전파·기록해야 한다. |
| SRS-ARC-007 | lifecycle 순서는 service runtime 조립, DMS resource 생성·선택적 startup check, custom lifespan 진입·종료, DMS resource 역순 close, service runtime close여야 한다. |

### 3.2 저장소와 설정

| ID | 요구사항 |
| --- | --- |
| SRS-STO-001 | PostgreSQL template은 `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`와 선택 `POSTGRES_PORT`로 metadata store를 구성해야 한다. `POSTGRES_DSN`은 dms-core v0.5.0에서 단독·병용 모두 지원하지 않으며 발견 시 조립 전에 거부해야 한다. |
| SRS-STO-002 | PostgreSQL backend 선택 시 필수 연결 필드가 없거나 연결을 구성할 수 없으면 SDK 조립 또는 health 단계가 실패해야 한다. |
| SRS-STO-003 | 서비스는 `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`으로 object store를 구성해야 한다. |
| SRS-STO-004 | 제품 DMS 조립 계층은 `MINIO_BUCKET`을 필수로 검증해야 하며, bucket이 없거나 client를 구성할 수 없으면 DMS resource factory를 실패시켜야 한다. fastapi-core 서비스 설정에서의 필드 optional 여부와 제품 저장소 요구사항을 혼동해서는 안 된다. |
| SRS-STO-005 | DMS `ManagedResource.healthcheck`는 `sdk.check_health().ok`를 명시적으로 판정하고 required readiness check로 항상 등록해야 한다. `DOCMESH_HEALTHCHECK_ENABLED`는 DMS environment factory와 FastAPI managed-resource startup 사전 실행에 각각 소비되므로 배포에서 값을 명시해야 한다. 값이 없으면 DMS factory는 startup check를 기본 실행하지만 FastAPI는 managed-resource startup check를 기본 생략한다. service-runtime의 failure mode·retry 설정은 managed-resource check에 자동 적용되지 않는다. |
| SRS-STO-006 | 원본 filename, `created_by`, 사용자 정의 metadata는 PostgreSQL document metadata에 보관하고 MinIO object metadata에는 저장하지 않아야 한다. |
| SRS-STO-007 | PostgreSQL metadata는 object를 찾기 위한 내부 `storage_key`를 보관할 수 있으나 일반 API response에 노출해서는 안 된다. |
| SRS-CFG-001 | 서비스는 startup 전에 PostgreSQL·MinIO·인증 구성의 필수 값 누락 또는 공백을 검증해야 한다. |
| SRS-CFG-002 | password, access key, secret key, client secret은 secret provider 또는 환경변수에서 읽어야 하며 source code, 기본값, API response에 하드코딩해서는 안 된다. |
| SRS-CFG-003 | `ROOT_PATH`, `TOKEN_URL`, `CORS_ORIGINS`, `CORS_CREDENTIALS`, `DOCMESH_HEALTHCHECK_ENABLED`, `READINESS_PARALLEL`, `READINESS_TIMEOUT_SECONDS`, `READINESS_OVERALL_TIMEOUT_SECONDS`는 배포 환경별로 명시할 수 있어야 한다. `ROOT_PATH`는 ASGI root path이고 `TOKEN_URL`은 OpenAPI OAuth2 URL이며 실제 `/token` route를 변경하지 않는다. |
| SRS-CFG-004 | DMS SDK의 PostgreSQL·MinIO 조립과 health 정책은 `DOCMESH_SERVICES` 및 `READINESS_REQUIRED_SERVICES`로 대체하거나 중복 조립해서는 안 된다. DMS aggregate health는 managed-resource readiness에, FastAPI service client health는 service-runtime readiness에 연결해야 한다. |

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

HTTP 공개 metadata에는 최소 `document_id`, `original_filename`, `content_type`, `file_size`, `status`, `created_at`, `updated_at`, `deleted_at`, `created_by`, `checksum`, 사용자 `metadata`를 포함해야 한다. SDK의 `extra_metadata`는 HTTP `metadata`로 validation alias 변환하고 `storage_key`는 포함해서는 안 된다.

| ID | 요구사항 |
| --- | --- |
| SRS-DOM-001 | 업로드 성공 문서는 `available` 상태의 metadata와 접근 가능한 object를 가져야 한다. |
| SRS-DOM-002 | soft delete는 object를 삭제하고 metadata 상태를 `deleted` 및 `deleted_at`으로 갱신해 metadata를 보존해야 한다. |
| SRS-DOM-003 | hard delete는 object 삭제 후 metadata 행을 제거해야 한다. |
| SRS-DOM-004 | soft-deleted 문서의 단건 metadata·콘텐츠·streaming 조회는 존재하지 않는 문서와 같은 not-found 정책으로 차단해야 한다. 목록은 status filter를 통해 deleted metadata를 반환할 수 있다. |
| SRS-DOM-005 | `deleting` 중 object 삭제에 실패하면 SDK는 가능한 범위에서 `failed` 상태로 전환하고 오류를 반환해야 한다. |
| SRS-DOM-006 | metadata가 존재하지만 object가 없는 콘텐츠 조회는 consistency 오류로 처리해야 한다. |
| SRS-DOM-007 | 문서 복구와 버전 관리는 MVP에서 제공해서는 안 된다. |

### 3.5 HTTP 인터페이스

| 논리 기능 | HTTP method 및 URI | 성공 응답 |
| --- | --- | --- |
| 문서 생성 | `POST /documents` | `201 Created` + public metadata |
| 문서 목록 조회 | `GET /documents` | `200 OK` + public metadata 배열 |
| metadata 조회 | `GET /documents/{document_id}` | `200 OK` + public metadata |
| 전체 콘텐츠 조회 | `GET /documents/{document_id}/content` | `200 OK` + bytes |
| streaming download | `GET /documents/{document_id}/download` | `200 OK` + streaming body |
| soft delete | `DELETE /documents/{document_id}` | `200 OK` + 삭제 결과 |
| hard delete | `DELETE /documents/{document_id}?hard=true` | `200 OK` + 삭제 결과 |

| ID | 요구사항 |
| --- | --- |
| SRS-API-001 | `POST /documents`는 `multipart/form-data`로 `file`과 선택 `document_id`, `metadata`, `checksum`을 받고 filename과 content type은 `UploadFile`에서 읽어야 한다. |
| SRS-API-002 | 업로드 route는 입력을 `UploadDocumentStreamRequest`로 변환해 `sdk.upload_document_stream(...)`을 호출하고 `Location` header와 public metadata를 반환해야 한다. |
| SRS-API-003 | 빈 본문, trim 후 빈 filename/content type, 0 이하 chunk size 같은 잘못된 입력은 저장소 작업 전에 validation 오류로 반환해야 한다. |
| SRS-API-004 | `GET /documents`는 `offset=0`, `limit=100`을 기본으로 하고 각각 0 이상, 1 이상으로 검증한 뒤 선택 status filter와 함께 SDK `list_documents(...)`에 전달해야 한다. HTTP API는 dms-core의 cursor API를 노출하지 않으며 공개 metadata만 반환해야 한다. |
| SRS-API-005 | `GET /documents/{document_id}`는 공개 안전 metadata 결과를 response allowlist schema로 직렬화해야 한다. |
| SRS-API-006 | `GET /documents/{document_id}/content`는 저장된 content type과 안전한 inline `Content-Disposition`을 유지해야 한다. |
| SRS-API-007 | `GET /documents/{document_id}/download`는 `DocumentContentStream.iter_chunks()`를 `StreamingResponse`로 전달하고 attachment `Content-Disposition`을 설정해야 한다. |
| SRS-API-008 | streaming response는 완료, 예외, 클라이언트 연결 종료의 모든 경로에서 `DocumentContentStream.close()`를 호출해야 한다. |
| SRS-API-009 | soft delete route는 `sdk.soft_delete_document(document_id)`를, hard delete route는 권한 검사 후 `sdk.hard_delete_document(document_id)`를 호출해야 한다. 응답은 `document_id`, `deleted`, `hard_deleted`, `status`만 공개해야 한다. |
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
| SRS-ERR-001 | validation, document not found 또는 deleted, duplicate, configuration, storage, consistency 오류는 `register_error_mapper(...)`로 안정된 HTTP status와 기계 판독 가능한 code에 매핑하고, `create_app(error_renderer=...)`에 전달한 제품 renderer로 아래 envelope를 생성해야 한다. fastapi-core 기본 Problem Detail renderer에 의존해서는 안 된다. |
| SRS-ERR-002 | 정의되지 않은 예외는 제품 handler/renderer에서 내부 구현 정보를 노출하지 않고 `INTERNAL_ERROR`로 반환해야 한다. |
| SRS-ERR-003 | object 저장 후 metadata 저장이 실패하면 SDK cleanup을 방해해서는 안 되며 cleanup 실패의 `ConsistencyError`는 별도 오류 code와 error-level log로 기록해야 한다. |
| SRS-ERR-004 | response body와 로그에는 문서 본문, access token, secret, password, 전체 DSN, `storage_key`, 내부 stack trace를 포함해서는 안 된다. |
| SRS-OPS-001 | 서비스는 `GET /health/liveness`에서 정상 프로세스에 200과 `status=ok`를 반환해야 한다. |
| SRS-OPS-002 | `GET /health/readiness`는 DMS SDK `HealthStatus.ok`를 판정하는 check에 연결해야 한다. check가 없거나 모두 정상이면 200 `ok`를 반환해야 한다. |
| SRS-OPS-003 | PostgreSQL 또는 MinIO 장애는 required DMS dependency 실패로 간주하여 readiness 503과 `status=error`로 반환해야 한다. overall timeout도 503 `error`로 처리해야 한다. |
| SRS-OPS-004 | 선택 service만 실패한 경우 200과 `status=degraded`를 반환할 수 있으며, 외부 오류 상세는 `redact_errors` 정책에 따라 secret과 내부 endpoint를 마스킹해야 한다. |
| SRS-OPS-005 | correlation ID는 request state와 response header에 유지되고 오류 응답에서 같은 요청을 추적할 수 있어야 한다. |

### 3.7 품질 게이트

| ID | 요구사항 |
| --- | --- |
| SRS-NFR-001 | 기본 다운로드 경로는 전체 object를 애플리케이션 메모리에 적재하지 않는 streaming을 지원해야 한다. |
| SRS-NFR-002 | 서비스는 정상 종료, resource factory 실패 rollback, 역순 shutdown, streaming 완료·예외·연결 종료에서 resource close를 보장해야 한다. resource close 실패가 있어도 service runtime close를 시도해야 한다. |
| SRS-NFR-003 | API contract test는 성공 응답, custom 오류 envelope, 인증·권한, auth router opt-in/out, content type, `Content-Disposition`, 유효·무효 correlation ID, required/optional readiness 상태를 검증해야 한다. |
| SRS-NFR-004 | integration test는 실제 PostgreSQL 및 MinIO를 사용해 upload, metadata 조회, download, soft/hard delete, health, startup failure를 검증해야 한다. |
| SRS-NFR-005 | 실패 주입 test는 metadata 저장 실패 뒤 object cleanup, cleanup 실패에 따른 consistency 오류, object 누락 consistency 오류를 검증해야 한다. |
| SRS-NFR-006 | route, dependency, exception mapper, metadata·object store, lifespan은 테스트에서 독립적으로 교체 또는 검증할 수 있어야 한다. |
| SRS-NFR-007 | 서비스는 Python 3.11 이상과 저장소에 고정된 `dms`, `fastapi-core`, `docmesh-py-core` 조합에서 테스트를 통과해야 한다. |
| SRS-NFR-008 | OpenAPI 문서는 보호된 route의 인증 방식, 권한 요구사항, request/response schema, status code, 오류 code를 포함해야 한다. |

## 4. PRD 추적성

| PRD 영역 | SRS 요구사항 |
| --- | --- |
| 애플리케이션 및 보안 | SRS-ARC-001 ~ SRS-ARC-007, SRS-SEC-001 ~ SRS-SEC-006 |
| 문서 lifecycle | SRS-DOM-001 ~ SRS-DOM-007, SRS-API-001 ~ SRS-API-010 |
| 오류 및 정합성 | SRS-ERR-001 ~ SRS-ERR-004 |
| 저장소·설정·운영 | SRS-STO-001 ~ SRS-STO-007, SRS-CFG-001 ~ SRS-CFG-004, SRS-OPS-001 ~ SRS-OPS-005 |
| 품질 및 검증 | SRS-NFR-001 ~ SRS-NFR-008 |