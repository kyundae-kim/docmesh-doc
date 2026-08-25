---
title: fastapi-core application assembly
created: 2026-07-11
updated: 2026-08-24
type: concept
tags: [fastapi, fastapi-core, architecture, deployment, configuration, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference.md, raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-wiki-configuration.md, raw/articles/fastapi-core-wiki-configuration-v0.5.0.md, raw/articles/fastapi-core-wiki-configuration-v0.6.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.4.0.md, raw/articles/fastapi-core-env-example-v0.5.0.md, raw/articles/fastapi-core-env-example-v0.6.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md, raw/articles/fastapi-core-wiki-examples.md, raw/articles/fastapi-core-wiki-examples-v0.5.0.md, raw/articles/fastapi-core-wiki-examples-v0.6.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.2.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-wiki-api-reference-v0.9.0.md, raw/articles/dms-core-wiki-examples-v0.9.0.md, raw/articles/dms-core-wiki-api-reference-v0.10.0.md, raw/articles/dms-core-wiki-examples-v0.10.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# fastapi-core application assembly

`fastapi-core`의 `create_app(...)`은 DMS FastAPI 서비스의 공통 조립 지점이다. tagged API snapshot은 config와 settings의 생략 시 각각 앱/선택 서비스 설정을 로딩한다고 설명하지만, GitHub Wiki snapshot은 settings 대신 사전 조립된 `ServiceRuntime` 주입만 지원한다고 설명한다. 두 source의 body가 다르므로 소비 애플리케이션은 설치된 `fastapi-core`의 signature와 테스트로 조립 방식을 확인해야 한다. ^[raw/articles/fastapi-core-api-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-api-reference.md]

## Lifecycle and state

조립 단계에서 구성된 config, settings, service clients, readiness metadata는 `app.state`에 보관된다. `v0.3.0`에서는 `service_runtime`, typed `readiness_registry`, `resource_registry`, 앱 전용 OAuth2 scheme도 명시적 상태 계약이며, legacy readiness alias는 없다. custom lifespan은 service runtime과 managed resource 준비 뒤에 실행되고, shutdown 예외가 있어도 resource를 역순 정리한 뒤 runtime close가 `finally`에서 수행된다. 이 구조는 [[fastapi-core]]를 서비스 HTTP 계층으로 두고 [[docmesh-py-core]]의 외부 의존성 설정/클라이언트를 재사용하는 경계를 만든다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

GitHub Wiki snapshot은 `app.state.settings`와 `app.state.service_clients`도 제거된 비공개 state라고 명시하며 config, root logger, service runtime, readiness/resource registry, OAuth2 scheme, error renderer, 필요 시 auth provider만 계약으로 열거한다. service 설정과 concrete client는 runtime을 반환하는 dependency로 접근한다. 이는 tagged snapshot의 flat state 설명과 상충하므로, DMS adapter는 runtime/dependency API를 우선하고 flat state에 의존하지 않아야 한다. ^[raw/articles/fastapi-core-wiki-api-reference.md]

v0.5.0 Wiki API reference도 같은 state 모델과 `create_app(config, runtime, lifespan, include_auth_router, resources, error_renderer)` 조립 경계를 기록하며 auth router opt-in의 기본값은 `False`다. 설치된 v0.5.0은 이 public signature/state를 제공한다. `docmesh_doc.create_application`은 자신의 기본값 `True`를 `create_app`에 명시 전달하므로 auth route 포함 정책을 adapter가 결정한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.5.0.md]

v0.6.0 API reference는 `routers`, `modules`, `error_mappers`, `auth_provider`를 `create_app`의 명시적 조립 입력으로 추가했고, 현재 v0.7.0 설치본에서도 같은 module-first surface를 확인했다. DMS adapter는 `documents` module에 router, required DMS resource와 DMS/validation error mapper를 함께 등록한다. module contract와 auth-provider 주입 경계도 테스트한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.6.0 Examples는 framework가 runtime/resource를 사용자 lifespan보다 먼저 시작하고 종료 시 사용자 lifespan → resource → runtime 순으로 정리한다고 보인다. 현재 adapter는 package-owned module resource lifecycle로 이 순서를 유지하며 정상 close, startup factory 실패와 shutdown close 실패 테스트를 통과한다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md]

v0.7.0 API는 `create_app`을 explicit `routers`/`modules`/`resources`/error-mapper 입력과 `DomainModule`/`TransportPolicy` policy로 확장하고, framework가 user lifespan을 runtime/resource cleanup으로 감싸는 state/lifecycle contract를 명시한다. `ResourceBinding`은 typed dependency·health·reverse shutdown·startup rollback을 하나의 registry에 묶고, `ManagedStreamingResponse`는 producer exception/disconnect/cancellation에서도 resource close를 정확히 한 번 수행한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.7.0 Examples는 module route에만 validation/security/error/OpenAPI policy를 적용하고, `include_auth_router=False` service-free app을 기본 smoke test로 삼으며, `assert_application_contract`로 path/method/status/security/schema와 synthetic 422 제거를 의미 기반 검증한다. 현재 source의 `DomainModule` 조립 모양과 설치 runtime이 일치하며, `test_application.py`가 auth opt-in/out·module·OpenAPI·startup/shutdown lifecycle을 검증한다. ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md] ^[raw/articles/fastapi-core-env-example-v0.7.0.md]

소비 애플리케이션은 route reverse lookup으로 업로드 `Location`을 생성해 `AppConfig.root_path`를 보존하고, document module router에 제품 오류 envelope의 OpenAPI response를 선언한다. `assert_openapi_contract`는 document path·method·OAuth2 scheme·operation-ID 및 schema reference를 검증하며, 별도 assertion은 runtime의 400 validation 계약과 생성 문서가 일치하고 기본 422가 남지 않음을 확인한다. 세부 검토는 [[fastapi-core-application-optimization]]에 기록한다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md]

`v0.3.0` config 문서는 `create_app()`이 `load_app_config()` 뒤에 application logging을 초기화하고, lifespan startup에서 selected service runtime을 조립한다고 설명한다. `token_url`은 앱마다 별도의 `OAuth2PasswordBearer`와 OpenAPI password flow에 저장되므로, 한 프로세스에서 서로 다른 token URL로 여러 앱을 조립해도 기존 앱의 OpenAPI 계약을 바꾸지 않는다. ^[raw/articles/fastapi-core-config-v0.3.0.md]

GitHub Wiki Configuration snapshot은 runtime 조립 경로를 `AppConfig` 로딩 → runtime plan → non-mutating environment overlay → `assemble_runtime()` → `app.state.service_runtime`/readiness 등록 → shutdown close로 설명한다. `create_app(runtime=...)`은 이 서비스 조립만 우회하고 CORS, logging, readiness AppConfig 정책은 보존한다. 하지만 overlay가 개발 fallback을 추가하는지 여부는 tagged v0.3.0 config snapshot과 상충하므로, DMS 배포는 explicit configuration을 제공해야 한다. ^[raw/articles/fastapi-core-wiki-configuration.md]

v0.5.0 configuration reference는 동일한 assembly boundary에 startup failure mode와 retry configuration을 추가해 문서화한다. 설치된 v0.5.0 `AppConfig`에는 그 세 필드가 있고 프로젝트는 `docmesh-py-core 0.4.0`을 선언한다. 따라서 startup policy는 설정 가능한 현재 surface이지만, DMS deployment에 값을 채택할 때는 version-aligned DocMesh settings와 함께 테스트해야 한다. ^[raw/articles/fastapi-core-wiki-configuration-v0.5.0.md]

인증 endpoint가 불필요한 내부 서비스는 auth router를 제외할 수 있고, 보호 router는 `create_app()` 결과에 명시적으로 포함한다. `v0.3.0` 예제는 domain SDK를 `ManagedResource`로 등록해 factory·healthcheck·lifecycle cleanup·route dependency를 함께 조립하는 패턴을 보여 준다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

GitHub Wiki Examples는 `create_app()`이 runtime/managed resource를 사용자 lifespan 바깥에서 소유하므로 사용자 shutdown 오류에도 공통 정리를 시도한다고 예시로 확인한다. 일반 DMS app은 `create_app(resources=...)`에 맡기고, 직접 `build_lifespan` 또는 router-only assembly를 선택하면 readiness registry, runtime state, middleware, error handler를 직접 구성해야 한다. ^[raw/articles/fastapi-core-wiki-examples.md]

v0.5.0 Wiki Examples는 `ResourceKey` 기반 typed resource와 `get_resource(name)`을 같은 registry 경계에서 사용하는 예를 제공하며, framework-owned lifecycle이 startup·healthcheck·역순 close를 담당한다고 설명한다. 현재 adapter의 `ManagedResource(name="dms", ...)`, error mapper, explicit auth-router forwarding은 설치된 v0.5.0 signatures로 확인된다. 설치본은 health/auth contract helper를 제공하지만 v0.6.0의 module/OpenAPI test helper는 아직 없으므로, 후자는 upgrade 전 보류한다. ^[raw/articles/fastapi-core-wiki-examples-v0.5.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

## docmesh-config plan boundary

`docmesh-config`의 `RuntimePlan`과 `HealthcheckPolicy`는 FastAPI가 소비할 수 있는 선택/정책 metadata를 표현하지만 `create_app(...)`의 `AppConfig`, managed resource, readiness registry 또는 framework-owned lifecycle을 대체하지 않는다. 현재 source set만으로 이 plan이 DMS resource나 FastAPI runtime에 자동 주입된다고 단정하지 않고, 소비 adapter의 explicit bridge와 version-aligned tests가 필요하다. [[docmesh-config-runtime-plan]]과 [[fastapi-core-configuration]]을 함께 참조한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## v0.6 docmesh-py-core hosting boundary

v0.6.0 source set은 `docmesh_config.RuntimePlan` → `docmesh_py_core.service_lifespan` package bridge와 generic FastAPI `app.state.services` consumer pattern을 확인한다. 이는 `fastapi-core` `create_app`의 module/resource/error-mapper contract나 DMS resource 자동 주입을 대체하지 않는다. 이 wiki는 package bridge를 [[docmesh-py-core-v060-runtime-contract]]에, FastAPI hosting contract를 이 페이지에 각각 보존한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Readiness policy

Readiness는 활성/필수 서비스와 check callable을 기준으로 실행된다. 체크가 없으면 `ok`, 필수 서비스 실패면 503 `error`, 선택 서비스만 실패하면 200 `degraded`를 반환한다. DMS 배포 시 required-services 정책과 readiness 병렬 실행 여부는 서비스 특성에 맞게 명시해야 한다.

`v0.4.0` environment template은 services/required-services CSV를 모두 빈 값으로 둔 서비스 없는 앱을 최소 실행 기준으로 제시한다. 이 template을 사용할 때 기본 readiness는 external service를 요구하지 않으며, DMS가 Keycloak·storage·NATS 등을 필요로 하면 service selection, required policy, 그리고 해당 credential을 같은 배포 configuration에서 함께 명시해야 한다. ^[raw/articles/fastapi-core-env-example-v0.4.0.md]

v0.5.0 environment template도 동일한 empty-service readiness baseline을 유지하고 required services가 enabled services의 부분집합이어야 함을 명시한다. DMS adapter는 이 baseline 위에 required `dms` managed resource check를 추가한다. 설치된 v0.5.0 `AppConfig`에는 template의 startup retry keys가 있으나, 실제 deployment 값은 startup failure policy를 포함한 integration test 뒤에 정한다. ^[raw/articles/fastapi-core-env-example-v0.5.0.md]

v0.6.0 environment template은 empty service/readiness CSV를 active service-free baseline으로 두고 timeout 값은 commented opt-in으로 둔다. DMS adapter는 storage SDK aggregate health를 required managed-resource check로 명시하므로, template의 empty service-client baseline을 DMS readiness 보장으로 확대 해석하지 않는다. ^[raw/articles/fastapi-core-env-example-v0.6.0.md]

이 정책의 환경변수와 두 설정 계층은 [[fastapi-core-configuration]]에 정리한다. [[fastapi-core]]가 `AppConfig`를 소비해 state와 middleware를 구성한 뒤 readiness metadata를 생성하므로, service selection과 required service selection은 함께 검토해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

NATS를 포함한 메시징은 app assembly에서 선택 가능한 service client이며, 연결 객체/route를 직접 제공하는 표면은 아니다. `enabled_services` metadata가 있어도 NATS 설정과 client 생성이 없으면 readiness check는 등록되지 않을 수 있다. 메시징의 readiness와 custom-lifespan 확장 경계는 [[fastapi-core-messaging-integration]]에서 다룬다. ^[raw/articles/fastapi-core-messaging-v0.2.0.md]

package 기본 client 외 DMS SDK aggregate check 같은 추가 자원은 `ManagedResource(name, factory, healthcheck, close, ...)`로 선언하고 `get_resource(name)` dependency로 주입할 수 있다. resource startup 실패는 이미 생성한 resource를 역순 rollback하며, readiness는 `register_readiness_check(...)`가 아닌 resource healthcheck로도 typed registry에 등록된다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

DMS SDK를 HTTP 서비스에 붙일 때는 [[dms-core]]의 host-owned 생성 경계와 per-operation stream 정리 규칙을 resource/lifespan 및 response 경계에 배치한다. DMS v0.10.0 facade에는 global health나 close가 없으므로 readiness와 injected engine/client/component shutdown은 FastAPI host가 소유한다. Native async assembly를 선택하면 `AsyncDocumentManagementSDKFactory.create_async()`/`ready()`도 managed-resource startup 안에서 완료해야 한다. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

DMS v0.7.0의 `recommended_http_error(...)`는 historical claim이다. v0.10.0은 HTTP error helper를 공개하지 않으므로 FastAPI code는 stable DMS fields (`code`, `category`, `retryable`, optional `document_id`)를 제품 envelope/status로 투영한다. 현재 renderer의 payload-size, retryable idempotency, deleted-document hiding 정책은 DMS SDK가 아니라 host policy로 남는다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

v0.10.0 sync factory는 SDK assembly 중 MinIO bucket discovery/creation을 수행할 수 있다. 현재 소비 adapter signature는 설치된 factory와 호환되지만, 외부 MinIO 없이 실행한 ordinary test는 이 startup network boundary에서 1건 실패했다. FastAPI resource tests는 object-store client를 격리하고, integration tests는 실제 bucket 준비·startup failure·host cleanup을 검증해야 한다. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md]

HTTP 인증 주체는 `AccessContext.user_id`/`DmsOperationContext.user_id`로 명시적으로 변환한다. v0.10.0 cursor, object namespace, idempotency operation, read/delete/recovery/reset은 user scope를 공유하므로 다른 사용자 cursor나 document ID가 adapter 경계를 통과하지 않게 한다. Public response에는 `user_id`를 허용할 수 있지만 `storage_key`는 계속 internal/recovery 경계에만 둔다. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

## Open questions

- DMS에서 활성화해야 할 서비스와 필수 서비스의 정확한 목록은 무엇인가?
- DMS 고유 lifecycle 자원은 custom lifespan과 `app.state` 중 어떤 경계로 관리할 것인가?
- 문서에 없는 NATS 연결 상태 dependency가 필요한가?

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
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
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.2.0.md`
- `raw/articles/dms-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.10.0.md`
- `raw/articles/dms-core-wiki-examples-v0.10.0.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
