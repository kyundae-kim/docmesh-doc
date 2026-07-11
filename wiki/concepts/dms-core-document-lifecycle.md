---
title: dms-core document lifecycle
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [dms, document, metadata, storage, workflow, dms-core]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-examples-v0.2.0.md]
confidence: medium
---

# dms-core document lifecycle

`dms-core`의 문서 lifecycle은 object store와 metadata store의 정합성을 지키는 SDK 흐름이다. 업로드는 본문을 먼저 저장하고 metadata를 저장하며, metadata 실패 시 본문 정리를 시도한다. 정리도 실패하면 `ConsistencyError`가 발생한다.

## States and retrieval

업로드 성공 후 상태는 `available`이며, 삭제는 `deleting`을 거쳐 soft delete에서 `deleted` metadata를 남기거나 hard delete에서 metadata 행을 제거한다. 다운로드는 metadata를 먼저 확인한 뒤 object를 조회하며, metadata만 존재하고 본문이 없으면 `ConsistencyError`로 처리한다. 이 동작은 [[dms-core]]의 `DefaultDocumentManagementSDK` 공개 API로 수행된다.

## FastAPI integration boundary

HTTP route와 request/response 변환은 [[fastapi-core]]의 application layer에 두고, SDK 생성·close 및 DMS 의존성 주입은 [[fastapi-core-app-assembly]]의 custom lifespan/state 경계에서 설계할 수 있다. 현재 수집 source는 `dms-core` 자체 API를 설명하므로 구체적인 FastAPI adapter는 이후 통합 source로 확인해야 한다.

SDK 생성에 필요한 MinIO·metadata store·startup health 설정은 [[dms-core-configuration]]에서 관리한다. lifecycle integration은 이 설정의 health/close 정책과 정합성을 유지해야 한다.

upload·전체/stream 조회·soft/hard delete와 close를 포함한 실행 흐름은 [[dms-core-usage-patterns]]에 정리한다.

## Operational questions

- DMS API는 SDK error를 어떤 HTTP 상태·오류 모델로 매핑할 것인가?
- SDK의 `check_health()`와 FastAPI readiness를 어떻게 함께 보고할 것인가?
- SDK close callback과 FastAPI shutdown 순서는 어떤 contract로 보장할 것인가?

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
