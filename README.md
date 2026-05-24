# DocMesh Document Service

DocMesh Document Service는 사용자별 문서를 MinIO에 저장/조회/삭제(Soft Delete)하는 FastAPI 서비스입니다.
현재 애플리케이션 부트스트랩, 인증, 공통 헬스체크는 `fastapi-core`를 기반으로 구성되어 있습니다.

## 핵심 구조

- 앱 팩토리: `docmesh_doc.factory:create_app`
  - `fastapi_core.factory.create_app(...)`를 사용
  - `include_auth_router=True`로 core auth 라우트(`/token`, `/user`) 포함
  - lifespan에서 `set_auth_provider`, `set_minio_client` 등록
- 로컬 라우트: `docmesh_doc.routes`
  - `/documents` 계열 문서 API
  - `/health/live`, `/health/ready` (서비스 전용 단순 헬스)
- 스토리지: MinIO (`app.state.minio_client`)
- 인증/인가: fastapi-core dependency + Keycloak provider

## API 요약

- POST `/token` (fastapi-core 제공)
- GET `/user` (fastapi-core 제공)
- POST `/documents`
- GET `/documents/{file_path:path}`
- DELETE `/documents/{file_path:path}`
- GET `/health/live`
- GET `/health/ready`

## 동작 정책

- Object Key: `{username}/{file_path}`
- 사용자명 우선순위: `preferred_username` -> `username` -> `sub`
- 삭제는 물리 삭제가 아닌 Soft Delete(`deleted=true` 태그)

## 실행

```bash
uv sync
uv run fastapi dev docmesh_doc/main.py
```

## 테스트

```bash
uv run python -m pytest -q
```

## 설정

주요 설정은 `fastapi-core`의 `EnvConfig`/`ServiceSettings`를 사용합니다.

- 환경 변수: `.env` (예: `KEYCLOAK__*`, `MINIO__*`, `CONFIG_PATH`)
- 서비스 YAML: `CONFIG_PATH`가 가리키는 파일 (기본 `.devcontainer/config.yaml`)

## 참고

아래 모듈은 과거 호환을 위한 deprecated placeholder입니다(실행 경로에서 사용하지 않음).

- `docmesh_doc/routes/auth.py`
- `docmesh_doc/services/logging.py`
- `docmesh_doc/core/logging.py`
- `docmesh_doc/dependencies/config.py`
