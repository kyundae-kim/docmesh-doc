---
title: dms-core document lifecycle
created: 2026-07-11
updated: 2026-08-24
type: concept
tags: [dms, document, metadata, storage, workflow, dms-core]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.9.0.md, raw/articles/dms-core-wiki-examples-v0.9.0.md, raw/articles/dms-core-wiki-api-reference-v0.10.0.md, raw/articles/dms-core-wiki-examples-v0.10.0.md]
confidence: medium
---

# dms-core document lifecycle

`dms-core`의 문서 lifecycle은 object store와 metadata store의 정합성을 지키는 SDK 흐름이다. 업로드는 본문을 먼저 저장하고 metadata를 저장하며, metadata 실패 시 본문 정리를 시도한다. 정리도 실패하면 `ConsistencyError`가 발생한다.

## States and retrieval

업로드 성공 후 상태는 `available`이며, 삭제는 `deleting`을 거쳐 soft delete에서 `deleted` metadata를 남기거나 hard delete에서 metadata 행을 제거한다. 다운로드는 metadata를 먼저 확인한 뒤 object를 조회하며, metadata만 존재하고 본문이 없으면 `ConsistencyError`로 처리한다. 이 동작은 [[dms-core]]의 `DefaultDocumentManagementSDK` 공개 API로 수행된다.

## FastAPI integration boundary

HTTP route와 request/response 변환은 [[fastapi-core]]의 application layer에 두고, SDK 생성·close 및 DMS 의존성 주입은 [[fastapi-core-app-assembly]]의 custom lifespan/state 경계에서 설계할 수 있다. 현재 수집 source는 `dms-core` 자체 API를 설명하므로 구체적인 FastAPI adapter는 이후 통합 source로 확인해야 한다.

v0.7.0은 이 host boundary를 명시적인 설정 계약으로 만든다. FastAPI가 환경·secret을 해석하고 client/component를 생성한 뒤 resource ownership, health, close를 `fastapi-core` lifecycle에 등록해야 하며, DMS public API만으로 standalone HTTP server나 broker integration이 생긴다고 추론하지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

v0.7.0 API는 일반 single/list 조회에서 `DELETING`·`DELETED`를 숨기고 internal metadata와 recovery 결과만 관리 경계로 남긴다. `recommended_http_error(...)`는 stable code/category/retryability를 host 전송 계층용 권고 응답으로 투영하지만 예외에 HTTP 의미를 부여하지 않는다. [[fastapi-core-app-assembly]] adapter는 제품 envelope와 storage-key allowlist를 유지하면서 필요한 status projection을 수행한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

v0.7.0 Examples는 logical deletion이 일반 조회/list에서 숨겨지고 body 요청에는 `DocumentDeletedError`가 난다는 workflow, dry-run recovery plan을 재검사 후 실행하는 흐름, 그리고 sync/async content stream의 context-managed close를 제시한다. 현재 host는 sync stream close와 existing recovery audit path를 유지하며, async route 채택 시 완료·오류·취소 cleanup test를 함께 둔다. ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## v0.7 ownership and lifecycle contract

v0.7.0 Configuration은 DMS가 환경이나 connection을 만들지 않고 host가 만든 Engine/MinIO client 또는 storage component를 주입받는다고 명시한다. 기본 주입 자원은 caller-owned이며, `ManagedResource(ownership=SDK)`나 `close_callbacks`로 등록한 자원만 SDK가 역순으로 정리한다. startup health 실패 시 SDK-owned 자원만 rollback하고, caller-owned client는 자동으로 닫지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

sync/async SDK와 content stream은 context manager를 제공하며, async facade는 sync storage 작업을 worker thread에서 실행한다. async output stream은 정상 소진·읽기 오류·취소·조기 `aclose()`에서 반복 호출에 안전하게 정리되고, `copy_document_to()`는 SDK-owned source만 닫고 caller-owned sink는 닫지 않는다. cleanup 실패가 있으면 `ResourceCleanupError.errors`로 모든 오류를 보존한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

v0.7.0의 전역 `clear_all_data()`/`initialize_for_data_load()`는 metadata, `documents/` prefix object, upload operation record를 대상으로 하며 분산 transaction을 주장하지 않는다. 한 store 실패 후에도 나머지를 시도하고 부분 결과를 `DataResetError.result`에 남기므로, application은 reset을 개별 document delete와 다른 관리 권한·운영 관찰 경계로 둔다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## v0.10 current lifecycle contract

v0.10.0 preserves the object/metadata lifecycle and host ownership boundary while adding native async assembly. Sync and async factories accept host-owned engines and MinIO clients; direct assembly accepts host-owned components. SDK-opened files and returned content streams are cleaned up by their operation/stream contracts, while caller-provided upload streams and copy sinks remain caller-owned. No facade exposes global `close()`, `aclose()`, or `check_health()`. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

User scope is now part of lifecycle isolation rather than only an external authorization hint. The same `user_id` constrains metadata, object namespace, upload-operation scope, cursor continuation, reads, deletion, recovery, and reset. Cross-user document operations fail with `AccessDeniedError`; a scoped reset removes only that user's DMS-managed data. Cursor reuse must preserve user scope as well as status and page size. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

Public retrieval/listing can include `user_id` but still returns `PublicDocumentMetadata` without `storage_key`; internal metadata, inspection, and recovery results remain explicit management surfaces. Reset and reconciliation preserve partial results and item errors, plans are revalidated at execution, and recovery audit callbacks remain best-effort. Stable DMS errors still have no HTTP status or response-body contract, so [[fastapi-core-app-assembly]] must project them separately. ^[raw/articles/dms-core-wiki-api-reference-v0.10.0.md] ^[raw/articles/dms-core-wiki-examples-v0.10.0.md]

소비 host의 inline content와 attachment download는 모두 sync `DocumentContentStream`을 context manager로 소비하므로 public body 조회가 object 전체를 메모리에 복사하지 않는다. 통합 test fixture도 assertion 실패와 명시 삭제 성공 양쪽에서 best-effort hard delete를 수행해 테스트 문서 lifecycle을 닫는다. 세부 최적화는 [[dms-application-optimization]]과 [[dms-core-usage-patterns]]에 연결한다.

SDK 생성에 필요한 MinIO·metadata store·startup health 설정은 [[dms-core-configuration]]에서 관리한다. lifecycle integration은 이 설정의 health/close 정책과 정합성을 유지해야 한다.

upload·전체/stream 조회·soft/hard delete와 close를 포함한 실행 흐름은 [[dms-core-usage-patterns]]에 정리한다.

## Inspection and bounded recovery

v0.3.0의 `inspect_document`는 metadata/object 존재 여부, 상태, 일관성 및 `RecoveryIssue`를 반환하며 metadata 부재 자체는 예외가 아니다. `reconcile_document(s)`의 복구 action은 삭제 완료, metadata가 있으나 object가 없는 문서의 실패 표시, 호출자가 제공한 알려진 storage key의 orphan object purge로 제한된다. batch recovery는 FAILED/DELETING 상태와 기존 offset/limit을 대상으로 하며 dry-run과 항목별 SDK 오류 결과를 제공한다. MinIO prefix scan 또는 orphan 자동 발견은 범위 밖이므로 application layer가 object listing을 가정해서는 안 된다. 이 제한은 [[dms-core]]의 storage contract 및 [[dms-core-configuration]]의 운영 health 경계와 함께 적용한다. ^[raw/articles/dms-core-api-v0.3.0.md]

운영 예제는 reconciliation을 우선 `dry_run=True`로 미리 보고, batch에서는 `DocumentStatus.DELETING` 같은 상태와 `limit`을 명시해 수행한다. orphan purge에는 SDK가 추측하지 않는 안전한 `storage_key`를 운영자가 제공해야 한다. ^[raw/articles/dms-core-examples-v0.3.0.md]

## Operational questions

- DMS API는 SDK error를 어떤 HTTP 상태·오류 모델로 매핑할 것인가?
- SDK의 `check_health()`와 FastAPI readiness를 어떻게 함께 보고할 것인가?
- SDK close callback과 FastAPI shutdown 순서는 어떤 contract로 보장할 것인가?

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/dms-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.7.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.9.0.md`
- `raw/articles/dms-core-wiki-examples-v0.9.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.10.0.md`
- `raw/articles/dms-core-wiki-examples-v0.10.0.md`
