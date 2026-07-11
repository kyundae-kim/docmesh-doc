---
title: fastapi-core messaging integration
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [fastapi, fastapi-core, messaging, integration, deployment, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md]
confidence: medium
---

# fastapi-core messaging integration

`fastapi-core`에서 NATS 같은 메시징은 독립적인 FastAPI 공개 API가 아니라 service client, readiness, lifecycle에 연결되는 선택 가능한 외부 서비스다. 기본 제공 범위는 `get_nats_connection_builder()`와 공통 service lookup까지이며 publisher/subscriber helper, connection-state dependency, messaging route는 제공하지 않는다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

## Service selection and health policy

DMS는 `enabled_services`에 `nats`를 넣어 readiness 대상에 포함하고, `required_services`로 실패의 영향도를 정한다. 예를 들어 Keycloak만 필수이고 NATS가 선택이면 NATS 장애는 `200/degraded`가 될 수 있지만, NATS를 필수로 지정하면 503/error 대상이 된다. 이 앱 조립·상태 계약은 [[fastapi-core-app-assembly]]에, 환경변수와 secret 관리 정책은 [[fastapi-core-configuration]]에 연결된다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

## Extension boundary

기본 service-client lifecycle은 `create_app()`이 관리하고 shutdown 시 정리된다. 연결 상태 객체를 route/service layer에서 직접 사용할 필요가 있으면 custom lifespan에서 `app.state`를 확장하고 프로젝트별 dependency를 구현한다. 이 경계는 [[fastapi-core]]의 공개 표면을 보존하며, 설정/client-wrapper의 업스트림 계약은 [[docmesh-py-core]]에 있다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

## DMS deployment guidance

NATS credential 및 연결 세부 설정은 `ServiceConfigs` 영역에서 해석되고, `fastapi-core`는 서비스 선택과 readiness 정책을 주로 담당한다. 운영 환경에서는 `NATS_TOKEN`, password, credentials file 등 민감 값을 로그나 문서 예시에 노출하지 않고 외부 secret으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

## Open questions

- DMS에서 NATS는 필수 서비스인가, degraded를 허용하는 선택 서비스인가?
- project-level `app.state.nats`와 custom dependency의 이름·수명주기 계약은 무엇인가?
- publish/subscribe의 재시도, shutdown drain, startup 실패 정책은 어느 계층이 책임지는가?

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
