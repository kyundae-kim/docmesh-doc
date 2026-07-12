---
title: fastapi-core configuration model
created: 2026-07-11
updated: 2026-07-12
type: concept
tags: [fastapi, fastapi-core, configuration, deployment, security, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/dms-core-config-v0.2.0.md]
confidence: medium
---

# fastapi-core configuration model

`fastapi-core`의 설정은 앱 조립용 `AppConfig`와 외부 의존성용 `docmesh_py_core.ServiceConfigs`의 두 계층으로 나뉜다. 전자는 root path, token URL, CORS, logging, readiness와 서비스 선택을 제어하고, 후자는 Keycloak·PostgreSQL·SQLite·MinIO·Milvus·Ollama·Langfuse·NATS 연결 설정을 제공한다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

## Deployment contract

DMS FastAPI 배포는 `ROOT_PATH`, `TOKEN_URL`, CORS 설정, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`를 환경에서 명시해 [[fastapi-core-app-assembly]]의 공개 경로와 readiness 정책을 결정한다. [[fastapi-core]]는 이 값을 소비해 app state와 middleware를 구성하며, 외부 시스템 설정은 [[docmesh-py-core]]를 통해 service client에 전달한다.

## Operating guardrails

`build_docmesh_env_overlay()`의 Keycloak, MinIO, NATS 등의 값은 개발·테스트용 fallback이므로 운영 배포값이 아니다. 운영 환경에서는 secret/token/비밀번호를 명시적 환경변수나 외부 secret 주입으로 제공하고, wildcard CORS와 credential 조합을 피하며, required service 집합을 배포 정책으로 선언해야 한다.

`v0.2.0` 설정 문서는 PostgreSQL을 `ServiceConfigs`가 다루는 외부 시스템, development/test fallback, 그리고 전용 dependency 범위에 포함한다. 이는 PostgreSQL 지원이 `fastapi-core` 자체의 문서 저장 API를 뜻하는 것은 아니며, [[docmesh-py-core]]가 제공하는 설정·client wrapper를 [[fastapi-core-app-assembly]]가 선택 서비스와 readiness에 연결하는 application-layer 통합이다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

`CORS_ORIGINS`, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`에 빈 문자열을 명시하면 현재 validator는 `None`으로 바꾸며, non-optional list 필드는 기본값으로 복원되지 않아 validation error가 된다. 기본 동작을 쓰려면 빈 값으로 설정하지 말고 환경변수 자체를 생략해야 한다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

`AppConfig` 직접 주입, 환경변수 설정, SQLite만 선택 로딩하는 실행 예제는 [[fastapi-core-usage-patterns]]를 참고한다. 이 예제들은 [[fastapi-core-app-assembly]]의 readiness 상태와 service selection이 함께 바뀐다는 점을 보여 준다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

`SQLITE_PATH`와 MinIO 같은 이름이 두 계층에 걸쳐 보이지만, DMS SDK의 storage 선택·startup health 정책은 [[dms-core-configuration]]의 책임이고, `fastapi-core`는 application assembly와 service readiness 정책을 담당한다. 같은 환경을 배포하더라도 설정 소유 경계를 명시해야 한다. ^[raw/articles/dms-core-config-v0.2.0.md]

## Open questions

- DMS 프로덕션에서 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`에 포함할 서비스는 무엇인가?
- secret 주입은 배포 플랫폼의 어떤 메커니즘으로 표준화할 것인가?
- reverse proxy 경로와 `ROOT_PATH`/`TOKEN_URL` 조합은 어떤 URL 계약을 따라야 하는가?
- PostgreSQL을 DMS 배포의 enabled/required service 집합에 포함할지, 그리고 DMS SDK의 metadata-store 선택과 어떻게 정렬할 것인가?

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/dms-core-config-v0.2.0.md`
