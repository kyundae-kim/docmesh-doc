---
title: Service Selection and Health Checks
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [service, validation, reliability, decision]
sources: [raw/articles/docmesh-py-core-sdk-2026-06-18.md, raw/articles/docmesh-py-core-api-2026-06-18.md, raw/articles/fastapi-core-api-2026-06-18.md]
confidence: medium
---

# Service Selection and Health Checks

`docmesh-py-core` SDK는 별도의 backend selector보다 환경변수 존재 여부를 기준으로 서비스를 선택하고, 시작 시점에 health check를 수행하는 패턴을 권장한다.

## 서비스 선택 규칙
- PostgreSQL 사용 시 `POSTGRES_*` 설정 제공
- SQLite 사용 시 `SQLITE_*` 설정 제공
- 코드에서는 `settings.sqlite is not None` 같은 형태로 자연스럽게 분기

이 접근은 문서/메타데이터 서버가 로컬 개발에서는 SQLite, 운영에서는 PostgreSQL을 쓰는 구조에 잘 맞는다. 전체 초기화 흐름은 [[sdk-consumption-pattern]]을 따른다.

## Health check 규칙
- PostgreSQL / SQLite: 기본적으로 `SELECT 1`
- MinIO: 기본적으로 `list_buckets()`
- NATS: `create_client("nats")`가 [[nats-connection-builder]]를 반환하므로 `await builder.connect()` 또는 `await builder.check()`를 사용
- 여러 서비스를 함께 점검할 때는 `check_all_services()`를 사용하고 `required_services`로 필수 의존성을 표시

## API 레퍼런스에서 추가로 확인된 계약
- `check_all_services(service_checks, required_services=None)`는 서비스별 성공 여부, 지연 시간, 오류를 집계한다.
- 필수 서비스가 실패하면 `HealthCheckError`를 발생시킨다.
- 결과 객체에는 전체 성공 여부(`HealthCheckResult.ok`)와 서비스별 상태 목록(`HealthCheckResult.services`)이 포함된다.
- `langfuse`는 비활성화 시 client 자체가 `None`일 수 있으므로 health check 집합을 만들 때 조건부로 포함해야 한다.

## fastapi-core readiness 관점에서 추가된 내용
`fastapi-core`의 `GET /health/readiness`는 Keycloak, Database, MinIO, Langfuse, docmesh healthcheck 경로를 조건부로 검사하고 실패 시 서비스별 `503` 응답을 반환한다. 즉 health check는 단순 내부 유틸리티가 아니라 실제 HTTP readiness 계약으로 승격될 수 있다.

## 운영 관점의 의미
문서 다운로드 기능은 DB보다 객체 저장소에 더 의존적일 수 있고, 메타데이터 조회 API는 DB 의존성이 더 크다. 따라서 readiness 기준을 하나로 뭉뚱그리기보다 핵심 서비스와 선택 서비스를 구분해야 한다. 이 판단은 [[fastapi-sdk-lifespan-integration]]과 [[application-lifecycle-and-readiness]]에서 startup/readiness 정책으로 연결된다.

## 자주 하는 실수
- `Settings()`만 만들고 검증 흐름을 생략
- `create_client("nats")` 결과를 동기 client처럼 사용
- `langfuse`가 항상 활성화된다고 가정
- health check 없이 실제 로직부터 실행

## 관련 페이지
- [[sdk-consumption-pattern]]
- [[service-factory-registry]]
- [[fastapi-sdk-lifespan-integration]]
- [[service-client-wrapper]]
- [[nats-connection-builder]]
- [[application-lifecycle-and-readiness]]
