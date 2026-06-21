---
title: Document Storage Key Policy
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [document, validation, minio, convention]
sources: [raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# Document Storage Key Policy

`dms.sdk`는 object storage key를 caller가 아니라 SDK가 생성하도록 강제한다.

## 형식
- `documents/{document_id}/{sanitized_filename}`

## 정규화 규칙
- `filename.strip()` 적용
- `..`는 `.`로 치환
- `/`는 `-`로 치환
- `\\`는 `-`로 치환
- 결과가 `.` 또는 빈 문자열이면 요청은 거부된다.

## 충돌 정책
- 동일 `document_id` 재사용은 `DuplicateDocumentError`
- 동일 filename은 다른 `document_id`에서는 허용

## 의미
이 정책은 경로 주입(path traversal)과 사용자 제공 파일명에 의한 저장소 구조 오염을 줄인다. 또한 object key 생성 규칙을 SDK 내부에 고정함으로써 API 서버가 MinIO/S3 key naming을 중복 구현하지 않아도 된다.

## 관련 페이지
- [[document-metadata]]
- [[document-management-sdk]]
- [[document-operation-consistency]]
- [[sensitive-data-masking]]
