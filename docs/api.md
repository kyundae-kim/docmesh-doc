# API 명세 - DocMesh Document Service

## 1. 개요

본 서비스는 `fastapi-core` 기본 라우트와 `docmesh_doc` 로컬 라우트를 함께 제공한다.

- fastapi-core 라우트: `/token`, `/user`
- docmesh_doc 라우트: `/documents*`, `/documents/{document_id}/metadata*`, `/health/live`, `/health/ready`

---

## 2. 인증

- 방식: OAuth2 Bearer Token
- 문서 API(`/documents*`)와 metadata API(`/documents/{document_id}/metadata*`)는 인증 필요

### 2.1 POST /token (fastapi-core)

요청: `application/x-www-form-urlencoded`
- `username`
- `password`

응답 200:
```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```

### 2.2 GET /user (fastapi-core)

요청 헤더:
- Authorization: Bearer {access_token}

응답 200:
```json
{
  "sub": "...",
  "username": "...",
  "email": "...",
  "name": "...",
  "roles": ["..."],
  "scopes": ["..."]
}
```

---

## 3. 문서 API (ID 기반)

문서는 `file_path`가 아니라 `document_id(UUID)`로 접근한다.

### 3.1 POST /documents

설명: 문서 업로드 및 문서 ID 발급

인증: 필요

요청: `multipart/form-data`
- `file` (binary, 필수)
- `filename` (string, 선택)  // 원본 파일명 보관 용도

응답 201:
```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "filename": "example.txt"
}
```

오류:
- 400 요청 검증 실패
- 401 인증 실패

### 3.2 GET /documents/{document_id}

설명: 문서 다운로드

인증: 필요

Path Parameter:
- `document_id` (UUID)

응답 200:
- Body: 파일 바이너리
- Headers:
  - `Content-Type: <원본 타입>`
  - `Content-Disposition: attachment; filename="..."`

오류:
- 404 문서 없음 또는 Soft Delete 상태

### 3.3 DELETE /documents/{document_id}

설명: 문서 Soft Delete

인증: 필요

Path Parameter:
- `document_id` (UUID)

응답 204: No Content

오류:
- 404 문서 없음

---

## 4. Metadata API (Postgres, 문서 1:1)

metadata는 Postgres에 저장/관리되며, 문서와 1:1 관계를 가진다.

### 4.1 POST /documents/{document_id}/metadata

설명: 특정 문서의 metadata 생성

인증: 필요

Path Parameter:
- `document_id` (UUID)

요청 Body:
```json
{
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  }
}
```

응답 201:
```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:01:00Z"
}
```

오류:
- 400 요청 검증 실패
- 404 문서 없음
- 409 이미 metadata가 존재함(1:1 제약)

### 4.2 GET /documents/{document_id}/metadata

설명: 특정 문서의 metadata 조회

인증: 필요

Path Parameter:
- `document_id` (UUID)

응답 200:
```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:01:00Z"
}
```

오류:
- 404 문서 또는 metadata 없음

### 4.3 PATCH /documents/{document_id}/metadata

설명: 특정 문서의 metadata 수정(부분 업데이트)

인증: 필요

Path Parameter:
- `document_id` (UUID)

요청 Body (예시):
```json
{
  "metadata_value": {
    "category": "architecture",
    "priority": 2
  }
}
```

응답 200:
```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 2
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:10:00Z"
}
```

오류:
- 400 요청 검증 실패
- 404 문서 또는 metadata 없음

### 4.4 DELETE /documents/{document_id}/metadata

설명: 특정 문서의 metadata 삭제

인증: 필요

Path Parameter:
- `document_id` (UUID)

응답 204: No Content

오류:
- 404 문서 또는 metadata 없음

---

## 5. 헬스체크

### 5.1 GET /health/live

응답 200:
```json
{ "status": "ok" }
```

### 5.2 GET /health/ready

응답 200:
```json
{ "status": "ok" }
```

---

## 6. 권한 체크 에러 포맷

커스텀 권한 체크 실패(`require_roles`, `require_scopes`) 시:

응답 403:
```json
{
  "error": "insufficient_scope",
  "error_description": "Missing required roles: ..., scopes: ..."
}
```

---

## 7. 설정

앱은 다음 설정 체계를 사용한다.

- Env: `fastapi_core.core.config.EnvConfig`
- YAML: `fastapi_core.core.config.ServiceSettings`

대표 환경변수 예시:
- `CONFIG_PATH`
- `KEYCLOAK__HTTP_URL`
- `KEYCLOAK__REALM`
- `KEYCLOAK__CLIENT_ID`
- `KEYCLOAK__CLIENT_SECRET`
- `MINIO__ENDPOINT`
- `MINIO__ACCESS_KEY`
- `MINIO__SECRET_KEY`
- `MINIO__BUCKET`
- `MINIO__PRESIGNED_EXPIRES_SEC` (기본값: 900)
- `DB__HOST`
- `DB__PORT`
- `DB__NAME`
- `DB__USER`
- `DB__PASSWORD`
- `DB__URL` (직접 DSN 지정 시 위 개별 항목 무시)
- `DB__SSLMODE` (기본값: prefer)
- `DB__POOL_SIZE` (기본값: 5)
- `LOGGING__LEVEL` (WARNING / INFO / DEBUG, 기본값: DEBUG)
- `NATS__SERVERS` (기본값: nats://nats:4222, 쉼표 구분 멀티 서버 가능)
- `NATS__NAME` (기본값: fastapi-core)
- `NATS__CONNECT_TIMEOUT` (기본값: 2)
- `NATS__MAX_RECONNECT_ATTEMPTS` (기본값: 60)
- `NATS__RECONNECT_TIME_WAIT_MS` (기본값: 2000)
- `NATS__QUEUE_GROUP` (기본값: default-workers)

### 7.1 YAML 서비스 설정 (ServiceSettings)

`CONFIG_PATH`(기본: `.devcontainer/config.yaml`)에서 로드되는 설정 항목:

```yaml
cors:
  origins: ["*"]
  credentials: false

auth:
  verify_jwt: true              # JWT 서명 검증 여부
  allow_insecure_jwt_decode: false  # 서명 없이 디코드 허용 여부(개발용)
  use_introspection: false      # 토큰 인트로스펙션 사용 여부

health:
  check_keycloak: true          # readiness 시 Keycloak 헬스 확인
  check_database: true          # readiness 시 DB 연결 확인
  check_minio: true             # readiness 시 MinIO 연결 확인
```

### 7.2 create_app 파라미터

```python
from fastapi_core import create_app

app = create_app(
    config=None,             # EnvConfig 인스턴스 (None이면 자동 생성)
    settings=None,           # ServiceSettings 인스턴스 (None이면 YAML에서 로드)
    lifespan=None,           # FastAPI lifespan 콜백
    include_auth_router=True # False로 설정 시 /token, /user 라우트 미포함
)
```

---

## 8. 데이터 저장소 정책

- 문서 원문: MinIO
- 문서 식별자/인덱스 및 metadata: Postgres
- 문서 삭제(Soft Delete) 시 MinIO 객체는 `deleted=true`로 마킹
- metadata는 문서별 1건만 허용(1:1)

---

## 10. DB 스키마 마이그레이션

Postgres 스키마 변경은 Alembic으로 관리한다. 서비스 초기화 시 `Base.metadata.create_all()` 호출은 개발 환경에서만 허용한다.

### 프로젝트 구조 (마이그레이션 관련)

```
docmesh_doc/
  models/
    base.py          # 공통 Base 클래스 (DeclarativeBase)
    metadata.py      # DocumentMetadataModel (공통 Base 상속)
alembic/
  env.py
  versions/
    <revision>_initial_schema.py
alembic.ini
```

### 로컬 개발 (마이그레이션 적용)

```bash
# 최초 설정
uv run alembic init alembic

# 마이그레이션 파일 자동 생성
uv run alembic revision --autogenerate -m "initial schema"

# 마이그레이션 적용
uv run alembic upgrade head

# 이전 버전으로 롤백
uv run alembic downgrade -1
```

### alembic/env.py 핵심 설정

```python
from docmesh_doc.models.base import Base
from docmesh_doc.models import metadata  # noqa: F401 (모델 임포트로 Base에 등록)

target_metadata = Base.metadata
```

### 환경변수

마이그레이션 실행 시 DB 연결 정보는 동일한 환경변수를 사용한다.

- `DB__HOST`
- `DB__PORT`
- `DB__NAME`
- `DB__USER`
- `DB__PASSWORD`
