---
title: fastapi-core
created: 2026-07-11
updated: 2026-07-11
type: entity
tags: [fastapi-core, fastapi, api, integration, architecture]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-examples-v0.1.6.md]
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

## Configuration boundary

설정은 [[fastapi-core-configuration]]에서 정리한 `AppConfig`와 `ServiceConfigs`로 나뉜다. 운영 배포에서는 앱 공개 경로·CORS·readiness 정책과 외부 서비스 secret을 개발 fallback에 의존하지 않고 명시적으로 주입해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

## Usage patterns

실제 시작·인증·readiness override·custom lifespan·선택 서비스 로딩의 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리한다. 예제 문서는 API/config 문서와 같은 Git source tag를 가리키지만 문서 내부 버전 표기가 다르므로, 배포 대상 패키지에서 검증해야 한다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Version note

수집 URL은 Git tag `v0.1.6`를 가리키지만, 문서 본문은 스스로를 2026-07-03의 구현 반영본 `v0.5`로 표기한다. 이 위키에서는 URL이 고정한 소스 스냅샷을 기준으로 삼고, 배포 전 설치 패키지의 실제 버전과 API를 별도 검증해야 한다.

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
