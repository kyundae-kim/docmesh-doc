---
title: DocumentMetadata
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [document, metadata, schema, validation]
sources: [raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# DocumentMetadata

`DocumentMetadata`는 `dms.sdk`가 문서 파일과 분리해서 관리하는 메타데이터 레코드다.

## 핵심 필드
- `document_id`
- `original_filename`
- `content_type`
- `file_size`
- `storage_key`
- `status`
- `created_at`, `updated_at`
- optional: `checksum`, `deleted_at`, `created_by`, `extra_metadata`

## 상태 모델
`DocumentStatus`는 다음 값을 가진다.
- `uploaded`
- `available`
- `deleting`
- `deleted`
- `failed`

현재 upload 성공 직후의 기본 상태는 `available`이다.

## 의미
문서 서버에서 실제 바이너리 저장과 메타데이터 저장은 분리되어야 하며, 이 구조가 문서 상태 추적, soft delete, checksum 검증, 작성자 기록을 가능하게 한다. 저장 키 규칙은 [[document-storage-key-policy]]와 연결되고, 업로드/삭제 시 상태 전이는 [[document-operation-consistency]]에서 중요하다.

## 관련 페이지
- [[document-management-sdk]]
- [[document-storage-key-policy]]
- [[document-operation-consistency]]
- [[service-selection-and-health-checks]]
