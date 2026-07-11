---
title: fastapi-core usage patterns
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [fastapi, fastapi-core, api, deployment, testing, integration]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-messaging-v0.1.6.md]
confidence: medium
---

# fastapi-core usage patterns

`fastapi-core`의 예제는 DMS 서비스를 위한 네 가지 사용 패턴을 제시한다: 최소 app factory 사용, 인증·권한 dependency 주입, 설정 기반 서비스 선택 및 readiness 정책, custom lifespan을 통한 외부 자원 수명주기 관리. 문서는 구현과 테스트에서 확인된 패턴만 제시한다고 명시한다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Recommended DMS starting point

기본 서비스는 `create_app()`으로 시작하고, 인증 endpoint가 필요 없는 내부 서비스는 `include_auth_router=False`를 사용한다. 보호된 endpoint에는 `get_current_user`나 `require_permissions(...)`를 붙인다. 이 공개 표면과 route 계약은 [[fastapi-core]]에, 앱 상태와 lifecycle의 조립 경계는 [[fastapi-core-app-assembly]]에 정리되어 있다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Deployable composition

서비스별로 `AppConfig`를 직접 만들거나 환경변수로 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`를 지정한다. 선택 서비스는 degraded를 허용할 수 있고, 필수 서비스 실패는 503을 반환한다. `sqlite`만 선택해 settings와 readiness 대상을 제한하는 예제도 있으며, 이 설정 정책과 운영 guardrail은 [[fastapi-core-configuration]]에서 관리한다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

## Lifecycle and dependency choices

NATS 같은 외부 자원은 custom lifespan에서 초기화·정리하고, 구체 타입이 필요한 route에는 전용 dependency를 우선 사용한다. 공통 설정과 client-wrapper의 업스트림 계약은 [[docmesh-py-core]]에 연결된다. 기본 제공하지 않는 connection-state dependency나 publisher/subscriber helper는 [[fastapi-core-messaging-integration]]의 확장 경계를 따라 서비스 레이어에 둔다. ^[raw/articles/fastapi-core-messaging-v0.1.6.md]

## Version note

이 source는 Git tag `v0.1.6`에 고정되어 있지만 본문은 구현 반영본 `v0.2`라고 표기한다. API·config 문서의 `v0.5` 표기와 일치하지 않으므로, 예제 채택 전 대상 패키지와 테스트 스위트에서 현재 API를 확인해야 한다.

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-messaging-v0.1.6.md`
