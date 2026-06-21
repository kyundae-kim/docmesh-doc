---
title: NATS Event Subjects
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [async, api, validation, convention]
sources: [raw/articles/fastapi-core-api-2026-06-18.md, raw/articles/fastapi-core-messaging-2026-06-18.md]
confidence: medium
---

# NATS Event Subjects

`fastapi-core`는 메시징 helper에서 이벤트 subject 형식을 `<domain>.<entity>.<action>`으로 표준화한다.

## 핵심 API
- `validate_event_subject(subject)`
- `build_event_subject(domain, entity, action)`
- `publish_event(client, subject, payload)`
- `subscribe_event(...)`
- `subscribe_queue_event(...)`

## 규칙
- 각 segment는 소문자, 숫자, 하이픈만 허용한다.
- 반드시 3 segment 형식이어야 한다.
- 형식이 잘못되면 `build_event_subject()`는 `ValueError`를 발생시킨다.
- publish 시 payload는 compact JSON UTF-8 bytes로 인코딩된다.

## 메시징 가이드에서 보강된 내용
- 올바른 예: `orders.order.created`, `billing.invoice.updated`, `documents.file.deleted`
- 잘못된 예: 2-segment subject, 대문자 포함 subject, 4-segment subject
- queue 기반 소비는 `subscribe_queue_event()`로 명시한다.

## 문서 서버에서의 의미
문서 생성/갱신/삭제, 메타데이터 색인, 비동기 후처리 같은 이벤트를 발행할 때 subject 네이밍 규칙이 중요하다. 이 규칙이 있으면 이벤트 소비자와 프로듀서 간 계약이 명확해지고, [[nats-connection-builder]]와 함께 메시징 설계의 기반이 된다.

## 관련 페이지
- [[nats-connection-builder]]
- [[fastapi-core-messaging-integration]]
- [[domain-event-payload-conventions]]
- [[application-lifecycle-and-readiness]]
