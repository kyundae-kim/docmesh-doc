---
title: fastapi-core
created: 2026-07-11
updated: 2026-08-02
type: entity
tags: [fastapi-core, fastapi, api, integration, architecture]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-main.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-wiki-configuration.md, raw/articles/fastapi-core-wiki-configuration-v0.5.0.md, raw/articles/fastapi-core-wiki-configuration-v0.6.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.4.0.md, raw/articles/fastapi-core-env-example-v0.5.0.md, raw/articles/fastapi-core-env-example-v0.6.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md, raw/articles/fastapi-core-wiki-examples.md, raw/articles/fastapi-core-wiki-examples-v0.5.0.md, raw/articles/fastapi-core-wiki-examples-v0.6.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md]
confidence: medium
---

# fastapi-core

`fastapi-core`는 DMS FastAPI 서비스가 사용하는 공통 애플리케이션 계층이다. 이 API 문서 스냅샷에서는 공개 루트 API로 `create_app`을 제공하며, 앱 조립, 공통 라우터, 설정 로딩, 인증과 외부 서비스 클라이언트 접근을 묶는다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Public surface

- Git tag `v0.3.0` API snapshot은 `create_app(config=None, settings=None, lifespan=None, include_auth_router=True, resources=())`를 기록하지만, 별도 GitHub Wiki snapshot도 기준 버전을 `0.3.0`으로 표시하면서 `create_app(config=None, *, runtime=None, lifespan=None, include_auth_router=True, resources=(), error_renderer=None)`를 공개 계약으로 기록한다. 후자는 테스트/host app의 사전 조립 `ServiceRuntime` 주입과 custom error renderer를 추가하고 `settings` 주입을 제거한다. 두 source body는 서로 다르므로, installed package 검증 전에는 어느 쪽도 현재 runtime 계약으로 단정하지 않는다. ^[raw/articles/fastapi-core-api-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md]
- Wiki snapshot의 package root는 `create_app`, `ManagedResource`, `ResourceKey`, `ReadinessCheckSpec`, `ErrorMapping`, `ErrorRenderer`, `register_readiness_check`, `register_error_mapper`를 권장 API로 열거한다. 앱 상태의 readiness 단일 통합 지점은 `app.state.readiness_registry`이며, `settings`, `service_clients` 및 legacy readiness flat state/alias는 공개 계약이 아니고 생성되지 않는다고 명시한다. ^[raw/articles/fastapi-core-wiki-api-reference.md]
- GitHub Wiki의 2026-07-19 `0.5.0` API reference는 동일한 root export와 config·root logger·service runtime·readiness/resource registry·OAuth2 scheme·error renderer state를 current implementation 계약으로 기록한다. `fastapi-core 0.5.0` 설치본은 이 root export와 `include_auth_router=False` 기본값을 포함한 `create_app` signature를 확인한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md]
- v0.6.0 API reference는 `DomainModule`/`ErrorMapperSpec`와 `create_app(..., routers=(), modules=(), error_mappers=(), auth_provider=...)`를 문서화했다. 현재 v0.7.0 설치본에서 module/resource/router/error renderer signature, `fastapi_core.testing` contract helpers와 app state를 확인했으며, 소비 adapter는 문서 router, DMS resource와 오류 mapper를 `documents` module로 묶고 module/OpenAPI contract test를 통과한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]
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

v0.5.0 Wiki Configuration reference는 AppConfig 정책과 DocMesh ServiceConfigs 접속 설정의 ownership을 분리하고 `.env.example` 자동 loading을 부정한다. 설치된 v0.4.0은 같은 AppConfig 계층과 비자동 dotenv 동작을 확인했지만, v0.5.0에 문서화된 startup failure/retry 정책은 아직 없다. 따라서 서비스/secret 명시 주입 원칙은 유지하되 새 startup 필드는 package upgrade와 contract test 뒤에만 채택한다. ^[raw/articles/fastapi-core-wiki-configuration-v0.5.0.md]

v0.5.0 Git tag의 `.env.example`도 서비스 없는 baseline, explicit configuration, redacted secret, individual PostgreSQL connection field 정책을 제공한다. 이는 배포 policy의 upstream evidence이지만, 현재 설치된 v0.4.0에 없는 startup retry fields와 version-misaligned `docmesh-py-core` settings를 포함하므로 그대로 실행 template으로 채택하지 않는다. ^[raw/articles/fastapi-core-env-example-v0.5.0.md]

v0.6.0 `.env.example`는 service-free active baseline과 complete-per-selected-service block을 유지하면서 CORS wildcard를 credentials false와 함께 제시하고 access-log keys를 추가한다. 설치된 v0.6.0 `AppConfig`가 access-log와 startup policy field를 제공하므로 이 template은 현재 package surface와 일치하지만, 실제 service credential과 enabled/required 집합은 [[fastapi-core-configuration]]의 배포 정책으로 별도 주입한다. ^[raw/articles/fastapi-core-env-example-v0.6.0.md]

## v0.7.0 공개 계약

v0.7.0 GitHub Wiki API reference는 package-root와 공개 submodule의 `__all__`를 호환성 경계로 삼고, `create_app`, `DomainModule`, `ErrorMapperSpec`, `ResourceBinding`, typed readiness, error renderer, streaming response, runtime helper, consumer contract test와 logging surface를 하나의 API → source → test → example → config 추적표로 연결한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.7.0의 `create_app(...)`은 `routers`, `modules`, `resources`, `error_mappers`, `error_renderer`, `auth_provider`, `transport_policy`, `error_mapping_table`을 명시적으로 받으며 `include_auth_router` 기본값은 `False`다. health router는 항상 포함되고 auth router는 opt-in이며, `app.state.settings`와 `app.state.service_clients` 같은 flat state는 공개 계약에서 제외된다. `DomainModule`과 `TransportPolicy`는 route validation/error/OpenAPI policy를 함께 조립하되 health/auth router에 자동 전파하지 않는다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

v0.7.0 Configuration/Examples와 환경 템플릿은 `.env` 자동 로딩이 아닌 process-environment 주입, 서비스 없는 active baseline, 선택 service별 완전한 설정 block, `AppConfig`와 `docmesh_config.ServiceConfigs`의 ownership 분리를 재확인한다. Milvus의 canonical key는 `MILVUS_ENDPOINT`이며, NATS는 typed service dependency일 뿐 publisher/subscriber API가 아니다. ^[raw/articles/fastapi-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md] ^[raw/articles/fastapi-core-env-example-v0.7.0.md]

## docmesh-config boundary

`docmesh-config` v0.1.0은 `CommonConfig`와 8개 서비스 설정, `ServiceConfigs`, runtime plan과 환경 진단을 제공하지만 `fastapi-core`의 `AppConfig`, CORS, router, lifespan 또는 readiness registry를 직접 조립한다고 문서화하지 않는다. 따라서 같은 `DOCMESH_*`, `POSTGRES_*`, `MINIO_*` 이름이 보이더라도 FastAPI application configuration과 generic service configuration을 동일한 loader로 취급하지 않는다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

현재 project manifest는 `docmesh-config` v0.1.0을 선언하고 host `dms_factory`가 이를 실제로 사용한다. `docmesh-config`를 `fastapi-core` runtime에 자동 연결하는 것은 아니며, application은 DMS client assembly를 별도 managed resource로 등록해 ownership을 명시한다. 세부 설정 ownership은 [[docmesh-config-configuration]]과 [[fastapi-core-configuration]]을 함께 따른다.

## Usage patterns

실제 시작·인증·readiness override·custom lifespan·선택 서비스 로딩의 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리한다. `v0.3.0` 예제는 `ManagedResource`, typed readiness, role/scope/permission dependency, correlation-ID problem-details 확장을 포함한다. 문서 내부 버전 표기와 Git tag의 관계는 배포 대상 패키지에서 검증해야 한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

v0.5.0 Wiki Examples는 service-free app, explicit settings cache control, typed dependency/resource, error renderer, readiness 및 router assembly를 current examples로 제공한다. 현재 DMS adapter는 v0.7.0 package에 존재하는 resource/error/module APIs를 사용하고, v0.7.0 module/OpenAPI testing surface를 consumer contract test로 검증한다. ^[raw/articles/fastapi-core-wiki-examples-v0.5.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

v0.6.0 reference는 `fastapi_core.testing`에 health/auth/module/OpenAPI contract assertion과 isolated environment helper를 열거한다. 현재 설치된 v0.7.0에서 호환 helper export를 확인했으며 adapter는 기존 health/auth assertion에 module/OpenAPI contract를 추가했다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.6.0 Examples는 module 조립, `routers=` 충돌 방지, framework-owned lifecycle 순서, `test_environment` 및 OpenAPI/module contract assertion을 실행 패턴으로 제시한다. 현재 v0.7.0 설치본에서 이 표면을 확인했고 DMS adapter는 module-first 조립과 resource lifecycle을 채택했다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

## Version note

Git tag `v0.1.6`와 `main`의 API 문서를 각각 수집했으며, 2026-07-12 수집 시 두 raw 본문의 SHA-256은 동일했다. 두 URL은 동일한 API 스냅샷을 제공하지만, `main`은 변할 수 있으므로 이 동등성은 수집 시점의 사실이다. `v0.3.0` Git-tag API/config/examples와 GitHub Wiki API/config/examples reference는 모두 `0.3.0` 기준을 표방하지만 body SHA-256과 `create_app`/state/public-export, overlay fallback, example coverage가 다르다. 현재 `pyproject.toml`은 `fastapi-core` Git ref `v0.7.0`을 선언하고 interpreter에서도 v0.7.0 import/signature probe를 수행했다. 이전 v0.6.0 probe 결과는 수집 시점의 runtime evidence로 보존하고, 현재 consumer contract는 v0.7.0 module/resource/error renderer surface와 테스트 결과를 기준으로 한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

요청된 v0.6.0 Configuration Wiki raw endpoint는 수집 시 API Reference v0.6.0과 body-only SHA-256 및 바이트가 동일했다. 두 immutable provenance capture는 모두 보존하지만, mutable Wiki page가 이후 달라질 수 있으므로 이 동등성은 수집 시점의 사실이며 별도 configuration claim으로 중복 반영하지 않는다. 현재 v0.7.0 runtime evidence는 위 module/resource contract와 consumer tests에 기록한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-configuration-v0.6.0.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-main.md`
- `raw/articles/fastapi-core-api-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-api-reference.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-config-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-configuration.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.7.0.md`
- `raw/articles/fastapi-core-env-example-v0.4.0.md`
- `raw/articles/fastapi-core-env-example-v0.5.0.md`
- `raw/articles/fastapi-core-env-example-v0.6.0.md`
- `raw/articles/fastapi-core-env-example-v0.7.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-examples.md`
- `raw/articles/fastapi-core-wiki-examples-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-examples-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-examples-v0.7.0.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
