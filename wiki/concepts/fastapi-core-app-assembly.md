---
title: fastapi-core application assembly
created: 2026-07-11
updated: 2026-07-18
type: concept
tags: [fastapi, fastapi-core, architecture, deployment, configuration, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-wiki-configuration.md, raw/articles/fastapi-core-env-example-v0.4.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md, raw/articles/fastapi-core-wiki-examples.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.2.0.md, raw/articles/dms-core-wiki-api-reference-v0.4.0.md, raw/articles/dms-core-wiki-examples-v0.4.0.md]
confidence: medium
---

# fastapi-core application assembly

`fastapi-core`의 `create_app(...)`은 DMS FastAPI 서비스의 공통 조립 지점이다. tagged API snapshot은 config와 settings의 생략 시 각각 앱/선택 서비스 설정을 로딩한다고 설명하지만, GitHub Wiki snapshot은 settings 대신 사전 조립된 `ServiceRuntime` 주입만 지원한다고 설명한다. 두 source의 body가 다르므로 소비 애플리케이션은 설치된 `fastapi-core`의 signature와 테스트로 조립 방식을 확인해야 한다. ^[raw/articles/fastapi-core-api-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md]

## Lifecycle and state

조립 단계에서 구성된 config, settings, service clients, readiness metadata는 `app.state`에 보관된다. `v0.3.0`에서는 `service_runtime`, typed `readiness_registry`, `resource_registry`, 앱 전용 OAuth2 scheme도 명시적 상태 계약이며, legacy readiness alias는 없다. custom lifespan은 service runtime과 managed resource 준비 뒤에 실행되고, shutdown 예외가 있어도 resource를 역순 정리한 뒤 runtime close가 `finally`에서 수행된다. 이 구조는 [[fastapi-core]]를 서비스 HTTP 계층으로 두고 [[docmesh-py-core]]의 외부 의존성 설정/클라이언트를 재사용하는 경계를 만든다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

GitHub Wiki snapshot은 `app.state.settings`와 `app.state.service_clients`도 제거된 비공개 state라고 명시하며 config, root logger, service runtime, readiness/resource registry, OAuth2 scheme, error renderer, 필요 시 auth provider만 계약으로 열거한다. service 설정과 concrete client는 runtime을 반환하는 dependency로 접근한다. 이는 tagged snapshot의 flat state 설명과 상충하므로, DMS adapter는 runtime/dependency API를 우선하고 flat state에 의존하지 않아야 한다. ^[raw/articles/fastapi-core-wiki-api-reference.md]

`v0.3.0` config 문서는 `create_app()`이 `load_app_config()` 뒤에 application logging을 초기화하고, lifespan startup에서 selected service runtime을 조립한다고 설명한다. `token_url`은 앱마다 별도의 `OAuth2PasswordBearer`와 OpenAPI password flow에 저장되므로, 한 프로세스에서 서로 다른 token URL로 여러 앱을 조립해도 기존 앱의 OpenAPI 계약을 바꾸지 않는다. ^[raw/articles/fastapi-core-config-v0.3.0.md]

GitHub Wiki Configuration snapshot은 runtime 조립 경로를 `AppConfig` 로딩 → runtime plan → non-mutating environment overlay → `assemble_runtime()` → `app.state.service_runtime`/readiness 등록 → shutdown close로 설명한다. `create_app(runtime=...)`은 이 서비스 조립만 우회하고 CORS, logging, readiness AppConfig 정책은 보존한다. 하지만 overlay가 개발 fallback을 추가하는지 여부는 tagged v0.3.0 config snapshot과 상충하므로, DMS 배포는 explicit configuration을 제공해야 한다. ^[raw/articles/fastapi-core-wiki-configuration.md]

인증 endpoint가 불필요한 내부 서비스는 auth router를 제외할 수 있고, 보호 router는 `create_app()` 결과에 명시적으로 포함한다. `v0.3.0` 예제는 domain SDK를 `ManagedResource`로 등록해 factory·healthcheck·lifecycle cleanup·route dependency를 함께 조립하는 패턴을 보여 준다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

GitHub Wiki Examples는 `create_app()`이 runtime/managed resource를 사용자 lifespan 바깥에서 소유하므로 사용자 shutdown 오류에도 공통 정리를 시도한다고 예시로 확인한다. 일반 DMS app은 `create_app(resources=...)`에 맡기고, 직접 `build_lifespan` 또는 router-only assembly를 선택하면 readiness registry, runtime state, middleware, error handler를 직접 구성해야 한다. ^[raw/articles/fastapi-core-wiki-examples.md]

## Readiness policy

Readiness는 활성/필수 서비스와 check callable을 기준으로 실행된다. 체크가 없으면 `ok`, 필수 서비스 실패면 503 `error`, 선택 서비스만 실패하면 200 `degraded`를 반환한다. DMS 배포 시 required-services 정책과 readiness 병렬 실행 여부는 서비스 특성에 맞게 명시해야 한다.

`v0.4.0` environment template은 services/required-services CSV를 모두 빈 값으로 둔 서비스 없는 앱을 최소 실행 기준으로 제시한다. 이 template을 사용할 때 기본 readiness는 external service를 요구하지 않으며, DMS가 Keycloak·storage·NATS 등을 필요로 하면 service selection, required policy, 그리고 해당 credential을 같은 배포 configuration에서 함께 명시해야 한다. ^[raw/articles/fastapi-core-env-example-v0.4.0.md]

이 정책의 환경변수와 두 설정 계층은 [[fastapi-core-configuration]]에 정리한다. [[fastapi-core]]가 `AppConfig`를 소비해 state와 middleware를 구성한 뒤 readiness metadata를 생성하므로, service selection과 required service selection은 함께 검토해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

NATS를 포함한 메시징은 app assembly에서 선택 가능한 service client이며, 연결 객체/route를 직접 제공하는 표면은 아니다. `enabled_services` metadata가 있어도 NATS 설정과 client 생성이 없으면 readiness check는 등록되지 않을 수 있다. 메시징의 readiness와 custom-lifespan 확장 경계는 [[fastapi-core-messaging-integration]]에서 다룬다. ^[raw/articles/fastapi-core-messaging-v0.2.0.md]

package 기본 client 외 DMS SDK aggregate check 같은 추가 자원은 `ManagedResource(name, factory, healthcheck, close, ...)`로 선언하고 `get_resource(name)` dependency로 주입할 수 있다. resource startup 실패는 이미 생성한 resource를 역순 rollback하며, readiness는 `register_readiness_check(...)`가 아닌 resource healthcheck로도 typed registry에 등록된다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

DMS SDK를 HTTP 서비스에 붙일 때는 [[dms-core]]의 생성·health·close 흐름을 custom lifespan/state 경계에 배치하는 방안을 검토한다. 그 lifecycle과 정합성 규칙은 [[dms-core-document-lifecycle]]에 정리한다.

DMS v0.4.0의 내부 `storage_key`는 HTTP 공개 계약이 아니므로 route 응답은 `public_metadata(...)` 또는 동일한 allowlist schema를 적용해야 한다. 목록 API를 cursor 방식으로 노출할 때는 SDK의 불투명 `next_cursor`와 상태 필터 결합을 보존하고, offset·cursor 계약을 한 endpoint에서 모호하게 섞지 않는다. 현재 프로젝트는 `dms 0.4.0`을 설치하고 `storage_key` 없는 response model을 사용하므로 이 경계는 runtime과 application adapter 양쪽에서 확인된다. ^[raw/articles/dms-core-wiki-api-reference-v0.4.0.md]

v0.4.0 예제가 권장하는 HTTP-facing 흐름은 `public_metadata()`, cursor의 `has_more`/`next_cursor`, 명시적 soft/hard 삭제다. 현재 project adapter는 allowlist response model로 `storage_key`를 제외하지만 목록은 offset 방식이고 삭제는 호환 `delete_document(...)`를 사용한다. 이는 오류가 아니라 지원되는 legacy surface이며, cursor 또는 명시 삭제 endpoint로 이동할 때 [[dms-core-usage-patterns]]의 계약을 유지한다. ^[raw/articles/dms-core-wiki-examples-v0.4.0.md]

## Open questions

- DMS에서 활성화해야 할 서비스와 필수 서비스의 정확한 목록은 무엇인가?
- DMS 고유 lifecycle 자원은 custom lifespan과 `app.state` 중 어떤 경계로 관리할 것인가?
- 문서에 없는 NATS 연결 상태 dependency가 필요한가?

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-api-reference.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-config-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-configuration.md`
- `raw/articles/fastapi-core-env-example-v0.4.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-examples.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.2.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.4.0.md`
- `raw/articles/dms-core-wiki-examples-v0.4.0.md`
