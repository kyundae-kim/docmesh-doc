---
title: dms-core configuration model
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [dms-core, dms, configuration, storage, metadata, security, deployment]
sources: [raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-examples-v0.2.0.md]
confidence: medium
---

# dms-core configuration model

`dms-core`는 환경 기반 SDK 조립과 명시적 의존성 주입을 지원한다. 환경 기반 조립에서는 PostgreSQL 설정이 있으면 metadata store로 우선 선택하고, 없을 때 `SQLITE_PATH`를 사용한다. 어느 metadata store도 선택할 수 없거나 `MINIO_BUCKET`이 비어 있으면 SDK 생성은 `ConfigurationError`로 실패한다.

## Storage and startup-health contract

문서 본문 저장소는 MinIO가 필수이며 SQLite는 metadata store 대안일 뿐이다. `DOCMESH_HEALTHCHECK_ENABLED`는 기본 활성화되어 있고, SDK 생성 시 선택된 metadata store와 MinIO 상태 점검이 실패하면 `HealthCheckFailedError`가 발생한다. 이 정책은 [[dms-core]] factory와 [[dms-core-document-lifecycle]]의 운영 lifecycle에 연결된다.

## Shared configuration boundary

`KEYCLOAK_*`, `NATS_SERVERS`, `MILVUS_URI` 등은 DMS SDK 기능의 직접 설정이 아니라 `docmesh-py-core` loader 검증 때문에 환경에 필요할 수 있다. DMS SDK 설정과 FastAPI 앱 설정을 섞지 않고, 앱 레이어는 [[fastapi-core-configuration]], SDK 저장소/health 설정은 이 페이지에서 각각 관리해야 한다.

## Deployment guidance

로컬 개발은 SQLite + MinIO 구성에서 health check를 필요에 따라 끌 수 있지만, 통합/운영 환경에서는 PostgreSQL + MinIO 및 health check 활성화를 기준으로 검증한다. MinIO secret과 PostgreSQL DSN은 환경변수 원문 노출 대신 외부 secret 주입으로 관리한다.

환경 기반·명시적 component SDK 조립과 close 보장 패턴은 [[dms-core-usage-patterns]]에서 확인한다. 이 패턴은 [[dms-core-document-lifecycle]]의 upload/download/delete 작업 전후에 적용된다.

## Sources

- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
