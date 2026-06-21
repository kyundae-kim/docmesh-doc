# Test Plan

## 1. 목적

본 문서는 `docs/srs.md` 및 관련 설계 문서를 기준으로 DMS 서비스/SDK의 테스트 전략을 정의한다.

목표:

- SDK 모드와 서비스 모드를 모두 검증한다.
- `fastapi-core` 호스트 통합이 실제로 동작하는지 확인한다.
- object storage / metadata store / auth adapter / HTTP API를 계층별로 검증한다.

---

## 2. 테스트 계층

## 2.1 단위 테스트

대상:

- DMS SDK 비즈니스 로직
- validation 규칙
- 상태 전이
- rollback / consistency 처리
- auth adapter의 인터페이스 정규화

특징:

- fake metadata store 사용 가능
- fake object store 사용 가능
- 네트워크/외부 서비스 의존 없음

## 2.2 adapter 테스트

대상:

- PostgreSQL metadata adapter
- SQLite metadata adapter
- MinIO object adapter
- `fastapi-core` resource → DMS assembly helper

특징:

- fake 또는 lightweight 실제 리소스 사용 가능
- adapter 레벨 round-trip 검증

## 2.3 서비스 통합 테스트

대상:

- `fastapi-core.create_app()` 기반 앱 조립
- startup 시 DMS SDK 조립
- `app.state.dms_sdk` 등록
- dependency 주입
- HTTP API 엔드포인트
- readiness / health 연동

## 2.4 외부 서비스 통합 테스트

대상:

- 실제 PostgreSQL
- 실제 MinIO
- 선택적 실제 Keycloak

목적:

- 환경 변수와 실서비스 연결 검증
- 주요 happy path와 대표 실패 path 검증

---

## 3. 테스트 범위 매핑

| 영역 | 단위 | adapter | 서비스 통합 | 외부 통합 |
|---|---:|---:|---:|---:|
| upload_document | Y | Y | Y | Y |
| get_document_metadata | Y | Y | Y | Y |
| get_document_content | Y | Y | Y | Y |
| get_document_content_stream | Y | Y | Y | Y |
| delete_document | Y | Y | Y | Y |
| check_health | Y | N | Y | Y |
| auth adapter | Y | Y | Y | Y |
| app.state / dependency | N | N | Y | N |
| readiness 연계 | N | N | Y | Y |

---

## 4. 필수 테스트 시나리오

## 4.1 SDK 단위 테스트

### 업로드

- 빈 content 거부
- 빈 filename 거부
- 빈 content_type 거부
- filename 정규화 후 `.` 또는 빈 문자열이면 거부
- `document_id` 미지정 시 자동 생성
- 중복 `document_id` 거부
- checksum 미지정 시 자동 계산
- metadata 저장 성공 시 `available` 상태 반환

### 업로드 실패/롤백

- object 저장 실패 → `StorageError`
- metadata 저장 실패 → object rollback 시도
- rollback 성공 → `ConsistencyError`
- rollback 실패 → `ConsistencyError`

### 조회

- metadata 없는 문서 → `DocumentNotFoundError`
- metadata backend 예외 → `MetadataStoreError`
- content 조회 시 object missing → `ConsistencyError`

### 스트리밍

- `chunk_size <= 0` → `ValidationError`
- stream object 누락 → `ConsistencyError`
- stream close 동작 검증

### 삭제

- soft delete happy path
- hard delete happy path
- object 삭제 실패 → `StorageError`, status `failed` best-effort
- object 삭제 후 metadata 처리 실패 → `ConsistencyError`

### health

- 모든 서비스 정상 → `ok=True`
- 일부 서비스 실패 → `ok=False`, 서비스 상세 포함

---

## 4.2 Adapter 테스트

### Metadata store

- save/get round-trip
- exists 확인
- mark_deleted 동작
- hard_delete 동작
- index/primary key 기반 기본 제약 검증

### Object store

- put/get round-trip
- stream round-trip
- delete 동작
- metadata/header 기반 filename/checksum 복원 검증

### Assembly helper

- SQLAlchemy engine으로 `PostgresMetadataStore` 조립 가능
- MinIO client로 `MinioObjectStore` 조립 가능
- auth provider 없이도 SDK 조립 가능
- auth adapter 포함 조립 가능

---

## 4.3 서비스 통합 테스트

### startup / shutdown

- `fastapi-core.create_app()` 기반 앱 생성
- startup 시 DMS SDK 조립
- `app.state.dms_sdk` 존재 확인
- shutdown 시 close 호출 또는 리소스 정리 확인

### HTTP API

- `POST /documents` 성공
- `GET /documents/{id}/metadata` 성공
- `GET /documents/{id}/content` 성공
- `GET /documents/{id}/stream` 성공
- `DELETE /documents/{id}` soft delete 성공
- `DELETE /documents/{id}?hard_delete=true` hard delete 성공
- `GET /documents/health` 응답 형식 검증

### 오류 매핑

- `ValidationError` → 400
- `DocumentNotFoundError` → 404
- `DuplicateDocumentError` → 409
- 내부 저장/일관성 오류 → 500

### readiness 연계

- host readiness가 DB/MinIO/DMS SDK 조립 상태 반영
- 필요 시 DMS health 연결 정책 검증

---

## 4.4 인증 테스트

### 보호 엔드포인트

- 토큰 없이 업로드 호출 → 401
- 권한 없는 토큰으로 삭제 호출 → 403
- 유효한 토큰으로 업로드 성공

### created_by

- 인증 사용자 정보가 `created_by`에 반영되는지 검증
- 클라이언트 입력보다 서버 정책이 우선하는지 검증

### SDK helper

- auth adapter 미조립 상태에서 helper 호출 실패
- auth adapter 조립 상태에서 `get_authenticated_user()` 성공
- 잘못된 token 처리 검증

---

## 5. 테스트 환경 전략

## 5.1 로컬 빠른 테스트

사용 목적:

- 단위 테스트
- fake dependency 기반 서비스 테스트
- SQLite 기반 경량 통합 테스트

권장 도구:

- `pytest`
- `pytest-asyncio` 또는 FastAPI test client
- SQLite
- fake MinIO client / mock object store

## 5.2 실제 인프라 테스트

사용 목적:

- PostgreSQL/MinIO 실연결 검증
- 설정/네트워크/credential 검증

필수 요소:

- PostgreSQL DSN
- MinIO endpoint/access_key/secret_key/bucket
- 선택적 Keycloak test realm

---

## 6. 권장 테스트 파일 구조

```text
tests/
  unit/
    test_sdk_upload.py
    test_sdk_download.py
    test_sdk_delete.py
    test_sdk_health.py
    test_auth_adapter.py
  adapters/
    test_postgres_metadata_store.py
    test_sqlite_metadata_store.py
    test_minio_object_store.py
    test_dms_assembly.py
  integration/
    test_app_startup.py
    test_documents_api.py
    test_documents_auth.py
    test_readiness.py
  fixtures/
    fake_metadata_store.py
    fake_object_store.py
    fake_auth_provider.py
```

실제 저장소 구조는 프로젝트 관례에 맞게 조정 가능하다.

---

## 7. 실행 명령 예시

### 전체 단위 테스트

```bash
pytest -q
```

### 서비스 통합 테스트만

```bash
pytest -q -m integration
```

### 인증 테스트만

```bash
pytest -q -k auth
```

프로젝트 도구가 `uv` 중심이면 다음도 가능하다.

```bash
uv run pytest -q
```

---

## 8. 품질 게이트

최소 품질 기준:

- 핵심 SDK 기능 happy path 전부 테스트됨
- rollback/consistency 실패 경로 테스트됨
- HTTP API 엔드포인트 기본 성공/실패 경로 테스트됨
- auth adapter 테스트됨
- startup/shutdown 통합 테스트됨
- readiness/health 동작 테스트됨

권장 기준:

- 주요 도메인 로직은 높은 단위 테스트 커버리지 유지
- 외부 서비스 통합 테스트는 CI 또는 별도 환경에서 주기 실행

---

## 9. 테스트 제외 항목

현재 문서 범위 밖이므로 기본 테스트 범위에서도 제외한다.

- presigned URL
- 문서 검색/필터링
- 버전 관리
- NATS 이벤트 발행/구독
- Langfuse 연계
- 멀티파트 업로드
- background worker 후처리
