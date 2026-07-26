---
title: dms-core
created: 2026-07-11
updated: 2026-07-26
type: entity
tags: [dms-core, dms, document, metadata, storage, api]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.4.0.md, raw/articles/dms-core-wiki-api-reference-v0.5.0.md, raw/articles/dms-core-wiki-api-reference-v0.6.0.md, raw/articles/dms-core-wiki-configuration-v0.4.0.md, raw/articles/dms-core-wiki-configuration-v0.5.0.md, raw/articles/dms-core-wiki-configuration-v0.6.0.md, raw/articles/dms-core-wiki-examples-v0.4.0.md, raw/articles/dms-core-wiki-examples-v0.5.0.md, raw/articles/dms-core-wiki-examples-v0.6.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-env-example-v0.3.0.md, raw/articles/dms-core-env-example-v0.4.0.md, raw/articles/dms-core-env-example-v0.5.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/dms-core-messaging-v0.2.0.md]
confidence: medium
---

# dms-core

`dms-core`는 root 패키지 `dms`를 권장 진입점으로 제공하는 Python Document Management SDK다. SDK는 문서 업로드·metadata/content 조회·streaming download·soft/hard delete·health check·resource close를 공개하며, 일반 애플리케이션은 구현체를 직접 만들기보다 factory로 생성하는 것이 권장된다. ^[raw/articles/dms-core-api-v0.2.0.md]

v0.3.0 environment template은 `dms-core`가 standalone API server가 아닌 Python SDK임을 명시한다. 따라서 SDK의 PostgreSQL/SQLite·MinIO 조립 설정과 [[fastapi-core]]가 제공할 수 있는 HTTP hosting 설정은 분리해 운영한다. ^[raw/articles/dms-core-env-example-v0.3.0.md]

## Assembly and storage contracts

v0.3.0에서 `create_sdk_from_environment(...)`는 `DMS_METADATA_BACKEND=postgresql|sqlite`로 metadata store를 명시 선택할 수 있고, 미지정 시 PostgreSQL 우선 자동 선택을 유지한다. 두 설정이 공존하는 모호한 자동 선택은 `DMS_CONFIGURATION_STRICT=true`에서 오류가 되며, MinIO object store는 어느 선택에도 항상 필요하다. `create_sdk_from_components(...)`는 `MetadataStore`와 `ObjectStore` 프로토콜 구현을 직접 받아 SDK를 조립한다. 문서 lifecycle과 일관성 규칙은 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-config-v0.3.0.md]

v0.4.0 Wiki 설정 계약은 PostgreSQL DSN을 DMS 환경 조립 입력에서 제외하고 개별 connection fields를 사용한다. 설치된 `dms 0.4.0` 진단도 이 경계를 확인했으므로 v0.3.0의 DSN 지원 설명은 현재 runtime에 적용하지 않는다. component 조립에서는 custom metadata validator가 factory 기본 크기·깊이 제한을 자동 상속하지 않으며, 공통 설정 요구사항은 `diagnose_environment()` 결과로 확인한다. 세부 migration은 [[dms-core-configuration]]에 정리한다. ^[raw/articles/dms-core-wiki-configuration-v0.4.0.md]

v0.5.0 Wiki Configuration reference는 동일한 DSN exclusion·backend selection·healthcheck policy를 유지하면서, settings-bundle 기반 SDK 조립과 secret-free diagnosis formatter를 current contract로 설명한다. 설치된 `dms 0.4.0`은 DSN-only input을 여전히 거부하지만 새 factory/formatter는 제공하지 않는다. 그 API는 version-aligned upgrade 뒤에만 채택하며 현재 DMS storage configuration과 FastAPI hosting configuration의 분리 원칙은 유지한다. ^[raw/articles/dms-core-wiki-configuration-v0.5.0.md]

v0.6.0 Wiki Configuration reference는 environment/service-config/client/component factory의 자원 소유권, PostgreSQL·SQLite 선택 순서, DSN exclusion, MinIO bucket requirement와 production TLS policy를 한 계약으로 명시한다. 현재 설치된 `dms 0.5.0` probe는 individual PostgreSQL fields의 valid diagnosis, DSN-only input의 rejection, `ServiceConfigs` factory 및 safe diagnosis formatter를 확인한다. v0.6.0의 async/HTTP helper 및 production-specific behavior는 아직 이 runtime에서 검증하지 않았으므로, storage configuration과 [[fastapi-core]] hosting configuration을 분리한 upgrade candidate로 유지한다. ^[raw/articles/dms-core-wiki-configuration-v0.6.0.md]

Git tag v0.4.0의 environment template도 DSN 대신 개별 PostgreSQL 필드를 활성화하고 PostgreSQL metadata store와 MinIO object store를 기본 조합으로 제시한다. Placeholder endpoint 때문에 startup health check는 비활성화되어 있으며, 실제 secret과 reachable endpoint를 주입한 뒤 운영 health policy를 켜야 한다. ^[raw/articles/dms-core-env-example-v0.4.0.md]

Git tag v0.5.0 environment template도 PostgreSQL/SQLite 하나와 MinIO 하나의 SDK-only assembly를 유지하고, placeholder value를 실제 secret/endpoint로 교체하기 전에는 health check를 끄도록 한다. v0.5 template의 temporary environment overlay/restore 설명은 installed v0.4.0 mapping-based factory와 다르므로, runtime behavior로 단정하지 않고 v0.5 upgrade candidate로 유지한다. ^[raw/articles/dms-core-env-example-v0.5.0.md]

환경 변수, storage 선택, startup health check, upstream loader 검증의 경계는 [[dms-core-configuration]]에 정리한다. DMS 운영 구성에서는 SDK storage 설정과 FastAPI application 설정을 구분해야 한다. ^[raw/articles/dms-core-config-v0.2.0.md]

환경 기반 SDK 생성, explicit component injection, upload/download/delete, stream close의 실행 패턴은 [[dms-core-usage-patterns]]에 정리한다. ^[raw/articles/dms-core-examples-v0.2.0.md]

v0.3.0 examples는 large-file streaming upload, 상태 필터 목록 조회, checksum을 포함한 streaming idempotency, dry-run/batch reconciliation, 명시 backend 사전 진단을 실제 호출 흐름으로 확인한다. 이 예제는 SDK 기능 범위를 보여 주는 것이며 HTTP adapter나 broker 통합을 추가로 의미하지 않는다. ^[raw/articles/dms-core-examples-v0.3.0.md]

v0.3.0 API는 bytes/stream upload에 공통 metadata policy와 최대 파일 크기 제한을 추가하고, root `dms` 공개 표면에 streaming upload, idempotency, 환경 진단, 문서 inspection/reconciliation 모델을 포함한다. 운영 복구 API는 알려진 상태 전환만 수행하도록 제한되어 있으며, backend-neutral object listing 또는 자동 orphan 탐색을 제공하지 않는다. 구체적인 업로드·복구 경계는 [[dms-core-usage-patterns]] 및 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-api-v0.3.0.md]

v0.4.0 GitHub Wiki API 계약은 unknown-size stream의 bounded spool 업로드, 명시적 `idempotency_scope`와 upload-operation 조회, 안정적인 cursor pagination, 내부 `storage_key`를 제거하는 `PublicDocumentMetadata`, 재검증 가능한 reconciliation plan/audit hook, 구조화 metadata validator를 공개 표면에 추가한다. 이 프로젝트는 `dms` Git ref `v0.4.0`을 선언하고 있으며 설치된 `dms 0.4.0`에서 핵심 심볼과 method signature가 확인되었다. HTTP 응답 경계와 실행 패턴은 [[fastapi-core-app-assembly]], [[dms-core-usage-patterns]], [[dms-core-document-lifecycle]]에서 다룬다. ^[raw/articles/dms-core-wiki-api-reference-v0.4.0.md]

v0.5.0 Wiki API reference는 `create_sdk_from_service_configs`, `format_environment_diagnosis`, 공개 안전 `get_document_metadata`/`list_documents`, 내부 전용 metadata accessor를 추가한 계약으로 설명한다. 그러나 설치된 `dms 0.4.0`에는 앞의 두 factory/formatter와 내부 accessor가 없고 metadata/list 반환도 `DocumentMetadata`다. 따라서 새 source는 안전한 public metadata와 validated DocMesh settings 조립의 upstream migration candidate이며, 현재 adapter의 allowlist 응답 매핑을 대체하는 runtime 사실은 아니다. ^[raw/articles/dms-core-wiki-api-reference-v0.5.0.md]

v0.6.0 Wiki API reference는 v0.5.0의 public-safe metadata와 settings-bundle factory를 유지하면서 async upload/download stream, cursor 기반 기본 `list_documents`, 그리고 stable DMS 오류를 host HTTP 응답으로 변환하는 `recommended_http_error(...)`를 공개 계약에 넣는다. 이 workspace는 `dms 0.5.0`을 설치했으며 v0.5 factories/public metadata accessors는 확인되지만 async stream·HTTP helper는 없고 `list_documents`는 offset 목록 signature를 유지한다. 따라서 v0.6.0 API는 version-aligned upgrade와 adapter contract test 뒤에만 채택할 candidate다. ^[raw/articles/dms-core-wiki-api-reference-v0.6.0.md]

v0.4.0 예제는 이 계약을 root `dms` import만으로 조립하며 context-managed SDK/stream 종료, explicit idempotency scope와 operation 조회, bounded unknown-size upload, public metadata, cursor 순회, 명시 삭제, plan 기반 복구를 하나의 운영 흐름으로 확인한다. `StructuredMetadataValidator`는 parser/projector 결과를 자체 기본 policy에 다시 통과시킨다. ^[raw/articles/dms-core-wiki-examples-v0.4.0.md]

v0.5.0 Wiki Examples도 upload/idempotency/stream/cursor/recovery와 structured metadata를 root import로 조합하지만, environment factory를 process environment에서 argument 없이 호출하고 `format_environment_diagnosis`를 사용한다. 설치된 `dms 0.4.0`의 core upload·stream·cursor·delete·reconciliation signatures는 확인되었으나 `create_sdk_from_environment`에는 `env` mapping이 필수이고 formatter는 없다. 따라서 해당 assembly/diagnosis 예제는 v0.5.0 upgrade candidate다. ^[raw/articles/dms-core-wiki-examples-v0.5.0.md]

v0.6.0 Wiki Examples는 environment/service-config/component assembly, public/internal metadata, idempotent sync streams, structured metadata, recovery plan, and health lifecycle을 함께 보이며 async stream 및 `recommended_http_error(...)` 흐름도 추가한다. 설치된 `dms 0.5.0`은 environment/service-config/formatter와 sync upload·cursor page API를 제공하지만 async stream·HTTP helper가 없고 기본 list signature는 offset 방식이다. 그러므로 v0.6.0 예제의 신규 async/HTTP/cursor-default 흐름은 version-aligned upgrade 후 contract test로 채택한다. ^[raw/articles/dms-core-wiki-examples-v0.6.0.md]

## Messaging scope

현재 SDK에는 broker publish/subscribe나 이벤트 메시지 계약이 없으며, `NATS_SERVERS`가 필요할 수 있는 것은 upstream 설정 검증과 관련된 사실이다. FastAPI hosting layer의 NATS 확장과 SDK 범위의 차이는 [[dms-core-messaging-boundary]]에서 다룬다. ^[raw/articles/dms-core-messaging-v0.2.0.md]

## FastAPI deployment position

이 위키의 DMS 배포 모델에서는 [[fastapi-core]]가 HTTP application layer, `dms-core`가 문서 도메인/로직 SDK 역할을 맡는다. FastAPI lifecycle, state, readiness의 통합 경계는 [[fastapi-core-app-assembly]]에서 설계해야 하며, 이 API source만으로 두 패키지의 직접 코드 통합 계약이 존재한다고 단정하지는 않는다.

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.4.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.5.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.4.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.5.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.6.0.md`
- `raw/articles/dms-core-wiki-examples-v0.4.0.md`
- `raw/articles/dms-core-wiki-examples-v0.5.0.md`
- `raw/articles/dms-core-wiki-examples-v0.6.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.4.0.md`
- `raw/articles/dms-core-env-example-v0.5.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/dms-core-messaging-v0.2.0.md`
