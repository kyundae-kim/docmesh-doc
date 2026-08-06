---
title: docmesh-config runtime plan and diagnosis
created: 2026-08-02
updated: 2026-08-02
type: concept
tags: [configuration, architecture, observability, testing, integration]
sources: [raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-config runtime plan and diagnosis

`docmesh-config`의 runtime layer는 실제 client나 health probe를 실행하는 runtime이 아니라, 소비 runtime이 사용할 선택·요구·startup policy와 환경 진단 metadata를 표현한다. 중심 타입은 `Service`, `ServiceSelection`, `RuntimePlan`, `HealthcheckPolicy`, `RuntimePlanMetadata`다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## Plan structure

`Service`의 canonical key는 `keycloak`, `postgres`, `sqlite`, `minio`, `milvus`, `ollama`, `langfuse`, `nats`다. `Service.required()`와 `.optional()`은 immutable selection을 만들고, `RuntimePlan`은 하나 이상의 서비스를 선택해야 하며 중복 서비스·빈 대안 그룹·plan 밖 대안 서비스·MinIO 없이 설정한 bucket requirement를 거부한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

`one_of`는 PostgreSQL/SQLite 같은 대안 그룹을 표현한다. `diagnose_services(..., selection_mode="auto" | "explicit" | "strict")`에서 auto/explicit은 하나 이상의 구성된 대안을 충족으로 볼 수 있지만, strict는 정확히 하나만 구성되어야 한다. 예제는 SQLite와 PostgreSQL이 동시에 구성된 경우 `ambiguous_service_alternative`를 보고한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## Startup policy metadata

`HealthcheckPolicy`는 startup 실행 여부, 병렬 실행, 개별/전체 timeout, `StartupFailureMode.FAIL` 또는 `REPORT`, attempts와 retry delay를 담는다. 이 값은 runtime 계층이 소비할 정책 metadata일 뿐 `docmesh-config` 자체가 연결·상태 확인을 수행한다는 뜻은 아니다. 예제의 `REPORT` plan도 `build_runtime_plan_metadata(...)` 결과에 policy를 직렬화할 뿐이다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

`RuntimePlanMetadata`는 selected/configured/required service, alternative groups, healthcheck, MinIO bucket requirement, 서비스별 상태, 요구사항 충족 여부, 진단 문제를 secret-safe 형태로 결합한다. executable object나 설정 원문은 포함하지 않으며, 운영 로그·readiness 응답의 입력으로 사용할 때도 실제 secret을 별도로 남기지 않아야 한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## Diagnosis flow

`diagnose_services(plan=...)`는 서비스별 `absent`, `complete`, `partial`, `invalid` 상태를 계산하고 `ConfigIssue`에 service, canonical env key, reason, error type, remediation, severity를 넣는다. `validate_service_requirements(...)`는 required/one-of 요구를 검증하고, `require_minio_bucket(...)`은 bucket이 없을 때 구조화 오류를 낸다. 진단은 DNS, socket, 외부 API를 사용하지 않으므로 CI·startup preflight에서 구성 오류를 연결 오류와 분리할 수 있다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## Boundary with application runtimes

이 plan은 [[docmesh-config-configuration]]의 환경 설정 위에 놓인 package-neutral input이다. [[docmesh-py-core-usage-patterns]]에서 다루는 `ServiceRuntime`/assembly와 동일한 개념으로 취급하지 않는다. `docmesh-config` source set은 plan과 diagnosis metadata를 제공하지만 실제 service client factory, FastAPI `app.state`, managed resource lifecycle, readiness registry를 직접 제공한다고 확정하지 않는다.

따라서 [[fastapi-core-app-assembly]]가 이 metadata를 startup/readiness 정책으로 소비할 수는 있어도, 그 연결은 소비 adapter의 명시적 integration contract와 version-aligned 테스트가 입증해야 한다. [[dms-core-configuration]]의 metadata backend 선택도 별도 SDK 설정 경계로 유지한다. 같은 `POSTGRES_*` 또는 `MINIO_*` 이름이 plan의 서비스 선택과 DMS storage assembly를 자동으로 결합하지 않는다.

현재 workspace manifest는 `docmesh-config` v0.1.0을 선언하지만 Python interpreter에서 import probe가 실패했고 source usage도 확인되지 않았다. 이 페이지의 plan/diagnosis 내용은 실행 중인 runtime 사실이 아니라 v0.1.0 upstream contract와 소비 경계의 기록이다.

## v0.6 consumer relationship

`docmesh-py-core` v0.6.0 API/Examples는 이 `RuntimePlan`을 `service_lifespan`과 assembly의 입력으로 명시한다. 따라서 plan과 `ServiceRuntime`은 동일한 객체가 아니라, 설정 package가 version-aligned runtime package에 제공하는 input/output 경계다. `docmesh-config` 자체가 service client factory나 FastAPI lifecycle을 실행하는 것은 아니다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

현재 interpreter에는 두 package가 설치되어 있지 않아 이 관계는 문서 계약으로만 기록한다.

## Testing implications

예제는 외부 서비스 없이 `SQLITE_PATH=:memory:`를 사용해 complete/absent 상태, 대안 충돌, MinIO bucket requirement, partial PostgreSQL 오류, production transport 오류, secret-safe `model_dump()`와 URL masking을 검증한다. 테스트는 process environment를 격리하고 필요한 서비스 block만 주입해야 하며, 실제 network readiness는 별도 integration test로 분리한다. ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## Related pages

- [[docmesh-config]] — package의 공개 범위와 version/runtime reconciliation.
- [[docmesh-config-configuration]] — 환경변수·loading·production security contract.
- [[docmesh-py-core-usage-patterns]] — 별도 service assembly/runtime contract.
- [[fastapi-core-app-assembly]] — FastAPI lifecycle/readiness 소비 경계.
- [[dms-core-configuration]] — DMS storage configuration boundary.

## Sources

- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
