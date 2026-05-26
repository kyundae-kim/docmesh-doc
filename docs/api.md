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
{ "status": "live" }
```

### 5.2 GET /health/ready

응답 200:
```json
{ "status": "ready" }
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
- `MINIO__ENDPOINT`
- `MINIO__ACCESS_KEY`
- `MINIO__SECRET_KEY`
- `MINIO__BUCKET`
- `DB__HOST`
- `DB__PORT`
- `DB__NAME`
- `DB__USER`
- `DB__PASSWORD`

---

## 8. 데이터 저장소 정책

- 문서 원문: MinIO
- 문서 식별자/인덱스 및 metadata: Postgres
- 문서 삭제(Soft Delete) 시 MinIO 객체는 `deleted=true`로 마킹
- metadata는 문서별 1건만 허용(1:1)
