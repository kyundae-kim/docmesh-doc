---
title: docmesh-py-core
created: 2026-07-11
updated: 2026-08-02
type: entity
tags: [dms-core, integration, configuration, dependency, security]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-py-core

`docmesh-py-core`는 서비스 설정, client 구성, health/readiness 집계, Keycloak 인증 및 운영 보조 기능을 공개하는 별도 업스트림 Python 패키지다. `v0.6.0` Wiki API 레퍼런스는 `docmesh_config`를 설정·plan의 canonical package로, `docmesh_py_core`를 client/lifecycle/health API의 canonical package로 구분한다. 이는 DMS 로직 SDK인 [[dms-core]]와 동일하다고 단정하는 근거는 아니며, 현재는 [[fastapi-core]]가 재사용하는 외부 서비스 통합 계층으로 기록한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]


## v0.6.0 documented contract

- v0.6.0 API/Examples는 `docmesh_config`를 `RuntimePlan`·`Service`·`HealthcheckPolicy`의 canonical package로, `docmesh_py_core`를 client factory·container·lifecycle·health·오류/관측성 API의 canonical package로 분리한다. `docmesh_py_core` root는 설정 심볼을 재노출하지 않으며 `.config`, `.settings`, `.runtime_plan`, `.factories`는 호환 facade다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]
- 일반 async 애플리케이션은 `service_lifespan(plan=...)`을 우선 사용하고, `assemble_service_runtime()`은 낮은 수준의 bootstrap, `assemble_services()`는 NATS/timeout startup policy가 없는 sync 경로로 사용한다. `create_empty_service_runtime()`은 loader·factory·network 없는 별도 empty path다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]
- `ServiceRuntime`/`ServiceBundle`은 각각 async/sync ownership을 구분하고, `require()`·`require_client()`는 선택·초기화·concrete type 오류를 분리한다. required health 실패는 `HealthCheckError`, overall timeout은 `asyncio.TimeoutError`가 될 수 있으며, 모든 close 실패는 aggregate error로 보존된다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]
- 모든 `*Config()`는 process environment만 읽고 `.env`를 자동 로드하지 않는다. v0.6.0 examples는 generic FastAPI `app.state.services`에 runtime을 두는 consumer pattern을 보여 주지만, 이는 `fastapi-core` `create_app` contract나 DMS storage assembly의 증거가 아니다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]



- 일반 애플리케이션의 권장 bootstrap은 typed `Service` selection과 `RuntimePlan`을 만든 뒤 `await assemble_service_runtime(plan=...)`을 호출하는 방식이다. plan은 선택 서비스·필수 여부·대안 그룹·`HealthcheckPolicy`를 하나의 불변 계약으로 묶고, 빈 또는 모순된 plan은 `InvalidRuntimePlanError`로 거부한다. 동기 전용 `assemble_services()`는 NATS를 허용하지 않는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]
- `diagnose_services(plan=..., selection_mode="auto" | "strict")`는 네트워크 연결 전에 서비스별 `absent`·`complete`·`partial`·`invalid` 상태, non-secret 기본값, plan 위반과 production 보안 문제를 반환한다. strict 모드는 대안 그룹의 복수 구성도 문제로 처리한다. `SERVICE_CATALOG`와 `EnvironmentRequirement`는 값이나 secret을 읽지 않는 환경 요구사항 메타데이터 경계다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]
- `ServiceRuntime.require(Service)`는 plan 밖 서비스와 미초기화 서비스를 각각 `ServiceNotSelectedError`와 `ServiceNotInitializedError`로 구분한다. startup 검사 실패는 `StartupFailureMode.FAIL`에서 시작을 중단하거나 `REPORT`에서 `startup_healthcheck_result`로 노출할 수 있으며, 생성·검사 실패 뒤에는 이미 만든 자원을 best-effort로 정리한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]
- factory는 검증된 config만 받고 임의 SDK keyword override를 받지 않는다. `close_service_clients()`와 `async_close_service_clients()`는 종료를 계속 시도한 뒤 모든 실패를 `ServiceCloseError.failures`에 집계하는 계약이며, `DocMeshError`는 configuration·lookup·availability·shutdown 오류의 공통 구조화 기반이다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md]

현재 workspace interpreter에는 `docmesh-py-core` v0.6.0, `docmesh-config` v0.1.0, `fastapi-core` v0.7.0, `dms` v0.7.0이 설치되어 있다. package-root exports, config/client factory signatures와 host-owned DMS assembly를 직접 확인했으며, 아래 source-derived 사실과 consumer runtime evidence를 분리해 기록한다.

2026-07-26 wiki snapshot의 `docmesh-py-core 0.4.0` 설치 기록은 historical evidence다. 현재 `pyproject.toml`과 interpreter는 Git ref `v0.6.0`을 사용하며, consumer는 package-root `create_postgres_client`, `create_sqlite_client`, `create_minio_client`를 통해 host-owned DMS assembly를 구현한다.

## Relationship to docmesh-config

새로 수집한 `docmesh-config` v0.1.0은 process-environment-only 설정 모델, 선택 서비스 loader, `RuntimePlan`, 외부 연결 없는 diagnosis와 secret-safe metadata를 별도 package root에서 공개한다. 이는 이 페이지가 설명하는 `docmesh-py-core`의 client assembly/health/runtime contract와 인접한 설정 계층이지만, 해당 source set은 두 패키지가 직접 의존하거나 동일한 `ServiceConfigs` type을 공유한다고 말하지 않는다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

서비스 이름과 환경변수 prefix가 겹쳐도 loader 호환을 추론하지 않는다. 소비자가 `docmesh-config` plan/config bundle을 `docmesh-py-core` assembly에 전달하려면 version-aligned public signature와 adapter contract test가 별도로 필요하다. 설정 계층의 세부 내용은 [[docmesh-config-configuration]]과 [[docmesh-config-runtime-plan]]에서, FastAPI 소비 경계는 [[fastapi-core-configuration]]에서 관리한다.

v0.6.0 설정은 프로세스 환경변수만 읽고 공백 문자열을 미설정으로 처리하며, `DOCMESH_SECURITY_MODE`와 `DOCMESH_PRODUCTION_ALIASES`로 production 판정을 구성한다. `DOCMESH_HEALTHCHECK_ENABLED`는 지원되지 않고 startup 상태 확인은 `RuntimePlan.healthcheck`가 제어하므로, 소비 애플리케이션이 startup 정책을 명시해야 한다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

v0.6.0 source set은 `docmesh_config.RuntimePlan`을 `docmesh_py_core` lifecycle에 전달하는 package-level bridge를 명시하지만, DMS metadata backend/object-store factory나 document lifecycle을 제공한다고 말하지 않는다. 설정·runtime bridge는 [[docmesh-py-core-v060-runtime-contract]], DMS storage 소유권은 [[dms-core-configuration]]에서 별도로 추적한다.

## Relationship to the DMS service

[[fastapi-core]]는 이 의존성의 settings와 service-client wrapper를 자체 runtime에서 사용할 수 있고, 이 workspace의 `dms_factory`는 wrapper를 FastAPI managed DMS resource보다 먼저 host scope에서 만든다. [[fastapi-core-app-assembly]]는 그 DMS SDK와 readiness/lifespan 정책을 조립하는 경계다. DMS의 실제 로직 코어 패키지는 `dms`이며 `docmesh-py-core`는 client/lifecycle primitive를 제공한다.

`load_service_configs(...)`에 전달되는 외부 서비스 설정과 개발/테스트 fallback의 운영상 한계는 [[fastapi-core-configuration]]에 정리한다. Keycloak·MinIO·NATS 등의 연결 credential은 운영 배포에서 외부 secret으로 대체해야 한다. `docmesh-py-core`의 production 보안 검증은 안전하지 않은 TLS/secure 설정을 제한하지만, secret 주입·회전 정책 자체를 제공하지는 않는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

메시징 세부 연결값은 이 의존성의 `ServiceConfigs`에서 해석되고, `fastapi-core`는 NATS를 서비스 선택·readiness·lifecycle 확장 지점으로 다룬다. 자세한 경계는 [[fastapi-core-messaging-integration]]에 정리한다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

동기/비동기 assembly, FastAPI lifespan, selective service loading, health endpoint, NATS builder, Keycloak direct integration의 upstream 실행 예시는 [[docmesh-py-core-usage-patterns]]에 정리한다. 이 consumer는 DMS storage assembly에 필요한 동기 PostgreSQL/SQLite·MinIO wrapper factory만 명시적으로 사용하고, py-core의 generic service runtime이 DMS SDK를 자동 생성한다고 가정하지 않는다. ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
