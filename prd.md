# DocMesh Document Service PRD (Current Architecture)

## 1. 개요

DocMesh Document Service는 MinIO(S3 호환)를 사용해 사용자별 파일을 저장/조회/삭제(Soft Delete)하는 FastAPI 서비스다.
현재 구조는 `fastapi-core`를 공통 기반으로 사용한다.

## 2. 목표

- 인증 기반 문서 API 제공
- 사용자별 네임스페이스 분리 저장
- Soft Delete 기반 논리 삭제
- 공통 인증/설정/헬스체크 기능을 fastapi-core로 표준화

## 3. 아키텍처

### 3.1 앱 구성

- 엔트리포인트: `docmesh_doc.main:app`
- 앱 팩토리: `docmesh_doc.factory.create_app`
- 내부적으로 `fastapi_core.factory.create_app` 사용
- core auth 라우트 포함: `include_auth_router=True`

### 3.2 상태(State)

- `app.state.env_config` (fastapi_core `EnvConfig`)
- `app.state.service_settings` (fastapi_core `ServiceSettings`)
- `app.state.auth_provider` (KeycloakAuthProvider)
- `app.state.minio_client` (Minio)

### 3.3 라우트

- fastapi-core 제공
  - `POST /token`
  - `GET /user`
- docmesh_doc 제공
  - `POST /documents`
  - `GET /documents/{file_path:path}`
  - `DELETE /documents/{file_path:path}`
  - `GET /health/live`
  - `GET /health/ready`

## 4. 도메인/저장 정책

- 저장 키: `{username}/{file_path}`
- username 결정 우선순위:
  1) `preferred_username`
  2) `username`
  3) `sub`
- 삭제 방식: MinIO object tag `deleted=true`로 Soft Delete
- Soft Delete 객체 조회 시 404 처리

## 5. 기능 요구사항

### 5.1 문서 업로드

- Endpoint: `POST /documents`
- 인증: 필요
- 입력:
  - form-data `file_path`
  - form-data `file`
- 처리:
  - content length 계산 후 MinIO put
  - metadata(`filename`, `file_path`) 저장
  - tag `deleted=false` 저장
- 응답:
  - `{"file_path": "..."}`

### 5.2 문서 다운로드

- Endpoint: `GET /documents/{file_path:path}`
- 인증: 필요
- 처리:
  - object 조회
  - 없거나 deleted=true면 404
  - 스트리밍 응답

### 5.3 문서 삭제

- Endpoint: `DELETE /documents/{file_path:path}`
- 인증: 필요
- 처리:
  - 태그 `deleted=true` 설정
  - 미존재 시 404
- 응답: 204

### 5.4 헬스체크

- `GET /health/live` -> `{"status":"live"}`
- `GET /health/ready` -> `{"status":"ready"}`

## 6. 보안/인증

- OAuth2 Bearer
- 토큰 처리/유저 추출은 fastapi-core auth dependency 사용
- 권한 체크는 role/scope 기반 dependency 함수(`require_roles`, `require_scopes`) 사용

## 7. 설정

### 7.1 환경 변수(EnvConfig)

- Keycloak: `KEYCLOAK__HTTP_URL`, `KEYCLOAK__REALM`, `KEYCLOAK__CLIENT_ID` 등
- MinIO: `MINIO__ENDPOINT`, `MINIO__ACCESS_KEY`, `MINIO__SECRET_KEY`, `MINIO__BUCKET`
- 기타: `CONFIG_PATH`, `ROOT_PATH`, `ENV`

### 7.2 YAML(ServiceSettings)

- 기본 경로: `.devcontainer/config.yaml`
- 주요 키:
  - `cors.*`
  - `auth.verify_jwt`
  - 기타 service-level 옵션

## 8. 비기능 요구사항

- Stateless 구조 유지
- MinIO/Keycloak 외부 연동 안정성 확보
- pytest 기반 회귀 검증 가능

## 9. 테스트 기준

- 문서 업로드/다운로드 성공
- Soft Delete 후 404
- 미존재 삭제 404
- health live/ready 정상 응답
- 권한 체크 dependency 동작
