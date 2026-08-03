---
title: docmesh-py-core usage patterns
created: 2026-07-15
updated: 2026-08-02
type: concept
tags: [configuration, workflow, integration, testing, security]
sources: [raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-py-core usage patterns

`docmesh-py-core`의 기본 사용 원칙은 **assembly-first, direct-api-when-needed**다. 일반 동기 lifecycle은 `assemble_services()`로, NATS 또는 event-loop lifecycle은 `await assemble_service_runtime()`으로 구성하고, 개별 config·factory API는 단일 SDK 기능·CLI·테스트·명시적 factory hook 같은 제한된 경우에 사용한다. 이 패키지의 설정/health 계약은 [[docmesh-py-core]]와 [[fastapi-core-configuration]]에 연결된다. ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## v0.6.0 canonical package flow

v0.6.0 examples import `RuntimePlan`·`Service` from `docmesh_config` and `service_lifespan`, `assemble_services`, `create_*_client` from `docmesh_py_core`. 일반 async lifecycle은 `service_lifespan(plan=...)`, 동기 CLI/batch는 NATS와 timeout startup policy가 없을 때 `assemble_services(plan=...)`를 사용한다. 설정 package가 runtime package에 plan을 제공하는 관계는 [[docmesh-py-core-v060-runtime-contract]]에서 상세히 기록한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Assembly and lifecycle

동기 CLI/batch는 `RuntimePlan(services=(Service.POSTGRES.required(),))` 같은 typed plan을 만들고 `with assemble_services(plan=plan)`으로 정리한다. NATS 또는 startup timeout 정책이 필요하면 `service_lifespan()`/async runtime을 사용한다. ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

FastAPI custom lifespan에서는 bundle/runtime을 `app.state.services`에 두고, 필요한 wrapper/builder만 별도 state 키로 노출한다. runtime 예시는 `async with runtime:`으로 cleanup을 보장하고 readiness 실패를 503으로 투영한다. 앱 수준 lifecycle·readiness 정책은 [[fastapi-core-app-assembly]]와 [[fastapi-core-messaging-integration]]의 경계를 따른다. ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

v0.6.0 contract를 사용하는 소비자는 string 집합 대신 `RuntimePlan(services=(Service.SQLITE.required(), Service.NATS.optional()), ...)`처럼 typed plan을 구성하고 `await assemble_service_runtime(plan=...)`을 사용한다. `ServiceRuntime.require(Service.NATS)`는 plan 밖 접근과 초기화 실패를 구분하며, `async with runtime:`은 sync/async client 모두를 정리한다. 현재 interpreter에 package가 설치되어 있지 않으므로 dependency를 정렬하고 public signature를 확인한 뒤 실행 경로로 채택한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

## Selective services and health

부분 기능 소비자는 `load_service_configs(services={...})`로 선택 서비스만 로드한다. 선택하지 않은 `ServiceConfigs` 필드는 `None`이며, Langfuse가 비활성화된 경우 factory가 `None`을 반환할 수 있다. health endpoint는 `check_all_services(...)`에 required service 집합을 전달하고 `HealthCheckError`일 때 503 및 구조화된 결과를 반환하는 방식으로 구성한다. 설정 선택과 security guardrail은 [[docmesh-py-core]] 및 [[fastapi-core-configuration]]을 참고한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

`docmesh-config` v0.1.0의 `RuntimePlan`·`HealthcheckPolicy`·`diagnose_services(...)`는 이 assembly/runtime보다 앞선 설정과 preflight metadata 계층이다. source set은 실제 client factory나 `ServiceRuntime`에 대한 직접 bridge를 정의하지 않으므로, 같은 `Service`/service-name을 이유로 `docmesh-config` plan을 `docmesh-py-core` runtime에 바로 전달하지 않는다. [[docmesh-config-runtime-plan]]과 version-aligned adapter test가 그 경계를 확정해야 한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

v0.6.0 API/Examples는 version-aligned `docmesh_config.RuntimePlan`을 `docmesh_py_core` runtime에 직접 전달하는 경로를 명시하므로, 이전 문서의 “직접 bridge를 정의하지 않는다”는 제한은 v0.1.0 standalone source set 또는 비정렬 버전에 대한 주의로 해석한다. `docmesh-config` 자체가 client factory를 실행한다는 뜻은 아니며, v0.6.0 외 버전에서는 public signature와 adapter test를 다시 확인한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

새 plan 기반 preflight에서는 `diagnose_services(plan=plan, selection_mode="strict")`로 연결 없이 partial/invalid 설정, 대안 backend의 동시 구성, placeholder·전송 보안 위반을 먼저 확인한다. 진단 결과와 `SERVICE_CATALOG`은 secret 원문을 포함하지 않는 운영자용 입력이며 runtime assembly나 healthcheck의 대체물이 아니다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

## Direct integrations

NATS factory는 연결된 client가 아니라 `NatsConnectionBuilder`를 반환하며, `await builder.check()`는 임시 연결·`flush()`·정리를 수행한다. Keycloak password grant는 함수 인자가 환경 설정을 우선하고, JWT 원문이나 전체 claims는 로그에 남기지 않는다. Keycloak provisioning은 소비 애플리케이션이 admin-client 계약을 구현해 주입하며, dry-run은 변경 대신 planned 결과만 반환한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Source

- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
