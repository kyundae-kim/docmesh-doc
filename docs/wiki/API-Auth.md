# API 명세 - 인증

인증 라우트는 `fastapi-core`에서 제공한다.

## POST /token

Keycloak에서 Bearer 토큰을 발급받는다.

**요청:** `application/x-www-form-urlencoded`

| 파라미터 | 타입 | 필수 |
|---------|------|------|
| username | string | 필수 |
| password | string | 필수 |

**응답 200:**

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "token_type": "bearer"
}
```

---

## GET /user

현재 인증된 사용자 정보를 조회한다.

**요청 헤더:**

```
Authorization: Bearer <access_token>
```

**응답 200:**

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

## 권한 체크 에러 포맷

`require_roles` 또는 `require_scopes` 검사 실패 시:

**응답 403:**

```json
{
  "error": "insufficient_scope",
  "error_description": "Missing required roles: ..., scopes: ..."
}
```

---

[홈으로](./Home.md) | [다음: 문서 API](./API-Documents.md)
