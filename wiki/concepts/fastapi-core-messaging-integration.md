---
title: FastAPI Core Messaging Integration
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [async, api, architecture, service]
sources: [raw/articles/fastapi-core-messaging-2026-06-18.md, raw/articles/fastapi-core-api-2026-06-18.md]
confidence: medium
---

# FastAPI Core Messaging Integration

`fastapi-core`의 NATS 통합은 두 층으로 나뉜다: 순수 core helper(`fastapi_core.core.messaging`)와 FastAPI dependency helper(`fastapi_core.dependencies.messaging`).

## 두 층의 역할
- core helper: NATS client 생성, subject 검증/조합, JSON publish/subscribe helper 제공
- FastAPI dependency helper: `app.state.nats_client` 캐시와 docmesh registry 기반 lazy singleton 조회 제공

## FastAPI 계층의 규칙
- `set_nats_client(app, client=...)`는 전달된 클라이언트를 그대로 state에 저장한다.
- `set_nats_client(app, config=...)`는 `get_required_docmesh_service_async(app, "nats_client", config=config)` 결과를 저장한다.
- `get_nats_client()`는 state 캐시 우선, 없으면 registry로 생성 후 저장한다.
- 함수형 dependency 정책을 유지하며 callable class API는 공개하지 않는다.

## lifespan과의 연결
- managed lifespan에서는 `settings.lifecycle.eager_nats = true`일 때 startup에서 선행 초기화할 수 있다.
- 수동 lifespan에서는 `set_nats_client()` 후 종료 시 `app.state.nats_client.drain()`을 호출하는 패턴이 권장된다.

## 문서 서버에서의 의미
문서 업로드 완료, 메타데이터 갱신, 색인 트리거 같은 도메인 이벤트를 발행하는 REST API라면 메시징 초기화와 앱 수명주기를 분리해 생각할 수 없다. 이 페이지는 [[application-lifecycle-and-readiness]]와 [[nats-event-subjects]] 사이의 통합 지점을 설명한다.

## 관련 페이지
- [[application-lifecycle-and-readiness]]
- [[nats-event-subjects]]
- [[fastapi-core-dependency-policy]]
