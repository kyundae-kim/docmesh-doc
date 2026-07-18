---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/Configuration-v0.4.0.md
ingested: 2026-07-18
sha256: cb8cdafa78abc125bc6bd31016609ab6001d1a12d069a512c4ebee6077b5d193
---
# 설정 정의서

이 문서는 환경 기반 SDK 조립과 명시적 구성요소 조립의 모든 공개 설정값을 설명합니다. 공개 API의 매개변수·오류·반환 타입은 `docs/api.md`, 실행 흐름은 `docs/examples.md`를 참고하십시오.

## 설정 방식

| 방식 | 공개 API | 사용 시점 |
| --- | --- | --- |
| 환경 기반 | `create_sdk_from_environment(env, ...)` | PostgreSQL 또는 SQLite와 MinIO를 표준 환경 설정으로 조립할 때 |
| 구성요소 기반 | `create_sdk_from_components(metadata_store=..., object_store=..., ...)` | 애플리케이션이 어댑터, 검사, 종료, 정책을 직접 소유할 때 |
| 사전 진단 | `diagnose_environment(env)` | 연결·데이터 변경 없이 배포 환경의 선택·누락·경고를 확인할 때 |

`env`는 문자열 키·값 mapping입니다. 진단 결과 `EnvironmentDiagnosis`는 `metadata_backend`, `object_backend`(항상 `minio`), `healthcheck_enabled`, `missing_required_keys`, `warnings`, `valid`를 제공합니다. 비밀값은 결과에 포함하지 않습니다. 진단은 연결하지 않지만, 실행 환경의 docmesh 공통 설정 검증 결과를 반영할 수 있습니다.

## 환경 변수 전체 목록

| 변수 | 값/기본값 | 적용 범위 | 의미 |
| --- | --- | --- | --- |
| `DMS_METADATA_BACKEND` | `postgresql` 또는 `sqlite`, 생략 가능 | DMS | 문서 정보 저장소를 명시 선택합니다. 다른 값은 유효하지 않습니다. |
| `DMS_CONFIGURATION_STRICT` | `1`, `true`, `yes`, `on`이면 활성; 기본 비활성 | DMS | 자동 선택에서 PostgreSQL과 SQLite가 함께 구성된 모호성을 거부합니다. |
| `DOCMESH_HEALTHCHECK_ENABLED` | 기본 활성; `0`, `false`, `no`, `off`이면 비활성 | docmesh 공통 | 환경 기반 조립의 시작 상태 확인을 제어합니다. |
| `POSTGRES_HOST` | 필수( PostgreSQL 선택 시) | PostgreSQL | PostgreSQL 호스트입니다. |
| `POSTGRES_PORT` | 공통 설정이 요구하는 포트 값 | PostgreSQL | PostgreSQL 포트입니다. |
| `POSTGRES_DB` | 필수( PostgreSQL 선택 시) | PostgreSQL | 데이터베이스 이름입니다. |
| `POSTGRES_USER` | 필수( PostgreSQL 선택 시) | PostgreSQL | 접속 사용자입니다. |
| `POSTGRES_PASSWORD` | 필수( PostgreSQL 선택 시) | PostgreSQL | 접속 비밀값입니다. |
| `SQLITE_PATH` | 필수(SQLite 선택 시) | SQLite | SQLite 파일 경로입니다. |
| `MINIO_ENDPOINT` | 필수 | MinIO | MinIO 엔드포인트입니다. |
| `MINIO_ACCESS_KEY` | 필수 | MinIO | MinIO 접근 키입니다. |
| `MINIO_SECRET_KEY` | 필수 | MinIO | MinIO 비밀 키입니다. |
| `MINIO_BUCKET` | 필수 | MinIO | 문서 본문 버킷입니다. |
| `MINIO_SECURE` | 공통 설정이 해석하는 boolean | MinIO | MinIO 전송 보안을 지정합니다. |
| `DOCMESH_ENV` 및 docmesh 공통 변수 | 설치된 공통 설정에 따름 | docmesh 공통 | 런타임 공통 검증이 요구할 수 있는 값입니다. `diagnose_environment()`로 실제 누락 항목을 확인합니다. |

비밀값(`POSTGRES_PASSWORD`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY` 등)을 문서, 로그, 예외 메시지, 소스 저장소에 기록하지 마십시오. `POSTGRES_DSN`은 DMS의 환경 조립 입력이 아닙니다.

## 저장소 선택 규칙

1. `DMS_METADATA_BACKEND=postgresql`이면 PostgreSQL만, `sqlite`이면 SQLite만 검증·조립합니다. 선택하지 않은 저장소의 값은 선택 결과를 바꾸지 않습니다.
2. 명시 선택이 없고 하나 이상의 `POSTGRES_*` 키가 있으면 PostgreSQL을 선택합니다.
3. 그 외 `SQLITE_PATH`가 있으면 SQLite를 선택합니다.
4. PostgreSQL과 SQLite가 모두 있으면 자동 모드는 PostgreSQL을 선택하고 경고합니다. `DMS_CONFIGURATION_STRICT`가 truthy면 조립 전 `ConfigurationError`로 거부합니다.
5. 어느 저장소도 선택할 수 없으면 MinIO와 함께 메타데이터 저장소 선택/설정이 누락된 구성입니다.

`create_sdk_from_environment()`는 선택 정책 위반과 설정 오류를 `ConfigurationError`, 시작 상태 확인 실패를 `HealthCheckFailedError`, 연결 불가를 `StorageError` 또는 `MetadataStoreError`로 구분합니다. 환경 조립이 중간에 실패하면 확보한 서비스 bundle을 닫으려 시도합니다.

## 환경 구성 예시

### SQLite + MinIO

```python
from os import environ
from dms import create_sdk_from_environment

with create_sdk_from_environment(environ) as sdk:
    health = sdk.check_health()
    if not health.ok:
        raise RuntimeError("DMS dependencies are unhealthy")
```

실행 전 최소 환경은 `DMS_METADATA_BACKEND=sqlite`, `SQLITE_PATH`, `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`입니다. 공통 설정이 추가 키를 요구하면 `diagnose_environment(environ).missing_required_keys`를 기준으로 보완합니다.

### PostgreSQL + MinIO

`DMS_METADATA_BACKEND=postgresql`과 `POSTGRES_HOST`, `POSTGRES_PORT`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`, 그리고 위 MinIO 네 값을 제공합니다. 명시 선택을 생략해도 PostgreSQL 키가 있으면 PostgreSQL이 우선하지만 운영 배포에서는 명시 선택을 권장합니다.

## 구성요소 기반 조립 옵션

`create_sdk_from_components()`의 필수 옵션은 `metadata_store`와 `object_store`입니다. 두 객체는 각각 문서 메타데이터와 본문 저장소 프로토콜을 구현해야 합니다. 나머지 공개 옵션은 다음과 같습니다.

| 옵션 | 기본값 | 효과 |
| --- | --- | --- |
| `logger` | `dms.sdk` logger | 구조화된 SDK 로그의 대상입니다. |
| `id_generator` | UUID 생성기 | `document_id`를 생략한 등록의 식별자를 생성합니다. |
| `service_checks` | 없음 | 서비스명에서 callable로의 mapping입니다. `check_health()`가 실행합니다. |
| `close_callbacks` | 없음 | `close()`에서 한 번 실행할 callable iterable입니다. |
| `max_file_size` | 제한 없음 | 양수 바이트 상한입니다. 등록과 미지 크기 스트림의 `max_size`에 적용합니다. |
| `operation_store` | 없음 | 멱등 등록과 업로드 작업 조회에 필요한 영속 저장소입니다. |
| `metadata_validator` | `DefaultMetadataPolicy` | 요청 metadata를 검증·정규화하는 callable입니다. |
| `metadata_max_serialized_bytes` | 16,384 | 기본 metadata 정책의 JSON 직렬화 바이트 상한입니다. |
| `metadata_max_depth` | 8 | 기본 metadata 정책의 중첩 깊이 상한입니다. |
| `recovery_audit_hook` | 없음 | 복구 시도 `RecoveryAuditEvent`를 받는 best-effort callable입니다. |

`metadata_validator`를 지정하면 두 metadata limit은 해당 validator에 적용되지 않습니다. `max_file_size`가 0 이하이면 `ValidationError`입니다.

## 메타데이터 정책 설정

기본 정책은 민감 키, 비문자열 키, JSON 비직렬화 값, 과도한 깊이와 크기를 등록 전에 거부합니다. 업무 스키마는 `StructuredMetadataValidator` 또는 호환 callable을 `metadata_validator`로 주입합니다. schema version, field 오류, projection 계약은 `docs/api.md`의 메타데이터 검증 절을 따릅니다.

## 상태 확인과 종료

환경 기반 조립은 기본적으로 시작 상태 확인을 실행합니다. 개발 또는 의존 서비스가 아직 준비되지 않은 특수 흐름에서만 `DOCMESH_HEALTHCHECK_ENABLED=false`를 사용하고, 이후 `sdk.check_health()` 결과를 확인하십시오. `with create_sdk_from_environment(...) as sdk:` 또는 명시 `sdk.close()`로 bundle 정리를 보장해야 합니다.
