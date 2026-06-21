---
title: SDK Consumption Pattern
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [api, architecture, service, convention]
sources: [raw/articles/docmesh-py-core-sdk-2026-06-18.md, raw/articles/docmesh-py-core-config-2026-06-18.md, raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# SDK Consumption Pattern

`docmesh-py-core` 및 이를 기반으로 한 `dms.sdk` 소비 프로젝트에서 권장하는 표준 흐름은 설정 로드 → 서비스 조립 → 선택적 health check → 업무 메서드 호출 → 종료 정리 순서다.

## 표준 흐름
1. 환경변수 준비
2. `load_settings()` 호출로 설정 로드와 검증 수행
3. `ServiceFactoryRegistry` 또는 `create_sdk(environ)`로 서비스 조립
4. 필요한 서비스만 생성하거나 SDK protocol로 묶인 메서드 호출
5. `check()` / `check_health()` 또는 실제 메서드로 연결성 검증
6. 종료 시 `registry.close_all()` 또는 `sdk.close()` 호출

## 설정 측면에서 추가된 의미
이 흐름의 첫 단계는 단순 파싱이 아니라 환경변수 정책 집행이다. 공백 문자열 처리, boolean 해석, 숫자 범위 검증, 서비스별 조건부 필수값 확인, 운영 환경의 TLS/인증서 검증 정책이 모두 `load_settings()` 이전/내부 계약의 일부다. 즉 [[settings]]와 [[environment-variable-configuration]]을 이해해야 이 흐름을 안전하게 사용할 수 있다.

## dms SDK가 추가한 소비 패턴
- 환경 기반 factory는 MinIO 존재 확인, PostgreSQL 우선/SQLite fallback, optional Keycloak 조립, startup health check까지 포함한다.
- 테스트나 경량 조립 경로에서는 명시적 dependency 주입으로 `metadata_store`, `object_store`, `auth_service` 등을 넣을 수 있다.
- 종료 시 `close_callbacks`와 `registry.close_all()`을 통해 정리 책임을 밖으로 새지 않게 한다.

## 의미
이 패턴은 문서/메타데이터 서버에서 반복되는 설정 로드, 외부 서비스 클라이언트 생성, 헬스 체크, 종료 정리를 공통화한다. 따라서 라우터나 서비스 계층은 비즈니스 로직에 집중하고 인프라 초기화는 [[service-factory-registry]] 또는 [[document-management-sdk]] 경계에 위임하게 된다.

## 적용 대상
- FastAPI 같은 API 서버
- background worker / consumer
- 배치 / CLI 작업
- PostgreSQL, SQLite, MinIO, NATS, Keycloak을 조합하는 애플리케이션

## 설계 시사점
문서 서버를 설계할 때도 저장소 선택, 인증, 비동기 메시징을 애플리케이션 진입 시점에서 일관되게 조립하는 것이 중요하다. 이 점에서 [[fastapi-sdk-lifespan-integration]]은 API 서버에 맞는 구체적 배치 예시이고, [[service-selection-and-health-checks]]는 어떤 서비스를 필수/선택으로 둘지 결정하는 운영 규칙을 제공한다. 문서 도메인 API 계약 자체는 [[document-management-sdk]]와 [[document-operation-consistency]]에서 더 구체화된다.

## 관련 페이지
- [[service-factory-registry]]
- [[document-management-sdk]]
- [[document-operation-consistency]]
- [[fastapi-sdk-lifespan-integration]]
- [[service-selection-and-health-checks]]
- [[settings]]
- [[environment-variable-configuration]]
