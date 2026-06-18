---
title: FastAPI SDK Lifespan Integration
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [api, architecture, async, reliability]
sources: [raw/articles/docmesh-py-core-sdk-2026-06-18.md, raw/articles/fastapi-core-api-2026-06-18.md]
confidence: medium
---

# FastAPI SDK Lifespan Integration

`docmesh-py-core` 문서는 FastAPI 애플리케이션의 `lifespan`에서 설정 로드, registry 생성, health check, app state 저장, 종료 정리를 묶는 패턴을 권장한다.

## 핵심 흐름
- 시작 시 `load_settings(environ)` 호출
- `ServiceFactoryRegistry(settings)` 생성
- 설정된 저장소(PostgreSQL 또는 SQLite) health check 수행
- `app.state.settings`, `app.state.registry`에 공유 자원 저장
- 종료 시 `registry.close_all()` 호출

## 장점
- 잘못된 설정이나 연결 실패를 startup 시점에 즉시 드러낸다.
- 애플리케이션 전역 자원 관리 지점을 한곳으로 통일한다.
- 문서/메타데이터 API 라우터가 직접 외부 클라이언트를 만들지 않아도 된다.

## 문서 서버에 주는 의미
문서 업로드 API가 MinIO를 사용하고, 메타데이터 API가 PostgreSQL을 사용하며, 이벤트 발행이 NATS를 사용하는 구조라면 lifespan 단계에서 어떤 의존성이 준비되어야 하는지를 선언적으로 정리할 수 있다. 이 구조는 [[sdk-consumption-pattern]]의 서버 적용판이며, 실제 자원 생성 책임은 [[service-factory-registry]]가 가진다.

## fastapi-core와의 연결
`fastapi-core`는 이 패턴을 한 단계 더 구체화해 `create_managed_lifespan()`, `initialize_app_services()`, `shutdown_app_services()`, `create_app()` 조합으로 표준화한다. 즉 SDK 레벨의 일반 원칙이 실제 앱 팩토리/헬스 엔드포인트까지 내려간 사례로 [[application-lifecycle-and-readiness]]를 참고할 수 있다.

## 주의점
- readiness에 반드시 필요한 서비스와 optional 서비스를 구분해야 한다.
- NATS는 비동기 builder를 반환하므로 동기 DB client와 동일하게 다루면 안 된다. 세부 규칙은 [[service-selection-and-health-checks]]에 정리한다.

## 관련 페이지
- [[sdk-consumption-pattern]]
- [[service-factory-registry]]
- [[service-selection-and-health-checks]]
- [[application-lifecycle-and-readiness]]
