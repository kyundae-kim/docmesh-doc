---
title: dms-core configuration model
created: 2026-07-11
updated: 2026-08-15
type: concept
tags: [dms-core, dms, configuration, storage, metadata, security, deployment]
sources: [raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-env-example-v0.3.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md, raw/articles/dms-core-wiki-api-reference-v0.9.0.md, raw/articles/dms-core-wiki-examples-v0.9.0.md]
confidence: medium
---

# dms-core configuration model

v0.3.0 source set은 환경 기반 SDK 조립과 backend 선택을 설명했다. 이 선택 정책은 해당 버전의 historical contract로 보존한다. ^[raw/articles/dms-core-config-v0.3.0.md]

## v0.7 host-owned configuration boundary

v0.7.0 Configuration reference는 공개 DMS package에 환경변수를 읽는 factory나 환경 진단 API가 없다고 명시한다. 현재 공개 조립은 `create_sdk_from_clients(...)`, `create_sdk_from_components(...)`와 각각의 async facade이며, 호스트가 설정 파일·환경변수·secret manager를 읽어 Engine/MinIO client 또는 storage component를 만든 뒤 주입한다. 따라서 `POSTGRES_*`, `POSTGRES_DSN`, `SQLITE_PATH`, `MINIO_*`, `DMS_METADATA_BACKEND`, `DMS_CONFIGURATION_STRICT`는 DMS가 자동 해석하는 입력이 아니다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

`DmsServiceConfigs`는 MinIO와 PostgreSQL/SQLite 중 정확히 하나를 표현하는 immutable host-side value object다. DMS public factory가 이 객체를 자동 소비하지 않으므로, 호스트는 이를 사용해 client를 만들거나 component adapter를 조립해야 한다. `metadata_backend`, `strict_configuration`, startup check/timeout, metadata limits, access policy와 observer는 `DmsAssemblyPlan`으로 전달되는 정책 값이며 환경변수 selector로 해석하지 않는다. 현재 interpreter에서 `dms` v0.7.0의 public factory와 plan signature를 확인했으며, workspace host adapter는 이 계약을 따르는 client injection과 close callback을 사용한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## v0.9 current assembly boundary

The v0.9.0 contract replaces the v0.7 plan/factory description as current runtime guidance. The host reads environment, secret, and deployment configuration, creates the SQLAlchemy `Engine` and MinIO client or structural storage components, then injects them through `DocumentManagementSDKFactory` or `DefaultDocumentManagementSDK`. Current factory policy is expressed by `bucket_name`, `max_file_size`, `access_policy`, `operation_observer`, and `recovery_audit_hook`; there is no public environment factory or DMS-owned diagnosis loader. ^[raw/articles/dms-core-wiki-api-reference-v0.9.0.md] ^[raw/articles/dms-core-wiki-examples-v0.9.0.md]

The host, not DMS, owns client/component readiness and shutdown. The SDK has no global health or close method. Per-operation files and returned content streams are SDK-managed where documented; caller-provided upload inputs and output sinks remain caller-owned. FastAPI readiness and lifecycle must therefore be represented by the hosting application boundary, not inferred from a DMS SDK health API. ^[raw/articles/dms-core-wiki-api-reference-v0.9.0.md]

## Storage and startup-health contract

아래의 PostgreSQL/SQLite 선택·환경 진단 세부사항은 v0.3.0 historical contract다. v0.7.0 candidate에서는 같은 정책을 호스트 설정 계층이 수행하고, DMS는 이미 생성된 저장소와 명시된 `DmsAssemblyPlan`을 검증·실행한다.

문서 본문 저장소는 MinIO가 필수이며 SQLite는 metadata store 대안일 뿐이다. v0.7 DMS는 startup health를 환경변수에서 결정하지 않으므로 host가 `DmsAssemblyPlan(check_on_startup=...)` 또는 FastAPI managed-resource policy 중 하나의 경계를 명시해야 한다. 이 workspace는 assembly plan의 network health check를 기본 비활성화하고, `ManagedResource.healthcheck`를 required readiness 경계로 등록한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

## Shared configuration boundary

`KEYCLOAK_*`, `NATS_SERVERS`, `MILVUS_URI` 등은 DMS SDK 기능의 직접 설정이 아니라 `docmesh-py-core` loader가 해당 서비스를 선택했을 때 검증할 수 있는 외부 통합 설정이다. `load_service_configs(services=...)`는 선택 서비스만 검증하지만, `load_available_service_configs(...)`는 관련 prefix가 보이는 부분 설정을 오류로 다룬다. DMS SDK 설정과 FastAPI 앱 설정을 섞지 않고, 앱 레이어는 [[fastapi-core-configuration]], SDK 저장소/health 설정은 이 페이지에서 각각 관리해야 한다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

`docmesh-config` v0.1.0도 같은 외부 서비스 이름과 environment prefix를 다루지만, 그 source set은 DMS metadata backend 선택·object-store factory·`dms` SDK 조립을 정의하지 않는다. generic `PostgresConfig`/`MinioConfig`와 `RuntimePlan`을 발견했다고 해서 DMS의 `POSTGRES_DSN` exclusion, PostgreSQL/SQLite 선택, MinIO 필수 정책이 자동으로 위임되었다고 추론하지 않는다. 이 package boundary는 [[docmesh-config-configuration]]과 [[docmesh-config-runtime-plan]]에서 별도로 기록한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

v0.3.0 API의 `diagnose_environment(env)`는 historical environment-factory contract다. v0.7 DMS에는 이 public API가 없으므로, 현재 host는 `docmesh_config.diagnose_services(...)`를 strict mode에서 사용해 대안 backend ambiguity를 network-free로 검증하고, 선택 service는 `load_service_configs(...)`로 로드한다. ^[raw/articles/dms-core-api-v0.3.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]


v0.7.0은 factory 공통 option과 plan 정책을 분리한다. `max_file_size`는 bytes/file/known-size sync stream에 공통 적용되고, `operation_store`는 component factory의 영속 idempotency에 필요하다. `check_on_startup`과 timeout은 등록한 service check를 조립 직후 실행하며 실패 시 SDK-owned resource만 역순 rollback한다. caller-owned engine/client는 explicit `ManagedResource(SDK)` 또는 callback으로 등록하지 않으면 닫지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

v0.7.0 logging은 주입 logger의 `dms_` structured fields를 사용하되 본문·token·password를 기록하지 않는다. 외부 HTTP 계층은 내부 exception text 대신 `error_descriptor()` 또는 `recommended_http_error()`의 secret-safe 표현을 사용한다. DMS 자체는 auth helper, search, presigned URL, message broker 설정을 제공하지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

예제의 SQLite 사전 진단은 `DMS_METADATA_BACKEND=sqlite`, `SQLITE_PATH`와 네 개의 MinIO 필수 키를 같은 환경에 넣은 뒤 configuration diagnosis와 selected-service loader를 통해 SDK를 생성한다. 현재 consumer는 이 host boundary를 `docmesh-config`/`docmesh-py-core` adapter로 구현하며, credential을 로그에 기록하지 않는다. ^[raw/articles/dms-core-examples-v0.3.0.md] ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## v0.6 docmesh-py-core boundary

`docmesh-py-core` v0.6.0은 generic service client/lifecycle assembly와 `docmesh_config.RuntimePlan` 소비를 문서화하지만 DMS metadata backend, object-store factory, `POSTGRES_DSN` exclusion 또는 DMS document lifecycle을 정의하지 않는다. 따라서 이 package bridge는 DMS storage configuration을 대체하지 않지만, 현재 consumer가 명시적으로 선택한 backend의 client를 만드는 구현 primitive로 사용한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

## Deployment guidance

로컬 개발은 SQLite + MinIO 구성에서 host assembly의 startup health check를 비활성화할 수 있지만, 통합/운영 환경에서는 PostgreSQL + MinIO와 required managed-resource readiness를 기준으로 검증한다. 실제 서비스 주소·credential을 주입한 뒤에만 network health check를 활성화하고, SQLite를 의도하면 `POSTGRES_*`를 제거/주석 처리하거나 backend를 `sqlite`로 선택한다. 실제 endpoint·credential·DSN은 외부 secret 주입으로 관리한다. 운영 환경에서는 `MINIO_SECURE=true`와 유효한 TLS 구성을 권장하고, MinIO bucket과 PostgreSQL 계정에는 최소 권한을 준다. ^[raw/articles/dms-core-env-example-v0.3.0.md]

환경 기반·명시적 component SDK 조립과 close 보장 패턴은 [[dms-core-usage-patterns]]에서 확인한다. 이 패턴은 [[dms-core-document-lifecycle]]의 upload/download/delete 작업 전후에 적용된다.

## Sources

- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.3.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.7.0.md`
- `raw/articles/dms-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.9.0.md`
- `raw/articles/dms-core-wiki-examples-v0.9.0.md`
