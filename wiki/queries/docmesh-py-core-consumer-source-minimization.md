---
title: docmesh-py-core consumer source minimization
created: 2026-08-04
updated: 2026-08-04
type: query
tags: [integration, architecture, testing, performance, dependency, security]
sources: [raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md]
confidence: high
---

# docmesh-py-core consumer source minimization

## 결론

`docmesh-py-core`의 가장 큰 개선점은 새로운 개별 client factory를 추가하는 것이 아니라, 이미 존재하는 `assemble_services()`/`assemble_service_runtime()`을 외부 SDK 조립 경계에서 안전하게 사용할 수 있도록 ownership transfer와 health-result 계약을 명확히 하는 것이다. 현재 consumer는 py-core의 canonical assembly를 우회하고 `create_postgres_client()`, `create_sqlite_client()`, `create_minio_client()`와 자체 rollback/close glue를 직접 조립한다.

현재 workspace의 실제 근거는 `docmesh_doc/dms_factory.py`다. 파일은 148줄이고 `create_dms_sdk()` 하나가 56줄이다. 이 함수는 backend 환경정책, `RuntimePlan` 진단, service config loading, 세 client factory 호출, wrapper 내부 `.client` 추출, DMS `close_callbacks`, 실패 시 역순 cleanup을 직접 묶는다. `docmesh_doc/application.py`는 50줄이며 FastAPI `ManagedResource`에 이 SDK를 주입한다.

## 이미 있는 py-core 표면

installed `docmesh-py-core 0.6.0`의 실제 public signature는 다음과 같다.

- `assemble_services(*, plan, observer=None) -> ServiceBundle`
- `assemble_service_runtime(*, plan, observer=None) -> ServiceRuntime`
- `service_lifespan(*, plan, observer=None)`
- `ServiceBundle.require_client(service, expected_type)` — wrapper를 벗긴 concrete client를 반환
- `ServiceBundle.close()` / `ServiceRuntime.close()` — container 수준에서 멱등 종료
- `close_service_clients()` / `async_close_service_clients()` — 종료를 계속 시도하고 전체 실패를 집계

`assemble_services()`는 plan 기반 preflight, config loading, catalog factory 호출, typed container, health descriptor와 rollback을 이미 소유한다. `ServiceBundle`은 DMS처럼 raw client를 요구하는 외부 SDK에도 `require_client()`로 concrete client를 제공할 수 있다. 따라서 현재 DMS consumer가 직접 factory를 호출하는 것은 기능 공백이라기보다 canonical assembly를 외부-owner 경계에서 사용하는 예제가 없는 문제에 가깝다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## 실제 bridge probe

network-free 환경에서 SQLite와 MinIO 설정을 process environment에 주입하고 다음 경계를 직접 확인했다.

1. `assemble_services()`로 SQLite/MinIO `ServiceBundle`을 만든다.
2. `bundle.require_client(Service.SQLITE, Engine)`과 `bundle.require_client(Service.MINIO, Minio)`로 concrete client를 얻는다.
3. DMS `create_sdk_from_clients()`에 `close_callbacks=(bundle.close,)`를 전달한다.
4. SDK를 두 번 닫아도 bundle close가 한 번만 자원 종료를 수행한다.

실행 결과는 `sync_bundle_dms_bridge ok selected=['minio', 'sqlite']`였다. async 경로에서도 `assemble_service_runtime()`과 typed Engine 추출, 두 번의 `runtime.close()`가 성공했다. 이는 py-core의 기존 container가 DMS 외부 owner bridge의 기반으로 충분히 동작한다는 runtime evidence다.

DMS는 `create_sdk_from_clients()`에 caller-owned engine/MinIO와 `close_callbacks`를 받고, SDK `close()`/`aclose()`가 해당 lifecycle을 종료한다. FastAPI `ManagedResource`도 명시적 `close`가 없으면 값의 `aclose()` 또는 `close()`를 자동 탐색한다. 그러므로 py-core, DMS, FastAPI가 각각 close를 중복 소유하지 않도록 bridge의 단일 ownership callback을 명시해야 한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

## 개선 우선순위

### P0 — canonical external-owner 조립 패턴을 먼저 제공

새 API보다 먼저 py-core 예제와 contract test를 추가해 다음 패턴을 canonical로 만든다.

```text
plan = RuntimePlan(
    services=(selected_metadata_service.required(), Service.MINIO.required()),
    minio_bucket_required=True,
    healthcheck=HealthcheckPolicy(on_startup=False),
)
bundle = assemble_services(plan=plan)
sdk = dms.create_sdk_from_clients(
    engine=bundle.require_client(selected_metadata_service, Engine),
    minio_client=bundle.require_client(Service.MINIO, Minio),
    bucket_name=bundle.configs.require_minio().bucket,
    close_callbacks=(bundle.close,),
    plan=dms_plan,
)
```

이 패턴은 consumer의 직접 `create_*_client()` 호출, wrapper `.client` 접근, `_close_once()`, `_close_on_failure()`를 제거할 수 있다. `DMS_METADATA_BACKEND`가 PostgreSQL/SQLite 중 무엇을 고를지는 여전히 consumer/host policy가 결정하고, py-core가 `one_of` 순서로 조용히 선택해서는 안 된다.

### P0 — 명시적인 ownership transfer/lease 계약 검토

`bundle.close`를 외부 SDK callback으로 전달하는 현재 pattern은 동작하지만, `ServiceBundle`이 계속 owner인지 DMS가 owner인지 API 이름만으로는 드러나지 않는다. 여러 외부 host가 같은 pattern을 반복하면 다음과 같은 additive primitive를 검토한다.

```text
bundle.lease(Service.SQLITE, Service.MINIO)
    -> ServiceLease[Service]

lease.require_client(service, expected_type)
lease.close()  # idempotent; external owner callback으로 사용 가능
```

`ServiceLease`는 선택 client의 concrete lookup, 역순 close, rollback 시 best-effort cleanup, double-close 방지를 명시해야 한다. 단, 실제 DMS 한 소비자만을 위해 lease를 추가하지 말고 두 개 이상의 독립 host에서 반복이 확인될 때 도입한다. 기존 `ServiceBundle`/`ServiceRuntime`과 direct factory API는 하위 호환으로 유지한다.

### P1 — close order를 lifecycle 계약으로 승격

현재 `close_service_clients()`와 container close는 모든 client 종료 실패를 집계하지만, 문서상 외부 의존성의 역순 종료가 일반 계약으로 명시되어 있지 않다. DMS consumer는 metadata와 MinIO callback을 역순으로 닫기 위해 `_close_on_failure()`를 별도로 구현한다.

client creation order를 보존한 LIFO close를 기본 계약으로 만들거나, `close_order`가 명시된 lease/bundle API를 additive로 제공하면 dependent resource cleanup을 반복 구현하지 않아도 된다. 변경 시 기존 순서에 의존하는 consumer가 있으므로 release note와 regression test가 필요하다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

### P1 — framework-neutral health-result adapter

현재 low-level `check_all_services()`는 callback이 예외를 던지지 않으면 반환값이 `False`여도 성공으로 간주한다. 실제 probe에서 `check_all_services({'false_probe': lambda: False})`의 결과는 `ok=True`, status `ok=True`였다. 이는 built-in client factory가 예외 기반 sentinel을 사용한다는 기존 계약과는 맞지만, 외부 resource의 `False`, `.ok=False`, nested `HealthCheckResult`를 안전하게 해석하려는 consumer에는 불충분하다.

`HealthResultAdapter` 또는 `HealthOutcome` 같은 optional, framework-neutral hook을 py-core에 두고, 기본값은 기존 non-boolean sentinel 호환을 유지한다. `False`, `ServiceHealthStatus`, `HealthCheckResult`, `.ok` 객체를 strict하게 해석하는 policy는 opt-in으로 제공한다. 현재 `fastapi-core` readiness가 이미 유사한 `health_result_adapter`를 구현하므로, 중복 의미가 생기지 않도록 공통 normalization contract를 py-core로 승격하거나 bridge에서 명확히 소비해야 한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

### P2 — sync/async container protocol 타입 정합화

`ServiceContainerProtocol.selected_services`는 문서상 `frozenset[str]`로 표현되지만 `ServiceRuntime`은 `frozenset[Service]`를 반환하고 `ServiceBundle`은 문자열을 반환한다. 이 차이는 기능 장애는 아니지만 generic adapter와 type checker가 불필요한 변환을 작성하게 만든다. protocol을 generic key type으로 만들거나 sync/async protocol을 분리하는 정도로 정리할 수 있다.

## 소유권별 분류

| 반복 구현 | 적합한 소유권 | 판단 |
| --- | --- | --- |
| RuntimePlan 기반 config loading, catalog factory, typed client lookup | `docmesh-py-core` | 이미 `assemble_services()`가 제공하므로 consumer가 사용하도록 문서·예제를 보강한다. |
| close aggregation, idempotent container shutdown, health descriptor validation | `docmesh-py-core` | package-neutral safety invariant다. lease가 추가되더라도 기존 container 계약을 대체하지 않는다. |
| py-core bundle에서 DMS raw engine/MinIO로 변환하고 DMS callback으로 ownership 전달 | DMS host bridge | 두 독립 package를 연결하는 integration boundary다. DMS-specific factory를 py-core에 넣지 않는다. |
| PostgreSQL/SQLite backend 기본값, `DMS_METADATA_BACKEND`, bucket policy, `check_on_startup=False` | consumer 또는 DMS host config | 제품 및 DMS 조립 정책이다. py-core가 자동 선택하면 안 된다. |
| FastAPI `ManagedResource`, readiness status, router/error mapper, app state | `fastapi-core` bridge/consumer | web framework 의존성을 py-core에 추가하지 않는다. |
| public metadata, 권한, route, HTTP status/error envelope | DMS/consumer product policy | source 감소보다 API 보안·제품 계약이 우선이다. |

## upstream으로 옮기면 안 되는 것

- `dms.create_sdk_from_clients()`나 `DmsAssemblyPlan`을 py-core core API로 흡수하는 것
- DMS metadata backend와 MinIO bucket의 제품 기본값·권한 정책
- FastAPI import, `ManagedResource`, readiness endpoint, router/DTO/error mapping
- caller가 소유하는 NATS persistent connection의 자동 close 정책
- 테스트 전용 factory override나 임의 constructor kwargs 주입

py-core는 설정 객체를 받아 client/lifecycle/health의 공통 불변조건을 제공해야 한다. DMS와 FastAPI를 직접 알도록 만들면 한 consumer의 줄 수는 줄어도 package-neutral primitive와 integration bridge가 결합된다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## 권장 구현 순서와 acceptance tests

1. **무변경 migration probe:** 현재 consumer를 `assemble_services()` + typed `require_client()` + `bundle.close` callback 패턴으로 옮겨 direct factory/수동 cleanup 제거 가능성을 확인한다.
2. **P0 contract:** SQLite/MinIO network-free assembly, missing bucket, selected/required mismatch, DMS SDK construction failure, SDK close와 bundle close의 double-call을 고정한다.
3. **P1 health contract:** 기존 exception-based built-in check, `False`, `.ok=False`, nested `HealthCheckResult`, timeout/cancellation을 strict adapter별로 검증한다.
4. **반복 확인 후 lease:** 두 개 이상의 외부 SDK host가 ownership transfer를 반복할 때만 `ServiceLease`를 additive로 도입한다.
5. **protocol 정리:** sync/async selected-service type 차이를 type-checker와 public API test로 정리한다.

성공 기준은 단순 LOC 감소가 아니다. consumer가 client 생성·rollback·close semantics를 재구현하지 않고, DMS/py-core/FastAPI 중 한 계층만 resource ownership을 최종적으로 수행하며, health 실패가 false success로 숨겨지지 않고, backend/권한/HTTP 정책은 소비자에 남아 있어야 한다. ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## 관련 페이지

- [[docmesh-py-core]] — package entity와 DMS/FastAPI 관계.
- [[docmesh-py-core-v060-runtime-contract]] — plan-to-client, container, lifecycle contract.
- [[docmesh-py-core-usage-patterns]] — sync/async assembly와 소비자 예제.
- [[docmesh-config-consumer-source-minimization]] — configuration resolution과 DMS host bridge의 선행 분석.
- [[dms-core-configuration]] — caller-owned client와 DMS assembly policy 경계.
- [[fastapi-core-app-assembly]] — ManagedResource/readiness/lifecycle bridge.

## 검증

2026-08-04 installed runtime에서 `docmesh-py-core 0.6.0`, `dms 0.7.0`, `fastapi-core 0.7.0` signature를 확인했다. sync bundle-to-DMS bridge와 async runtime close는 성공했으며, low-level false health probe의 현재 결과도 기록했다. 기존 workspace test suite는 `uv run pytest -q`에서 `66 passed, 1 skipped`였다.
