---
title: dms-core configuration model
created: 2026-07-11
updated: 2026-07-15
type: concept
tags: [dms-core, dms, configuration, storage, metadata, security, deployment]
sources: [raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-env-example-v0.3.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md, raw/articles/docmesh-py-core-config-v0.2.0.md]
confidence: medium
---

# dms-core configuration model

`dms-core`는 환경 기반 SDK 조립과 명시적 의존성 주입을 지원한다. v0.3.0에서 `DMS_METADATA_BACKEND=postgresql|sqlite`를 지정하면 선택한 metadata backend만 로드·검증하며, 미지정이면 PostgreSQL 우선 자동 선택을 유지한다. 자동 선택에서 양쪽 설정이 공존하면 경고 후 PostgreSQL을 선택하지만 `DMS_CONFIGURATION_STRICT=true`면 `ConfigurationError`로 거부한다. 어느 metadata store도 선택할 수 없거나 `MINIO_BUCKET`이 비어 있으면 SDK 생성은 실패한다. ^[raw/articles/dms-core-config-v0.3.0.md]

## Storage and startup-health contract

문서 본문 저장소는 MinIO가 필수이며 SQLite는 metadata store 대안일 뿐이다. `DOCMESH_HEALTHCHECK_ENABLED`는 기본 활성화되어 있고, SDK 생성 시 선택된 metadata store와 MinIO 상태 점검이 실패하면 `HealthCheckFailedError`가 발생한다. 이 정책은 [[dms-core]] factory와 [[dms-core-document-lifecycle]]의 운영 lifecycle에 연결된다.

명시 선택은 SQLite 개발 환경에 남아 있는 `POSTGRES_` 변수가 의도치 않게 PostgreSQL을 선택하는 문제를 피하는 방법이다. SDK 직접 조립에 필요한 MinIO 키는 `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`이고, PostgreSQL에는 `POSTGRES_DSN` 또는 host/db/user/password 조합, SQLite에는 `SQLITE_PATH`가 필요하다. ^[raw/articles/dms-core-config-v0.3.0.md]

## Shared configuration boundary

`KEYCLOAK_*`, `NATS_SERVERS`, `MILVUS_URI` 등은 DMS SDK 기능의 직접 설정이 아니라 `docmesh-py-core` loader가 해당 서비스를 선택했을 때 검증할 수 있는 외부 통합 설정이다. `load_service_configs(services=...)`는 선택 서비스만 검증하지만, `load_available_service_configs(...)`는 관련 prefix가 보이는 부분 설정을 오류로 다룬다. DMS SDK 설정과 FastAPI 앱 설정을 섞지 않고, 앱 레이어는 [[fastapi-core-configuration]], SDK 저장소/health 설정은 이 페이지에서 각각 관리해야 한다. ^[raw/articles/docmesh-py-core-config-v0.2.0.md]

v0.3.0 API의 `diagnose_environment(env)`는 연결·client 생성·SDK 조립 없이 선택 결과, MinIO/healthcheck 상태, 누락 키, 경고와 유효성을 사전 점검하고 secret 또는 설정값 자체를 결과에 포함하지 않는다. 이 진단은 [[dms-core]]의 environment factory 실패를 대체하지 않으며, 배포 검증 단계에서 설정을 노출하지 않는 보조 신호로 취급한다. ^[raw/articles/dms-core-api-v0.3.0.md]

예제의 SQLite 사전 진단은 `DMS_METADATA_BACKEND=sqlite`, `SQLITE_PATH`와 네 개의 MinIO 필수 키를 같은 `env` mapping에 넣은 뒤 `report.valid`를 확인하고 SDK를 생성한다. 이 흐름은 credential을 로그에 기록하지 않은 채 CI/배포 준비 단계에서 configuration 오류를 분리하는 방법이다. ^[raw/articles/dms-core-examples-v0.3.0.md]

## Deployment guidance

로컬 개발은 SQLite + MinIO 구성에서 health check를 필요에 따라 끌 수 있지만, 통합/운영 환경에서는 PostgreSQL + MinIO 및 health check 활성화를 기준으로 검증한다. v0.3.0 `.env.example`은 placeholder endpoint 때문에 `DOCMESH_HEALTHCHECK_ENABLED=false`를 기본으로 하고 `DMS_METADATA_BACKEND=postgresql`을 명시한다. 실제 서비스 주소·credential을 주입한 뒤에만 health check를 활성화하며, SQLite를 의도하면 `POSTGRES_*`를 제거/주석 처리하거나 backend를 `sqlite`로 선택한다. 실제 endpoint·credential·DSN은 외부 secret 주입으로 관리한다. 운영 환경에서는 `MINIO_SECURE=true`와 유효한 TLS 구성을 권장하고, MinIO bucket과 PostgreSQL 계정에는 최소 권한을 준다. ^[raw/articles/dms-core-env-example-v0.3.0.md]

통합 테스트는 별도 credential set을 요구하지 않고, 준비·도달 가능한 기존 `POSTGRES_*`/`MINIO_*` 값을 재사용한다. 이 템플릿은 [[dms-core]] SDK의 조립 범위만 나타내며 [[fastapi-core-configuration]]의 application hosting 설정을 대신하지 않는다. ^[raw/articles/dms-core-env-example-v0.3.0.md]

환경 기반·명시적 component SDK 조립과 close 보장 패턴은 [[dms-core-usage-patterns]]에서 확인한다. 이 패턴은 [[dms-core-document-lifecycle]]의 upload/download/delete 작업 전후에 적용된다.

## Sources

- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-env-example-v0.3.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
- `raw/articles/docmesh-py-core-config-v0.2.0.md`
