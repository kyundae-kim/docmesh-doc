# DocMesh Document Service

DocMesh Document Service는 사용자 문서를 MinIO에 저장/조회/삭제(Soft Delete)하는 FastAPI 서비스입니다.

이 저장소의 문서는 목적별로 분리되어 있습니다.

- 제품 요구사항: `prd.md`
- API 명세: `api.md`
- 테스트 가이드: `test.md`
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
  - `/documents` (업로드/다운로드/삭제)
  - `/health/live`, `/health/ready`

## 핵심 동작

- 객체 키 규칙: `{username}/{file_path}`
- 사용자명 우선순위: `preferred_username -> username -> sub`
- 삭제 정책: 물리 삭제 대신 MinIO tag `deleted=true`로 Soft Delete

## 설정

- 환경 변수: `fastapi_core.core.config.EnvConfig`
- 서비스 YAML: `fastapi_core.core.config.ServiceSettings`
- 기본 YAML 경로: `.devcontainer/config.yaml` (`CONFIG_PATH`로 변경 가능)

자세한 키는 `api.md`의 "설정" 섹션을 참고하세요.
