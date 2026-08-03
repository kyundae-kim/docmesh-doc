---
title: fastapi-core usage patterns
created: 2026-07-11
updated: 2026-08-02
type: concept
tags: [fastapi, fastapi-core, api, deployment, testing, integration]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md, raw/articles/fastapi-core-wiki-examples.md, raw/articles/fastapi-core-wiki-examples-v0.5.0.md, raw/articles/fastapi-core-wiki-examples-v0.6.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md]
confidence: medium
---

# fastapi-core usage patterns

`fastapi-core`의 예제는 DMS 서비스를 위한 네 가지 사용 패턴을 제시한다: 최소 app factory 사용, 인증·권한 dependency 주입, 설정 기반 서비스 선택 및 readiness 정책, custom lifespan을 통한 외부 자원 수명주기 관리. 문서는 구현과 테스트에서 확인된 패턴만 제시한다고 명시한다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Recommended DMS starting point

기본 서비스는 `create_app()`으로 시작하고, 인증 endpoint가 필요 없는 내부 서비스는 `include_auth_router=False`를 사용한다. 보호된 endpoint에는 `get_current_user`나 `require_permissions(...)`를 붙인다. 이 공개 표면과 route 계약은 [[fastapi-core]]에, 앱 상태와 lifecycle의 조립 경계는 [[fastapi-core-app-assembly]]에 정리되어 있다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

`v0.2.0` 예제는 보호 route를 선언한 뒤 `app = create_app()`과 `app.include_router(router)`까지 함께 보여 준다. token endpoint 예제는 Keycloak 도달성, Keycloak 환경변수, 유효한 사용자 credential이 실제 성공의 전제임을 명시한다. ^[raw/articles/fastapi-core-examples-v0.2.0.md]

`v0.3.0` 예제는 `require_roles`, `require_scopes`, `require_permissions`의 분리와 scope의 OpenAPI security 반영을 명시한다. typed `register_readiness_check(...)`는 required·timeout·error redaction을 선언적으로 추가하며, `ManagedResource`는 domain SDK factory/healthcheck/close를 lifecycle, readiness, `get_resource(name)` dependency에 함께 연결한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

GitHub Wiki API reference는 `ResourceKey(name).dependency`와 `get_resource(name)`가 같은 registry에서 managed resource를 해석한다고 명시하고, custom error renderer와 prebuilt `runtime` 주입을 포함한 `create_app` signature를 기록한다. 다만 같은 `0.3.0` 기준을 표기한 tagged API snapshot은 `settings` 주입을 기록하므로, 프로젝트 코드는 runtime 확인 전 둘 중 하나의 injection path에 고정하지 않는다. ^[raw/articles/fastapi-core-wiki-api-reference.md]

v0.5.0 API reference는 일반 app에 package root/dependency API를 우선하고 registry/runtime 직접 조립은 고급 API로 한정한다. 설치된 v0.5.0은 auth router 기본값 `False`를 포함한 같은 root export, runtime injection, resource/error extension과 state를 제공한다. `create_application(..., include_auth_router=...)`처럼 route 정책을 명시적으로 전달하는 현행 패턴을 유지한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md]

v0.6.0 reference는 module 단위 조립과 `fastapi_core.testing`의 health/auth/module/OpenAPI assertion을 권장 공개 surface에 포함한다. 설치된 v0.6.0에서 확장 signature와 helper export를 확인했으며 현 adapter는 DMS resource/router/error mapper를 `documents` module로 묶고 health·auth·module contract를 검증한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

v0.6.0 Examples는 `DomainModule`에 router·readiness·error mapper를 묶고, `create_app(routers=...)`에 기본 health/auth router를 중복 전달하지 않는 패턴을 보인다. 현재 adapter는 module의 resource lifecycle과 mapper 설치를 package helper로 검증하고 기존 startup/close 실패 테스트도 유지한다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md]

v0.7.0 Examples는 서비스 없는 최소 app, auth provider seam, `ResourceBinding`/`DomainModule`, health result adapter, module transport policy, error renderer, sync/async invocation, streaming close exactly once, runtime/client dependency, consumer contract test와 구조화 logging을 `EX-*` ID로 추적한다. `TransportPolicy(validation_status=400, include_synthetic_422=False)`는 module route의 runtime validation과 OpenAPI를 함께 바꾸며, `test_environment`는 환경변수와 settings cache 격리에 사용된다. ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.7.0 예제 문서의 마지막 AST 검증 명령은 `wiki/raw/articles/fastapi-core-examples-guide-v0.7.0.md`를 읽도록 되어 있지만, 이번 immutable capture의 실제 파일명은 `raw/articles/fastapi-core-wiki-examples-v0.7.0.md`다. 문서 경로 discrepancy는 보존하되, 현재 package가 설치되어 있으므로 consumer의 실제 app/module/resource contract test를 별도로 실행했다. ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

현재 adapter는 `assert_openapi_contract`까지 contract gate에 포함하고, root-path-aware route reverse lookup과 제품 오류 response model을 사용한다. 조건부 async 권한 검사를 수행하는 delete route는 동기 SDK I/O를 thread pool로 넘겨 event loop를 보호한다. 이로써 reverse proxy 배포의 생성 resource URL, runtime/OpenAPI validation status와 동기 SDK 실행 경계가 일치한다. 적용 범위와 남은 성능 후보는 [[fastapi-core-application-optimization]]에서 추적한다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md]

GitHub Wiki Examples snapshot은 서비스 없는 최소 app에 `AppConfig(enabled_services=[], required_services=[])`, `include_auth_router=False`, `get_config` dependency를 사용하고, runtime/settings/client dependency는 lifespan 안에서만 접근한다는 실행 패턴을 제시한다. managed resource에는 `ResourceKey[T].dependency`를, domain error에는 `ErrorMapping`/`ErrorRenderer`를 사용하며, router만 직접 include하는 방식은 runtime state·middleware·error handler가 필요 없을 때의 최소 조립으로 한정한다. ^[raw/articles/fastapi-core-wiki-examples.md]

v0.5.0 Wiki Examples는 같은 서비스 없는 baseline, cache-clear가 필요한 environment loader, typed `ResourceKey`/`ManagedResource`, custom error renderer, readiness와 router-only assembly 경계를 current implementation 예제로 정리한다. 현재 v0.7.0은 `create_app`, `ManagedResource`, `ResourceKey`, error/readiness registration과 health/auth/module testing helpers를 제공하므로 DMS adapter의 managed resource·error mapper·module 패턴과 맞는다. ^[raw/articles/fastapi-core-wiki-examples-v0.5.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

## Deployable composition

서비스별로 `AppConfig`를 직접 만들거나 환경변수로 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`를 지정한다. 선택 서비스는 degraded를 허용할 수 있고, 필수 서비스 실패는 503을 반환한다. `sqlite`만 선택해 settings와 readiness 대상을 제한하는 예제도 있으며, 이 설정 정책과 운영 guardrail은 [[fastapi-core-configuration]]에서 관리한다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

PostgreSQL을 선택 서비스로 둘 때 예제는 `POSTGRES_DSN` 단독 또는 host·port·database·user·password 등의 개별 접속 설정 중 하나를 사용하고, DSN과 개별 접속 값을 함께 설정할 필요가 없다고 안내한다. credential과 DSN은 secret으로 주입하고 저장소에 커밋하지 않아야 한다. ^[raw/articles/fastapi-core-examples-v0.2.0.md]

`v0.3.0` AppConfig 예제는 `service_alternatives`, startup/readiness timeout, startup healthcheck, enabled/required 서비스 집합을 한 구성에서 선언한다. 예를 들어 `postgres`/`sqlite` 대안을 둘 수 있으며, required가 아닌 NATS 장애는 degraded 후보가 된다. 이 배포 정책은 [[fastapi-core-configuration]]의 실제 loader 규칙과 함께 적용해야 한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

## Lifecycle and dependency choices

NATS 같은 외부 자원은 custom lifespan에서 초기화·정리하고, 구체 타입이 필요한 route에는 전용 dependency를 우선 사용한다. 공통 설정과 client-wrapper의 업스트림 계약은 [[docmesh-py-core]]에 연결된다. 기본 제공하지 않는 connection-state dependency나 publisher/subscriber helper는 [[fastapi-core-messaging-integration]]의 확장 경계를 따라 서비스 레이어에 둔다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

domain SDK 같은 추가 자원은 `ManagedResource`로 등록하면 선언 순서 생성·역순 cleanup, startup rollback, healthcheck의 typed readiness 등록을 얻는다. custom lifespan은 resource startup 뒤에 진입하고 shutdown 뒤 resource cleanup이 이어지며, runtime close는 shutdown 예외에도 `finally`에서 수행된다. DMS domain resource의 적합한 factory/healthcheck는 [[dms-core-document-lifecycle]] 및 [[fastapi-core-app-assembly]]과 맞춰야 한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

DMS v0.7.0은 FastAPI host가 환경·secret을 해석해 Engine/MinIO client 또는 component를 만든 뒤 SDK에 주입하는 흐름을 명시한다. 현재 consumer는 `docmesh-config` → `docmesh-py-core` → `dms.create_sdk_from_clients(...)`를 사용하고, 결과 SDK를 FastAPI `ManagedResource`/lifespan에 연결한다. `create_sdk_from_environment()`나 DMS가 제공하는 broker/HTTP server를 전제로 하지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

## Version note

Git tag `v0.1.6`, `v0.2.0`, `v0.3.0`의 examples는 모두 문서 내부에서 `2026-07-03` 구현 반영본으로 표기한다. GitHub Wiki Examples도 `0.3.0` 기준을 표방하지만 body hash가 다르고, `ResourceKey`·error renderer·runtime-centric dependency/lifecycle 예제를 포함한다. Git ref나 문서 내부 버전만으로 설치 패키지 API를 확정할 수 없으므로 예제 채택 전 대상 패키지와 테스트 스위트를 확인해야 한다. 현재 `pyproject.toml`과 interpreter는 `fastapi-core` v0.7.0을 사용하고, app/module/resource smoke와 consumer contract test를 실행했다. 이전 v0.6.0 결과는 수집 시점의 evidence로 보존한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-examples.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-wiki-api-reference.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.7.0.md`
- `raw/articles/fastapi-core-env-example-v0.7.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-examples.md`
- `raw/articles/fastapi-core-wiki-examples-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-examples-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-examples-v0.7.0.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
