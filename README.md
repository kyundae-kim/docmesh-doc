# DocMesh Document Service

DocMesh Document Service는 사용자 문서를 MinIO에 저장/조회/삭제(Soft Delete)하고,
문서 연관 metadata를 Postgres에 저장/관리하는 FastAPI 서비스입니다.

이 저장소의 문서는 목적별로 분리되어 있습니다.

- 제품 요구사항: `docs/prd.md`
- API 명세: `docs/api.md`
- 테스트 가이드: `docs/test.md`
- 현재 문서: `README.md` (빠른 시작/구조 개요)

## 빠른 시작

1) 의존성 설치

```bash
uv sync
```

2) 앱 실행

```bash
uv run fastapi dev docmesh_doc/main.py
```

3) 테스트 실행

```bash
uv run python -m pytest -q
```

## 아키텍처 요약

- 앱 팩토리: `docmesh_doc.factory:create_app`
- 공통 기반: `fastapi-core`
  - auth 라우트(`/token`, `/user`) 포함
  - Keycloak provider, MinIO client를 앱 시작 시 state에 등록
- 로컬 라우트:
  - `/documents` (업로드/다운로드/삭제, ID 기반)
  - `/documents/{document_id}/metadata` (문서별 metadata CRUD)
  - `/health/live`, `/health/ready`

## 핵심 동작

- 문서 접근 키: `document_id(UUID)`
- MinIO 객체 키 예시: `{username}/{document_id}`
- 사용자명 우선순위: `preferred_username -> username -> sub`
- 문서 삭제 정책: 물리 삭제 대신 MinIO tag `deleted=true`로 Soft Delete
- metadata 저장소: Postgres
- 관계 모델: 문서 1건당 metadata 1건(1:1)
- DB 스키마 관리: Alembic 마이그레이션 (프로덕션에서 `create_all()` 사용 금지)

## DB 마이그레이션

Postgres 스키마는 Alembic으로 관리한다. 자세한 내용은 `docs/api.md`의 "DB 스키마 마이그레이션" 섹션을 참고한다.

```bash
# 마이그레이션 적용
uv run alembic upgrade head
```

## 설정

- 환경 변수: `fastapi_core.core.config.EnvConfig`
- 서비스 YAML: `fastapi_core.core.config.ServiceSettings`
- 기본 YAML 경로: `.devcontainer/config.yaml` (`CONFIG_PATH`로 변경 가능)

자세한 키는 `docs/api.md`의 "설정" 섹션을 참고하세요.
