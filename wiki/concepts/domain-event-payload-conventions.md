---
title: Domain Event Payload Conventions
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [async, schema, convention, validation]
sources: [raw/articles/fastapi-core-messaging-2026-06-18.md]
confidence: medium
---

# Domain Event Payload Conventions

`fastapi-core` 메시징 가이드는 subject 규칙뿐 아니라 이벤트 payload 관례도 제시한다.

## 권장 관례
- `event_id` 같은 멱등성 키를 포함한다.
- payload에 `event` 또는 `schema_version` 필드를 포함한다.
- subject는 helper로 생성해 규칙 위반을 방지한다.

## 예시 구조
- `event_id`
- `event`
- 도메인 식별자 예: `order_id`, `customer_id`

## 문서 서버에서의 의미
문서/메타데이터 서버에서 `documents.file.created`, `documents.metadata.updated` 같은 이벤트를 발행할 때 중복 처리와 스키마 진화를 고려해야 한다. 이 관례는 비동기 후처리, 검색 색인, 감사 이벤트 수집에 특히 중요하다.

## 관련 페이지
- [[nats-event-subjects]]
- [[fastapi-core-messaging-integration]]
- [[service-selection-and-health-checks]]
