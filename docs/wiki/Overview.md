# 개요 및 아키텍처

## 서비스 목적

DocMesh Document Service는 인증된 사용자가 문서를 안전하게 업로드/다운로드/삭제하고,
문서에 연관된 metadata를 생성/조회/수정/삭제(CRUD)할 수 있는 API를 제공한다.

## 핵심 동작

| 항목 | 내용 |
|------|------|
| 문서 접근 키 | `document_id` (UUID) |
| MinIO 객체 키 예시 | `{username}/{document_id}` |
| 사용자명 우선순위 | `preferred_username -> username -> sub` |
| 문서 삭제 정책 | Soft Delete (MinIO tag `deleted=true`) |
| Metadata 저장소 | PostgreSQL |
| 문서-Metadata 관계 | 1:1 |
| DB 스키마 관리 | Alembic 마이그레이션 (프로덕션 `create_all()` 금지) |

## 아키텍처 구성

```
docmesh_doc/
  factory.py          # 앱 팩토리 (create_app)
  routes/
    documents.py      # POST/GET/DELETE /documents
    metadata.py       # POST/GET/PATCH/DELETE /documents/{id}/metadata
    health.py         # GET /health/live, /health/ready
  services/
    document.py       # 문서 비즈니스 로직
    metadata.py       # Metadata 비즈니스 로직
    security.py       # 인증/권한 처리
  models/
    base.py           # 공통 SQLAlchemy Base
    document.py       # Document ORM 모델
    metadata.py       # DocumentMetadata ORM 모델
  schemas/            # Pydantic 스키마
  dependencies/       # FastAPI 의존성
  core/
    exceptions.py     # 커스텀 예외
```

## fastapi-core 제공 기능

`fastapi-core` 라이브러리가 다음 공통 기능을 제공한다:

- Keycloak OAuth2/OIDC 인증 (`KeycloakAuthProvider`, `get_current_user`)
- PostgreSQL SQLAlchemy 엔진 관리 (`set_db_engine`, `get_db_session`)
- MinIO 객체 스토리지 클라이언트 (`set_minio_client`, `get_minio_client`)
- NATS 메시징 클라이언트 (`set_nats_client`, `get_nats_client`, `publish_json`, `subscribe_json`)
- 앱 팩토리 (`create_app(include_auth_router=True)`)
- 공통 설정 모델 (`EnvConfig`, `ServiceSettings`, `NatsConfig`)
- 공통 라우트: `GET /health/liveness`, `GET /health/readiness`, `POST /token`, `GET /user`

---

[홈으로](./Home.md)
