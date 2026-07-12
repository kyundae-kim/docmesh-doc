---
title: fastapi-core
created: 2026-07-11
updated: 2026-07-12
type: entity
tags: [fastapi-core, fastapi, api, integration, architecture]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-main.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md]
confidence: medium
---

# fastapi-core

`fastapi-core`는 DMS FastAPI 서비스가 사용하는 공통 애플리케이션 계층이다. 이 API 문서 스냅샷에서는 공개 루트 API로 `create_app`을 제공하며, 앱 조립, 공통 라우터, 설정 로딩, 인증과 외부 서비스 클라이언트 접근을 묶는다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Public surface

- `create_app(config=None, settings=None, lifespan=None, include_auth_router=True)`가 `FastAPI` 인스턴스를 구성한다.
- 앱 상태에 config, settings, service-client map, readiness 정책, 필요 시 auth provider를 저장한다.
- 기본으로 health router를 포함하고, 선택적으로 auth router를 포함한다.
- `POST /token`, `GET /user`, `GET /health/liveness`, `GET /health/readiness`가 문서화된 기본 HTTP 표면이다.

## DMS deployment relevance

DMS 애플리케이션은 [[fastapi-core-app-assembly]]를 통해 lifecycle·CORS·logging·readiness를 일관되게 설정할 수 있다. 서비스별 실제 연결과 설정 계약은 [[docmesh-py-core]]에 위임되며, 필요한 구체 타입은 전용 dependency로 가져오고 일반 lookup에는 `get_service_client(...)`를 사용한다.

## DMS core boundary

이 위키의 목표 아키텍처에서는 [[dms-core]]가 문서 도메인 SDK를, `fastapi-core`가 FastAPI application layer를 맡는다. 문서 SDK의 lifecycle·health·오류를 HTTP 경계에 연결하는 구체 adapter 계약은 [[dms-core-document-lifecycle]] 및 이후 통합 source에서 확정해야 한다.

## Configuration boundary

설정은 [[fastapi-core-configuration]]에서 정리한 `AppConfig`와 `ServiceConfigs`로 나뉜다. `v0.2.0` 설정 문서는 PostgreSQL을 서비스 설정·개발 fallback·전용 dependency 범위에 명시적으로 포함한다. 운영 배포에서는 앱 공개 경로·CORS·readiness 정책과 외부 서비스 secret을 개발 fallback에 의존하지 않고 명시적으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

## Usage patterns

실제 시작·인증·readiness override·custom lifespan·선택 서비스 로딩의 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리한다. `v0.2.0` 예제는 보호 route를 app에 실제 포함하는 형태와 PostgreSQL DSN/개별 접속 설정의 선택을 명시한다. 문서 내부 버전 표기와 Git tag의 관계는 배포 대상 패키지에서 검증해야 한다. ^[raw/articles/fastapi-core-examples-v0.2.0.md]

## Version note

Git tag `v0.1.6`와 `main`의 API 문서를 각각 수집했으며, 2026-07-12 수집 시 두 raw 본문의 SHA-256은 동일했다. 두 URL은 동일한 API 스냅샷을 제공하지만, `main`은 변할 수 있으므로 이 동등성은 수집 시점의 사실이다. 문서 본문은 스스로를 2026-07-03의 구현 반영본 `v0.5`로 표기한다. 배포 전에는 설치 패키지의 실제 버전과 API를 별도 검증해야 한다. ^[raw/articles/fastapi-core-api-main.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-main.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.2.0.md`
