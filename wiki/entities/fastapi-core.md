---
title: fastapi-core
created: 2026-07-11
updated: 2026-07-18
type: entity
tags: [fastapi-core, fastapi, api, integration, architecture]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-main.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-wiki-configuration.md, raw/articles/fastapi-core-env-example-v0.4.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md, raw/articles/fastapi-core-wiki-examples.md]
confidence: medium
---

# fastapi-core

`fastapi-core`는 DMS FastAPI 서비스가 사용하는 공통 애플리케이션 계층이다. 이 API 문서 스냅샷에서는 공개 루트 API로 `create_app`을 제공하며, 앱 조립, 공통 라우터, 설정 로딩, 인증과 외부 서비스 클라이언트 접근을 묶는다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Public surface

- Git tag `v0.3.0` API snapshot은 `create_app(config=None, settings=None, lifespan=None, include_auth_router=True, resources=())`를 기록하지만, 별도 GitHub Wiki snapshot도 기준 버전을 `0.3.0`으로 표시하면서 `create_app(config=None, *, runtime=None, lifespan=None, include_auth_router=True, resources=(), error_renderer=None)`를 공개 계약으로 기록한다. 후자는 테스트/host app의 사전 조립 `ServiceRuntime` 주입과 custom error renderer를 추가하고 `settings` 주입을 제거한다. 두 source body는 서로 다르므로, installed package 검증 전에는 어느 쪽도 현재 runtime 계약으로 단정하지 않는다. ^[raw/articles/fastapi-core-api-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md]
- Wiki snapshot의 package root는 `create_app`, `ManagedResource`, `ResourceKey`, `ReadinessCheckSpec`, `ErrorMapping`, `ErrorRenderer`, `register_readiness_check`, `register_error_mapper`를 권장 API로 열거한다. 앱 상태의 readiness 단일 통합 지점은 `app.state.readiness_registry`이며, `settings`, `service_clients` 및 legacy readiness flat state/alias는 공개 계약이 아니고 생성되지 않는다고 명시한다. ^[raw/articles/fastapi-core-wiki-api-reference.md]
- Wiki snapshot은 app state에 config, `service_runtime`, readiness/resource registry, 앱별 OAuth2 scheme, error renderer와 필요 시 auth provider를 둔다. service client와 설정은 runtime을 통해 dependency에서 해석한다. ^[raw/articles/fastapi-core-wiki-api-reference.md]
- 기본으로 health router를 포함하고, 선택적으로 auth router를 포함한다.
- `POST /token`, `GET /user`, `GET /health/liveness`, `GET /health/readiness`가 문서화된 기본 HTTP 표면이다.

## DMS deployment relevance

DMS 애플리케이션은 [[fastapi-core-app-assembly]]를 통해 lifecycle·CORS·logging·readiness를 일관되게 설정할 수 있다. 서비스별 실제 연결과 설정 계약은 [[docmesh-py-core]]에 위임되며, 필요한 구체 타입은 전용 dependency로 가져오고 일반 lookup에는 `get_service_client(...)`를 사용한다. DMS aggregate health나 SDK lifecycle처럼 package 기본 서비스 client 범위를 넘어서는 자원은 `ManagedResource`와 `get_resource(name)` 또는 custom lifespan으로 명시적으로 통합해야 한다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

## DMS core boundary

이 위키의 목표 아키텍처에서는 [[dms-core]]가 문서 도메인 SDK를, `fastapi-core`가 FastAPI application layer를 맡는다. 문서 SDK의 lifecycle·health·오류를 HTTP 경계에 연결하는 구체 adapter 계약은 [[dms-core-document-lifecycle]] 및 이후 통합 source에서 확정해야 한다.

## Configuration boundary

설정은 [[fastapi-core-configuration]]에서 정리한 `AppConfig`와 `ServiceConfigs`로 나뉜다. `v0.3.0` source들은 service alternatives, startup healthcheck, readiness timeout, enabled/required service 집합을 `AppConfig`에 두고 외부 서비스 설정은 Py Core loader/assembly로 위임한다. GitHub Wiki config snapshot은 `runtime` 주입이 서비스 조립만 우회하고 AppConfig 정책은 계속 적용된다고 설명한다. 개발 fallback의 존재는 nominally 같은 v0.3.0 source끼리도 상충하므로, 운영 배포는 앱 공개 경로·CORS·readiness 정책과 외부 서비스 secret을 명시적으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-configuration.md]

이 프로젝트가 선언한 `v0.4.0`의 environment template은 서비스 없는 앱을 기본 예시로 두고 빈 enabled/required CSV와 placeholder/redacted secret을 사용한다. 이를 runtime 사실로 단정할 수는 없지만, 배포 configuration에서는 keycloak이나 다른 external service를 implicit default로 기대하지 않고 필요 service와 secret을 명시해야 한다는 upstream candidate다. ^[raw/articles/fastapi-core-env-example-v0.4.0.md]

## Usage patterns

실제 시작·인증·readiness override·custom lifespan·선택 서비스 로딩의 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리한다. `v0.3.0` 예제는 `ManagedResource`, typed readiness, role/scope/permission dependency, correlation-ID problem-details 확장을 포함한다. 문서 내부 버전 표기와 Git tag의 관계는 배포 대상 패키지에서 검증해야 한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

## Version note

Git tag `v0.1.6`와 `main`의 API 문서를 각각 수집했으며, 2026-07-12 수집 시 두 raw 본문의 SHA-256은 동일했다. 두 URL은 동일한 API 스냅샷을 제공하지만, `main`은 변할 수 있으므로 이 동등성은 수집 시점의 사실이다. `v0.3.0` Git-tag API/config/examples와 GitHub Wiki API/config/examples reference는 모두 `0.3.0` 기준을 표방하지만 body SHA-256과 `create_app`/state/public-export, overlay fallback, example coverage가 다르다. 소비 프로젝트가 선언한 `v0.4.0` environment template은 서비스 없는 default와 full service/security configuration catalog를 제공하지만, runtime import가 불가능했으므로 v0.4.0 template도 실행 검증 전 upstream reference로 유지한다. ^[raw/articles/fastapi-core-api-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md] ^[raw/articles/fastapi-core-config-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-configuration.md] ^[raw/articles/fastapi-core-examples-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-examples.md] ^[raw/articles/fastapi-core-env-example-v0.4.0.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-main.md`
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
