# Wiki Index

> DMS를 `dms-core` 로직 코어와 `fastapi-core` FastAPI 컴포넌트로 구성하여 배포하기 위한 지식 카탈로그.
> Last updated: 2026-08-02 | Total pages: 18

## Entities
<!-- Alphabetical within section -->
- [[dms-core]] — host-injected v0.7.0 문서 SDK; 환경 factory 없이 client/component를 받아 bounded stream·cursor·삭제를 제공.
- [[docmesh-config]] — process environment 설정·network-free diagnosis·runtime plan metadata를 제공하고 DMS host adapter가 선택 로딩에 사용하는 v0.1.0 패키지.
- [[docmesh-py-core]] — canonical config object로 PostgreSQL/SQLite·MinIO client wrapper를 만들며 DMS에 주입되는 v0.6.0 공통 의존성.
- [[fastapi-core]] — v0.7.0 DMS FastAPI 서비스의 module 조립·managed resource·라우터·dependency·contract-test 공개 표면.

## Concepts
- [[dms-core-configuration]] — DMS SDK와 host 설정의 경계, v0.7 client injection, backend policy·MinIO·startup health 조립 규칙.
- [[dms-core-document-lifecycle]] — 업로드·조회·삭제·계획 기반 복구의 object/metadata 정합성과 공개 응답 경계.
- [[dms-core-messaging-boundary]] — DMS SDK의 비메시징 범위와 FastAPI/NATS hosting layer의 구분.
- [[dms-core-usage-patterns]] — SDK 조립·bounded stream·멱등 작업·cursor 목록·delete·close 실행 패턴.
- [[docmesh-config-configuration]] — 98개 환경변수, 선택 서비스 loader, secret-safe 출력과 production 보안 규칙.
- [[docmesh-config-runtime-plan]] — 서비스 선택·대안·startup policy와 외부 연결 없는 진단 metadata.
- [[docmesh-py-core-usage-patterns]] — 동기/비동기 service assembly, FastAPI lifespan, selective loading, health, NATS/Keycloak 직접 사용 패턴.
- [[docmesh-py-core-v060-runtime-contract]] — v0.6.0 canonical package bridge와 host-owned client factory·container·health·cleanup 계약.
- [[fastapi-core-app-assembly]] — v0.7 `create_app` 기반 DMS FastAPI module/resource 조립, lifecycle, 상태, readiness 정책.
- [[fastapi-core-configuration]] — `AppConfig`와 `docmesh-config`/DMS host settings의 배포·보안·readiness 소유 경계.
- [[fastapi-core-messaging-integration]] — NATS의 service selection, readiness, lifecycle 확장 경계.
- [[fastapi-core-usage-patterns]] — app factory, 인증, lifecycle, 서비스 선택을 위한 검증된 사용 패턴.

## Comparisons

## Queries
- [[dms-application-optimization]] — v0.6 동기 stream을 inline/download에 공통 적용하고 buffer 상한과 통합 cleanup을 강화한 검토.
- [[fastapi-core-application-optimization]] — v0.6 module 조립을 유지하면서 root path, OpenAPI 오류 계약과 contract test를 정합화한 적용 검토.
