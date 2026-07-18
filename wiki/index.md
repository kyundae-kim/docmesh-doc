# Wiki Index

> DMS를 `dms-core` 로직 코어와 `fastapi-core` FastAPI 컴포넌트로 구성하여 배포하기 위한 지식 카탈로그.
> Last updated: 2026-07-18 | Total pages: 12

## Entities
<!-- Alphabetical within section -->
- [[dms-core]] — bounded stream 업로드·멱등 작업·cursor 목록·명시 삭제·안전 복구를 제공하는 Python DMS SDK.
- [[docmesh-py-core]] — 설정·service client·health 집계·Keycloak/NATS 통합을 제공하는 `fastapi-core`의 공통 업스트림 의존성.
- [[fastapi-core]] — DMS FastAPI 서비스의 앱 조립·라우터·dependency 공개 표면.

## Concepts
- [[dms-core-configuration]] — DMS SDK의 tagged template, backend 선택, 개별 PostgreSQL 필드, MinIO, metadata policy와 startup health 설정 경계.
- [[dms-core-document-lifecycle]] — 업로드·조회·삭제·계획 기반 복구의 object/metadata 정합성과 공개 응답 경계.
- [[dms-core-messaging-boundary]] — DMS SDK의 비메시징 범위와 FastAPI/NATS hosting layer의 구분.
- [[dms-core-usage-patterns]] — SDK 조립·bounded stream·멱등 작업·cursor 목록·delete·close 실행 패턴.
- [[docmesh-py-core-usage-patterns]] — 동기/비동기 service assembly, FastAPI lifespan, selective loading, health, NATS/Keycloak 직접 사용 패턴.
- [[fastapi-core-app-assembly]] — `create_app` 기반 DMS FastAPI 조립, lifecycle, 상태, readiness 정책.
- [[fastapi-core-configuration]] — `AppConfig`와 `ServiceConfigs`의 배포·보안·readiness 설정 경계.
- [[fastapi-core-messaging-integration]] — NATS의 service selection, readiness, lifecycle 확장 경계.
- [[fastapi-core-usage-patterns]] — app factory, 인증, lifecycle, 서비스 선택을 위한 검증된 사용 패턴.

## Comparisons

## Queries
