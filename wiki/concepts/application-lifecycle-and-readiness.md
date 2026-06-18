---
title: Application Lifecycle and Readiness
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [reliability, async, service, architecture]
sources: [raw/articles/fastapi-core-api-2026-06-18.md, raw/articles/fastapi-core-config-2026-06-18.md]
confidence: medium
---

# Application Lifecycle and Readiness

`fastapi-core`는 `initialize_app_services()`, `shutdown_app_services()`, `create_managed_lifespan()`, `create_app()`를 통해 앱 수명주기와 readiness 정책을 조립한다.

## 생성 흐름
`create_app()`의 기본 순서는 다음과 같다.
1. `config` 기본값 보정
2. `settings` 기본값 보정
3. `lifespan` 기본값으로 `create_managed_lifespan(config, settings)` 사용
4. 로깅 설정
5. `FastAPI(...)` 생성
6. `config`, `settings`를 state에 저장
7. 미들웨어/에러 핸들러/라우터 등록

## 초기화/종료 책임
- `initialize_app_services()`는 registry bootstrap, registry-managed 서비스 eager init, `async_milvus_client` 직접 초기화를 수행한다.
- `shutdown_app_services()`는 `docmesh_registry.close_all()`, `nats_client.drain()`, `async_milvus_client.close()`, `milvus_client.close()`, `db_engine.dispose()`, `langfuse_client.flush()` 등을 시도한다.

## 설정 문서에서 확인된 lifecycle 해석 규칙
- `resolve_lifecycle_policy(settings)`는 `eager_keycloak/database/minio/langfuse`가 `null`이면 대응 `health.check_*` 값을 상속한다.
- `eager_milvus`, `eager_async_milvus`, `eager_ollama`, `eager_nats`는 명시값 그대로 사용한다.
- 관리 대상 서비스 중 하나라도 eager-init 대상이면 startup에서 docmesh registry를 초기화한다.
- `async_milvus_client`만 예외적으로 registry 대신 직접 생성된다.

## readiness 엔드포인트
`GET /health/readiness`는 Keycloak, Database, MinIO, Langfuse, docmesh healthcheck 통합 경로를 조건부로 검사한다. 실패 시 서비스별 `503` 응답을 돌려준다.

## 문서 서버에서의 의미
문서 업로드/다운로드와 메타데이터 조회가 여러 외부 서비스에 의존한다면, startup/lifespan과 readiness를 분리 설계하는 것이 중요하다. 이 구조는 [[fastapi-sdk-lifespan-integration]]과 유사하지만, `fastapi-core`는 더 구체적으로 엔드포인트와 종료 시퀀스까지 표준화한다.

## 관련 페이지
- [[fastapi-sdk-lifespan-integration]]
- [[service-selection-and-health-checks]]
- [[fastapi-core-dependency-policy]]
- [[fastapi-core-layered-configuration]]
