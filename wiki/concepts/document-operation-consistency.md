---
title: Document Operation Consistency
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [document, metadata, reliability, decision]
sources: [raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# Document Operation Consistency

`dms.sdk`는 object storage와 metadata store 사이의 불일치를 명시적으로 다루는 일관성 모델을 가진다.

## 업로드 semantics
- caller가 checksum을 주지 않으면 SDK가 SHA-256 hex digest를 계산한다.
- metadata 저장 전에 object를 먼저 저장한다.
- metadata 저장 실패 시 object 삭제 rollback을 시도한다.
- rollback까지 실패하면 `ConsistencyError`를 반환한다.

## 조회 semantics
- metadata가 없으면 `DocumentNotFoundError`
- metadata는 있지만 object가 없으면 `ConsistencyError`
- 큰 파일은 `get_document_content_stream()` 사용이 권장된다.

## 삭제 semantics
1. metadata status를 `deleting`으로 저장
2. object 삭제 시도
3. soft delete면 metadata를 `deleted`로 저장
4. hard delete면 metadata row 삭제

실패 시에는 `StorageError` 또는 `ConsistencyError`가 발생하며 metadata가 `deleting`이나 `failed` 상태로 남을 수 있다.

## 의미
문서 서버는 DB와 object storage를 단일 트랜잭션으로 묶기 어렵기 때문에, 이 문서는 실패 시 상태가 어떻게 남는지를 public contract로 고정한다. 운영 health check와는 별개로 애플리케이션 수준의 복구/재처리 설계가 필요하다는 뜻이다.

## 관련 페이지
- [[document-management-sdk]]
- [[document-metadata]]
- [[document-storage-key-policy]]
- [[service-selection-and-health-checks]]
