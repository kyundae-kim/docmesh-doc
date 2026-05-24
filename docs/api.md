# API 명세 - DocMesh Document Service

## 1. 개요

본 서비스는 `fastapi-core` 기본 라우트와 `docmesh_doc` 로컬 라우트를 함께 제공한다.

- fastapi-core 라우트: `/token`, `/user`
- docmesh_doc 라우트: `/documents*`, `/health/live`, `/health/ready`

---

## 2. 인증

- 방식: OAuth2 Bearer Token
- 문서 API(`/documents*`)는 인증 필요

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
- `Authorization: Bearer <token>`

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

## 3. 문서 API

## 3.1 POST /documents

설명: 문서 업로드

인증: 필요

요청: `multipart/form-data`
- `file_path` (string, 필수)
- `file` (binary, 필수)

응답 200:
```json
{
  "file_path": "projects/specs/example.txt"
}
```

오류:
- 401 인증 실패

## 3.2 GET /documents/{file_path:path}

설명: 문서 다운로드

인증: 필요

응답 200:
- Body: 파일 바이너리
- Headers:
  - `Content-Type: <원본 타입>`
  - `Content-Disposition: attachment; filename="..."`

오류:
- 404 문서 없음 또는 Soft Delete 상태

## 3.3 DELETE /documents/{file_path:path}

설명: 문서 Soft Delete

인증: 필요

응답 204: No Content

오류:
- 404 문서 없음

---

## 4. 헬스체크

### 4.1 GET /health/live

응답 200:
```json
{ "status": "live" }
```

### 4.2 GET /health/ready

응답 200:
```json
{ "status": "ready" }
```

---

## 5. 권한 체크 에러 포맷

커스텀 권한 체크 실패(`require_roles`, `require_scopes`) 시:

응답 403:
```json
{
  "error": "insufficient_scope",
  "error_description": "Missing required roles: ..., scopes: ..."
}
```

---

## 6. 설정

앱은 다음 설정 체계를 사용한다.

- Env: `fastapi_core.core.config.EnvConfig`
- YAML: `fastapi_core.core.config.ServiceSettings`

대표 환경변수 예시:
- `CONFIG_PATH`
- `KEYCLOAK__HTTP_URL`
- `KEYCLOAK__REALM`
- `KEYCLOAK__CLIENT_ID`
- `MINIO__ENDPOINT`
- `MINIO__ACCESS_KEY`
- `MINIO__SECRET_KEY`
- `MINIO__BUCKET`
