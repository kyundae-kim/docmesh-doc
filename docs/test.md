# 테스트 정의서

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 참조 문서 | [PRD](prd.md), [SRS](srs.md), [API Reference](api.md), [설정 정의서](config.md) |

## 1. 목적과 범위

이 문서는 DocMesh Document Service의 테스트 계층, 통합 테스트 환경, 시나리오 및 합격 기준을 정의한다. 특히 잠금된 `dms`, `fastapi-core`, `docmesh-py-core` 조합을 실제 PostgreSQL 및 MinIO와 연결하여 HTTP API부터 영속 저장소까지의 동작을 검증한다.

통합 테스트의 범위는 다음과 같다.

- FastAPI lifespan을 통한 DMS SDK 생성·재사용·종료
- 실제 PostgreSQL metadata store와 MinIO object store를 사용하는 문서 lifecycle
- upload, metadata/content 조회, streaming download, soft delete, hard delete
- liveness와 PostgreSQL·MinIO 상태를 반영한 readiness
- 필수 설정 누락 및 외부 의존성 장애 시 startup/readiness 동작
- metadata/object 저장 실패와 보상 처리, 정합성 오류
- 외부 API 계약, 인증·권한 및 secret 비노출

Keycloak 자체의 protocol 적합성, reverse proxy, 부하·장시간 안정성 및 운영 플랫폼의 secret manager는 별도 시스템/E2E 테스트 범위로 둔다. 다만 document route의 인증·권한 계약은 통합 테스트에서 검증한다.

## 2. 테스트 계층

| 계층 | 대상 | 외부 의존성 | 주요 검증 |
| --- | --- | --- | --- |
| 단위 테스트 | schema 변환, 오류 매핑, dependency, 권한 분기 | fake 또는 없음 | 빠른 경계값·분기 검증 |
| API 계약 테스트 | FastAPI route와 middleware | DMS SDK fake 허용 | status, header, schema, 오류 envelope |
| 통합 테스트 | FastAPI 앱 + 실제 DMS SDK + 저장소 adapter | 실제 PostgreSQL·MinIO | 영속화, object I/O, lifecycle, health, 정합성 |
| 시스템/E2E 테스트 | 배포된 서비스와 인증·proxy | 전체 배포 환경 | 공개 URL, token flow, network·TLS·운영 설정 |

`@pytest.mark.integration`은 PostgreSQL 또는 MinIO와 같은 실제 외부 서비스를 요구하는 테스트에만 적용한다. 기본 개발 테스트와 CI 통합 테스트 job은 marker로 분리 실행할 수 있어야 한다.

```bash
uv run pytest -m "not integration"
uv run pytest -m integration
uv run pytest
```

## 3. 통합 테스트 환경

### 3.1 필수 구성 요소

| 구성 요소 | 요구사항 |
| --- | --- |
| Python | 3.11 이상, 저장소 lockfile에 고정된 의존성 사용 |
| PostgreSQL | 테스트 전용 database/schema 및 계정 사용 |
| MinIO | 테스트 전용 bucket 또는 고유 prefix 사용 |
| 애플리케이션 | production과 동일한 `create_application()` 및 `sdk_from_environment()` 경로 사용 |
| 인증 | 보호 route는 테스트 사용자 override 또는 격리된 test realm/token 사용 |

통합 테스트는 SQLite, 메모리 metadata store, filesystem object store로 PostgreSQL·MinIO를 대체하지 않는다. 저장소 adapter를 mock하지 않고 `dms.create_sdk_from_environment(...)`가 실제 환경 설정으로 조립되는 경로를 검증한다.

### 3.2 환경변수

테스트 실행 환경에는 최소 다음 값을 secret 방식으로 주입한다.

```env
DOCMESH_ENV=test
DOCMESH_HEALTHCHECK_ENABLED=true
POSTGRES_DSN=postgresql://<user>:<password>@<host>:5432/<database>
MINIO_ENDPOINT=<host>:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=<test-bucket>
MINIO_SECURE=false
```

인증 router를 포함해 앱을 시작하는 job은 `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`, `KEYCLOAK_CLIENT_SECRET`도 제공한다. credential과 전체 DSN은 pytest 출력, assertion message, snapshot 및 CI artifact에 기록하지 않는다.

### 3.3 격리와 정리

1. 각 테스트는 충돌하지 않는 UUID 기반 `document_id`와 object key를 사용한다.
2. 테스트 전 PostgreSQL 연결과 MinIO bucket 접근 가능 여부를 확인한다. 의존성이 구성되지 않은 로컬 실행은 명시적으로 skip하되 CI integration job에서는 skip을 실패로 취급한다.
3. 테스트가 생성한 metadata와 object는 성공·실패 여부와 관계없이 fixture teardown에서 제거한다.
4. 정리 자체가 실패하면 생성된 식별자만 안전하게 보고하고 테스트를 실패시킨다. credential, endpoint 상세, 문서 본문은 출력하지 않는다.
5. 통합 테스트를 병렬 실행할 경우 worker별 database/schema 또는 object prefix를 분리한다.
6. 테스트 간 실행 순서 의존성을 두지 않는다.

## 4. 공통 합격 기준

모든 통합 시나리오는 해당 동작뿐 아니라 다음 공통 계약을 함께 확인한다.

- 성공·오류 응답의 HTTP status와 API schema가 [API Reference](api.md)와 일치한다.
- `X-Correlation-ID`가 호출자 제공값을 전달하거나 서버 생성값으로 반환된다.
- 외부 응답과 로그에 `storage_key`, credential, 전체 DSN, stack trace 및 문서 본문이 노출되지 않는다.
- PostgreSQL metadata와 MinIO object의 최종 상태가 기대 상태와 일치한다.
- response stream과 SDK가 정상·오류·shutdown 경로에서 닫힌다.
- 테스트 종료 후 잔여 metadata와 object가 없다. 단, 시나리오가 의도한 장애 상태를 검증한 직후 fixture가 정리한다.

## 5. 핵심 문서 lifecycle 시나리오

### INT-DOC-001 업로드와 영속화

**관련 요구사항:** FR-DOC-001, FR-DOC-008, FR-DOC-009, SRS-DOM-001, SRS-STO-006

1. filename, content type, 본문, `created_by`, checksum, 사용자 metadata를 포함해 `POST /documents`를 호출한다.
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
4. MinIO object가 삭제되거나 변경되지 않았음을 확인한다.
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
2. SDK가 한 번만 생성되고 여러 요청에서 같은 app state 인스턴스를 사용하는지 확인한다.
3. liveness가 `200`을 반환하는지 확인한다.
4. PostgreSQL·MinIO가 정상일 때 readiness가 `200`을 반환하는지 확인한다.
5. lifespan 종료 시 SDK와 저장소 client가 닫히는지 확인한다.

### INT-OPS-002 필수 설정 누락에 따른 startup 실패

**관련 요구사항:** FR-OPS-003, SRS-STO-002, SRS-STO-004, SRS-CFG-001

`POSTGRES_DSN`, `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`을 각각 제거하거나 공백으로 설정한 parameterized test를 실행한다. 각 경우 요청 수신 전 startup이 실패하고 오류에 secret 또는 전체 DSN이 포함되지 않음을 확인한다.

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
- 모듈 또는 테스트에 `@pytest.mark.integration`을 적용한다.
- 외부 서비스 fixture는 session scope로 연결 상태를 관리하되, 테스트 데이터는 function scope로 격리한다.
- timeout을 명시하여 외부 서비스 장애가 무한 대기로 이어지지 않게 한다.
- retry는 서비스 기동·복구와 같은 eventual consistency 확인에만 제한적으로 사용하며 업무 assertion 실패를 숨기지 않는다.

### 9.2 CI 단계

1. 잠금 파일 기준으로 의존성을 설치한다.
2. PostgreSQL과 MinIO를 고정 버전 service container로 시작한다.
3. PostgreSQL health와 MinIO bucket 준비를 확인한다.
4. `uv run pytest -m "not integration"`을 실행한다.
5. `uv run pytest -m integration`을 실행한다.
6. integration marker 테스트가 0건이거나 skip된 경우 job을 실패시킨다.
7. 실패 시 JUnit과 마스킹된 애플리케이션 로그만 artifact로 보관한다.
8. 성공·실패와 관계없이 test database, bucket object 및 container를 정리한다.

## 10. 출시 합격 기준

MVP 통합 테스트는 다음 조건을 모두 만족해야 한다.

1. 필수 시나리오 `INT-DOC-*`, `INT-OPS-*`, `INT-CON-*`, `INT-SEC-*`, `INT-API-*`가 모두 자동화되어 통과한다.
2. 실제 PostgreSQL 및 MinIO를 사용하며 대체 저장소로 통과시키지 않는다.
3. integration test skip 및 flaky 재실행 의존이 없다.
4. 테스트 종료 후 metadata와 object 잔여물이 없다.
5. 저장소 장애 시 readiness가 `503`을 반환하고 복구 후 정상화된다.
6. 정상·오류·shutdown 경로에서 stream과 SDK close 누락이 없다.
7. 응답, 로그 및 CI artifact에 credential, 전체 DSN, storage key 또는 문서 본문이 노출되지 않는다.
8. 저장소에 고정된 Python 및 package version 조합으로 전체 `pytest`가 통과한다.

## 11. 요구사항 추적성

| 요구사항 영역 | 통합 테스트 |
| --- | --- |
| 앱 조립 및 lifecycle | INT-OPS-001, INT-OPS-002 |
| upload 및 metadata 영속화 | INT-DOC-001, INT-DOC-002 |
| 조회 및 streaming | INT-DOC-003, INT-DOC-004 |
| soft/hard delete | INT-DOC-005, INT-DOC-006, INT-CON-004 |
| 오류 및 정합성 | INT-DOC-007, INT-CON-001 ~ INT-CON-004 |
| health/readiness | INT-OPS-001, INT-OPS-003, INT-OPS-004 |
| 인증·권한 | INT-SEC-001 ~ INT-SEC-003 |
| API 계약·보안 | INT-API-001 ~ INT-API-005 |
| SRS-NFR-004 | INT-DOC-001 ~ INT-DOC-007, INT-OPS-001 ~ INT-OPS-004 |
| SRS-NFR-005 | INT-CON-001 ~ INT-CON-004 |
