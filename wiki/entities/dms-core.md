---
title: dms-core
created: 2026-07-11
updated: 2026-07-11
type: entity
tags: [dms-core, dms, document, metadata, storage, api]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-messaging-v0.2.0.md]
confidence: medium
---

# dms-core

`dms-core`는 root 패키지 `dms`를 권장 진입점으로 제공하는 Python Document Management SDK다. SDK는 문서 업로드·metadata/content 조회·streaming download·soft/hard delete·health check·resource close를 공개하며, 일반 애플리케이션은 구현체를 직접 만들기보다 factory로 생성하는 것이 권장된다. ^[raw/articles/dms-core-api-v0.2.0.md]

## Assembly and storage contracts

`create_sdk_from_environment(...)`는 PostgreSQL을 우선하고 SQLite를 fallback metadata store로 선택하며, MinIO object store는 항상 필요하다. `create_sdk_from_components(...)`는 `MetadataStore`와 `ObjectStore` 프로토콜 구현을 직접 받아 SDK를 조립한다. 문서 lifecycle과 일관성 규칙은 [[dms-core-document-lifecycle]]에 정리한다.

환경 변수, storage 선택, startup health check, upstream loader 검증의 경계는 [[dms-core-configuration]]에 정리한다. DMS 운영 구성에서는 SDK storage 설정과 FastAPI application 설정을 구분해야 한다. ^[raw/articles/dms-core-config-v0.2.0.md]

환경 기반 SDK 생성, explicit component injection, upload/download/delete, stream close의 실행 패턴은 [[dms-core-usage-patterns]]에 정리한다. ^[raw/articles/dms-core-examples-v0.2.0.md]

## Messaging scope

현재 SDK에는 broker publish/subscribe나 이벤트 메시지 계약이 없으며, `NATS_SERVERS`가 필요할 수 있는 것은 upstream 설정 검증과 관련된 사실이다. FastAPI hosting layer의 NATS 확장과 SDK 범위의 차이는 [[dms-core-messaging-boundary]]에서 다룬다. ^[raw/articles/dms-core-messaging-v0.2.0.md]

## FastAPI deployment position

이 위키의 DMS 배포 모델에서는 [[fastapi-core]]가 HTTP application layer, `dms-core`가 문서 도메인/로직 SDK 역할을 맡는다. FastAPI lifecycle, state, readiness의 통합 경계는 [[fastapi-core-app-assembly]]에서 설계해야 하며, 이 API source만으로 두 패키지의 직접 코드 통합 계약이 존재한다고 단정하지는 않는다.

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-messaging-v0.2.0.md`
