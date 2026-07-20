---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/dms-core/Configuration-v0.5.0.md
ingested: 2026-07-20
sha256: f73060a146317b7938bbfa067aa80a49851bcca82f112c12c3ab6e60c211a92f
---
# 설정 참조

환경 기반 SDK 조립은 `create_sdk_from_environment()`를 사용한다. 설정을 적용하기 전에 `diagnose_environment(env)`로 연결 없이 확인할 수 있으며, 실제 누락 키의 최종 목록은 반환된 `missing_required_keys`를 기준으로 해야 한다. 상위 runtime 검증은 실행 환경에 따라 추가 키를 요구할 수 있으므로 고정 목록을 가정하지 않는다.

## 1. 환경 변수

| 변수 | 값·기본값 | 적용 범위·효과 | 비밀 |
| --- | --- | --- | --- |
| `DMS_METADATA_BACKEND` | `postgresql` 또는 `sqlite`; 미지정 시 자동 | 문서 정보 저장소를 명시 선택한다. 다른 값은 설정 오류다. | 아니오 |
| `DMS_CONFIGURATION_STRICT` | truthy: `1`, `true`, `yes`, `on`; 기본 false | 자동 모드에서 PostgreSQL·SQLite가 모두 있으면 모호성을 오류로 바꾼다. | 아니오 |
| `DOCMESH_HEALTHCHECK_ENABLED` | false 값 `0`, `false`, `no`, `off` 외에는 기본 활성 | 환경 기반 조립의 시작 상태 확인을 제어한다. | 아니오 |
| `POSTGRES_HOST` | 비어 있지 않은 값 | PostgreSQL 선택 시 필수 호스트 | 아니오 |
| `POSTGRES_PORT` | 포트 값 | PostgreSQL 연결 포트. runtime 검증 규칙을 따른다. | 아니오 |
| `POSTGRES_DB` | 비어 있지 않은 값 | PostgreSQL 선택 시 필수 데이터베이스 | 아니오 |
| `POSTGRES_USER` | 비어 있지 않은 값 | PostgreSQL 선택 시 필수 계정 | 예 |
| `POSTGRES_PASSWORD` | 비어 있지 않은 값 | PostgreSQL 선택 시 필수 암호 | 예 |
| `SQLITE_PATH` | 비어 있지 않은 경로 | SQLite 선택 시 필수 경로 | 아니오 |
| `MINIO_ENDPOINT` | 비어 있지 않은 endpoint | 문서 본문 저장소에 항상 필수 | 아니오 |
| `MINIO_ACCESS_KEY` | 비어 있지 않은 값 | MinIO 인증 | 예 |
| `MINIO_SECRET_KEY` | 비어 있지 않은 값 | MinIO 인증 | 예 |
| `MINIO_BUCKET` | 비어 있지 않은 값 | 문서 버킷에 항상 필수 | 아니오 |
| `MINIO_SECURE` | runtime 보안 정책 값 | MinIO TLS 연결 조건. 공통 실행 환경과 함께 검증된다. | 아니오 |
| `DOCMESH_ENV` | runtime 환경 값 | 공통 실행 보안 정책 검증에 사용된다. | 아니오 |
| `POSTGRES_DSN` | 지원 안 함 | 발견되면 `unsupported_keys`에 보고되고 조립 전 거부된다. 개별 `POSTGRES_*`를 사용한다. | 예 |

`DOCMESH_*`의 추가 공통 runtime 설정은 `docmesh-py-core`의 현재 검증 정책을 따른다. `diagnose_environment()`의 결과는 secret 값 자체를 포함하지 않으며 `format_environment_diagnosis()`도 운영자에게 안전한 문자열만 만든다.

## 2. 선택과 우선순위

1. `DMS_METADATA_BACKEND=postgresql|sqlite`가 있으면 해당 저장소만 선택·검증한다.
2. 명시 선택이 없고 `POSTGRES_*` 중 하나라도 있으면 PostgreSQL을 선택한다.
3. PostgreSQL 설정이 없고 `SQLITE_PATH`가 있으면 SQLite를 선택한다.
4. 두 저장소 설정이 모두 있고 strict가 아니면 PostgreSQL을 선택하고 `warnings`에 경고를 추가한다.
5. 두 저장소 설정이 모두 있고 `DMS_CONFIGURATION_STRICT`가 truthy면 조립을 거부한다.
6. 어느 저장소도 선택할 수 없으면 진단 결과가 메타데이터 저장소 설정 누락을 보고한다.

환경 기반 조립은 현재 프로세스 환경을 읽는다. SDK 생성 중 다른 실행 흐름이 `DMS_*`, `DOCMESH_*`, `POSTGRES_*`, `SQLITE_*`, `MINIO_*`를 변경하지 않아야 한다.

## 3. 설정 묶음 기반 조립

`create_sdk_from_service_configs(configs, check_on_startup=False, ...)`는 `docmesh_py_core.load_service_configs()` 등으로 얻은 설정 묶음을 사용한다. 환경을 읽거나 변경하지 않으며 다음을 요구한다.

- PostgreSQL 또는 SQLite 정확히 하나
- 버킷이 지정된 MinIO
- 공통 실행 보안 정책 및 MinIO 연결 보안 조건 충족

`check_on_startup=True`일 때만 조립 전에 상태를 확인한다. 실패하면 SDK가 생성한 자원을 정리하고 `HealthCheckFailedError`는 대상 `service`와 `reason`을 제공한다.

## 4. 구성요소 기반 조립 옵션

`create_sdk_from_components()`는 환경 변수 대신 제공된 구성요소를 사용한다.

| 옵션 | 기본값 | 계약 |
| --- | --- | --- |
| `metadata_store`, `object_store` | 필수 | 애플리케이션이 제공하는 문서 정보·본문 저장소 |
| `logger` | `dms.sdk` logger | 구조화된 SDK 로그 대상 |
| `id_generator` | UUID 생성 | 문서 ID 생성 callable |
| `service_checks` | 없음 | 이름→상태 점검 callable mapping |
| `close_callbacks` | 없음 | 종료 시 한 번 실행할 callback iterable |
| `max_file_size` | 제한 없음 | 양수 바이트 상한. 바이트·알려진 스트림 등록에 적용 |
| `operation_store` | 없음 | 영속 멱등성 작업 저장소 |
| `metadata_validator` | 표준 정책 | 입력 메타데이터를 새 dict로 검증·정규화하는 callable |
| `metadata_max_serialized_bytes` | 16384 | 기본 메타데이터 정책의 직렬화 바이트 상한 |
| `metadata_max_depth` | 8 | 기본 메타데이터 정책의 중첩 깊이 상한 |
| `recovery_audit_hook` | 없음 | 복구 시도마다 `RecoveryAuditEvent`를 받는 best-effort callback |

`metadata_validator`를 제공하면 두 기본 메타데이터 한계는 그 validator가 아닌 경우에만 적용된다. audit hook 예외는 복구 결과를 실패로 만들지 않는다.
