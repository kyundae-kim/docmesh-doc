---
title: fastapi-core
created: 2026-07-11
updated: 2026-07-15
type: entity
tags: [fastapi-core, fastapi, api, integration, architecture]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-main.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-examples-v0.2.0.md, raw/articles/fastapi-core-examples-v0.3.0.md]
confidence: medium
---

# fastapi-core

`fastapi-core`는 DMS FastAPI 서비스가 사용하는 공통 애플리케이션 계층이다. 이 API 문서 스냅샷에서는 공개 루트 API로 `create_app`을 제공하며, 앱 조립, 공통 라우터, 설정 로딩, 인증과 외부 서비스 클라이언트 접근을 묶는다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Public surface

- `v0.3.0`의 `create_app(config=None, settings=None, lifespan=None, include_auth_router=True, resources=())`는 `FastAPI` 인스턴스를 구성한다. `resources`는 추가 외부 자원의 생성·readiness·종료를 선언하는 `ManagedResource` sequence다. ^[raw/articles/fastapi-core-api-v0.3.0.md]
- package root는 `create_app` 외에 `ManagedResource`, `ReadinessCheckSpec`, `ErrorMapping`, `register_readiness_check`, `register_error_mapper`를 re-export한다. 앱 상태의 readiness 단일 통합 지점은 `app.state.readiness_registry`이며, 이전 alias(`readiness_checks`, `readiness_services`, `required_services`)는 제공하지 않는다. ^[raw/articles/fastapi-core-api-v0.3.0.md]
- 앱 상태에 config, settings, `service_runtime`, service-client map, readiness/resource registry, 필요 시 auth provider를 저장한다.
- 기본으로 health router를 포함하고, 선택적으로 auth router를 포함한다.
- `POST /token`, `GET /user`, `GET /health/liveness`, `GET /health/readiness`가 문서화된 기본 HTTP 표면이다.

## DMS deployment relevance

DMS 애플리케이션은 [[fastapi-core-app-assembly]]를 통해 lifecycle·CORS·logging·readiness를 일관되게 설정할 수 있다. 서비스별 실제 연결과 설정 계약은 [[docmesh-py-core]]에 위임되며, 필요한 구체 타입은 전용 dependency로 가져오고 일반 lookup에는 `get_service_client(...)`를 사용한다. DMS aggregate health나 SDK lifecycle처럼 package 기본 서비스 client 범위를 넘어서는 자원은 `ManagedResource`와 `get_resource(name)` 또는 custom lifespan으로 명시적으로 통합해야 한다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

## DMS core boundary

이 위키의 목표 아키텍처에서는 [[dms-core]]가 문서 도메인 SDK를, `fastapi-core`가 FastAPI application layer를 맡는다. 문서 SDK의 lifecycle·health·오류를 HTTP 경계에 연결하는 구체 adapter 계약은 [[dms-core-document-lifecycle]] 및 이후 통합 source에서 확정해야 한다.

## Configuration boundary

설정은 [[fastapi-core-configuration]]에서 정리한 `AppConfig`와 `ServiceConfigs`로 나뉜다. `v0.3.0`은 service alternatives, startup healthcheck, readiness timeout, enabled/required service 집합을 `AppConfig`에 두고 외부 서비스 설정은 Py Core loader/assembly로 위임한다. 운영 배포에서는 앱 공개 경로·CORS·readiness 정책과 외부 서비스 secret을 개발 fallback에 의존하지 않고 명시적으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.3.0.md]

## Usage patterns

실제 시작·인증·readiness override·custom lifespan·선택 서비스 로딩의 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리한다. `v0.3.0` 예제는 `ManagedResource`, typed readiness, role/scope/permission dependency, correlation-ID problem-details 확장을 포함한다. 문서 내부 버전 표기와 Git tag의 관계는 배포 대상 패키지에서 검증해야 한다. ^[raw/articles/fastapi-core-examples-v0.3.0.md]

## Version note

Git tag `v0.1.6`와 `main`의 API 문서를 각각 수집했으며, 2026-07-12 수집 시 두 raw 본문의 SHA-256은 동일했다. 두 URL은 동일한 API 스냅샷을 제공하지만, `main`은 변할 수 있으므로 이 동등성은 수집 시점의 사실이다. `v0.3.0` API snapshot은 body hash가 다르며 managed resource·typed readiness registry·problem-details/correlation-ID extension 표면을 추가로 문서화한다. 이 작업공간의 `pyproject.toml`은 `fastapi-core`를 직접 선언하지 않고 2026-07-15 runtime import도 불가능했으므로, v0.3.0 계약은 현재 환경에서 실행 검증되지 않은 upstream reference다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-main.md`
- `raw/articles/fastapi-core-api-v0.3.0.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-config-v0.3.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.2.0.md`
- `raw/articles/fastapi-core-examples-v0.3.0.md`
