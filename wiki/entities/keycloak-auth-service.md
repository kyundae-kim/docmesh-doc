---
title: KeycloakAuthService
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [auth, authorization, api, service]
sources: [raw/articles/docmesh-py-core-api-2026-06-18.md, raw/articles/docmesh-py-core-config-2026-06-18.md]
confidence: medium
---

# KeycloakAuthService

`KeycloakAuthService`는 `docmesh-py-core`에서 Keycloak access token 발급과 JWT 검증/사용자 정보 추출을 담당하는 공개 인증 API다.

## 역할
- `fetch_access_token(scope=None)`로 access token 요청
- `extract_user_info(token)`으로 JWT 검증 후 사용자/역할 정보 추출
- 알고리즘, 서명, issuer, expiry, audience 검증 수행

## 관련 설정 계약
- `KEYCLOAK_URL`, `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`는 기본 필수값이다.
- `KEYCLOAK_VERIFY_SSL`은 기본 `true`이며 운영에서는 유지가 권장된다.
- `KEYCLOAK_TOKEN_GRANT_TYPE=password`이면 `KEYCLOAK_TOKEN_USERNAME`, `KEYCLOAK_TOKEN_PASSWORD`가 필요하다.
- `KEYCLOAK_AUDIENCE`, timeout, retry 설정은 JWT 검증과 토큰 요청 행태에 직접 영향을 준다.

## 반환 및 예외
- `fetch_access_token()`은 `AccessTokenResult`를 반환한다.
- `extract_user_info()`는 `AuthenticatedUser`를 반환한다.
- 대표 예외는 `KeycloakTokenConfigurationError`, `KeycloakTokenAuthenticationError`, `KeycloakTokenTemporaryError`, `KeycloakTokenError`, `TokenValidationError`다.

## 문서 서버에서의 의미
문서/메타데이터 REST API에서 bearer token 검증, 사용자 식별, 역할 기반 접근 제어를 구현할 때 중심이 되는 컴포넌트다. 설정 로드와 서비스 초기화 흐름은 [[sdk-consumption-pattern]]에 연결되고, 운영 readiness와는 별도로 인증 오류 모델을 API 계층에서 일관되게 다루게 해준다. 프로비저닝 관련 운영 규칙은 [[keycloak-provisioning-configuration]]에서 따로 본다.

## 관련 페이지
- [[sdk-consumption-pattern]]
- [[service-factory-registry]]
- [[sensitive-data-masking]]
- [[keycloak-provisioning-configuration]]
- [[environment-variable-configuration]]
