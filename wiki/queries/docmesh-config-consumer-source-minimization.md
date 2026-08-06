---
title: docmesh-config consumer source minimization
created: 2026-08-04
updated: 2026-08-04
type: query
tags: [configuration, integration, architecture, dependency, testing, security]
sources: [raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]
confidence: high
---

# docmesh-config consumer source minimization

## 결론

현재 소비자 구현의 가장 큰 반복은 설정 모델 자체가 아니라 **`RuntimePlan`을 실제 로드 가능한 `ServiceConfigs`로 해석하고, 진단 오류를 소비자 예외로 변환하는 glue**다. `docmesh-config` v0.1.0은 이미 서비스 설정, 대안 그룹, network-free diagnosis, secret-safe `ConfigIssue`를 제공하지만 `load_service_configs()`는 `services` 집합만 받고 `diagnose_services()`는 별도 `RuntimePlan`을 요구한다. 따라서 consumer가 plan을 두 번 기술하고(진단용 plan과 실제 loader용 set), 오류 메시지도 다시 조립한다.

현재 workspace의 실제 근거는 `docmesh_doc/dms_factory.py`다. 파일은 148줄이고, `create_dms_sdk()` 하나가 56줄이다. `_metadata_backend()`, `_strict_configuration()`, `_diagnose_strict_configuration()`이 raw environment parsing·plan 생성·diagnosis formatting을 수행하며, 이어서 backend별 client factory 선택과 close rollback을 직접 조립한다. 전체 테스트는 현재 설치된 `docmesh-config 0.1.0`, `docmesh-py-core 0.6.0`, `dms 0.7.0`, `fastapi-core 0.7.0` 조합에서 `66 passed, 1 skipped`였다.

## 현재 표면과 반복

설치 runtime signature는 다음 경계를 확인한다.

- `load_service_configs(*, services: set[str | Service] | None = None)` — plan 또는 selection mode를 받지 않는다.
- `diagnose_services(*, plan: RuntimePlan, selection_mode="auto" | "explicit" | "strict")` — 진단만 반환하고 로드된 `ServiceConfigs`를 반환하지 않는다.
- `build_runtime_plan_metadata(plan=..., selection_mode=...)` — secret-safe metadata를 만들지만 client factory 입력은 아니다.
- `require_minio_bucket(config)` — bucket 검증은 이미 제공한다.

소비자에서는 이 네 단계가 분리되어 있다.

1. `DMS_METADATA_BACKEND`와 `DMS_CONFIGURATION_STRICT`를 raw `os.environ`에서 읽는다.
2. PostgreSQL/SQLite/MinIO의 `RuntimePlan`을 진단용으로 다시 만든다.
3. `load_service_configs(services={...})`에 backend별 서비스 집합을 별도로 만든다.
4. `ServiceConfigs`에서 config를 꺼내 `docmesh-py-core` client factory와 `dms.create_sdk_from_clients(...)`에 전달한다.

이 중 1~3은 여러 DMS host가 반복할 수 있는 configuration primitive이고, 4와 close/health/lifespan 연결은 DMS 또는 FastAPI integration boundary다. 실제 `dms_factory.py`와 `test_dms_factory.py`는 이 반복이 상상한 boilerplate가 아니라 현재 consumer source임을 보여 준다.

## 개선 우선순위

### P0 — plan-aware configuration resolution

기존 함수를 깨지 않는 additive API로, 다음과 같은 하나의 해석 경계를 제공하는 것이 가장 효과적이다.

```text
resolve_service_configs(plan, selection_mode="auto")
    -> ResolvedServiceConfigs(
         configs: ServiceConfigs,
         diagnosis: EnvironmentDiagnosis,
         plan: RuntimePlan,
       )
```

`resolve_service_configs()`는 같은 `RuntimePlan`으로 diagnosis를 수행하고, 성공하면 실제로 구성된 서비스만 `ServiceConfigs`에 로드해야 한다. `strict` 대안 충돌, required service 누락, partial/invalid 설정, `minio_bucket_required`를 하나의 structured result/error contract로 처리해야 한다. 기존 `load_service_configs(services=...)`와 `diagnose_services(...)`는 하위 호환을 위해 유지한다.

이 API가 backend를 자동 선택해서는 안 된다. `RuntimePlan.one_of`는 구성 대안을 표현할 뿐 `DMS_METADATA_BACKEND`라는 제품 정책의 우선순위를 의미하지 않는다. 소비자가 명시한 backend policy와 resolved configured services를 구분해야 silent PostgreSQL/SQLite 선택을 막을 수 있다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

### P0 — diagnosis를 구조화 오류로 승격하는 helper

현재 consumer는 `diagnosis.issues`를 순회해 `env_key: reason` 문자열을 다시 만들고 `ConfigError`를 직접 발생시킨다. `raise_for_diagnosis(diagnosis)` 또는 `ConfigError.from_diagnosis(diagnosis)`를 제공하면 모든 issue, `error_type`, remediation, severity를 보존하면서 consumer의 formatting code를 제거할 수 있다. 기본 message는 secret-safe하고 deterministic해야 하며, 제품별 error code나 HTTP status를 포함해서는 안 된다.

`validate_service_requirements(configs, ...)`는 이미 loaded bundle 검증에 유용하지만, 현재 host가 작성한 `RuntimePlan`과 diagnosis를 하나의 contract로 묶지는 않는다. 새 helper는 이 기존 primitive를 대체하기보다 plan diagnosis의 canonical error projection으로 추가하는 편이 안전하다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

### P1 — resolved selection과 metadata의 명시적 연결

`RuntimePlanMetadata`는 운영 preflight/readiness 입력으로 충분히 유용하지만 executable config나 client를 포함해서는 안 된다. `ResolvedServiceConfigs`가 `plan`, `diagnosis`, `configs`를 명시적으로 연결하고 metadata에는 계속 safe projection만 남기면, logging/readiness consumer가 설정 원문이나 client ownership을 오해하지 않는다.

가능하면 resolved object는 immutable bundle로 만들고, `configured_services`, `required_services`, 선택된 alternative와 diagnosis를 모두 조회 가능하게 한다. `ServiceConfigs` 자체를 무조건 runtime resource로 승격하거나 mutable global state로 만들면 오히려 lifecycle 경계가 흐려진다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

### P1 — DMS host-specific settings는 별도 계층으로 분리

`DMS_METADATA_BACKEND`, `DMS_CONFIGURATION_STRICT`, legacy `POSTGRES_DSN` 거부, MinIO bucket 필수 여부는 이 애플리케이션의 DMS storage policy다. 여러 DMS 소비자가 동일하게 반복한다면 `docmesh-config`의 generic service model에 섞기보다 `dms-host-config` 같은 별도 integration/config package에서 typed settings로 제공하는 것이 적절하다. 그 package는 `docmesh-config`의 plan/config를 소비할 수 있지만, generic `docmesh-config`가 DMS SDK나 FastAPI를 import해서는 안 된다.

이 분리는 현재 DMS v0.7의 host-injected contract와도 맞는다. DMS는 environment를 읽거나 client를 자동 생성하지 않고 host-created Engine/MinIO client 또는 component를 받는다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## 가장 큰 source reduction은 별도 bridge에서 발생한다

`docmesh-config`만 확장해도 plan/diagnosis/loading glue는 줄지만, 현재 148줄의 `dms_factory.py` 전체를 generic settings package로 옮기면 경계를 잘못 합치게 된다. 다음 bridge를 별도 package 또는 명시적 host adapter로 두는 것이 맞다.

- `docmesh-config` → `docmesh-py-core`의 resolved settings/client factory 연결
- PostgreSQL/SQLite 대안에 따른 DMS engine 선택
- MinIO client와 bucket을 DMS factory에 주입
- caller-owned client close callback의 역순 cleanup과 assembly rollback
- `DmsAssemblyPlan`의 `check_on_startup=False` 같은 DMS/FastAPI lifecycle policy 전달

이 bridge가 reusable해지면 각 애플리케이션은 `DmsServiceConfigs` 또는 typed host settings를 전달하고 SDK/resource binding만 선언할 수 있다. `fastapi-core`의 `DomainModule`/`ManagedResource`/typed resource dependency는 별도의 framework bridge로 남겨야 한다. 이미 module-first app assembly가 50줄 수준으로 작으므로 새 app factory를 만드는 것보다 반복되는 storage adapter를 줄이는 편이 우선이다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

## upstream으로 옮기면 안 되는 것

- HTTP router, `app.state`, FastAPI readiness registry, `ManagedResource` lifecycle
- 제품의 `DMS_METADATA_BACKEND` 기본값, 권한·route·reverse-proxy 정책
- `POSTGRES_DSN` 같은 버전 migration guard와 제품 오류 envelope/HTTP status
- DMS public metadata allowlist, `storage_key` 비공개 정책, correlation ID
- client를 생성하거나 DNS/socket/API에 연결하는 동작

`docmesh-config`의 역할은 process-environment parsing, declarative plan, network-free diagnosis와 safe metadata로 제한하는 것이 재사용성과 보안에 유리하다. 설정 package가 FastAPI/DMS를 직접 알아야 소비 source가 줄어드는 형태는 framework bridge 또는 product policy를 generic layer에 밀어 넣는 coupling 비용을 만든다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## 권장 구현 순서와 acceptance tests

1. `resolve_service_configs(plan, selection_mode)`의 return/error contract를 먼저 정의한다.
2. complete, absent optional, partial, invalid, strict alternative ambiguity, missing MinIO bucket을 network-free test로 고정한다.
3. diagnosis promotion helper가 secret-safe issue와 remediation을 모두 보존하는지 검증한다.
4. 실제 consumer에서 plan을 한 번만 선언하도록 마이그레이션하고, backend policy/DSN migration guard는 host 테스트로 유지한다.
5. 이후 별도 DMS host bridge를 도입해 py-core client creation, DMS injection, rollback/close-once semantics를 contract test로 재사용한다.

성공 기준은 단순히 줄 수를 줄이는 것이 아니다. consumer가 같은 선택 정책을 두 번 기술하지 않고, configuration failure가 connection failure와 구분되며, client ownership과 FastAPI lifecycle이 그대로 유지되어야 한다. ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## 관련 페이지

- [[docmesh-config]] — package 공개 범위와 현재 consumer relationship.
- [[docmesh-config-configuration]] — 환경변수 loading과 security contract.
- [[docmesh-config-runtime-plan]] — `RuntimePlan`, diagnosis와 startup metadata 경계.
- [[docmesh-py-core-v060-runtime-contract]] — settings-to-client/lifecycle package bridge.
- [[dms-core-configuration]] — DMS host-owned storage assembly boundary.
- [[fastapi-core-app-assembly]] — managed resource와 application lifecycle boundary.

## 검증

2026-08-04 현재 `uv run pytest -q` 결과는 `66 passed, 1 skipped`이며 upstream Starlette의 `httpx2` 전환 warning 1개가 남아 있다. 설치 runtime signature와 SQLite/MinIO complete 및 strict PostgreSQL/SQLite ambiguity diagnosis도 별도로 확인했다.
