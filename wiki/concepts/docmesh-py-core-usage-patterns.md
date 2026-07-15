---
title: docmesh-py-core usage patterns
created: 2026-07-15
updated: 2026-07-15
type: concept
tags: [configuration, workflow, integration, testing, security]
sources: [raw/articles/docmesh-py-core-examples-v0.2.0.md]
confidence: medium
---

# docmesh-py-core usage patterns

`docmesh-py-core`의 기본 사용 원칙은 **assembly-first, direct-api-when-needed**다. 일반 동기 lifecycle은 `assemble_services()`로, NATS 또는 event-loop lifecycle은 `await assemble_service_runtime()`으로 구성하고, 개별 config·factory API는 단일 SDK 기능·CLI·테스트·명시적 factory hook 같은 제한된 경우에 사용한다. 이 패키지의 설정/health 계약은 [[docmesh-py-core]]와 [[fastapi-core-configuration]]에 연결된다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

## Assembly and lifecycle

최소 동기 구성은 `services={"sqlite"}`, `required={"sqlite"}`, `check_on_startup=True`로 `assemble_services()`를 호출한 뒤 `with bundle:`로 정리한다. PostgreSQL/SQLite 대안은 `one_of=({"postgres", "sqlite"},)`로 선언하며, NATS는 동기 `ServiceBundle` 대상이 아니므로 async runtime을 사용한다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

FastAPI custom lifespan에서는 bundle/runtime을 `app.state.services`에 두고, 필요한 wrapper/builder만 별도 state 키로 노출한다. NATS runtime 예시는 `async with runtime:`으로 cleanup을 보장하고 `runtime.require("nats")`로 builder를 얻는다. 앱 수준 lifecycle·readiness 정책은 [[fastapi-core-app-assembly]]와 [[fastapi-core-messaging-integration]]의 경계를 따른다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

## Selective services and health

부분 기능 소비자는 `load_service_configs(services={...})`로 선택 서비스만 로드한다. 선택하지 않은 `ServiceConfigs` 필드는 `None`이며, Langfuse가 비활성화된 경우 factory가 `None`을 반환할 수 있다. health endpoint는 `check_all_services(...)`에 required service 집합을 전달하고 `HealthCheckError`일 때 503 및 구조화된 결과를 반환하는 방식으로 구성한다. 설정 선택과 security guardrail은 [[docmesh-py-core]] 및 [[fastapi-core-configuration]]을 참고한다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

## Direct integrations

NATS factory는 연결된 client가 아니라 `NatsConnectionBuilder`를 반환하며, `await builder.check()`는 임시 연결·`flush()`·정리를 수행한다. Keycloak password grant는 함수 인자가 환경 설정을 우선하고, JWT 원문이나 전체 claims는 로그에 남기지 않는다. Keycloak provisioning은 소비 애플리케이션이 admin-client 계약을 구현해 주입하며, dry-run은 변경 대신 planned 결과만 반환한다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

## Source

- `raw/articles/docmesh-py-core-examples-v0.2.0.md`
