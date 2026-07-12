# Wiki Index

> DMS를 `dms-core` 로직 코어와 `fastapi-core` FastAPI 컴포넌트로 구성하여 배포하기 위한 지식 카탈로그.
> Last updated: 2026-07-12 | Total pages: 11

## Entities
<!-- Alphabetical within section -->
- [[dms-core]] — 문서 저장·metadata·상태 점검을 제공하는 Python DMS SDK.
- [[docmesh-py-core]] — `fastapi-core`가 설정, 서비스 클라이언트, readiness를 위해 사용하는 공통 의존성.
- [[fastapi-core]] — DMS FastAPI 서비스의 앱 조립·라우터·dependency 공개 표면.

## Concepts
- [[dms-core-configuration]] — DMS SDK의 PostgreSQL/SQLite, MinIO, startup health 설정 경계.
- [[dms-core-document-lifecycle]] — 업로드·조회·삭제의 object/metadata 정합성과 FastAPI 통합 경계.
- [[dms-core-messaging-boundary]] — DMS SDK의 비메시징 범위와 FastAPI/NATS hosting layer의 구분.
- [[dms-core-usage-patterns]] — SDK 조립·upload·stream·delete·close를 위한 실행 패턴.
- [[fastapi-core-app-assembly]] — `create_app` 기반 DMS FastAPI 조립, lifecycle, 상태, readiness 정책.
- [[fastapi-core-configuration]] — `AppConfig`와 `ServiceConfigs`의 배포·보안·readiness 설정 경계.
- [[fastapi-core-messaging-integration]] — NATS의 service selection, readiness, lifecycle 확장 경계.
- [[fastapi-core-usage-patterns]] — app factory, 인증, lifecycle, 서비스 선택을 위한 검증된 사용 패턴.

## Comparisons

## Queries
