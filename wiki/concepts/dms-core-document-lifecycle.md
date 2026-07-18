---
title: dms-core document lifecycle
created: 2026-07-11
updated: 2026-07-18
type: concept
tags: [dms, document, metadata, storage, workflow, dms-core]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.4.0.md, raw/articles/dms-core-wiki-examples-v0.4.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md]
confidence: medium
---

# dms-core document lifecycle

`dms-core`의 문서 lifecycle은 object store와 metadata store의 정합성을 지키는 SDK 흐름이다. 업로드는 본문을 먼저 저장하고 metadata를 저장하며, metadata 실패 시 본문 정리를 시도한다. 정리도 실패하면 `ConsistencyError`가 발생한다.

## States and retrieval

업로드 성공 후 상태는 `available`이며, 삭제는 `deleting`을 거쳐 soft delete에서 `deleted` metadata를 남기거나 hard delete에서 metadata 행을 제거한다. 다운로드는 metadata를 먼저 확인한 뒤 object를 조회하며, metadata만 존재하고 본문이 없으면 `ConsistencyError`로 처리한다. 이 동작은 [[dms-core]]의 `DefaultDocumentManagementSDK` 공개 API로 수행된다.

v0.4.0 예제는 soft/hard 삭제를 각각 `soft_delete_document(...)`와 `hard_delete_document(...)`로 명시하고 통합 `delete_document(...)`를 호환 경로로 둔다. 삭제 중 `ConsistencyError`는 부분 완료 가능성을 뜻하므로 즉시 반복 삭제하기보다 `inspect_document(...)`와 [[dms-core-configuration]]에 연결된 운영 복구 흐름을 먼저 적용한다. ^[raw/articles/dms-core-wiki-examples-v0.4.0.md]

## FastAPI integration boundary

HTTP route와 request/response 변환은 [[fastapi-core]]의 application layer에 두고, SDK 생성·close 및 DMS 의존성 주입은 [[fastapi-core-app-assembly]]의 custom lifespan/state 경계에서 설계할 수 있다. 현재 수집 source는 `dms-core` 자체 API를 설명하므로 구체적인 FastAPI adapter는 이후 통합 source로 확인해야 한다.

v0.4.0은 `storage_key`를 adapter/recovery용 내부 필드로 명시하고 `public_metadata(...)`와 `PublicDocumentMetadata`를 공개 응답 경계로 제공한다. FastAPI adapter는 내부 metadata를 직접 직렬화하지 말고 이 변환 또는 동일한 allowlist response model을 사용해야 한다. 현재 프로젝트의 response model은 `storage_key`를 제외하지만, SDK helper를 사용할지 자체 매핑을 유지할지는 application contract로 결정한다. ^[raw/articles/dms-core-wiki-api-reference-v0.4.0.md]

SDK 생성에 필요한 MinIO·metadata store·startup health 설정은 [[dms-core-configuration]]에서 관리한다. lifecycle integration은 이 설정의 health/close 정책과 정합성을 유지해야 한다.

upload·전체/stream 조회·soft/hard delete와 close를 포함한 실행 흐름은 [[dms-core-usage-patterns]]에 정리한다.

## Inspection and bounded recovery

v0.3.0의 `inspect_document`는 metadata/object 존재 여부, 상태, 일관성 및 `RecoveryIssue`를 반환하며 metadata 부재 자체는 예외가 아니다. `reconcile_document(s)`의 복구 action은 삭제 완료, metadata가 있으나 object가 없는 문서의 실패 표시, 호출자가 제공한 알려진 storage key의 orphan object purge로 제한된다. batch recovery는 FAILED/DELETING 상태와 기존 offset/limit을 대상으로 하며 dry-run과 항목별 SDK 오류 결과를 제공한다. MinIO prefix scan 또는 orphan 자동 발견은 범위 밖이므로 application layer가 object listing을 가정해서는 안 된다. 이 제한은 [[dms-core]]의 storage contract 및 [[dms-core-configuration]]의 운영 health 경계와 함께 적용한다. ^[raw/articles/dms-core-api-v0.3.0.md]

운영 예제는 reconciliation을 우선 `dry_run=True`로 미리 보고, batch에서는 `DocumentStatus.DELETING` 같은 상태와 `limit`을 명시해 수행한다. orphan purge에는 SDK가 추측하지 않는 안전한 `storage_key`를 운영자가 제공해야 한다. ^[raw/articles/dms-core-examples-v0.3.0.md]

v0.4.0의 dry-run batch 결과는 불변 `ReconciliationPlan`으로 변환해 `execute_reconciliation_plan(...)`에 전달할 수 있다. 실행은 각 항목 직전에 현재 상태를 다시 점검하므로 preview 이후 stale해진 항목은 적용하지 않고 구조화된 항목 오류로 남긴다. 모든 시도는 `RecoveryAuditEvent`를 만들며 선택적 `recovery_audit_hook`은 best-effort라서 hook 실패가 복구 결과를 바꾸지는 않는다. 운영자는 actor를 전달하고 SDK hook 외부에도 durable audit 보존 정책을 설계해야 한다. ^[raw/articles/dms-core-wiki-api-reference-v0.4.0.md]

v0.4.0 예제는 dry-run result를 `to_plan()`으로 변환한 뒤 같은 actor를 사용해 실행하고 `scanned`·`applied`·`failed`를 운영 결과로 확인하는 흐름을 제시한다. audit hook 실패는 복구 결과를 바꾸지 않으므로 별도 모니터링이 필요하다. ^[raw/articles/dms-core-wiki-examples-v0.4.0.md]

## Operational questions

- DMS API는 SDK error를 어떤 HTTP 상태·오류 모델로 매핑할 것인가?
- SDK의 `check_health()`와 FastAPI readiness를 어떻게 함께 보고할 것인가?
- SDK close callback과 FastAPI shutdown 순서는 어떤 contract로 보장할 것인가?

## Source

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.4.0.md`
- `raw/articles/dms-core-wiki-examples-v0.4.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
