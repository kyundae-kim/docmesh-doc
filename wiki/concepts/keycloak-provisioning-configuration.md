---
title: Keycloak Provisioning Configuration
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [auth, authorization, validation, decision]
sources: [raw/articles/docmesh-py-core-config-2026-06-18.md, raw/articles/docmesh-py-core-api-2026-06-18.md]
confidence: medium
---

# Keycloak Provisioning Configuration

`docmesh-py-core`는 Keycloak 인증 설정과 별도로 realm/client/role 프로비저닝을 환경변수로 제어하는 모델을 제공한다.

## 핵심 설정
- `KEYCLOAK_PROVISIONING_ENABLED`
- `KEYCLOAK_PROVISIONING_DRY_RUN`
- `KEYCLOAK_ADMIN_REALM`
- `KEYCLOAK_ADMIN_CLIENT_ID`
- `KEYCLOAK_ADMIN_CLIENT_SECRET`
- `KEYCLOAK_ADMIN_USERNAME`
- `KEYCLOAK_ADMIN_PASSWORD`
- `KEYCLOAK_REALM_ROLES`
- `KEYCLOAK_CLIENT_ROLES`

## 규칙
- 프로비저닝이 활성화되면 Admin API 인증정보가 필요하다.
- 인증 방식은 service account 또는 관리자 사용자명/비밀번호 중 하나만 사용한다.
- 대상 realm/client는 각각 `KEYCLOAK_REALM`, `KEYCLOAK_CLIENT_ID`를 사용한다.
- 선언에서 제거된 리소스를 자동 삭제하지 않는다.

## API와의 연결
실제 실행 책임은 [[keycloak-auth-service]]가 아니라 `KeycloakProvisioner`가 가진다. API 문서 기준으로 프로비저너는 외부 `admin_client` 구현에 위임하며, 결과로 `created`, `updated`, `unchanged`, `failed`, `planned`, `dry_run` 집계를 제공한다.

## 문서 서버에서의 의미
문서/메타데이터 서버가 역할 기반 접근 제어를 강하게 요구한다면 배포 시점에 realm/client/role 구성을 선언적으로 맞추는 것이 중요하다. 다만 운영 보안을 위해 최소 권한과 비밀정보 분리가 필수이며, 일반 요청 처리 흐름과는 분리해서 운영해야 한다.

## 관련 페이지
- [[keycloak-auth-service]]
- [[settings]]
- [[environment-variable-configuration]]
