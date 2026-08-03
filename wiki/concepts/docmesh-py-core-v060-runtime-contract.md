---
title: docmesh-py-core v0.6.0 runtime contract
created: 2026-08-02
updated: 2026-08-02
type: concept
tags: [architecture, configuration, integration, observability, testing, migration, dependency]
sources: [raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-py-core v0.6.0 runtime contract

`docmesh-py-core` v0.6.0은 설정 모델과 runtime client/lifecycle을 두 package root로 분리한다. `docmesh_config`가 `RuntimePlan`, `Service`, `HealthcheckPolicy`와 서비스별 `*Config`를 canonical하게 제공하고, `docmesh_py_core`가 factory·container·healthcheck·lifecycle·Keycloak API·오류/관측성 helper를 제공한다. `docmesh_py_core` root는 `docmesh_config` 심볼을 재노출하지 않으며, `docmesh_py_core.config`, `.settings`, `.runtime_plan`, `.factories`는 호환 facade다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

## Source-set and runtime status

요청된 API Reference, Configuration, Examples와 v0.6.0 `.env.example`은 모두 v0.6.0을 self-report한다. API/Configuration/Examples는 각각 `docmesh_config` → `docmesh_py_core` import와 `RuntimePlan` 기반 사용 흐름을 연결하며, `.env.example`은 process environment 주입과 placeholder 교체를 요구한다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md] ^[raw/articles/docmesh-py-core-env-example-v0.6.0.md]

현재 `pyproject.toml`은 `docmesh-py-core` v0.6.0과 `docmesh-config` v0.1.0을 선언하고, interpreter에서도 두 package의 import와 public factory signature를 확인했다. 아래 source-derived 계약과 달리, 실제 DMS consumer bridge는 `docmesh_doc/dms_factory.py`와 `test_dms_factory.py`의 runtime evidence로 별도 기록한다.

## Bootstrap and lifecycle

일반 비동기 애플리케이션은 `service_lifespan(plan=plan)`을 우선 사용한다. 이 context manager는 현재 event loop를 유지하고 `ServiceRuntime`을 열고 닫으며, 정상 종료와 예외 종료 모두에서 async cleanup을 수행한다. 낮은 수준의 `assemble_service_runtime(plan=...)`은 설정 진단·client 생성·startup policy 적용 뒤 runtime을 반환한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

`assemble_services(plan=...)`는 동기 서비스 전용이며 NATS 또는 timeout이 지정된 동기 startup healthcheck를 거부한다. `create_empty_service_runtime()`은 설정 loader·factory·network를 호출하지 않는 별도 empty path다. `production_runtime_plan(...)`과 `authenticated_runtime_plan(...)`은 required 서비스와 기본 healthcheck policy를 명시적으로 만든다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

## Container and lookup contract

`ServiceBundle`은 sync context manager와 문자열 key를 사용하고, `ServiceRuntime`은 async context manager와 `docmesh_config.Service` key를 사용한다. 두 container는 configs, clients, selected/required services, checks, diagnosis와 startup 결과를 공개한다. 일반 소비자는 직접 container를 만들기보다 assembly API를 사용해야 descriptor·rollback 불변조건을 얻는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

`get()`은 미선택/미초기화를 `None`으로 돌려주고, `require()`는 `ServiceNotSelectedError`와 `ServiceNotInitializedError`를 구분한다. `get_client()`는 호환 조회 API이고, `require_client(service, expected_type)`은 concrete client type을 검사해 `ServiceClientTypeError`를 낸다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Health and failure semantics

`check_all_services`와 `async_check_all_services`는 입력 순서를 보존하고 required/optional 실패를 집계한다. optional 실패는 결과에 남지만 required 실패는 전체 `HealthCheckResult`를 가진 `HealthCheckError`가 된다. 서비스별 timeout은 실패 status로 바뀌지만 overall timeout은 partial result 없이 `asyncio.TimeoutError`로 전파될 수 있다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

`ServiceRuntime.check_with_policy(policy)`는 policy의 `on_startup` 값과 무관하게 즉시 검사하고 runtime을 닫지 않는다. FastAPI 예제는 필수/optional/overall timeout의 모든 실패 경로를 readiness endpoint에서 503으로 매핑한다. 이는 일반 FastAPI 소비 패턴이며 `fastapi-core`의 `create_app` 또는 readiness registry 계약 자체를 증명하지 않는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Factories, ownership, and cleanup

Factory는 이미 검증된 `docmesh_config` config object를 받고 임의 constructor kwargs를 공개하지 않는다. `ServiceClientWrapper`는 concrete client, health callback, close function과 runtime defaults를 감싸며, `close_service_clients`/`async_close_service_clients`는 모든 close를 시도한 뒤 `ServiceCloseError.failures`에 전체 실패를 모은다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

`create_nats_client()`는 연결하지 않는 `NatsConnectionBuilder`를 반환한다. `check()`/`ping()`은 임시 연결을 열고 정리하며, `connect()`가 반환한 persistent connection은 호출자가 drain/close한다. `connect_kwargs`에는 credential이 포함될 수 있으므로 로그에 남기지 않는다. MinIO/Milvus/Ollama의 timeout·retry·model·bucket 값 일부는 wrapper의 runtime defaults로 보존되며 SDK constructor에 자동 연결되지 않는 항목이 있다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Configuration and environment

모든 `*Config()`는 process environment만 읽고 constructor kwargs·mapping·test 전용 env file 주입을 허용하지 않는다. `.env.example`은 자동 로드되지 않으며, 선택한 RuntimePlan과 같은 서비스 block만 uncomment한 뒤 shell/container/orchestrator가 process environment로 주입해야 한다. production에서는 placeholder와 insecure transport flag를 거부한다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/docmesh-py-core-env-example-v0.6.0.md]

이 경계는 [[docmesh-config-configuration]]의 환경변수 소유권과 [[docmesh-config-runtime-plan]]의 package-neutral plan metadata를 직접 소비하는 v0.6.0 package bridge다. `docmesh-py-core`가 DMS metadata backend/object-store factory를 자동 제공한다는 뜻은 아니지만, 이 consumer는 선택된 `PostgresConfig`/`SqliteConfig`/`MinioConfig`를 canonical client factory에 전달해 DMS client factory에 주입한다. 그 storage contract는 [[dms-core-configuration]]에서 별도로 관리한다.

## Observability and safe error projection

`serialize_error()`는 알려진 오류의 type/message/service/reason/remediation과 JSON-safe details를 보존하고 민감값을 마스킹한다. `configure_logging`, `build_service_log_event`, `LifecycleEvent`/observer와 `retry_call`은 logging level·structured lifecycle·선택적 재시도 정책을 제공한다. generic exception에 secret을 넣지 않는 책임은 소비자에게 남는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Consumer boundaries

v0.6.0 Examples는 FastAPI를 별도 dependency로 설치하고 `app.state.services`에 `ServiceRuntime`을 둔 뒤 readiness 결과를 200/503으로 변환하는 framework-level 패턴을 보여 준다. 이 예제는 `docmesh_config`와 `docmesh_py_core`의 package bridge를 입증하지만 [[fastapi-core-app-assembly]]의 `create_app` module/resource/error-mapper contract이나 [[dms-core]]의 document storage assembly까지 자동으로 연결한다고 말하지 않는다.

## Related pages

- [[docmesh-py-core]] — package entity, public scope와 version reconciliation.
- [[docmesh-py-core-usage-patterns]] — v0.6 소비 예제와 lifecycle 선택.
- [[docmesh-config]] — settings/plan package entity.
- [[docmesh-config-runtime-plan]] — plan과 diagnosis metadata.
- [[fastapi-core-app-assembly]] — FastAPI hosting lifecycle 경계.
- [[dms-core-configuration]] — DMS storage configuration 경계.

## Sources

- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
