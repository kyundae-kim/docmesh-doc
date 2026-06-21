---
title: ServiceClientWrapper
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [service, api, reliability, convention]
sources: [raw/articles/docmesh-py-core-api-2026-06-18.md]
confidence: medium
---

# ServiceClientWrapper

`ServiceClientWrapper`는 Keycloak, PostgreSQL, SQLite, MinIO, Milvus, Ollama, Langfuse 같은 서비스 SDK 위에 공통 `ping()` / `check()` / `close()` 인터페이스를 제공하는 래퍼다.

## 역할
- 서비스별 SDK를 공통 인터페이스 아래 정렬한다.
- 원본 client 메서드는 그대로 위임한다.
- 기본 `check()` 동작을 서비스 유형별로 표준화한다.

## 기본 health check 계약
- Keycloak: `fetch_access_token()`
- PostgreSQL / SQLite: `SELECT 1`
- MinIO: `list_buckets()`
- Milvus: `list_collections()`
- Ollama: `ps()`
- Langfuse: `auth_check()`

## 문서 서버에서의 의미
문서 API가 여러 외부 의존성을 동시에 쓰더라도 상태 점검 인터페이스를 통일할 수 있다. 따라서 [[service-selection-and-health-checks]]에서 서비스별 readiness를 비교 가능하게 만들고, [[service-factory-registry]]가 생성한 결과를 동일한 방식으로 운영 코드에서 다룰 수 있다.

## 관련 페이지
- [[service-factory-registry]]
- [[service-selection-and-health-checks]]
- [[sdk-consumption-pattern]]
