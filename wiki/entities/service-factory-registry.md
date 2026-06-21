---
title: ServiceFactoryRegistry
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [service, repository, architecture, api]
sources: [raw/articles/docmesh-py-core-sdk-2026-06-18.md, raw/articles/docmesh-py-core-api-2026-06-18.md]
confidence: medium
---

# ServiceFactoryRegistry

`ServiceFactoryRegistry`는 `docmesh-py-core` SDK에서 서비스별 클라이언트 생성을 한곳으로 모으는 핵심 엔트리 포인트다.

## 역할
- `load_settings()`로 검증된 설정을 입력으로 받는다.
- `create_client("postgres")`, `create_client("sqlite")`, `create_client("minio")`, `create_client("nats")` 같은 서비스별 생성 책임을 캡슐화한다.
- 종료 시 `close_all()`로 연결, 엔진, 클라이언트 정리를 일관되게 수행한다.

## API 계약에서 추가로 확인된 내용
공개 API 문서 기준으로 주요 메서드는 `create_client(service_name)`, `create_clients(services)`, `close_all()`이다. 지원 서비스명은 `keycloak`, `postgres`, `sqlite`, `minio`, `milvus`, `ollama`, `langfuse`, `nats`이며, 지원하지 않는 이름은 `KeyError`를 발생시킨다.

서비스별 반환 규칙도 중요하다.
- 대부분의 서비스는 [[service-client-wrapper]]를 반환한다.
- `langfuse`는 비활성화 시 `None`일 수 있다.
- `nats`는 연결된 클라이언트가 아니라 [[nats-connection-builder]]를 반환한다.

## 왜 중요한가
문서/메타데이터 서버처럼 PostgreSQL, MinIO, NATS, Keycloak 등 여러 외부 의존성을 함께 쓰는 FastAPI 애플리케이션에서는 초기화 코드가 쉽게 분산된다. 이 레지스트리는 그런 초기화 로직을 애플리케이션 코드에서 분리해 [[sdk-consumption-pattern]]과 [[fastapi-sdk-lifespan-integration]]을 단순하게 만든다.

## 사용 패턴
1. `settings = load_settings(environ)`
2. `registry = ServiceFactoryRegistry(settings)`
3. 필요한 서비스만 `create_client()`로 생성
4. 시작 시 `check()` 또는 async health 확인
5. 종료 시 `registry.close_all()` 호출

## 주의점
- 모든 서비스를 한 번에 올리는 방식보다 실제 사용하는 서비스만 명시적으로 생성하는 방식이 권장된다.
- `create_client("nats")`는 연결된 동기 클라이언트가 아니라 [[nats-connection-builder]]를 반환하므로 비동기 흐름을 전제로 다뤄야 한다. 이 차이는 [[service-selection-and-health-checks]]에서 별도로 정리한다.
- `langfuse`처럼 optional 반환값이 있는 서비스는 `None` 가능성을 호출부에서 처리해야 한다.

## 관련 페이지
- [[sdk-consumption-pattern]]
- [[fastapi-sdk-lifespan-integration]]
- [[service-selection-and-health-checks]]
- [[service-client-wrapper]]
- [[nats-connection-builder]]
