---
title: docmesh-py-core
created: 2026-07-11
updated: 2026-07-11
type: entity
tags: [dms-core, integration, configuration, dependency, security]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md]
confidence: medium
---

# docmesh-py-core

`docmesh-py-core`는 수집한 `fastapi-core` API 문서에서 서비스 설정, 클라이언트 구성, readiness 집계, 인증 타입을 제공하는 공통 의존성으로 나타난다. 이는 사용자가 지칭한 DMS 로직 코어와 동일하다고 단정하지 않으며, 현재는 별도 업스트림 의존성으로 기록한다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Observed integration contract

- `fastapi-core`는 `load_service_configs(...)`를 통해 선택된 서비스 설정을 로딩한다.
- readiness는 `check_all_services(...)`로 집계하며, 필수 서비스 실패는 error/503, 선택 서비스 실패는 degraded/200으로 구분한다.
- Keycloak 인증, NATS builder 및 여러 외부 서비스 wrapper/client가 FastAPI dependency의 기반을 이룬다.

## Relationship to the DMS service

[[fastapi-core]]는 이 의존성의 settings와 service-client wrapper를 FastAPI 앱의 `app.state`에 배치한다. [[fastapi-core-app-assembly]]는 DMS 배포에서 그 상태, lifespan, readiness 정책을 조립하는 경계다. DMS의 실제 로직 코어 패키지가 `docmesh-py-core`인지 여부는 별도 DMS 소스로 확인해야 한다.

`load_service_configs(...)`에 전달되는 외부 서비스 설정과 개발/테스트 fallback의 운영상 한계는 [[fastapi-core-configuration]]에 정리한다. Keycloak·MinIO·NATS 등의 연결 credential은 운영 배포에서 외부 secret으로 대체해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

메시징 세부 연결값은 이 의존성의 `ServiceConfigs`에서 해석되고, `fastapi-core`는 NATS를 서비스 선택·readiness·lifecycle 확장 지점으로 다룬다. 자세한 경계는 [[fastapi-core-messaging-integration]]에 정리한다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
