---
title: fastapi-core messaging integration
created: 2026-07-11
updated: 2026-08-02
type: concept
tags: [fastapi, fastapi-core, messaging, integration, deployment, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.2.0.md, raw/articles/dms-core-messaging-v0.2.0.md]
confidence: medium
---

# fastapi-core messaging integration

`fastapi-core`에서 NATS 같은 메시징은 독립적인 FastAPI 공개 API가 아니라 service client, readiness, lifecycle에 연결되는 선택 가능한 외부 서비스다. 기본 제공 범위는 `get_nats_connection_builder()`와 공통 service lookup까지이며 publisher/subscriber helper, connection-state dependency, messaging route는 제공하지 않는다. NATS가 비활성화되었거나 runtime에 없으면 builder dependency는 503을, 등록 객체의 타입이 맞지 않으면 500을 반환한다. ^[raw/articles/fastapi-core-messaging-v0.2.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md]

v0.5.0 API reference도 `get_nats_connection_builder`를 typed service dependency로, `get_service_client`를 일반 lookup으로 열거하지만 messaging route·publisher·subscriber API는 열거하지 않는다. 따라서 이 source는 NATS가 hosting/runtime 확장 경계라는 기존 결론을 보강할 뿐 `dms-core`와 직접 통합된다는 근거는 아니다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md]

v0.6.0 API reference도 `get_nats_connection_builder`를 8개 typed service dependency 중 하나로 열거하고, module 조립을 추가하면서도 messaging router·publisher·subscriber API는 추가하지 않는다. 따라서 module API는 host application의 조립 단위일 뿐 `dms-core`와 직접 메시징 통합을 뜻하지 않는다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

v0.7.0 API/config/examples는 같은 경계를 유지한다. `get_nats_connection_builder`는 typed service dependency이고 `NatsConfig`는 `NATS_SERVERS`와 user/password, token, creds-file 중 하나의 인증 mode를 다루지만, publisher/subscriber helper·messaging router·connection-state dependency는 공개하지 않는다. 실제 persistent connection과 drain ownership은 consumer의 `ManagedResource`/lifespan 확장으로 남는다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

## Service selection and health policy

`fastapi-core`로 호스팅되는 DMS application은 `enabled_services`에 `nats`를 넣어 readiness metadata에 포함하고, `required_services`로 실패의 영향도를 정할 수 있다. 하지만 NATS 설정과 `create_nats_client()`를 통한 client 생성이 있어야 check가 자동 등록된다. 예를 들어 Keycloak만 필수이고 NATS가 선택이면 등록된 NATS check의 장애는 `200/degraded`가 될 수 있지만, NATS를 필수로 지정하면 503/error 대상이 된다. 이 앱 조립·상태 계약은 [[fastapi-core-app-assembly]]에, 환경변수와 secret 관리 정책은 [[fastapi-core-configuration]]에 연결된다. ^[raw/articles/fastapi-core-messaging-v0.2.0.md]

중요하게도 이 application-layer 확장성은 `dms-core` SDK가 직접 메시지를 발행·구독한다는 뜻이 아니다. SDK의 현재 비메시징 범위와 미래 확장 조건은 [[dms-core-messaging-boundary]]에 정리한다. ^[raw/articles/dms-core-messaging-v0.2.0.md]

## Extension boundary

`v0.3.0` API 기준 기본 service-client lifecycle은 `ServiceRuntime`이 관리한다. custom lifespan shutdown이 예외로 끝나도 내부 wrapper는 `finally`에서 managed resource를 역순 정리하고 runtime close를 수행한다. 연결 상태 객체를 route/service layer에서 직접 사용할 필요가 있으면 `ManagedResource` 또는 custom lifespan에서 `app.state`를 확장하고 프로젝트별 dependency를 구현한다. 이 경계는 [[fastapi-core]]의 공개 표면을 보존하며, 설정/client-wrapper의 업스트림 계약은 [[docmesh-py-core]]에 있다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

## DMS deployment guidance

NATS credential 및 연결 세부 설정은 `ServiceConfigs` 영역에서 해석되고, `fastapi-core`는 서비스 선택과 readiness 정책을 주로 담당한다. 운영 환경에서는 `NATS_TOKEN`, password, credentials file 등 민감 값을 로그나 문서 예시에 노출하지 않고 외부 secret으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

## Open questions

- DMS에서 NATS는 필수 서비스인가, degraded를 허용하는 선택 서비스인가?
- project-level `app.state.nats`와 custom dependency의 이름·수명주기 계약은 무엇인가?
- publish/subscribe의 재시도, shutdown drain, startup 실패 정책은 어느 계층이 책임지는가?

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-api-reference.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.7.0.md`
- `raw/articles/fastapi-core-wiki-examples-v0.7.0.md`
- `raw/articles/fastapi-core-env-example-v0.7.0.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.2.0.md`
- `raw/articles/dms-core-messaging-v0.2.0.md`
