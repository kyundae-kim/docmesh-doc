---
title: fastapi-core application assembly
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [fastapi, fastapi-core, architecture, deployment, configuration, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md]
confidence: medium
---

# fastapi-core application assembly

`fastapi-core`의 `create_app(...)`은 DMS FastAPI 서비스의 공통 조립 지점이다. config와 settings가 생략되면 각각 앱 설정과 선택 서비스 설정을 로딩하고, service-client map·logging·CORS·OAuth2 token URL·기본 health router를 구성한다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

## Lifecycle and state

조립 단계에서 구성된 config, settings, service clients, readiness metadata는 `app.state`에 보관된다. custom lifespan은 내부 wrapper가 감싸며, 종료 때 service client 정리를 보장한다. 이 구조는 [[fastapi-core]]를 서비스 HTTP 계층으로 두고 [[docmesh-py-core]]의 외부 의존성 설정/클라이언트를 재사용하는 경계를 만든다. ^[raw/articles/fastapi-core-api-v0.1.6.md]

외부 자원은 custom lifespan으로 초기화·종료하고, 인증 endpoint가 불필요한 내부 서비스는 auth router를 제외하는 실제 패턴이 [[fastapi-core-usage-patterns]]에 있다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Readiness policy

Readiness는 활성/필수 서비스와 check callable을 기준으로 실행된다. 체크가 없으면 `ok`, 필수 서비스 실패면 503 `error`, 선택 서비스만 실패하면 200 `degraded`를 반환한다. DMS 배포 시 required-services 정책과 readiness 병렬 실행 여부는 서비스 특성에 맞게 명시해야 한다.

이 정책의 환경변수와 두 설정 계층은 [[fastapi-core-configuration]]에 정리한다. [[fastapi-core]]가 `AppConfig`를 소비해 state와 middleware를 구성한 뒤 readiness metadata를 생성하므로, service selection과 required service selection은 함께 검토해야 한다. ^[raw/articles/fastapi-core-config-v0.1.6.md]

NATS를 포함한 메시징은 app assembly에서 선택 가능한 service client이며, 연결 객체/route를 직접 제공하는 표면은 아니다. 메시징의 readiness와 custom-lifespan 확장 경계는 [[fastapi-core-messaging-integration]]에서 다룬다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

DMS SDK를 HTTP 서비스에 붙일 때는 [[dms-core]]의 생성·health·close 흐름을 custom lifespan/state 경계에 배치하는 방안을 검토한다. 그 lifecycle과 정합성 규칙은 [[dms-core-document-lifecycle]]에 정리한다.

## Open questions

- DMS에서 활성화해야 할 서비스와 필수 서비스의 정확한 목록은 무엇인가?
- DMS 고유 lifecycle 자원은 custom lifespan과 `app.state` 중 어떤 경계로 관리할 것인가?
- 문서에 없는 NATS 연결 상태 dependency가 필요한가?

## Source

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
