# 테스트 정의서

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.2 |
| 최종 코드 대조일 | 2026-07-18 |
| 참조 문서 | [PRD](prd.md), [SRS](srs.md), [API Reference](api.md), [설정 정의서](config.md) |

## 1. 목적과 범위

이 문서는 DocMesh Document Service의 **현재 자동화 테스트 기준선**과 미구현 테스트 backlog를 구분해 정의한다. 현재 suite는 unit/API 테스트와 실제 PostgreSQL·MinIO를 사용하는 일부 통합 테스트로 구성된다.

현재 구현된 저장소 통합 테스트의 범위는 다음과 같다.

- 실제 PostgreSQL·MinIO SDK를 사용한 upload
- HTTP 목록·metadata·streaming download
- 권한이 있을 때 hard delete; 역할이 없으면 해당 테스트 skip
- DMS SDK `check_health()`

HTTP `/content`, soft delete, HTTP readiness, startup 설정 누락, 저장소 장애·복구, 보상/정합성 실패 주입, 실제 무인증 401, secret log 비노출은 현재 통합 테스트로 구현되어 있지 않다.

Keycloak 자체의 protocol 적합성, reverse proxy, 부하·장시간 안정성 및 운영 플랫폼의 secret manager는 별도 시스템/E2E 테스트 범위로 둔다. 현재 document API 테스트는 인증 dependency를 override하며 hard-delete 403 분기를 검증한다. 실제 무인증 401과 통합 수준의 권한 거부 경로는 미구현이다.

## 2. 테스트 계층

| 계층 | 대상 | 외부 의존성 | 주요 검증 |
| --- | --- | --- | --- |
| 단위 테스트 | schema 변환, 오류 매핑, dependency, 권한 분기 | fake 또는 없음 | 빠른 경계값·분기 검증 |
| API 계약 테스트 | FastAPI route와 middleware | DMS SDK fake 허용 | status, header, schema, 오류 envelope |
| 통합 테스트 | FastAPI 앱 + 실제 DMS SDK + 저장소 adapter | 실제 PostgreSQL·MinIO | 영속화, object I/O, lifecycle, health, 정합성 |
| 시스템/E2E 테스트 | 배포된 서비스와 인증·proxy | 전체 배포 환경 | 공개 URL, token flow, network·TLS·운영 설정 |

현재 `test_docmesh_doc/integration/conftest.py`의 module-level `pytestmark`는 다른 test module에 전파되지 않는다. 따라서 현재 suite에서 `-m integration` / `-m "not integration"`은 통합 테스트를 신뢰성 있게 분리하지 못한다. 경로로 분리한다.

```bash
uv run pytest --ignore=test_docmesh_doc/integration
uv run pytest test_docmesh_doc/integration
uv run pytest
```

## 3. 통합 테스트 환경

### 3.1 필수 구성 요소

| 구성 요소 | 요구사항 |
| --- | --- |
| Python | 3.11 이상, 저장소 lockfile에 고정된 의존성 사용 |
| PostgreSQL | 테스트 전용 database/schema 및 계정 사용 |
| MinIO | 테스트 전용 bucket 또는 고유 prefix 사용 |
| 애플리케이션 | `create_application()` 및 `dms.create_sdk_from_environment(...)` 경로 사용 |
| 인증 | 보호 route는 테스트 사용자 override 또는 격리된 test realm/token 사용 |

통합 테스트는 SQLite, 메모리 metadata store, filesystem object store로 PostgreSQL·MinIO를 대체하지 않는다. 저장소 adapter를 mock하지 않고 `dms.create_sdk_from_environment(...)`가 실제 환경 설정으로 조립되는 경로를 검증한다.

### 3.2 환경변수

테스트 실행 환경에는 최소 다음 값을 secret 방식으로 주입한다.

```env
DOCMESH_ENV=test
DOCMESH_HEALTHCHECK_ENABLED=true
DMS_METADATA_BACKEND=postgresql
DMS_CONFIGURATION_STRICT=true
POSTGRES_HOST=<host>
POSTGRES_PORT=5432
POSTGRES_DB=<database>
POSTGRES_USER=<user>
POSTGRES_PASSWORD=<db-secret>
MINIO_ENDPOINT=<host>:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=<test-bucket>
MINIO_SECURE=false
```

인증 router를 포함해 앱을 시작하는 job은 `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_CLIENT_SECRET`도 제공한다. credential과 전체 연결 정보는 pytest 출력, assertion message, snapshot 및 CI artifact에 기록하지 않는다.

### 3.3 격리와 정리

1. 각 테스트는 충돌하지 않는 UUID 기반 `document_id`와 object key를 사용한다.
2. 테스트 전 PostgreSQL 연결과 MinIO bucket 접근 가능 여부를 확인한다. 의존성이 구성되지 않은 로컬 실행은 명시적으로 skip하되 CI integration job에서는 skip을 실패로 취급한다.
3. 현재 통합 테스트는 성공 경로 마지막에 hard delete를 직접 호출한다. assertion 중간 실패 시 fixture teardown이 document를 보장 정리하지 않으므로 잔여 데이터가 생길 수 있다.
4. 정리 자체가 실패하면 생성된 식별자만 안전하게 보고하고 테스트를 실패시킨다. credential, endpoint 상세, 문서 본문은 출력하지 않는다.
5. 통합 테스트를 병렬 실행할 경우 worker별 database/schema 또는 object prefix를 분리한다.
6. 테스트 간 실행 순서 의존성을 두지 않는다.

## 4. 공통 합격 기준

아래 항목은 통합 테스트에 대한 목표 계약이다. 현재 구현 여부는 §10의 기준선 표를 따른다.

- 성공·오류 응답의 HTTP status와 API schema가 [API Reference](api.md)와 일치한다.
- `X-Correlation-ID`가 호출자 제공값을 전달하거나 서버 생성값으로 반환된다.
- 외부 응답과 로그에 `storage_key`, credential, 전체 DSN, stack trace 및 문서 본문이 노출되지 않는다.
- PostgreSQL metadata와 MinIO object의 최종 상태가 기대 상태와 일치한다.
- response stream과 SDK가 정상·오류·shutdown 경로에서 닫힌다.
- 테스트 종료 후 잔여 metadata와 object가 없다. 단, 시나리오가 의도한 장애 상태를 검증한 직후 fixture가 정리한다.

## 5. 핵심 문서 lifecycle 시나리오

### INT-DOC-001 업로드와 영속화

**관련 요구사항:** FR-DOC-001, FR-DOC-008, FR-DOC-009, SRS-DOM-001, SRS-STO-006

1. filename, content type, 본문, checksum, 사용자 metadata를 포함해 `POST /documents`를 호출한다. `created_by`는 form field가 아니라 인증 사용자 `sub`에서 설정된다.
2. `201 Created`, `Location`, correlation ID 및 `available` metadata를 확인한다.
3. PostgreSQL에서 filename, uploader, checksum, 사용자 metadata 및 `storage_key`를 확인한다.
4. MinIO에서 object 본문과 크기를 확인한다.
5. MinIO object metadata에 filename, uploader 및 사용자 metadata가 저장되지 않았음을 확인한다.
6. API 응답에는 내부 `storage_key`가 없음을 확인한다.

### INT-DOC-002 서버 생성 document ID

**관련 요구사항:** FR-DOC-002

1. `document_id` 없이 서로 다른 문서를 두 번 업로드한다.
2. 두 응답의 ID가 비어 있지 않고 서로 다름을 확인한다.
3. 각 ID로 metadata와 본문을 독립적으로 조회할 수 있음을 확인한다.

### INT-DOC-003 metadata 및 전체 콘텐츠 조회

**관련 요구사항:** FR-DOC-003, FR-DOC-004, SRS-API-005, SRS-API-006

1. 문서를 업로드한 뒤 `GET /documents/{document_id}`를 호출한다.
2. 업로드 정보와 조회 metadata가 일치하고 `storage_key`가 노출되지 않음을 확인한다.
3. `GET /documents/{document_id}/content`의 body, `Content-Type`, `Content-Length`, 안전한 inline `Content-Disposition`을 확인한다.

### INT-DOC-003A 문서 목록 조회

**관련 요구사항:** FR-DOC-010, SRS-API-013

1. 문서를 업로드한 뒤 `GET /documents?status=available`을 호출한다.
2. 목록에 생성한 문서가 포함되고 `storage_key`가 노출되지 않음을 확인한다.
3. `offset`, `limit`, `status`가 SDK에 전달되며 잘못된 값은 저장소 호출 전에 `400 VALIDATION_ERROR`로 거부됨을 확인한다.

### INT-DOC-004 streaming download와 자원 정리

**관련 요구사항:** FR-DOC-005, SRS-API-007 ~ SRS-API-009, SRS-NFR-001 ~ SRS-NFR-002

1. 여러 chunk보다 큰 payload를 업로드한다.
2. 작은 양의 `chunk_size`로 `GET /documents/{document_id}/download`를 호출한다.
3. 수신한 chunk를 조합한 값이 원본과 같고 content header가 보존됨을 확인한다.
4. 정상 완료 후 MinIO response stream이 닫혔음을 확인한다.
5. 소비 중단 및 iterator 예외를 주입한 별도 테스트에서 stream close가 호출됨을 확인한다.
6. `chunk_size=0`은 저장소 호출 전에 `400 VALIDATION_ERROR`로 거부됨을 확인한다.

### INT-DOC-005 soft delete

**관련 요구사항:** FR-DOC-006, SRS-DOM-002, SRS-DOM-004

1. 문서를 업로드한 뒤 `DELETE /documents/{document_id}`를 호출한다.
2. 응답이 `hard_deleted=false`, 상태 `deleted`를 나타내는지 확인한다.
3. PostgreSQL metadata의 상태와 `deleted_at`이 갱신되었음을 확인한다.
4. MinIO object가 삭제되고 PostgreSQL의 deleted metadata는 보존되었음을 확인한다.
5. 이후 metadata, content, download 요청이 모두 동일한 not-found 정책을 따르는지 확인한다.

### INT-DOC-006 hard delete와 권한

**관련 요구사항:** FR-DOC-007, SRS-SEC-003, SRS-DOM-003

1. 권한 없는 사용자로 `DELETE /documents/{document_id}?hard=true`를 호출해 `403 FORBIDDEN`을 확인한다.
2. 이때 PostgreSQL metadata와 MinIO object가 모두 유지됨을 확인한다.
3. `document:delete:hard` 역할을 가진 사용자로 다시 호출해 성공 응답을 확인한다.
4. PostgreSQL metadata 행과 MinIO object가 모두 제거되었음을 확인한다.
5. 삭제 후 조회와 download가 not-found를 반환하는지 확인한다.

### INT-DOC-007 중복 ID와 존재하지 않는 문서

**관련 요구사항:** FR-ERR-001, FR-ERR-005, SRS-API-004

1. 같은 `document_id`로 두 번째 업로드를 시도해 `409 DOCUMENT_ALREADY_EXISTS`를 확인한다.
2. 최초 metadata와 object가 변경되지 않았음을 확인한다.
3. 존재하지 않는 ID의 metadata, content, download, delete가 계약에 정의된 not-found 응답을 반환하는지 확인한다.

## 6. lifecycle 및 health 시나리오

### INT-OPS-001 정상 startup과 shutdown

**관련 요구사항:** FR-APP-001 ~ FR-APP-004, SRS-ARC-001 ~ SRS-ARC-007

1. 실제 환경 factory로 애플리케이션 lifespan을 시작한다.
2. SDK가 한 번만 생성되고 여러 요청에서 `app.state.resource_registry`의 같은 managed resource 인스턴스를 사용하는지 확인한다.
3. liveness가 `200`을 반환하는지 확인한다.
4. PostgreSQL·MinIO가 정상일 때 readiness가 `200`을 반환하는지 확인한다.
5. lifespan 종료 시 SDK와 저장소 client가 닫히는지 확인한다.

### INT-OPS-002 필수 설정 누락에 따른 startup 실패

**관련 요구사항:** FR-OPS-003, SRS-STO-002, SRS-STO-004, SRS-CFG-001

`POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`을 각각 제거하거나 공백으로 설정한 parameterized test를 실행한다. 각 경우 요청 수신 전 startup이 실패하고 오류에 secret 또는 전체 연결 정보가 포함되지 않음을 확인한다.

### INT-OPS-003 PostgreSQL 장애와 readiness

**관련 요구사항:** FR-OPS-006, SRS-ERR-005, SRS-OPS-002 ~ SRS-OPS-005

1. 정상 기동 후 테스트 제어로 PostgreSQL 연결을 차단한다.
2. readiness가 `503` 및 오류 상태를 반환하는지 확인한다.
3. metadata 작업이 문서화된 metadata/dependency 오류로 매핑되는지 확인한다.
4. response와 로그에 DSN 또는 password가 노출되지 않음을 확인한다.
5. 연결 복구 후 readiness가 다시 정상화되는지 확인한다.

### INT-OPS-004 MinIO 장애와 readiness

**관련 요구사항:** FR-OPS-006, SRS-ERR-005, SRS-OPS-002 ~ SRS-OPS-005

1. 정상 기동 후 MinIO 접근을 차단하거나 bucket 권한을 제거한다.
2. readiness가 `503`을 반환하는지 확인한다.
3. object 작업이 문서화된 storage/dependency 오류로 매핑되는지 확인한다.
4. endpoint와 access key가 외부 응답 및 로그에 노출되지 않음을 확인한다.
5. 접근 복구 후 readiness가 다시 정상화되는지 확인한다.

## 7. 실패 주입 및 정합성 시나리오

실패 주입은 HTTP route를 mock하는 방식이 아니라 실제 SDK와 한쪽 실제 저장소를 유지한 채 adapter 경계 또는 제어 가능한 proxy에서 특정 저장소 작업만 실패시키는 방식으로 수행한다.

### INT-CON-001 metadata 저장 실패 후 object cleanup

**관련 요구사항:** FR-ERR-003, SRS-ERR-003, SRS-NFR-005

1. MinIO object 저장은 성공하고 PostgreSQL metadata 저장만 실패하도록 주입한다.
2. 업로드가 문서화된 오류 응답을 반환하는지 확인한다.
3. SDK가 생성한 MinIO object를 제거했는지 확인한다.
4. PostgreSQL metadata와 MinIO object가 모두 남지 않았음을 확인한다.

### INT-CON-002 cleanup 실패에 따른 consistency 오류

**관련 요구사항:** FR-ERR-004, SRS-ERR-003

1. PostgreSQL metadata 저장 실패와 후속 MinIO object 삭제 실패를 함께 주입한다.
2. API가 `500 DOCUMENT_CONSISTENCY_ERROR`를 반환하는지 확인한다.
3. correlation ID가 응답과 error-level 구조화 로그에서 연결되는지 확인한다.
4. 로그에 credential과 본문이 없음을 확인한다.
5. 잔여 object를 확인한 후 fixture에서 강제 정리한다.

### INT-CON-003 metadata는 존재하지만 object가 없음

**관련 요구사항:** FR-ERR-004, SRS-ERR-004

1. 정상 업로드 후 테스트 fixture가 MinIO object만 제거한다.
2. content와 download 요청이 `DOCUMENT_CONSISTENCY_ERROR`로 처리되는지 확인한다.
3. metadata 조회 정책은 API 계약에 따른 결과를 반환하는지 확인한다.
4. 오류 로그에 document ID와 correlation ID가 있고 storage credential은 없는지 확인한다.

### INT-CON-004 hard delete 중 object 삭제 실패

**관련 요구사항:** SRS-DOM-003, SRS 상태 전이 정책

1. hard delete의 MinIO object 삭제만 실패하도록 주입한다.
2. API가 storage 오류를 반환하는지 확인한다.
3. PostgreSQL metadata가 제거되지 않고 SDK 계약에 따른 `failed` 또는 재시도 가능한 상태로 남는지 확인한다.
4. 장애 해제 후 재시도 결과가 object와 metadata를 모두 제거하는지 확인한다.

## 8. 인증 및 API 계약 시나리오

| ID | 시나리오 | 기대 결과 |
| --- | --- | --- |
| INT-SEC-001 | 인증 정보 없이 각 document route 호출 | `401 UNAUTHENTICATED`, 저장소 변경 없음 |
| INT-SEC-002 | 일반 사용자 hard delete | `403 FORBIDDEN`, 저장소 변경 없음 |
| INT-SEC-003 | 권한 사용자 hard delete | 성공 및 metadata/object 제거 |
| INT-API-001 | 호출자가 correlation ID 제공 | 동일 ID가 성공·오류 응답에 반환 |
| INT-API-002 | correlation ID 생략 | 서버 생성 non-empty ID 반환 |
| INT-API-003 | 빈 파일, 빈 filename/content type, 잘못된 metadata JSON | `400 VALIDATION_ERROR`, 저장소 변경 없음 |
| INT-API-004 | 특수문자·비ASCII filename 다운로드 | 안전한 UTF-8 `Content-Disposition`, header injection 없음 |
| INT-API-005 | 공개 OpenAPI schema 확인 | 보호 route, request/response schema, status 및 security scheme 존재 |

## 9. 자동화 및 실행 정책

### 9.1 pytest 구성

- 통합 테스트 파일은 `test_docmesh_doc/integration/` 아래에 둔다.
- 파일명은 `test_*.py`, 함수명은 `test_*` 규칙을 따른다.
- marker 분리를 사용할 경우 실제 test module 또는 test function에 `@pytest.mark.integration`을 적용해야 한다. 현재는 integration `conftest.py`에만 있어 전파되지 않는다.
- 외부 서비스 fixture는 session scope로 연결 상태를 관리하되, 테스트 데이터는 function scope로 격리한다.
- timeout을 명시하여 외부 서비스 장애가 무한 대기로 이어지지 않게 한다.
- retry는 서비스 기동·복구와 같은 eventual consistency 확인에만 제한적으로 사용하며 업무 assertion 실패를 숨기지 않는다.

### 9.2 CI 단계

1. 잠금 파일 기준으로 의존성을 설치한다.
2. PostgreSQL과 MinIO를 고정 버전 service container로 시작한다.
3. PostgreSQL health와 MinIO bucket 준비를 확인한다.
4. 현재 marker 문제를 수정하기 전에는 `uv run pytest --ignore=test_docmesh_doc/integration`을 실행한다.
5. `uv run pytest test_docmesh_doc/integration`을 실행한다.
6. 현재 hard-delete 통합 테스트는 test user role이 없으면 skip될 수 있다. CI에서 skip을 금지하려면 해당 role을 fixture에 제공하고 별도 정책을 구성해야 한다.
7. 실패 시 JUnit과 마스킹된 애플리케이션 로그만 artifact로 보관한다.
8. 성공·실패와 관계없이 test database, bucket object 및 container를 정리한다.

## 10. 현재 자동화 기준선

| 영역 | 현재 자동화 상태 |
| --- | --- |
| 앱/resource lifecycle | SDK 생성·재사용, readiness `dms` 성공/실패, 정상 close, close 실패, SDK factory 실패를 단위 테스트 |
| upload | stream request 변환, validation, 인증 사용자 `created_by`, 공개 metadata를 API 테스트; 실제 저장소 upload를 통합 테스트 |
| 목록/metadata/content | 목록·metadata는 fake SDK API 테스트와 실제 저장소 통합 테스트. `/content`는 soft-deleted 404 guard만 API 테스트하며 정상 body/header는 미검증 |
| streaming | header/body/chunk 전달과 정상 완료 close를 API 테스트; 실제 저장소 download를 통합 테스트 |
| delete | soft/hard SDK 분기와 hard-delete 403을 API 테스트; hard delete만 실제 저장소 통합 테스트하며 role 부재 시 skip |
| 오류 | validation 400, document 404, 일반 route 404, hard-delete 403 envelope를 테스트 |
| health | managed `dms` readiness를 단위 테스트하고 SDK health를 통합 테스트; HTTP 장애·복구는 미구현 |
| 미구현 backlog | `INT-DOC-002`, HTTP content/soft delete, `INT-OPS-002~004`, `INT-CON-*`, 실제 `INT-SEC-001`, OpenAPI 오류/binary schema, secret log 검사, stream 예외/client disconnect |

아래 §5~§8의 `INT-*` 시나리오는 현재 구현된 테스트와 향후 backlog를 함께 정의한 catalog다. 이 표에서 미구현으로 명시한 항목을 이미 통과한 release gate로 해석하지 않는다.

## 11. 요구사항 추적성

| 요구사항 영역 | 통합 테스트 |
| --- | --- |
| 앱 조립 및 lifecycle | INT-OPS-001, INT-OPS-002 |
| upload 및 metadata 영속화 | INT-DOC-001, INT-DOC-002 |
| 조회 및 streaming | INT-DOC-003, INT-DOC-003A, INT-DOC-004 |
| soft/hard delete | INT-DOC-005, INT-DOC-006, INT-CON-004 |
| 오류 및 정합성 | INT-DOC-007, INT-CON-001 ~ INT-CON-004 |
| health/readiness | INT-OPS-001, INT-OPS-003, INT-OPS-004 |
| 인증·권한 | INT-SEC-001 ~ INT-SEC-003 |
| API 계약·보안 | INT-API-001 ~ INT-API-005 |
| SRS-NFR-004 | INT-DOC-001 ~ INT-DOC-007, INT-OPS-001 ~ INT-OPS-004 |
| SRS-NFR-005 | INT-CON-001 ~ INT-CON-004 |
