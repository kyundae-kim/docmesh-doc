---
title: dms-core
created: 2026-07-11
updated: 2026-08-04
type: entity
tags: [dms-core, dms, document, metadata, storage, api]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-env-example-v0.3.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/dms-core-messaging-v0.2.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# dms-core

`dms-core`는 root 패키지 `dms`를 권장 진입점으로 제공하는 Python Document Management SDK다. SDK는 문서 업로드·metadata/content 조회·streaming download·soft/hard delete·health check·resource close를 공개하며, 일반 애플리케이션은 구현체를 직접 만들기보다 factory로 생성하는 것이 권장된다. ^[raw/articles/dms-core-api-v0.2.0.md]

v0.3.0 environment template은 `dms-core`가 standalone API server가 아닌 Python SDK임을 명시한다. 따라서 SDK의 PostgreSQL/SQLite·MinIO 조립 설정과 [[fastapi-core]]가 제공할 수 있는 HTTP hosting 설정은 분리해 운영한다. ^[raw/articles/dms-core-env-example-v0.3.0.md]

## Assembly and storage contracts

v0.3.0에서 `create_sdk_from_environment(...)`는 `DMS_METADATA_BACKEND=postgresql|sqlite`로 metadata store를 명시 선택할 수 있고, 미지정 시 PostgreSQL 우선 자동 선택을 유지한다. 두 설정이 공존하는 모호한 자동 선택은 `DMS_CONFIGURATION_STRICT=true`에서 오류가 되며, MinIO object store는 어느 선택에도 항상 필요하다. `create_sdk_from_components(...)`는 `MetadataStore`와 `ObjectStore` 프로토콜 구현을 직접 받아 SDK를 조립한다. 문서 lifecycle과 일관성 규칙은 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-config-v0.3.0.md]


환경 변수, storage 선택, startup health check, upstream loader 검증의 경계는 [[dms-core-configuration]]에 정리한다. DMS 운영 구성에서는 SDK storage 설정과 FastAPI application 설정을 구분해야 한다. ^[raw/articles/dms-core-config-v0.2.0.md]

환경 기반 SDK 생성, explicit component injection, upload/download/delete, stream close의 실행 패턴은 [[dms-core-usage-patterns]]에 정리한다. ^[raw/articles/dms-core-examples-v0.2.0.md]

v0.3.0 examples는 large-file streaming upload, 상태 필터 목록 조회, checksum을 포함한 streaming idempotency, dry-run/batch reconciliation, 명시 backend 사전 진단을 실제 호출 흐름으로 확인한다. 이 예제는 SDK 기능 범위를 보여 주는 것이며 HTTP adapter나 broker 통합을 추가로 의미하지 않는다. ^[raw/articles/dms-core-examples-v0.3.0.md]

v0.3.0 API는 bytes/stream upload에 공통 metadata policy와 최대 파일 크기 제한을 추가하고, root `dms` 공개 표면에 streaming upload, idempotency, 환경 진단, 문서 inspection/reconciliation 모델을 포함한다. 운영 복구 API는 알려진 상태 전환만 수행하도록 제한되어 있으며, backend-neutral object listing 또는 자동 orphan 탐색을 제공하지 않는다. 구체적인 업로드·복구 경계는 [[dms-core-usage-patterns]] 및 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-api-v0.3.0.md]



v0.7.0 API·Configuration·Examples는 DMS를 host-injected SDK로 명확히 한정한다. 공개 factory는 client/component 기반 sync·async 네 가지이며, 환경변수 factory·환경 진단·자동 client 생성은 공개 계약이 아니다. `DmsServiceConfigs`는 호스트 설정 계층에서 사용할 immutable value object지만 public factory가 이를 자동 소비하지 않는다. 현재 workspace의 `uv` environment에서 `dms` v0.7.0 factory·request·plan exports를 직접 확인했고, host adapter가 client factory를 실제로 호출하는 회귀 테스트도 통과했다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

v0.7.0은 `DmsAssemblyPlan`으로 metadata/backend 정책, startup timeout, access policy, operation observer와 recovery audit hook을 묶고, `ManagedResource`로 SDK/caller ownership과 reverse cleanup을 명시한다. `scoped(context)` facade는 tenant·작성자·idempotency scope·audit actor 같은 작업 맥락을 공유 SDK에 immutable하게 적용한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

v0.7.0 Examples는 public/internal metadata, cursor pagination, reset, recovery plan, structured metadata, transport-neutral error descriptor와 HTTP 권고 변환, sync/async facade 및 기능별 protocol을 하나의 소비자 흐름으로 연결한다. 반대로 unknown-size stream과 async input stream 직접 upload, search, presigned URL, broker, standalone API server는 범위 밖으로 남는다. ^[raw/articles/dms-core-wiki-examples-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

## docmesh-config boundary

`docmesh-config` v0.1.0은 PostgreSQL·SQLite·MinIO 등 generic service settings와 plan/diagnosis metadata를 제공하지만 DMS metadata backend 선택, object-store factory, document lifecycle 또는 `dms` SDK 생성 계약을 정의하지 않는다. `POSTGRES_*`와 `MINIO_*`가 양쪽 문서에 나타나도 `docmesh-config`의 generic bundle을 DMS storage assembly로 직접 전달한다고 추론하지 않는다. DMS 고유 선택·DSN exclusion·MinIO 요구사항은 [[dms-core-configuration]]에 남긴다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

현재 consumer manifest와 application source는 `docmesh-config`와 `docmesh-py-core`를 실제로 bridge한다. `docmesh_doc.dms_factory`가 `load_service_configs(...)`로 선택 backend/MinIO 설정을 읽고 `create_postgres_client`·`create_sqlite_client`·`create_minio_client`로 caller-owned client를 만든 뒤 `create_sdk_from_clients(...)`에 close callbacks와 `DmsAssemblyPlan`을 전달한다. 이 구현으로 환경 읽기·client 생성은 host 소유이고, 문서 lifecycle·storage adapter는 DMS 소유라는 경계가 검증된다.

## v0.6 docmesh-py-core boundary

`docmesh-py-core` v0.6.0 API/Examples의 `RuntimePlan`·service client lifecycle은 DMS storage SDK 계약과 별도다. generic `PostgresConfig`/`MinioConfig`가 DMS factory를 자동 조립하는 것은 아니지만, 이 소비 adapter는 두 canonical client factory를 명시적으로 호출해 DMS client factory에 주입한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

## Messaging scope

현재 SDK에는 broker publish/subscribe나 이벤트 메시지 계약이 없으며, `NATS_SERVERS`가 필요할 수 있는 것은 upstream 설정 검증과 관련된 사실이다. FastAPI hosting layer의 NATS 확장과 SDK 범위의 차이는 [[dms-core-messaging-boundary]]에서 다룬다. ^[raw/articles/dms-core-messaging-v0.2.0.md]

## FastAPI deployment position

이 위키의 DMS 배포 모델에서는 [[fastapi-core]]가 HTTP application layer, `dms-core`가 문서 도메인/로직 SDK 역할을 맡는다. FastAPI lifecycle, state, readiness의 통합 경계는 [[fastapi-core-app-assembly]]에서 설계해야 하며, 이 API source만으로 두 패키지의 직접 코드 통합 계약이 존재한다고 단정하지는 않는다.

v0.7.0 Configuration은 호스트가 환경·secret을 읽고 SQLAlchemy Engine/MinIO client 또는 storage component를 먼저 만든 뒤 DMS factory에 주입하도록 명시한다. 이 workspace는 그 경계를 `docmesh_doc.dms_factory`와 `fastapi-core`의 required managed resource로 구현한다. FastAPI 통합은 DMS가 환경을 다시 읽는 경로가 아니라 [[fastapi-core-app-assembly]]의 resource/lifespan 경계에서 ownership·health·close를 연결한다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## Consumer source minimization

v0.7.0의 source minimization 개선점은 환경 factory나 FastAPI 결합을 DMS에 추가하는 것이 아니라, `DmsOperationContext`·public metadata·close-safe stream·transport-neutral error descriptor를 host bridge가 재사용하도록 하는 데 있다. config/client assembly와 HTTP 제품 정책은 별도 integration boundary로 유지해야 한다. 상세 우선순위와 acceptance tests는 [[dms-core-consumer-source-minimization]]에 정리한다.

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.7.0.md`
- `raw/articles/dms-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.3.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/dms-core-messaging-v0.2.0.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
