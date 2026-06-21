---
title: KeycloakAuthProvider
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [auth, authorization, api, service]
sources: [raw/articles/fastapi-core-api-2026-06-18.md]
confidence: medium
---

# KeycloakAuthProvider

`KeycloakAuthProvider`는 `fastapi-core`에서 Keycloak 기반 인증과 토큰 검증을 수행하는 핵심 인증 provider다.

## 생성 계약
생성자는 다음 인자를 받는다.
- `http_url`
- `realm`
- `client_id`
- `client_secret`

입력 검증:
- `http_url`이 비어 있으면 `ValueError("http_url must not be empty")`
- `realm`이 비어 있으면 `ValueError("realm must not be empty")`
- `client_id`가 비어 있으면 `ValueError("client_id must not be empty")`

## 파생 속성
- `token_url`
- `introspection_url`
- `jwks_url`
- `issuer`

즉 provider는 단순 HTTP 래퍼가 아니라 Keycloak OIDC 엔드포인트 구성을 내부에서 책임진다.

## 주요 메서드
- `authenticate(username, password)`
- `refresh_access_token(refresh_token)`
- `decode_token(token)`
- `decode_token_insecure(token)`
- `introspect_token(token)`
- `to_user(payload)`

## 문서 서버에서의 의미
문서/메타데이터 API에서 로그인, bearer token 검증, 역할 추출을 구현할 때 중심 컴포넌트다. `get_current_user()` dependency와 결합되어 라우터 수준의 인증 흐름을 형성하며, 환경설정 관점에서는 [[environment-variable-configuration]]과도 연결된다.

## 관련 페이지
- [[fastapi-core-dependency-policy]]
- [[application-lifecycle-and-readiness]]
- [[keycloak-auth-service]]
