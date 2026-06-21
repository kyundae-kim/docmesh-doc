---
title: DocumentManagementSDK
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [api, service, document, metadata]
sources: [raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# DocumentManagementSDK

`DocumentManagementSDK`는 문서 업로드, 메타데이터 조회, 콘텐츠 조회/스트리밍, 삭제, 인증 helper, health check, 종료 처리를 하나의 public protocol로 노출하는 `dms.sdk`의 핵심 인터페이스다.

## 공개 메서드
- `fetch_access_token(scope=None)`
- `get_authenticated_user(token)`
- `upload_document(request)`
- `get_document_metadata(document_id)`
- `get_document_content(document_id)`
- `get_document_content_stream(document_id, chunk_size=65536)`
- `delete_document(document_id, hard_delete=False)`
- `check_health()`
- `close()`

## 생성 경로
- `create_sdk(environ, logger=...)` 형태의 환경 기반 생성
- `create_sdk(metadata_store=..., object_store=..., auth_service=..., ...)` 형태의 명시적 dependency 주입
- `create_sdk_from_environment(env)` alias

## 의미
이 인터페이스는 문서 저장소와 메타데이터 저장소를 묶어 애플리케이션이 단일 SDK 경계로 문서 도메인을 다루게 만든다. 업로드/삭제 시 일관성 정책은 [[document-operation-consistency]]에 연결되고, 메타데이터 구조는 [[document-metadata]]에서 구체화된다.

## 관련 페이지
- [[document-metadata]]
- [[document-operation-consistency]]
- [[sdk-consumption-pattern]]
- [[service-selection-and-health-checks]]
