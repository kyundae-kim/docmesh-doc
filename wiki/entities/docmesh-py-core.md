---
title: docmesh-py-core
created: 2026-07-11
updated: 2026-07-26
type: entity
tags: [dms-core, integration, configuration, dependency, security]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/docmesh-py-core-api-v0.2.0.md, raw/articles/docmesh-py-core-config-v0.2.0.md, raw/articles/docmesh-py-core-examples-v0.2.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]
confidence: medium
---

# docmesh-py-core

`docmesh-py-core`는 서비스 설정, client 구성, health/readiness 집계, Keycloak 인증 및 운영 보조 기능을 공개하는 별도 업스트림 Python 패키지다. `v0.5.0` Wiki API 레퍼런스는 패키지 루트 `__all__`을 공개 범위로 명시하고 plan 기반 runtime 조립·진단 계약을 추가로 설명한다. 이는 DMS 로직 SDK인 [[dms-core]]와 동일하다고 단정하는 근거는 아니며, 현재는 [[fastapi-core]]가 재사용하는 외부 서비스 통합 계층으로 기록한다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md] ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]

## Observed integration contract

- `load_service_configs(...)`는 선택된 서비스만 검증하며, `load_available_service_configs(...)`는 관련 환경 변수 prefix가 존재하는 후보만 실제 validation한다. `ServiceConfigs`는 Keycloak·PostgreSQL·SQLite·MinIO·Milvus·Ollama·Langfuse·NATS 설정을 묶고, 미로딩 서비스는 `require_*()`에서 구조화된 `ConfigError`로 드러낸다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md]
- 일반 lifecycle은 동기 `assemble_services()` 또는 NATS를 포함하는 비동기 `assemble_service_runtime()`으로 조립한다. NATS는 builder를 반환하며, 실제 연결은 `connect()`·`ping()`·`check()` 호출 때 일어난다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md]
- `check_all_services(...)`와 `async_check_all_services(...)`는 required 실패를 `HealthCheckError`로 집계하고, wrapper 및 health 오류 메시지는 민감 값을 마스킹한다. async cleanup은 한 client 종료 실패 후에도 나머지를 정리하고 실패를 보존하지만, 동기 `close_service_clients(...)`는 첫 종료 예외를 전파한다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md]
- `validate_runtime_security(...)`는 production 판정에서 Keycloak SSL 검증, MinIO secure, Milvus secure가 비활성화되는 구성을 거부한다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md]

## v0.5.0 documented contract

- 일반 애플리케이션의 권장 bootstrap은 typed `Service` selection과 `RuntimePlan`을 만든 뒤 `await assemble_service_runtime(plan=...)`을 호출하는 방식이다. plan은 선택 서비스·필수 여부·대안 그룹·`HealthcheckPolicy`를 하나의 불변 계약으로 묶고, 빈 또는 모순된 plan은 `InvalidRuntimePlanError`로 거부한다. 동기 전용 `assemble_services()`는 NATS를 허용하지 않는다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]
- `diagnose_services(plan=..., selection_mode="auto" | "strict")`는 네트워크 연결 전에 서비스별 `absent`·`complete`·`partial`·`invalid` 상태, non-secret 기본값, plan 위반과 production 보안 문제를 반환한다. strict 모드는 대안 그룹의 복수 구성도 문제로 처리한다. `SERVICE_CATALOG`와 `EnvironmentRequirement`는 값이나 secret을 읽지 않는 환경 요구사항 메타데이터 경계다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]
- `ServiceRuntime.require(Service)`는 plan 밖 서비스와 미초기화 서비스를 각각 `ServiceNotSelectedError`와 `ServiceNotInitializedError`로 구분한다. startup 검사 실패는 `StartupFailureMode.FAIL`에서 시작을 중단하거나 `REPORT`에서 `startup_healthcheck_result`로 노출할 수 있으며, 생성·검사 실패 뒤에는 이미 만든 자원을 best-effort로 정리한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]
- factory는 검증된 config만 받고 임의 SDK keyword override를 받지 않는다. `close_service_clients()`와 `async_close_service_clients()`는 종료를 계속 시도한 뒤 모든 실패를 `ServiceCloseError.failures`에 집계하는 계약이며, `DocMeshError`는 configuration·lookup·availability·shutdown 오류의 공통 구조화 기반이다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md]

현재 workspace는 `docmesh-py-core 0.4.0`을 설치하고 있으므로, 이 페이지의 v0.5.0 plan·diagnosis·오류 계층은 현행 runtime을 확인한 사실이 아니라 업그레이드 대상 공개 계약으로 취급한다. 소비 애플리케이션은 version-aligned dependency를 설치하고 public exports/signatures를 재확인하기 전에는 해당 추가 API에 의존하면 안 된다.

`v0.2.0` 설정 문서는 공백 문자열을 미설정으로 처리하고 Boolean은 `true`/`false`만 허용한다고 명시한다. `DOCMESH_SECURITY_MODE`가 있으면 환경 이름보다 우선해 production 여부를 정하고, 없으면 `DOCMESH_PRODUCTION_ALIASES`(기본 `prod,production`)와 비교한다. `DOCMESH_HEALTHCHECK_ENABLED`는 config에만 로드될 뿐 assembly API의 `check_on_startup`을 자동으로 바꾸지 않으므로, 소비 애플리케이션이 startup 정책을 명시해야 한다. ^[raw/articles/docmesh-py-core-config-v0.2.0.md]

## Relationship to the DMS service

[[fastapi-core]]는 이 의존성의 settings와 service-client wrapper를 FastAPI 앱의 `app.state`에 배치한다. [[fastapi-core-app-assembly]]는 DMS 배포에서 그 상태, lifespan, readiness 정책을 조립하는 경계다. DMS의 실제 로직 코어 패키지가 `docmesh-py-core`인지 여부는 별도 DMS 소스로 확인해야 한다.

`load_service_configs(...)`에 전달되는 외부 서비스 설정과 개발/테스트 fallback의 운영상 한계는 [[fastapi-core-configuration]]에 정리한다. Keycloak·MinIO·NATS 등의 연결 credential은 운영 배포에서 외부 secret으로 대체해야 한다. `docmesh-py-core`의 production 보안 검증은 안전하지 않은 TLS/secure 설정을 제한하지만, secret 주입·회전 정책 자체를 제공하지는 않는다. ^[raw/articles/docmesh-py-core-api-v0.2.0.md]

메시징 세부 연결값은 이 의존성의 `ServiceConfigs`에서 해석되고, `fastapi-core`는 NATS를 서비스 선택·readiness·lifecycle 확장 지점으로 다룬다. 자세한 경계는 [[fastapi-core-messaging-integration]]에 정리한다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

동기/비동기 assembly, FastAPI lifespan, selective service loading, health endpoint, NATS builder, Keycloak direct integration의 실행 예시는 [[docmesh-py-core-usage-patterns]]에 정리한다. ^[raw/articles/docmesh-py-core-examples-v0.2.0.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/docmesh-py-core-api-v0.2.0.md`
- `raw/articles/docmesh-py-core-config-v0.2.0.md`
- `raw/articles/docmesh-py-core-examples-v0.2.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.5.0.md`
