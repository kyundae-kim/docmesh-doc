---
title: dms-core messaging boundary
created: 2026-07-11
updated: 2026-07-15
type: concept
tags: [dms-core, dms, messaging, integration, architecture]
sources: [raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-messaging-v0.2.0.md, raw/articles/fastapi-core-messaging-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.2.0.md]
confidence: medium
---

# dms-core messaging boundary

현재 `dms-core`는 동기식 Python SDK이며 message broker publish/subscribe, event payload serialization, async queue, webhook을 공개 API로 제공하지 않는다. `NATS_SERVERS`가 런타임에 필요할 수 있는 경우도 `docmesh-py-core` 설정 검증의 요구사항일 뿐, SDK가 NATS를 사용한다는 근거는 아니다.

v0.3.0 DMS `.env.example` 기준으로는 Keycloak, NATS, Langfuse, Milvus, Ollama 설정이 템플릿에 포함되지 않으며 DMS SDK 조립 대상도 아니다. 별도 hosting application 또는 upstream loader가 이를 요구할 수 있다는 가능성과 SDK의 직접 설정 범위는 구분해야 한다. ^[raw/articles/dms-core-config-v0.3.0.md]

## Hosting application versus SDK

[[fastapi-core-messaging-integration]]은 FastAPI application layer가 NATS를 선택 서비스, readiness, lifecycle 확장 지점으로 다룰 수 있음을 설명한다. `enabled_services` metadata만으로 NATS check가 보장되는 것은 아니며 settings와 client 생성이 추가 조건이다. 이는 [[dms-core]] SDK 자체에 메시징 계약이 존재한다는 뜻이 아니다. DMS SDK storage/health 설정과 upstream loader의 경계는 [[dms-core-configuration]]에서 확인한다. ^[raw/articles/fastapi-core-messaging-v0.2.0.md]

## Extension trigger

DMS SDK에 event publisher/consumer, message model, retry/idempotency/ordering policy, broker topic/queue contract가 추가될 때에만 이 문서를 실제 메시지 계약으로 확장한다. 그때에는 SDK 도메인 event와 FastAPI hosting layer의 NATS lifecycle을 별도 계약으로 문서화해야 한다.

## Sources

- `raw/articles/dms-core-messaging-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.2.0.md`
