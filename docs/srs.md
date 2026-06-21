# Software Requirements Specification (SRS)

## 1. 문서 목적

본 문서는 `dms-core` 저장소를 **독립 SDK 저장소**가 아니라, **`fastapi-core`를 호스트/라이프사이클 레이어로 사용하면서 DMS SDK를 그 위에 얹는 문서 관리 서비스/SDK 저장소**로 해석했을 때의 요구사항을 정리한다.

이 문서의 목적은 다음과 같다.

- `dms-core`의 향후 제품 경계를 명확히 한다.
- 현재 구현된 DMS SDK 계약을 유지하면서, 서비스 호스팅/리소스 lifecycle 책임을 `fastapi-core`로 이동하는 목표 구조를 정의한다.
- 이후 API 서버, 라우터, 의존성 조립, startup/shutdown 처리, 인증 연계, health check 확장 시 기준 문서로 사용한다.

이 문서는 **현재 코드의 사실**과 **목표 아키텍처의 요구사항**을 함께 포함한다. 따라서 일부 항목은 이미 구현 완료 상태이고, 일부 항목은 향후 구현 목표다.

---

## 2. 제품 비전

`dms-core`는 문서 content를 Object Storage(MinIO)에 저장하고 문서 메타데이터를 PostgreSQL 또는 SQLite에 저장/조회/삭제하는 도메인 기능을 제공한다.

향후 목표 구조에서:

- **문서 도메인 기능과 일관성 규칙은 `dms-core`가 담당**한다.
- **FastAPI 앱 생성, startup/shutdown lifecycle, app.state 기반 싱글톤 관리, 공통 인증/설정/헬스체크는 `fastapi-core`가 담당**한다.
- `dms-core`는 `fastapi-core` 위에 탑재되는 **문서 관리 모듈**로 동작해야 한다.

즉, 제품은 아래 두 사용 방식을 모두 만족해야 한다.

1. **라이브러리 모드**: Python 코드에서 `dms.sdk`를 직접 import 하여 사용
2. **서비스 모드**: `fastapi-core` 앱 안에 DMS SDK를 조립하여 HTTP API로 노출

---

## 3. 범위

### 3.1 포함 범위

본 SRS의 범위에 포함되는 항목:

- DMS SDK public contract
- MinIO + PostgreSQL/SQLite 기반 문서 저장/조회/삭제
- `fastapi-core` 기반 앱 lifecycle 통합
- DMS SDK의 explicit dependency injection 조립
- FastAPI 앱 상태(`app.state`)에 DMS SDK 등록
- 선택적 Keycloak 기반 인증 연계
- 런타임 health check 및 readiness 연계
- DMS 전용 라우터/서비스 계층의 요구사항

### 3.2 제외 범위

현재 범위에 포함하지 않는 항목:

- 문서 검색/필터링
- 문서 버전 관리
- presigned URL 발급
- 멀티파트 업로드
- 비동기 후처리 워커
- 감사 로그 저장소 구축
- 멀티테넌시/세분화된 권한 정책 모델
- NATS 기반 이벤트 발행/구독 구현
- Langfuse 연계

---

## 4. 구현 기준 소스

본 문서는 다음 구현과 문서를 기준으로 작성되었다.

### 4.1 `dms-core`
- `SDK_INTERFACE.md`

### 4.2 `fastapi-core`
- `fastapi-core-api.md`
- `fastapi-core-config.md`
- `fastapi-core-messaging.md`

---

## 5. 이해관계자

- 문서 기능을 재사용하려는 Python 애플리케이션 개발자
- DMS를 HTTP 서비스로 배포하려는 백엔드 개발자
- 공통 플랫폼 SDK를 관리하는 개발자
- Keycloak/PostgreSQL/MinIO 운영 담당자
- 테스트/품질 보증 담당자

---

## 6. 상위 아키텍처

### 6.1 계층 분리

목표 구조의 책임 분리는 다음과 같아야 한다.

#### A. `fastapi-core` 책임
- FastAPI 앱 생성 (`create_app()`)
- lifecycle(startup/shutdown) 관리
- `app.state` 기반 공용 리소스 싱글톤 관리
- 공통 설정 로드 (`EnvConfig`, `ServiceSettings`)
- 공통 인증/인가 provider 초기화
- DB engine / MinIO client / 기타 인프라 초기화
- 공통 health/readiness 라우트

#### B. `dms-core` 책임
- 문서 업로드/조회/삭제 도메인 규칙
- content 저장과 metadata 저장의 일관성 보장
- DMS 전용 오류 모델
- DMS SDK public interface
- DMS용 metadata/object store adapter
- DMS용 서비스 조립 함수
- DMS용 FastAPI router에서 사용할 application service

#### C. 통합 계층 책임
- `fastapi-core`가 초기화한 DB/MinIO/auth 자원을 사용해 DMS SDK를 조립
- 조립된 DMS SDK를 `app.state`에 저장
- FastAPI dependency를 통해 SDK 또는 상위 service를 라우터에 주입
- shutdown 시 DMS close callback 실행 여부를 `fastapi-core` lifecycle에 정렬

### 6.2 현재 코드 기준 가능성

현재 코드 기준으로 아래는 이미 성립한다.

- `dms.sdk.create_sdk(metadata_store=..., object_store=..., auth_service=...)` 경로가 존재한다.
- `fastapi_core.core.database.create_db_engine(...)` 가 SQLAlchemy `Engine`을 생성한다.
- `fastapi_core.core.storage.create_minio_client(...)` 가 MinIO client를 생성한다.
- `dms.infrastructure.metadata.postgres.PostgresMetadataStore(engine)` 로 metadata store를 조립할 수 있다.
- `dms.infrastructure.storage.minio.MinioObjectStore(client, bucket_name)` 로 object store를 조립할 수 있다.

반면 아래는 추가 구현 또는 adapter가 필요하다.

- `fastapi-core` auth provider를 DMS `AuthService` 프로토콜에 맞추는 adapter
- DMS 전용 `set_dms_sdk` / `get_dms_sdk` dependency
- DMS 라우터와 HTTP schema
- `fastapi-core` readiness 결과에 DMS health를 반영하는 방식
- `docmesh-py-core` 중심 환경 기반 DMS factory를 `fastapi-core` 호스팅 관점에 맞게 정리하는 작업

---

## 7. 제품 형태 요구사항

### FR-1. 이중 제품 형태 지원

시스템은 다음 두 실행 형태를 지원해야 한다.

1. **SDK 형태**: 기존처럼 Python 패키지로 import 하여 직접 사용 가능해야 한다.
2. **서비스 형태**: `fastapi-core`가 생성한 FastAPI 앱 안에서 DMS 기능을 HTTP API로 노출할 수 있어야 한다.

### FR-2. SDK 계약 유지

서비스 형태가 추가되더라도, 기존 `dms.sdk`의 핵심 public contract는 호환성을 유지해야 한다.

유지 대상 최소 기능:
- `upload_document(...)`
- `get_document_metadata(document_id)`
- `get_document_content(document_id)`
- `get_document_content_stream(document_id, chunk_size=...)`
- `delete_document(document_id, hard_delete=...)`
- `check_health()`
- 선택적 `fetch_access_token(...)`
- 선택적 `get_authenticated_user(token)`
- `close()`

---

## 8. 통합 아키텍처 요구사항

### FR-3. `fastapi-core` 호스트 사용

DMS 서비스 모드는 자체 FastAPI 부트스트랩을 새로 구현하기보다, **`fastapi-core.create_app()`를 기본 호스트 팩토리로 사용**해야 한다.

### FR-4. managed lifespan 정렬

DMS 서비스 모드는 `fastapi-core`의 managed lifespan 또는 이에 준하는 custom lifespan 위에서 동작해야 하며, 최소한 다음 순서를 만족해야 한다.

1. 설정 로드
2. 공용 인프라 초기화(DB, MinIO, 선택적 auth)
3. DMS SDK 조립
4. DMS SDK를 `app.state`에 등록
5. 요청 처리 시작
6. 종료 시 DMS 리소스 정리
7. 공용 인프라 종료

### FR-5. app.state 등록

조립된 DMS SDK 또는 그 상위 DMS application service는 `app.state`에 저장되어야 한다.

권장 상태 키 예시:
- `app.state.dms_sdk`
- `app.state.dms_service`

### FR-6. FastAPI dependency 제공

DMS 서비스 모드는 라우터에서 사용할 함수형 dependency를 제공해야 한다.

최소 요구 dependency:
- `get_dms_sdk(request) -> DocumentManagementSDK`
- 또는 `get_dms_service(request) -> DmsService`

이 dependency는 class-based singleton dependency가 아니라, `fastapi-core`의 현재 패턴과 일치하는 함수형 dependency여야 한다.

---

## 9. 조립(assembly) 요구사항

### FR-7. explicit DI 우선

`fastapi-core` 호스팅 모드에서 DMS 조립은 **환경 기반 `create_sdk(env)`보다 explicit DI 경로를 우선** 사용해야 한다.

즉 다음 조립 방식이 기준이어야 한다.

- `PostgresMetadataStore(engine)` 또는 `SqliteMetadataStore(engine)` 생성
- `MinioObjectStore(client, bucket_name)` 생성
- 필요 시 auth adapter 생성
- `create_sdk(metadata_store=..., object_store=..., auth_service=...)` 호출

### FR-8. DB 엔진 재사용

DMS 서비스 모드는 `fastapi-core`가 생성한 SQLAlchemy engine을 재사용해야 한다.

- 별도의 독립 engine을 이중으로 생성하지 않아야 한다.
- metadata store는 동일 engine 위에 조립되어야 한다.
- metadata table 기본 이름은 `document_metadata`를 유지해야 한다.

### FR-9. MinIO client 재사용

DMS 서비스 모드는 `fastapi-core`가 생성한 MinIO client를 재사용해야 한다.

- 별도 MinIO client를 이중 생성하지 않아야 한다.
- bucket 이름은 `fastapi-core` config에서 전달받아야 한다.
- DMS object storage adapter는 단일 bucket 정책을 유지해야 한다.

### FR-10. 인증 adapter

`fastapi-core`의 auth provider는 현재 DMS `AuthService` 프로토콜과 직접 호환되지 않으므로, 서비스 모드는 필요 시 adapter를 제공해야 한다.

adapter는 최소한 다음 계약을 제공해야 한다.
- `fetch_access_token(scope=None)`
- `extract_user_info(token)`

### FR-11. 환경 기반 factory의 역할 축소

`create_sdk(env)` 경로는 SDK 단독 사용/하위 호환을 위해 유지할 수 있으나, `fastapi-core` 호스팅 모드의 주 조립 경로가 되어서는 안 된다.

---

## 10. 기능 요구사항 — SDK 도메인

### FR-12. 업로드

시스템은 문서 업로드를 지원해야 한다.

요구사항:
1. 입력은 `UploadDocumentRequest` 여야 한다.
2. `content`는 비어 있으면 안 된다.
3. `filename`은 공백만으로 구성될 수 없다.
4. `content_type`은 공백만으로 구성될 수 없다.
5. caller가 `document_id`를 주지 않으면 UUID 기반 식별자를 생성해야 한다.
6. 동일 `document_id`가 존재하면 `DuplicateDocumentError`를 반환해야 한다.
7. checksum 미제공 시 SHA-256 hex digest를 계산해야 한다.
8. object 저장 후 metadata를 저장해야 한다.
9. metadata 저장 실패 시 object 삭제 rollback을 시도해야 한다.
10. rollback까지 실패하면 `ConsistencyError`를 반환해야 한다.

### FR-13. metadata 조회

1. 시스템은 `document_id` 기반 metadata 조회를 제공해야 한다.
2. 없는 문서는 `DocumentNotFoundError`를 반환해야 한다.
3. metadata backend 예외는 `MetadataStoreError`로 매핑해야 한다.

### FR-14. content 전체 조회

1. 시스템은 문서 content 전체 바이트 조회를 제공해야 한다.
2. content 조회 전 metadata를 먼저 조회해야 한다.
3. metadata는 존재하지만 object가 없으면 `ConsistencyError`를 반환해야 한다.
4. 반환 타입은 `DocumentContent`여야 한다.

### FR-15. content 스트리밍 조회

1. 시스템은 chunked streaming 다운로드를 제공해야 한다.
2. `chunk_size <= 0`은 `ValidationError`여야 한다.
3. metadata는 존재하지만 object stream이 없으면 `ConsistencyError`여야 한다.
4. 반환 타입은 `DocumentContentStream`이어야 한다.
5. stream consumer는 사용 후 close할 수 있어야 한다.

### FR-16. 삭제

1. 시스템은 soft delete와 hard delete를 모두 지원해야 한다.
2. 삭제 시작 시 metadata status를 `deleting`으로 저장해야 한다.
3. object 삭제 실패 시 best-effort로 status를 `failed`로 바꾸고 `StorageError`를 반환해야 한다.
4. soft delete는 object 삭제 후 metadata를 `deleted` 상태로 남겨야 한다.
5. hard delete는 object 삭제 후 metadata row를 제거해야 한다.
6. object 삭제 후 metadata 후속 처리 실패는 `ConsistencyError`여야 한다.

### FR-17. health check

1. SDK는 런타임 health check API를 제공해야 한다.
2. health check는 metadata store, object store, 선택적 auth check를 보고할 수 있어야 한다.
3. 반환 타입은 `HealthStatus`여야 한다.
4. 서비스별 세부 결과는 `ServiceHealth`로 표현해야 한다.

---

## 11. 기능 요구사항 — 서비스 모드

### FR-18. HTTP 업로드 API

서비스 모드는 문서 업로드용 HTTP 엔드포인트를 제공해야 한다.

최소 요구사항:
- multipart file 업로드 또는 동등한 HTTP 입력 방식 지원
- optional metadata 전달 지원
- optional `created_by` 전달 지원
- 응답에 `document_id`, `storage_key`, metadata 핵심 필드 포함

### FR-19. HTTP metadata 조회 API

서비스 모드는 문서 metadata 조회 엔드포인트를 제공해야 한다.

### FR-20. HTTP content 다운로드 API

서비스 모드는 문서 전체 다운로드 및 stream 다운로드를 제공할 수 있어야 한다.

최소 요구사항:
- 적절한 `Content-Type` 반환
- filename 전달 가능
- 대용량 파일에 대해 stream 응답 사용 가능

### FR-21. HTTP 삭제 API

서비스 모드는 soft delete / hard delete를 구분할 수 있는 삭제 엔드포인트를 제공해야 한다.

### FR-22. 서비스 readiness 반영

서비스 모드의 readiness는 최소한 다음 상태를 반영해야 한다.

- DB 연결 가능 여부
- MinIO 연결 가능 여부
- DMS SDK 조립 완료 여부
- 선택적으로 DMS `check_health()` 결과

### FR-23. 인증 연계

서비스 모드가 보호된 엔드포인트를 제공할 경우, `fastapi-core`의 인증 dependency와 정렬되어야 한다.

예:
- `get_current_user`
- `require_permissions(...)`

`created_by`는 인증 사용자 정보와 연동 가능해야 한다.

---

## 12. 데이터 모델 요구사항

### FR-24. 문서 metadata 모델

문서 metadata는 최소한 다음 필드를 가져야 한다.

- `document_id: str`
- `original_filename: str`
- `content_type: str`
- `file_size: int`
- `storage_key: str`
- `status: DocumentStatus`
- `created_at: datetime`
- `updated_at: datetime`
- `checksum: str | None`
- `deleted_at: datetime | None`
- `created_by: str | None`
- `extra_metadata: dict[str, Any]`

### FR-25. 상태 모델

최소 상태 집합:
- `uploaded`
- `available`
- `deleting`
- `deleted`
- `failed`

현재 업로드 완료 기본 상태는 `available` 이어야 한다.

---

## 13. 스토리지 정책

### FR-26. object key 규칙

1. object key prefix는 항상 `documents/` 이어야 한다.
2. 형식은 `documents/{document_id}/{sanitized_filename}` 이어야 한다.
3. filename 정규화 규칙은 다음과 같다.
   - 앞뒤 공백 제거
   - `..` 를 `.` 로 치환
   - `/` 를 `-` 로 치환
   - `\\` 를 `-` 로 치환
4. 정규화 결과가 `.` 또는 빈 문자열이면 업로드를 거부해야 한다.

### FR-27. 충돌 기준

1. 충돌 기준은 filename이 아니라 `document_id`다.
2. 서로 다른 `document_id`는 같은 filename을 가질 수 있어야 한다.

---

## 14. persistence 요구사항

### FR-28. metadata store 계약

metadata store는 최소한 다음 연산을 제공해야 한다.

- `save_metadata(metadata)`
- `get_metadata(document_id)`
- `mark_deleted(document_id)`
- `hard_delete(document_id)`
- `exists(document_id)`

### FR-29. PostgreSQL/SQLite 지원

1. 서비스 모드는 기본적으로 PostgreSQL metadata store를 우선 지원해야 한다.
2. 개발/단일 프로세스 테스트에서는 SQLite fallback을 허용할 수 있다.
3. SQLite는 주 배포 경로가 아니라 개발/테스트 경로로 간주한다.

### FR-30. schema/index

`document_metadata` 테이블은 최소한 다음 제약을 가져야 한다.

- primary key: `document_id`
- secondary index: `storage_key`
- secondary index: `status`
- secondary index: `created_at`

---

## 15. 오류 모델 요구사항

### FR-31. public 예외 계층

시스템은 최소한 다음 예외를 public contract로 노출해야 한다.

- `DmsError`
- `ConfigurationError`
- `ValidationError`
- `AuthenticationError`
- `DocumentNotFoundError`
- `DuplicateDocumentError`
- `StorageError`
- `MetadataStoreError`
- `ConsistencyError`
- `HealthCheckFailedError`

### FR-32. 서비스 모드의 오류 매핑

HTTP 서비스 모드는 SDK 예외를 적절한 HTTP 응답으로 매핑해야 한다.

권장 예시:
- `ValidationError` → 400
- `AuthenticationError` → 401
- `DocumentNotFoundError` → 404
- `DuplicateDocumentError` → 409
- `ConfigurationError` → 500
- `StorageError` / `MetadataStoreError` / `ConsistencyError` → 500

---

## 16. 로깅 및 관측성 요구사항

### FR-33. structured logging

1. SDK는 optional logger를 받을 수 있어야 한다.
2. operation 경계 로그는 `dms_` prefix extra field를 사용해야 한다.
3. raw token과 raw document content는 로그에 남기지 않아야 한다.

예시 필드:
- `dms_event`
- `dms_document_id`
- `dms_storage_key`
- `dms_duration_ms`
- `dms_error_type`

### FR-34. 호스트 로그 정렬

서비스 모드에서는 DMS 로그가 `fastapi-core`의 애플리케이션 로깅 정책과 공존 가능해야 한다.

- request 로그와 SDK 로그가 함께 추적 가능해야 한다.
- 문서 식별자 기반 진단이 가능해야 한다.

---

## 17. 보안 요구사항

### FR-35. 인증 정보 보호

- access token, refresh token, document content 원문은 로그에 출력되면 안 된다.
- Keycloak 관련 설정값은 환경/설정 계층에서 관리되어야 한다.

### FR-36. 사용자 정보 연계

서비스 모드에서 인증 사용 시, 요청 사용자 정보는 `created_by` 같은 문서 metadata 필드와 연결될 수 있어야 한다.

---

## 18. 테스트 요구사항

### FR-37. SDK 단위 테스트

1. 순수 SDK 동작은 fake/in-memory store로 테스트 가능해야 한다.
2. 업로드/조회/삭제/실패 rollback 경로가 단위 테스트로 검증되어야 한다.

### FR-38. adapter 테스트

1. PostgreSQL/SQLite metadata adapter와 MinIO adapter는 개별 round-trip 테스트를 가져야 한다.
2. fake MinIO client 또는 테스트용 실서비스를 사용할 수 있어야 한다.

### FR-39. 서비스 통합 테스트

서비스 모드는 `fastapi-core` 호스트 위에서 다음 통합 시나리오를 검증해야 한다.

- startup 시 DMS SDK 조립 성공
- HTTP 업로드 성공
- HTTP metadata 조회 성공
- HTTP 다운로드 성공
- HTTP 삭제 성공
- readiness 응답에서 DMS 의존성 반영
- shutdown 시 리소스 정리

### FR-40. 환경 독립성

- 외부 서비스가 없는 테스트는 fake/dependency override로 검증 가능해야 한다.
- 실제 PostgreSQL/MinIO 기반 integration test는 별도 환경에서 실행 가능해야 한다.

---

## 19. 마이그레이션 요구사항

### FR-41. 단계적 전환

저장소는 다음 순서로 점진적으로 전환 가능해야 한다.

1. 기존 SDK public contract 유지
2. explicit DI 기반 DMS assembly helper 추가
3. FastAPI dependency / app.state helper 추가
4. DMS router 및 HTTP schema 추가
5. `fastapi-core` 앱 호스팅 예제 및 테스트 추가
6. 필요 시 환경 기반 factory 역할 축소 또는 문서화 정리

### FR-42. 하위 호환성

기존 SDK 소비자는 서비스 모드 추가로 인해 깨지지 않아야 한다.

- `dms.sdk` import 경로 유지
- 핵심 예외 타입 유지
- 핵심 요청/응답 타입 유지

---

## 20. 승인 기준

본 SRS는 아래 조건을 만족할 때 목표 충족으로 간주한다.

1. `fastapi-core` 기반 앱에서 DMS SDK가 startup 시 조립된다.
2. 조립된 SDK 또는 DMS service가 `app.state`와 dependency를 통해 라우터에서 사용된다.
3. DB/MinIO 클라이언트는 `fastapi-core`가 만든 인스턴스를 재사용한다.
4. 인증이 필요한 경우 DMS auth adapter가 동작한다.
5. 업로드/조회/다운로드/삭제 HTTP 경로가 통합 테스트로 검증된다.
6. SDK 단독 사용 경로는 계속 유지된다.
7. shutdown 시 DMS와 공용 인프라 리소스가 정상 정리된다.

---

## 21. 결론

`dms-core`의 목표 형태는 더 이상 “`docmesh-py-core` 환경 팩토리에 강하게 결합된 독립 SDK”에 머무르지 않고, **문서 도메인 기능은 DMS가 담당하고 애플리케이션 호스팅과 lifecycle은 `fastapi-core`가 담당하는 구조**로 정리되는 것이다.

이 구조는 다음 장점을 제공한다.

- FastAPI 앱 조립과 리소스 관리의 중복 제거
- 공통 인증/설정/헬스체크 정책 일원화
- DMS SDK의 도메인 순도 유지
- 라이브러리 모드와 서비스 모드의 동시 지원

향후 구현은 **explicit DI 기반 DMS 조립**, **auth adapter**, **DMS FastAPI dependency/router**, **통합 테스트** 순서로 진행하는 것이 바람직하다.
