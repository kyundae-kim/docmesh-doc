---
title: fastapi-core configuration model
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [fastapi, fastapi-core, configuration, deployment, security, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-examples-v0.1.6.md]
confidence: medium
---

# fastapi-core configuration model

`fastapi-core`의 설정은 앱 조립용 `AppConfig`와 외부 의존성용 `docmesh_py_core.ServiceConfigs`의 두 계층으로 나뉜다. 전자는 root path, token URL, CORS, logging, readiness와 서비스 선택을 제어하고, 후자는 Keycloak·SQLite·MinIO·Milvus·Ollama·Langfuse·NATS 연결 설정을 제공한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

## Deployment contract

DMS FastAPI 배포는 `ROOT_PATH`, `TOKEN_URL`, CORS 설정, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`를 환경에서 명시해 [[fastapi-core-app-assembly]]의 공개 경로와 readiness 정책을 결정한다. [[fastapi-core]]는 이 값을 소비해 app state와 middleware를 구성하며, 외부 시스템 설정은 [[docmesh-py-core]]를 통해 service client에 전달한다.

## Operating guardrails

`build_docmesh_env_overlay()`의 Keycloak, MinIO, NATS 등의 값은 개발·테스트용 fallback이므로 운영 배포값이 아니다. 운영 환경에서는 secret/token/비밀번호를 명시적 환경변수나 외부 secret 주입으로 제공하고, wildcard CORS와 credential 조합을 피하며, required service 집합을 배포 정책으로 선언해야 한다.

`AppConfig` 직접 주입, 환경변수 설정, SQLite만 선택 로딩하는 실행 예제는 [[fastapi-core-usage-patterns]]를 참고한다. 이 예제들은 [[fastapi-core-app-assembly]]의 readiness 상태와 service selection이 함께 바뀐다는 점을 보여 준다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Open questions

- DMS 프로덕션에서 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`에 포함할 서비스는 무엇인가?
- secret 주입은 배포 플랫폼의 어떤 메커니즘으로 표준화할 것인가?
- reverse proxy 경로와 `ROOT_PATH`/`TOKEN_URL` 조합은 어떤 URL 계약을 따라야 하는가?

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
