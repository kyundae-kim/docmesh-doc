# PRD - DocMesh Document Service

## 1. 목적

DocMesh Document Service는 인증된 사용자가 문서를 안전하게 업로드/다운로드/삭제하고,
문서에 연관된 metadata를 생성/조회/수정/삭제(CRUD)할 수 있는 API를 제공한다.

## 2. 문제 정의

- 서비스별로 인증/스토리지 연동 구현이 중복되면 유지보수 비용이 커진다.
- 사용자별 파일 경계가 명확하지 않으면 접근 통제가 약해진다.
- 삭제 이력/복구 가능성을 고려해 즉시 물리 삭제를 피할 필요가 있다.
- 문서 접근을 파일 위치(`file_path`)에 의존하면 경로 변경/이관 시 참조 안정성이 떨어진다.
- 문서와 metadata 관계가 1:1로 고정되어야 하는 도메인에서 별도 맵핑 구조는 복잡도를 높인다.

## 3. 제품 목표

- Keycloak 기반 인증을 통과한 사용자만 문서 API 접근 가능
- MinIO 기반 문서 영속 저장
- 문서는 `document_id(UUID)` 기반으로 접근
- Soft Delete 지원
- Postgres 기반 metadata 저장/관리
- 문서와 metadata를 1:1로 관리

## 4. 범위

### 포함

- 문서 업로드/다운로드/삭제 API (ID 기반)
- metadata CRUD API (문서별 1:1)
- 헬스체크 API
- fastapi-core 기반 인증/설정/앱 조립

### fastapi-core 제공 기능 (v0.1.2)

- Keycloak OAuth2/OIDC 인증 (`KeycloakAuthProvider`, `get_current_user`)
- PostgreSQL SQLAlchemy 엔진 관리 (`set_db_engine`, `get_db_session`)
- MinIO 객체 스토리지 클라이언트 (`set_minio_client`, `get_minio_client`)
- NATS 메시징 클라이언트 (`set_nats_client`, `get_nats_client`, `publish_json`, `subscribe_json`)
- 앱 팩토리 (`create_app(include_auth_router=True)`)
- 공통 설정 모델 (`EnvConfig`, `ServiceSettings`, `NatsConfig`)
- 공통 라우트: `GET /health/liveness`, `GET /health/readiness`, `POST /token`, `GET /user`

### 제외(추후)

- metadata 고급 검색(복합 조건/전문 검색)
- metadata 버전 관리
- Audit/Metadata 외부 서비스 연동

## 5. 사용자/이해관계자

- 백엔드 개발자: 문서 저장 API, metadata API 연동
- 플랫폼/운영: Keycloak·MinIO·Postgres 설정 및 운영

## 6. 기능 요구사항

1) 문서 업로드
- 인증 필요
- 파일 본문 수신
- 서버에서 `document_id(UUID)` 생성
- MinIO에 저장, `deleted=false` 태그 기록

2) 문서 다운로드
- 인증 필요
- `document_id`로 문서 조회
- Soft Delete 또는 미존재 시 404
- 파일 스트리밍 응답

3) 문서 삭제
- 인증 필요
- `document_id`로 삭제 요청
- 물리 삭제 대신 `deleted=true` 설정
- 미존재 시 404

4) metadata 생성
- 인증 필요
- `document_id` 기준 metadata 생성
- Postgres에 저장
- 문서당 metadata는 1개만 허용(1:1)

5) metadata 조회
- 인증 필요
- `document_id` 기준 metadata 단건 조회

6) metadata 수정
- 인증 필요
- `document_id` 기준 metadata 부분 수정(PATCH)

7) metadata 삭제
- 인증 필요
- `document_id` 기준 metadata 삭제

8) 헬스체크
- `/health/live`, `/health/ready` 제공

## 7. 데이터 요구사항

- 문서 본문: MinIO 객체 스토리지
- metadata 본문: Postgres 테이블 저장(JSONB 권장)
- 관계 모델: 문서 1건 ↔ metadata 1건 (1:1)

권장 테이블:
- `documents`
  - `id` (UUID, PK)
  - `owner_username` (TEXT)
  - `object_key` (TEXT, UNIQUE)  // 예: `{username}/{document_id}`
  - `original_filename` (TEXT)
  - `content_type` (TEXT)
  - `created_at`, `updated_at` (TIMESTAMPTZ)
- `document_metadata`
  - `document_id` (UUID, PK, FK -> `documents.id`)
  - `metadata_value` (JSONB)
  - `created_at`, `updated_at` (TIMESTAMPTZ)

## 8. 비기능 요구사항

- 보안: Bearer 토큰 필수
- 확장성: Stateless 구조 유지
- 신뢰성: Soft Delete 일관 동작, metadata 트랜잭션 일관성 보장
- 운영성: 환경변수/YAML 기반 설정
- 성능: 문서 조회 시 metadata 단건 조회가 과도한 추가 쿼리를 유발하지 않도록 구현
- 마이그레이션: 프로덕션 DB 스키마 변경은 Alembic을 통해 버전 관리하며, 서비스 초기화 시 `create_all()` 방식을 사용하지 않는다

## 9. DB 스키마 관리 방침

개발 환경과 프로덕션 환경의 스키마 관리 방식을 분리한다.

- 개발 환경: `Base.metadata.create_all()` 허용 (빠른 반복 개발)
- 프로덕션 환경: Alembic 마이그레이션만 허용 (`create_all()` 금지)

### 모델 통합 관리

SQLAlchemy `Base` 클래스는 `docmesh_doc/models/base.py` 한 곳에서 선언하고,
모든 ORM 모델은 이 공통 `Base`를 상속한다. 서비스 파일 내부에 로컬 `Base`를 선언하지 않는다.

### Alembic 도입 이유

- `create_all()`은 기존 테이블의 컬럼 추가/삭제/변경을 감지하지 못한다.
- 프로덕션에서 스키마 변경 이력이 추적되지 않아 롤백이 불가능하다.
- Alembic 마이그레이션 파일은 버전 관리(git)에 포함되어 팀 단위 협업 시 스키마 변경을 명시적으로 검토할 수 있다.

## 9. 성공 기준

- 핵심 API(문서 업로드/다운로드/삭제) 정상 동작
- metadata CRUD API 정상 동작
- 문서 접근이 `document_id` 기준으로 동작
- 문서-metadata 1:1 제약이 보장됨
- 권한 체크(role/scope) 정상 동작
- 자동 테스트 통과
