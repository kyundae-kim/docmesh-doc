---
title: dms-core usage patterns
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [dms-core, dms, document, storage, workflow, testing, integration]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-examples-v0.2.0.md]
confidence: medium
---

# dms-core usage patterns

DMS SDK의 기본 사용 흐름은 환경 또는 명시적 component로 SDK를 만들고, upload → metadata/content 조회 → delete → `close()` 순서로 리소스를 정리하는 것이다. 운영 코드에서는 `try/finally`로 SDK close를 보장해야 한다. ^[raw/articles/dms-core-examples-v0.2.0.md]

## Upload and retrieval

`UploadDocumentRequest`에 content, filename, content type과 선택적 metadata/created_by/checksum을 넣어 업로드한다. document ID를 생략하면 SDK가 생성한다. 대용량 콘텐츠는 전체 bytes를 가져오는 API보다 `get_document_content_stream(...)`와 `iter_chunks()`를 우선하고, stream도 반드시 close해야 한다. 공개 모델과 검증 세부 사항은 [[dms-core]] 및 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-api-v0.2.0.md]

## Assembly choices

일반 애플리케이션은 `create_sdk_from_environment(...)`를 사용하고, 테스트나 custom infrastructure 조립에는 `create_sdk_from_components(...)`를 사용한다. PostgreSQL/SQLite metadata store 모두 MinIO object store가 필요하며, 최소 환경변수와 startup health policy는 [[dms-core-configuration]]에서 관리한다. ^[raw/articles/dms-core-config-v0.2.0.md]

## HTTP integration boundary

FastAPI route는 request parsing, SDK error-to-HTTP mapping, streaming response 변환을 책임지고, SDK는 문서 도메인 작업을 담당하도록 분리한다. SDK 생성·close는 [[fastapi-core-app-assembly]]의 custom lifespan/state 경계와 맞춰야 하며, `fastapi-core`의 application layer 역할은 [[fastapi-core]]를 따른다.

## Error handling focus

서비스는 validation, duplicate document, configuration, storage, consistency, not-found error를 구분해 처리해야 한다. 특히 `chunk_size <= 0`은 `ValidationError`이며, stream/SDK close 누락은 리소스 정리 문제를 만들 수 있다. ^[raw/articles/dms-core-examples-v0.2.0.md]

## Sources

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
