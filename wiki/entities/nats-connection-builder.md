---
title: NatsConnectionBuilder
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [async, service, api, reliability]
sources: [raw/articles/docmesh-py-core-api-2026-06-18.md]
confidence: medium
---

# NatsConnectionBuilder

`NatsConnectionBuilder`는 `create_client("nats")`가 반환하는 비동기 연결 빌더다. 연결된 동기 클라이언트가 아니라는 점이 가장 중요한 계약이다.

## 역할
- NATS 연결 인자를 보관한다.
- `connect()` 호출 시 실제 연결을 생성한다.
- `check()`는 연결 후 `flush()`까지 수행한다.

## 핵심 규칙
- 반드시 `await builder.connect()` 또는 `await builder.check()`로 사용한다.
- 동기 DB client처럼 즉시 메서드를 호출하는 방식은 잘못된 사용이다.

## 문서 서버에서의 의미
문서 업로드 완료 이벤트, 메타데이터 변경 이벤트, 비동기 후처리 트리거를 NATS로 발행/소비하는 시스템이라면 이 비동기 경계를 명확히 이해해야 한다. 이 규칙은 [[service-selection-and-health-checks]]와 [[fastapi-sdk-lifespan-integration]]에서 startup 및 readiness 정책으로 이어진다.

## 관련 페이지
- [[service-selection-and-health-checks]]
- [[fastapi-sdk-lifespan-integration]]
- [[service-factory-registry]]
