# Architecture

## 1. 목적

본 문서는 `docs/srs.md`를 바탕으로, **`fastapi-core`를 호스트/라이프사이클 레이어로 사용하고 DMS SDK를 그 위에 얹는 구조**의 아키텍처를 설명한다.

핵심 원칙은 다음과 같다.

- `fastapi-core`는 앱 생성, lifecycle, 공용 인프라, 인증, readiness를 담당한다.
- DMS는 문서 도메인 규칙과 SDK 계약을 담당한다.
- 서비스 모드에서는 `fastapi-core.create_app()` 위에 DMS 조립 계층을 추가한다.
- SDK 모드와 서비스 모드는 동시에 유지한다.

---

## 2. 시스템 컨텍스트

```text
Client / Other Service
        |
        v
  FastAPI HTTP Layer
        |
        v
  fastapi-core Host Layer
  - create_app()
  - lifecycle
  - app.state
  - auth dependencies
  - config / logging / readiness
        |
        v
  DMS Integration Layer
  - build_dms_sdk(...)
  - auth adapter
  - get_dms_sdk()
  - get_dms_service()
        |
        v
  DMS Domain Layer
  - upload_document
  - get_document_metadata
  - get_document_content
  - get_document_content_stream
  - delete_document
  - check_health
        |
        +-------------------+
        |                   |
        v                   v
 PostgreSQL / SQLite      MinIO
 document_metadata        object content
```

---

## 3. 책임 분리

## 3.1 fastapi-core 책임

`fastapi-core`는 아래를 담당한다.

- `create_app()`를 통한 FastAPI 앱 생성
- startup / shutdown lifecycle 관리
- `app.state` 기반 싱글톤 저장
- 공통 설정 로드 (`EnvConfig`, `ServiceSettings`)
- DB engine 생성
- MinIO client 생성
- Keycloak auth provider 생성
- 공통 health / readiness 라우트 제공
- 로깅, 예외 핸들링, CORS 정책

## 3.2 DMS 책임

DMS는 아래를 담당한다.

- 문서 업로드/조회/삭제 도메인 규칙
- metadata ↔ object storage 간 일관성 보장
- DMS SDK public interface 유지
- DMS 전용 오류 모델 유지
- Postgres/SQLite metadata adapter 제공
- MinIO object adapter 제공
- 런타임 `check_health()` 제공

## 3.3 통합 계층 책임

통합 계층은 아래를 담당한다.

- `fastapi-core` 자원으로 DMS SDK 조립
- DMS SDK를 `app.state.dms_sdk`에 등록
- 필요 시 `app.state.dms_service` 등록
- FastAPI dependency 제공
- auth adapter 제공
- readiness에 DMS 상태를 연결

---

## 4. 런타임 구성요소

## 4.1 앱 구성요소

권장 구성요소는 다음과 같다.

- `app` : `fastapi-core.create_app()`로 생성된 FastAPI 앱
- `app.state.db_engine` : SQLAlchemy engine
- `app.state.minio_client` : MinIO client
- `app.state.auth_provider` : Keycloak provider 또는 동등 객체
- `app.state.dms_sdk` : 조립된 `DocumentManagementSDK`
- `app.state.dms_service` : 선택적 상위 application service

## 4.2 DMS 조립 구성요소

권장 조립 요소:

- `PostgresMetadataStore(engine)` 또는 `SqliteMetadataStore(...)`
- `MinioObjectStore(client, bucket_name)`
- `FastapiCoreAuthAdapter(provider)`
- `create_sdk(metadata_store=..., object_store=..., auth_service=...)`

---

## 5. 조립 흐름

## 5.1 startup sequence

```text
1. fastapi-core config/settings 로드
2. fastapi-core lifecycle이 DB/MinIO/auth 초기화
3. DMS integration layer가 metadata_store 생성
4. DMS integration layer가 object_store 생성
5. 필요 시 auth adapter 생성
6. create_sdk(...)로 DMS SDK 조립
7. app.state.dms_sdk 저장
8. router 요청 처리 시작
```

## 5.2 shutdown sequence

```text
1. 요청 수락 중지
2. DMS SDK close() 호출
3. DB / MinIO / auth 등 공용 리소스 종료
4. app shutdown 완료
```

shutdown 시 DMS close callback과 `fastapi-core` lifecycle 종료 순서는 충돌하지 않도록 정렬되어야 한다.

---

## 6. 의존성 주입 구조

서비스 모드에서는 **환경 기반 `create_sdk(env)`보다 explicit DI를 우선**한다.

권장 패턴:

```python
engine = app.state.db_engine
minio_client = app.state.minio_client
auth_provider = getattr(app.state, "auth_provider", None)

metadata_store = PostgresMetadataStore(engine)
object_store = MinioObjectStore(client=minio_client, bucket_name=config.minio.bucket)
auth_service = FastapiCoreAuthAdapter(auth_provider) if auth_provider else None

sdk = create_sdk(
    metadata_store=metadata_store,
    object_store=object_store,
    auth_service=auth_service,
)
```

이 방식의 장점:

- DB/MinIO 중복 초기화 방지
- 테스트에서 fake dependency 주입 용이
- `fastapi-core` lifecycle과 자원 관리 일관성 확보
- 기존 SDK public contract 유지 가능

---

## 7. app.state / dependency 설계

## 7.1 상태 키

권장 상태 키:

- `app.state.dms_sdk`
- `app.state.dms_service`

## 7.2 dependency

권장 dependency:

```python
def get_dms_sdk(request: Request) -> DocumentManagementSDK:
    return request.app.state.dms_sdk
```

선택적 상위 서비스 패턴:

```python
def get_dms_service(request: Request) -> DmsService:
    return request.app.state.dms_service
```

함수형 dependency를 사용해 `fastapi-core`의 현재 패턴과 정렬한다.

---

## 8. 데이터 흐름

## 8.1 업로드 흐름

```text
HTTP request
  -> Router
  -> DMS service / SDK
  -> validate request
  -> store object in MinIO
  -> store metadata in PostgreSQL/SQLite
  -> return document_id + metadata
```

실패 시:

- object 저장 성공 후 metadata 저장 실패 → object rollback 시도
- rollback 실패 → `ConsistencyError`

## 8.2 다운로드 흐름

```text
HTTP request
  -> Router
  -> DMS SDK
  -> load metadata
  -> load object from MinIO
  -> return bytes or stream response
```

## 8.3 삭제 흐름

```text
HTTP request
  -> Router
  -> DMS SDK
  -> mark metadata as deleting
  -> delete object
  -> soft delete: mark metadata deleted
  -> hard delete: remove metadata row
```

---

## 9. readiness / health 설계

## 9.1 Host readiness

기본 readiness는 `fastapi-core`가 담당한다.

최소 체크 대상:

- DB 연결 가능 여부
- MinIO 연결 가능 여부
- auth provider 초기화 여부
- DMS SDK 조립 여부

## 9.2 DMS health 연결

선택적으로 readiness는 DMS `check_health()` 결과를 포함할 수 있다.

권장 원칙:

- startup readiness는 host 관점 최소 인프라 체크 우선
- 상세 DMS 진단은 별도 health detail 또는 내부 진단 경로로 제공
- readiness는 너무 무거운 체크가 되지 않도록 설계

---

## 10. 설계 제약

- DMS public SDK contract는 유지되어야 한다.
- 서비스 모드가 SDK 모드를 깨뜨리면 안 된다.
- `fastapi-core`가 이미 만든 DB/MinIO/auth 리소스를 재사용해야 한다.
- 환경 기반 factory는 보조 경로로만 유지한다.
- 로그에는 raw token / raw content를 남기지 않는다.

---

## 11. 향후 확장 포인트

향후 추가 가능한 영역:

- DMS router 모듈 분리
- presigned URL 전용 application service
- NATS 이벤트 발행 연계
- 감사 로그 저장
- background worker 연계
- 문서 검색/필터링 API
- 버전 관리 및 감사 추적

현재 문서 범위에서는 위 항목들을 다루지 않는다.
