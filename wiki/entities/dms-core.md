---
title: dms-core
created: 2026-07-11
updated: 2026-07-15
type: entity
tags: [dms-core, dms, document, metadata, storage, api]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-env-example-v0.3.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/dms-core-messaging-v0.2.0.md]
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

## Messaging scope

현재 SDK에는 broker publish/subscribe나 이벤트 메시지 계약이 없으며, `NATS_SERVERS`가 필요할 수 있는 것은 upstream 설정 검증과 관련된 사실이다. FastAPI hosting layer의 NATS 확장과 SDK 범위의 차이는 [[dms-core-messaging-boundary]]에서 다룬다. ^[raw/articles/dms-core-messaging-v0.2.0.md]

## FastAPI deployment position

이 위키의 DMS 배포 모델에서는 [[fastapi-core]]가 HTTP application layer, `dms-core`가 문서 도메인/로직 SDK 역할을 맡는다. FastAPI lifecycle, state, readiness의 통합 경계는 [[fastapi-core-app-assembly]]에서 설계해야 하며, 이 API source만으로 두 패키지의 직접 코드 통합 계약이 존재한다고 단정하지는 않는다.

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.3.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/dms-core-messaging-v0.2.0.md`
