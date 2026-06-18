# Wiki Index

> Content catalog. Every wiki page listed under its type with a one-line summary.
> Read this first to find relevant pages for any query.
> Last updated: 2026-06-18 | Total pages: 20

## Entities
<!-- Alphabetical within section -->
- [[env-config]] — `fastapi-core` 앱의 런타임 환경설정을 담는 state 기반 설정 객체.
- [[keycloak-auth-provider]] — `fastapi-core`에서 Keycloak 인증, 토큰 검증, 사용자 변환을 담당하는 provider.
- [[keycloak-auth-service]] — Keycloak access token 발급과 JWT 검증/사용자 정보 추출을 담당하는 공개 인증 API.
- [[nats-connection-builder]] — `create_client("nats")`가 반환하는 비동기 NATS 연결 빌더와 그 사용 계약.
- [[service-client-wrapper]] — 서비스 SDK 위에 공통 `check()`/`close()` 인터페이스를 제공하는 래퍼.
- [[service-factory-registry]] — SDK에서 서비스별 클라이언트 생성과 종료 정리를 한곳으로 모으는 핵심 엔트리 포인트.
- [[service-settings]] — 서비스 초기화 정책과 auth/health/lifecycle 제어를 담는 설정 객체.
- [[settings]] — 환경변수에서 읽은 공통/서비스별 설정을 구조화해 제공하는 최상위 설정 객체.

## Concepts
- [[application-lifecycle-and-readiness]] — `create_app()`와 managed lifespan, readiness endpoint까지 포함한 앱 수명주기 표준화.
- [[domain-event-payload-conventions]] — 멱등성 키와 schema/version 필드를 포함하는 도메인 이벤트 payload 관례.
- [[environment-variable-configuration]] — 환경변수 기반 설정, 검증, 비밀 주입, 환경 분리 운영 원칙.
- [[fastapi-core-dependency-policy]] — 함수형 dependency, app state 캐시, registry-backed 해석 규칙.
- [[fastapi-core-layered-configuration]] — `EnvConfig`와 `ServiceSettings`로 나뉘는 2계층 설정 모델.
- [[fastapi-core-messaging-integration]] — core helper와 FastAPI dependency helper로 나뉘는 NATS 통합 구조.
- [[fastapi-sdk-lifespan-integration]] — FastAPI lifespan에서 설정 로드, registry 생성, health check, 종료 정리를 묶는 통합 패턴.
- [[keycloak-provisioning-configuration]] — Keycloak realm/client/role 프로비저닝을 제어하는 설정 규칙과 운영 계약.
- [[nats-event-subjects]] — `<domain>.<entity>.<action>` 형식의 NATS 이벤트 subject 네이밍 규칙.
- [[sdk-consumption-pattern]] — `load_settings()`부터 `close_all()`까지 이어지는 SDK 소비 프로젝트의 표준 사용 흐름.
- [[sensitive-data-masking]] — 로그와 예외 경로에서 credential/token 노출을 막기 위한 민감정보 마스킹 규칙.
- [[service-selection-and-health-checks]] — 환경변수 기반 서비스 선택과 required/optional health check 설계 규칙.

## Comparisons

## Queries
