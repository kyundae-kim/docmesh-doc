---
title: ServiceSettings
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [schema, validation, service, configuration]
sources: [raw/articles/fastapi-core-api-2026-06-18.md, raw/articles/fastapi-core-config-2026-06-18.md]
confidence: medium
---

# ServiceSettings

`ServiceSettings`는 `fastapi-core`에서 서비스 초기화 정책과 health/lifecycle 제어를 담는 설정 객체다.

## 역할
- `app.state.settings`에 저장된다.
- `get_settings()`는 state에 없으면 `ServiceSettings.from_yaml(config.config_path)` 결과를 저장한다.
- `get_current_user()`의 인증 분기, readiness 체크, lifecycle eager-init 정책의 판단 근거가 된다.

## 중요한 사용 지점
- `settings.auth.use_introspection`
- `settings.auth.verify_jwt`
- `settings.auth.allow_insecure_jwt_decode`
- `health.check_keycloak`, `health.check_database`, `health.check_minio`, `health.check_langfuse`
- lifecycle eager-init 관련 설정

## 설정 문서에서 확인된 세부 규칙
- YAML 파일이 없어도 `ServiceSettings.from_yaml(path)`는 예외 없이 기본값을 사용한다.
- `auth`는 JWT 검증, insecure decode, introspection 정책을 제어한다.
- `health`는 readiness에서 어떤 외부 서비스를 확인할지 결정한다.
- `lifecycle.eager_keycloak/database/minio/langfuse`가 `null`이면 대응 `health.check_*` 값을 상속한다.
- `lifecycle.use_docmesh_registry`는 dependency 계층의 registry 사용을 끄는 스위치가 아니라 startup에서 registry를 선행 초기화할지까지 포함한 정책 플래그다.

## 문서 서버에서의 의미
문서와 메타데이터를 다루는 API는 단순 config만으로는 충분하지 않고, 어떤 서비스가 필수인지와 어떤 검사를 startup/readiness에서 수행할지 정책화해야 한다. 이 정책 객체가 바로 `ServiceSettings`다.

## 관련 페이지
- [[env-config]]
- [[service-selection-and-health-checks]]
- [[application-lifecycle-and-readiness]]
- [[fastapi-core-layered-configuration]]
