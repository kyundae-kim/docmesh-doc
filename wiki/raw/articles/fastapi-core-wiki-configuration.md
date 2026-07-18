---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Configuration.md
ingested: 2026-07-18
sha256: 54914b72be02ed9d93422762d2c954b03287078a58d598d12dcc1787324e3ef3
---
# fastapi-core Configuration Reference

> 기준 버전: `fastapi-core 0.3.0`, `docmesh-py-core v0.3.0`  
> 기준 구현: `fastapi_core/config.py`, `fastapi_core/runtime.py`, `fastapi_core/docmesh_settings.py` 및 설치된 DocMesh 설정 모델  
> `.env.example`은 이 문서의 복사 가능한 환경변수 목록이다.

## 1. 설정 계층과 소유권

fastapi-core 설정은 두 계층으로 나뉜다.

| 계층 | 소유 모델/loader | 책임 |
|---|---|---|
| FastAPI 앱 조립 | `AppConfig`, `load_app_config()` | root path, OAuth2 문서 URL, CORS, readiness 실행 정책, logging, 활성/필수 서비스 선택 |
| DocMesh 서비스 | DocMesh `CommonConfig`와 서비스별 config, `load_service_configs()` | Keycloak/PostgreSQL/SQLite/MinIO/Milvus/Ollama/Langfuse/NATS 연결·보안·client 설정 |

fastapi-core는 DocMesh 서비스 설정 모델을 복제하지 않는다. 현재 process environment를 DocMesh loader에 전달하고 그 결과로 `ServiceRuntime`을 조립한다.

## 2. 실제 조립 경로

`create_app()`의 기본 경로는 다음과 같다.

1. 전달된 `AppConfig`를 사용하거나 `load_app_config()`로 process environment를 읽는다.
2. `build_runtime_plan(config)`가 활성/필수/대안 서비스 및 healthcheck 정책을 만든다.
3. lifespan startup에서 `build_docmesh_env_overlay()`가 현재 environment를 복사한다.
4. `assemble_runtime()`이 DocMesh `assemble_service_runtime()`을 호출한다.
5. 완성된 runtime을 `app.state.service_runtime`에 저장한다.
6. runtime client check를 readiness registry에 등록한다.
7. shutdown에서 runtime을 닫는다.

`create_app(runtime=...)`으로 미리 만든 runtime을 주입하면 서비스 설정/클라이언트 조립은 우회한다. 다만 앱 CORS, logging, readiness 실행 정책 등은 여전히 `AppConfig`를 사용한다.

## 3. 환경 파일 정책

- 저장소의 `.env.example`은 자동으로 로드되지 않는다.
- shell, container, orchestrator, secret manager 또는 애플리케이션이 선택한 dotenv loader로 값을 process environment에 주입한다.
- 실제 secret을 `.env.example`, 문서, 로그, Git에 저장하지 않는다.
- `load_app_config()`와 `load_docmesh_settings()`는 cache된다. 테스트에서 환경을 바꾸면 각 함수의 `cache_clear()`가 필요하다.
- `build_docmesh_env_overlay()`는 `dict(os.environ)` 복사본을 반환하며 개발 기본값을 추가하거나 원본 환경을 변경하지 않는다.

`AppConfig`의 입력 우선순위는 직접 생성자 인자, process environment, dotenv source, file secret source 순서다. 현재 모델은 `env_file`과 `secrets_dir`을 지정하지 않으므로 저장소 파일을 자동 탐색하지 않는다. 환경변수 이름은 대소문자를 구분하지 않고, 알 수 없는 입력은 무시하며, 복합값의 JSON 자동 decoding은 비활성화되어 있다.

## 4. `AppConfig`

<a id="cfg-app"></a>
### 4.1 전체 필드

| ID | 필드 | 환경변수 | 타입 | 기본값 | 사용 위치 |
|---|---|---|---|---|---|
| CFG-APP-001 | `root_path` | `ROOT_PATH` | `str` | `""` | `FastAPI(root_path=...)` |
| CFG-APP-002 | `token_url` | `TOKEN_URL` | `str` | `"/token"` | 앱별 OAuth2/OpenAPI security scheme |
| CFG-APP-003 | `cors_origins` | `CORS_ORIGINS` | CSV `list[str]` | `["*"]` | CORS allow origins |
| CFG-APP-004 | `cors_credentials` | `CORS_CREDENTIALS` | `bool` | `false` | CORS credentials |
| CFG-APP-005 | `readiness_parallel` | `READINESS_PARALLEL` | `bool` | `false` | startup/readiness 병렬 실행 |
| CFG-APP-006 | `readiness_timeout_seconds` | `READINESS_TIMEOUT_SECONDS` | `float \| None` | `None` | check별 기본 timeout; 0보다 커야 함 |
| CFG-APP-007 | `readiness_overall_timeout_seconds` | `READINESS_OVERALL_TIMEOUT_SECONDS` | `float \| None` | `None` | 전체 readiness timeout; 0보다 커야 함 |
| CFG-APP-008 | `service_alternatives` | `DOCMESH_SERVICE_ALTERNATIVES` | `list[list[str]]` | `[]` | RuntimePlan one-of 그룹 |
| CFG-APP-009 | `startup_healthcheck` | `DOCMESH_HEALTHCHECK_ENABLED` | `bool` | `false` | startup에서 runtime/resource check 여부 |
| CFG-APP-010 | `log_level` | `DOCMESH_LOG_LEVEL` | `str \| None` | `"WARNING"` | application logging level |
| CFG-APP-011 | `log_path` | `APP_LOG_PATH` | `str \| None` | `None` | log 출력 경로 |
| CFG-APP-012 | `log_json` | `APP_LOG_JSON` | `bool` | `true` | JSON formatter 적용 여부 |
| CFG-APP-013 | `log_force` | `APP_LOG_FORCE` | `bool` | `false` | 기존 logging handler 강제 재구성 여부 |
| CFG-APP-014 | `enabled_services` | `DOCMESH_SERVICES` | CSV `list[str]` | `["keycloak"]` | 조립할 서비스 |
| CFG-APP-015 | `required_services` | `READINESS_REQUIRED_SERVICES` | CSV `list[str]` | `["keycloak"]` | 실패 시 startup/readiness를 실패시킬 서비스 |

Python 생성자에서는 field 이름과 대문자 alias를 모두 받을 수 있다. 둘 다 전달하면 field 이름 값이 우선한다.

### 4.2 목록 parsing

```dotenv
CORS_ORIGINS=https://app.example.com,https://admin.example.com
DOCMESH_SERVICES=keycloak,postgres,nats
READINESS_REQUIRED_SERVICES=keycloak,postgres
DOCMESH_SERVICE_ALTERNATIVES=postgres,sqlite;minio,milvus
```

- CSV 항목은 trim되고 빈 항목은 제외된다.
- `service_alternatives`는 `;`로 그룹을 나누고 각 그룹을 CSV로 parsing한다.
- environment에서 `CORS_ORIGINS=`, `DOCMESH_SERVICES=`, `READINESS_REQUIRED_SERVICES=`처럼 명시적으로 빈 값을 주면 빈 목록이다.
- 해당 환경변수를 제거하면 모델 기본값을 사용한다.
- 직접 `AppConfig(cors_origins="")`처럼 빈 문자열을 생성자에 전달하는 것은 validation error다. 직접 생성할 때 빈 목록 `[]`을 쓴다.

### 4.3 교차 필드 validation

`required_services`의 모든 값은 `enabled_services`에 포함되어야 한다.

```python
from fastapi_core.config import AppConfig

config = AppConfig(
    enabled_services=["sqlite", "postgres"],
    required_services=["sqlite"],
    service_alternatives=[["sqlite", "postgres"]],
)
```

다음은 거부된다.

```python
AppConfig(enabled_services=["sqlite"], required_services=["keycloak"])
```

지원 서비스 이름과 `service_alternatives` 그룹의 실행 가능성은 `AppConfig`가 아니라 `build_runtime_plan()` 및 DocMesh runtime 조립 단계에서 추가 검증된다.

### 4.4 `TOKEN_URL`의 범위

`TOKEN_URL`은 OpenAPI OAuth2 password flow의 `tokenUrl`을 설정한다. 내장 `POST /token` route 자체의 path를 변경하지 않는다. route path를 바꾸려면 내장 auth router를 제외하고 사용자 router를 구성한다.

### 4.5 `DOCMESH_HEALTHCHECK_ENABLED` 공유 이름

이 환경변수는 두 계층에서 읽힌다.

- `AppConfig.startup_healthcheck`: startup check 실행 여부, fastapi-core 기본값 `false`
- `CommonConfig.healthcheck_enabled`: DocMesh 공통 설정, DocMesh 기본값 `true`

환경변수를 명시하면 두 값이 같은 boolean을 읽는다. 환경변수가 없으면 각 모델의 기본값이 서로 다르므로, startup 실행 정책은 `AppConfig.startup_healthcheck`를 기준으로 해석한다.

## 5. DocMesh 공통 설정

<a id="cfg-common"></a>
| ID | 환경변수 | 타입 | 기본값 | validation/의미 |
|---|---|---|---|---|
| CFG-COMMON-001 | `DOCMESH_ENV` | `str` | `development` | 실행 환경 이름 |
| CFG-COMMON-002 | `DOCMESH_HEALTHCHECK_ENABLED` | `bool` | `true` | DocMesh 공통 healthcheck 설정 |
| CFG-COMMON-003 | `DOCMESH_SECURITY_MODE` | `development \| production \| None` | `None` | 명시적 보안 mode |
| CFG-COMMON-004 | `DOCMESH_PRODUCTION_ALIASES` | CSV | `prod,production` | `DOCMESH_ENV`를 production으로 판정할 alias |

`DOCMESH_SECURITY_MODE`가 있으면 환경 alias보다 우선한다. production으로 판정되면 다음 insecure 설정은 거부된다.

- `KEYCLOAK_VERIFY_SSL=false`
- `MINIO_SECURE=false`
- `MILVUS_SECURE=false`

## 6. 서비스 선택

지원 서비스 이름:

| 서비스 | `DOCMESH_SERVICES` 값 | typed dependency |
|---|---|---|
| Keycloak | `keycloak` | `get_keycloak_auth_service` |
| PostgreSQL | `postgres` | `get_postgres_engine` |
| SQLite | `sqlite` | `get_sqlite_engine` |
| MinIO | `minio` | `get_minio_client` |
| Milvus | `milvus` | `get_milvus_client` |
| Ollama | `ollama` | `get_ollama_client` |
| Langfuse | `langfuse` | `get_langfuse_client` |
| NATS | `nats` | `get_nats_connection_builder` |

선택된 서비스만 설정 탐색과 client 조립 후보가 된다. required 서비스는 설정이 없거나 불완전하면 startup이 실패한다. optional 서비스는 관련 환경변수가 전혀 없으면 조립에서 제외될 수 있지만, prefix에 해당하는 일부 값만 있으면 부분 설정 validation이 실패할 수 있다. `DOCMESH_SERVICE_ALTERNATIVES`의 각 그룹은 조립 시 적어도 하나가 완전히 구성되어야 한다.

DocMesh 서비스 모델은 문자열의 앞뒤 공백을 제거하고, 그 결과가 빈 문자열이면 `None`으로 취급한다. 설정 오류는 secret 값을 포함하지 않는 `ConfigError`/`ConfigIssue` 경계로 변환된다.

서비스 없는 앱은 두 CSV를 명시적으로 비운다.

```dotenv
DOCMESH_SERVICES=
READINESS_REQUIRED_SERVICES=
```

## 7. Keycloak 설정

<a id="cfg-keycloak"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-KC-001 | `KEYCLOAK_URL` | `str` | 없음 | 항상 필수 |
| CFG-KC-002 | `KEYCLOAK_REALM` | `str` | 없음 | 항상 필수 |
| CFG-KC-003 | `KEYCLOAK_CLIENT_ID` | `str` | 없음 | 항상 필수 |
| CFG-KC-004 | `KEYCLOAK_CLIENT_SECRET` | secret `str \| None` | `None` | confidential client일 때 필수 |
| CFG-KC-005 | `KEYCLOAK_VERIFY_SSL` | `bool` | `true` | production에서 false 금지 |
| CFG-KC-006 | `KEYCLOAK_AUDIENCE` | `str \| None` | `None` | 선택 |
| CFG-KC-007 | `KEYCLOAK_TOKEN_GRANT_TYPE` | `password \| client_credentials` | `password` | 두 값만 허용 |
| CFG-KC-008 | `KEYCLOAK_TOKEN_SCOPE` | `str \| None` | `None` | 선택 |
| CFG-KC-009 | `KEYCLOAK_TOKEN_USERNAME` | `str \| None` | `None` | password grant/readiness에 사용 가능 |
| CFG-KC-010 | `KEYCLOAK_TOKEN_PASSWORD` | secret `str \| None` | `None` | username과 함께 사용 |
| CFG-KC-011 | `KEYCLOAK_REQUEST_TIMEOUT_SECONDS` | `int` | `10` | 1 이상 |
| CFG-KC-012 | `KEYCLOAK_MAX_RETRIES` | `int` | `3` | 0 이상 |
| CFG-KC-013 | `KEYCLOAK_JWKS_CACHE_TTL_SECONDS` | `int` | `300` | 0 이상 |
| CFG-KC-014 | `KEYCLOAK_PROVISIONING_ENABLED` | `bool` | `false` | provisioning 사용 여부 |
| CFG-KC-015 | `KEYCLOAK_PROVISIONING_DRY_RUN` | `bool` | `false` | dry-run 여부 |
| CFG-KC-016 | `KEYCLOAK_ADMIN_REALM` | `str` | `master` | provisioning 설정 |
| CFG-KC-017 | `KEYCLOAK_ADMIN_CLIENT_ID` | `str` | `admin-cli` | provisioning 설정 |
| CFG-KC-018 | `KEYCLOAK_ADMIN_CLIENT_SECRET` | secret `str \| None` | `None` | 관리자 service-account 방식 |
| CFG-KC-019 | `KEYCLOAK_ADMIN_USERNAME` | `str \| None` | `None` | 관리자 user 방식 |
| CFG-KC-020 | `KEYCLOAK_ADMIN_PASSWORD` | secret `str \| None` | `None` | 관리자 user 방식 |
| CFG-KC-021 | `KEYCLOAK_REALM_ENABLED` | `bool` | `true` | provisioning target realm |
| CFG-KC-022 | `KEYCLOAK_REALM_DISPLAY_NAME` | `str \| None` | `None` | 선택 |
| CFG-KC-023 | `KEYCLOAK_CLIENT_PUBLIC` | `bool` | `false` | false면 client secret 필수 |
| CFG-KC-024 | `KEYCLOAK_CLIENT_REDIRECT_URIS` | CSV | `[]` | 선택 |
| CFG-KC-025 | `KEYCLOAK_CLIENT_WEB_ORIGINS` | CSV | `[]` | 선택 |
| CFG-KC-026 | `KEYCLOAK_REALM_ROLES` | CSV | `[]` | 선택 |
| CFG-KC-027 | `KEYCLOAK_CLIENT_ROLES` | CSV | `[]` | 선택 |

Provisioning을 활성화하면 관리자 인증은 다음 중 정확히 하나여야 한다.

1. `KEYCLOAK_ADMIN_CLIENT_SECRET`
2. `KEYCLOAK_ADMIN_USERNAME` + `KEYCLOAK_ADMIN_PASSWORD`

fastapi-core는 runtime 연결 시 Keycloak provider의 허용 알고리즘을 RS256으로 설정한다. Keycloak readiness에는 startup 시점의 token username/password와 `FASTAPI_CORE_TEST_SCOPE`가 선택적으로 전달된다.

## 8. PostgreSQL 설정

<a id="cfg-postgres"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-PG-001 | `POSTGRES_HOST` | `str \| None` | `None` | DSN 미사용 시 필수 |
| CFG-PG-002 | `POSTGRES_PORT` | `int` | `5432` | 1 이상 |
| CFG-PG-003 | `POSTGRES_DB` | `str \| None` | `None` | DSN 미사용 시 필수 |
| CFG-PG-004 | `POSTGRES_USER` | `str \| None` | `None` | DSN 미사용 시 필수 |
| CFG-PG-005 | `POSTGRES_PASSWORD` | secret `str \| None` | `None` | DSN 미사용 시 필수 |
| CFG-PG-006 | `POSTGRES_SSLMODE` | `str` | `prefer` | 선택 |
| CFG-PG-007 | `POSTGRES_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 1 이상 |
| CFG-PG-008 | `POSTGRES_POOL_SIZE` | `int` | `5` | 1 이상 |
| CFG-PG-009 | `POSTGRES_MAX_OVERFLOW` | `int` | `10` | 0 이상 |
| CFG-PG-010 | `POSTGRES_DSN` | secret `str \| None` | `None` | deprecated 호환 경로 |

개별 접속 항목이 권장 방식이다.

```dotenv
POSTGRES_HOST=postgres.example.com
POSTGRES_PORT=5432
POSTGRES_DB=docmesh
POSTGRES_USER=docmesh
POSTGRES_PASSWORD=[secret]
```

`POSTGRES_DSN`은 deprecated이며 개별 접속 필드와 함께 설정하면 validation error다.

## 9. SQLite 설정

<a id="cfg-sqlite"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-SQLITE-001 | `SQLITE_PATH` | `str` | 없음 | 항상 필수 |
| CFG-SQLITE-002 | `SQLITE_READONLY` | `bool` | `false` | 선택 |
| CFG-SQLITE-003 | `SQLITE_ENABLE_WAL` | `bool` | `false` | 선택 |
| CFG-SQLITE-004 | `SQLITE_BUSY_TIMEOUT_MS` | `int` | `5000` | 0 이상 |

로컬 ephemeral 예시는 `SQLITE_PATH=:memory:`다.

## 10. MinIO 설정

<a id="cfg-minio"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-MINIO-001 | `MINIO_ENDPOINT` | `str` | 없음 | 필수 |
| CFG-MINIO-002 | `MINIO_ACCESS_KEY` | secret `str` | 없음 | 필수 |
| CFG-MINIO-003 | `MINIO_SECRET_KEY` | secret `str` | 없음 | 필수 |
| CFG-MINIO-004 | `MINIO_SECURE` | `bool` | `true` | production에서 false 금지 |
| CFG-MINIO-005 | `MINIO_REGION` | `str \| None` | `None` | 선택 |
| CFG-MINIO-006 | `MINIO_BUCKET` | `str \| None` | `None` | 선택; 도메인 요구에 따라 별도 필수화 가능 |
| CFG-MINIO-007 | `MINIO_REQUEST_TIMEOUT_SECONDS` | `int` | `30` | 1 이상 |
| CFG-MINIO-008 | `MINIO_MAX_RETRIES` | `int` | `3` | 0 이상 |

## 11. Milvus 설정

<a id="cfg-milvus"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-MILVUS-001 | `MILVUS_URI` | `str` | 없음 | 필수 |
| CFG-MILVUS-002 | `MILVUS_TOKEN` | secret `str \| None` | `None` | 선택 |
| CFG-MILVUS-003 | `MILVUS_DB_NAME` | `str` | `default` | 선택 |
| CFG-MILVUS-004 | `MILVUS_COLLECTION` | `str \| None` | `None` | 선택 |
| CFG-MILVUS-005 | `MILVUS_SECURE` | `bool` | `false` | production에서는 true 필요 |
| CFG-MILVUS-006 | `MILVUS_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 1 이상 |
| CFG-MILVUS-007 | `MILVUS_REQUEST_TIMEOUT_SECONDS` | `int` | `30` | 1 이상 |
| CFG-MILVUS-008 | `MILVUS_MAX_RETRIES` | `int` | `3` | 0 이상 |

## 12. Ollama 설정

<a id="cfg-ollama"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-OLLAMA-001 | `OLLAMA_HOST` | `str` | 없음 | 필수 |
| CFG-OLLAMA-002 | `OLLAMA_GENERATION_MODEL` | `str \| None` | `None` | 선택 |
| CFG-OLLAMA-003 | `OLLAMA_EMBEDDING_MODEL` | `str \| None` | `None` | 선택 |
| CFG-OLLAMA-004 | `OLLAMA_REQUEST_TIMEOUT_SECONDS` | `int` | `120` | 1 이상 |
| CFG-OLLAMA-005 | `OLLAMA_MAX_RETRIES` | `int` | `2` | 0 이상 |

## 13. Langfuse 설정

<a id="cfg-langfuse"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-LANGFUSE-001 | `LANGFUSE_ENABLED` | `bool` | `true` | false면 필수 credential 검사 생략 |
| CFG-LANGFUSE-002 | `LANGFUSE_HOST` | `str \| None` | `None` | enabled=true면 필수 |
| CFG-LANGFUSE-003 | `LANGFUSE_PUBLIC_KEY` | secret `str \| None` | `None` | enabled=true면 필수 |
| CFG-LANGFUSE-004 | `LANGFUSE_SECRET_KEY` | secret `str \| None` | `None` | enabled=true면 필수 |
| CFG-LANGFUSE-005 | `LANGFUSE_RELEASE` | `str \| None` | `None` | 선택 |
| CFG-LANGFUSE-006 | `LANGFUSE_ENVIRONMENT` | `str \| None` | `DOCMESH_ENV` | 미지정 시 공통 환경 사용 |
| CFG-LANGFUSE-007 | `LANGFUSE_REQUEST_TIMEOUT_SECONDS` | `int` | `10` | 1 이상 |
| CFG-LANGFUSE-008 | `LANGFUSE_MAX_RETRIES` | `int` | `3` | 0 이상 |

현재 DocMesh 기본 Langfuse factory는 `LANGFUSE_MAX_RETRIES`를 client 생성자에 전달하지 않고 설정 객체에 보존한다.

## 14. NATS 설정

<a id="cfg-nats"></a>
| ID | 환경변수 | 타입 | 기본값 | 필수 조건 |
|---|---|---|---|---|
| CFG-NATS-001 | `NATS_SERVERS` | CSV `list[str]` | `[]` | 하나 이상 필수 |
| CFG-NATS-002 | `NATS_USER` | `str \| None` | `None` | password와 쌍 |
| CFG-NATS-003 | `NATS_PASSWORD` | secret `str \| None` | `None` | user와 쌍 |
| CFG-NATS-004 | `NATS_TOKEN` | secret `str \| None` | `None` | 인증 방식 중 하나 |
| CFG-NATS-005 | `NATS_CREDS_FILE` | `str \| None` | `None` | 인증 방식 중 하나 |
| CFG-NATS-006 | `NATS_NAME` | `str` | `docmesh-py-core` | 선택 |
| CFG-NATS-007 | `NATS_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 1 이상 |
| CFG-NATS-008 | `NATS_MAX_RECONNECT_ATTEMPTS` | `int` | `10` | 0 이상 |

인증은 다음 중 최대 하나만 선택한다.

1. `NATS_TOKEN`
2. `NATS_USER` + `NATS_PASSWORD`
3. `NATS_CREDS_FILE`

user/password는 반드시 함께 제공한다.

## 15. Readiness 설정 상호작용

| 설정 | startup | `GET /health/readiness` |
|---|---|---|
| `DOCMESH_HEALTHCHECK_ENABLED` | true면 runtime 및 required managed resource를 startup에서 검사 | endpoint 자체는 항상 등록됨 |
| `READINESS_PARALLEL` | runtime/resource startup 검사 병렬 여부 | 요청 시 check 병렬 여부 |
| `READINESS_TIMEOUT_SECONDS` | 개별 service check timeout | custom check에 별도 timeout이 없을 때 fallback |
| `READINESS_OVERALL_TIMEOUT_SECONDS` | startup 전체 timeout | readiness 요청 전체 timeout |
| `READINESS_REQUIRED_SERVICES` | required runtime service 결정 | 실패 시 503/`error` |

`ManagedResource.required`와 `register_readiness_check(required=...)`는 서비스 목록과 별개로 각 확장 check의 필수 여부를 결정한다.

## 16. Logging 설정 상호작용

```dotenv
DOCMESH_LOG_LEVEL=INFO
APP_LOG_PATH=/var/log/service/app.log
APP_LOG_JSON=true
APP_LOG_FORCE=false
```

- `create_app()` 시점에 logging을 구성한다.
- JSON mode는 root logger의 현재 handler에 formatter를 적용한다.
- JSON payload는 timestamp/logger/level/message와 선택 event/function_event/exception을 포함한다.
- secret과 token을 log field에 직접 넣지 않는다.

## 17. 권장 구성 예시

### 17.1 서비스 없는 앱

```dotenv
DOCMESH_SERVICES=
READINESS_REQUIRED_SERVICES=
```

### 17.2 SQLite 단일 서비스

```dotenv
DOCMESH_SERVICES=sqlite
READINESS_REQUIRED_SERVICES=sqlite
SQLITE_PATH=/var/lib/service/app.db
SQLITE_ENABLE_WAL=true
DOCMESH_HEALTHCHECK_ENABLED=true
```

### 17.3 Keycloak + PostgreSQL + NATS

```dotenv
DOCMESH_SERVICES=keycloak,postgres,nats
READINESS_REQUIRED_SERVICES=keycloak,postgres

KEYCLOAK_URL=https://keycloak.example.com
KEYCLOAK_REALM=docmesh
KEYCLOAK_CLIENT_ID=service-api
KEYCLOAK_CLIENT_SECRET=[secret]
KEYCLOAK_VERIFY_SSL=true

POSTGRES_HOST=postgres.example.com
POSTGRES_PORT=5432
POSTGRES_DB=docmesh
POSTGRES_USER=service
POSTGRES_PASSWORD=[secret]

NATS_SERVERS=nats://nats.example.com:4222
NATS_CREDS_FILE=/run/secrets/nats.creds
```

NATS가 optional이므로 실패하면 readiness는 `degraded`/200이 될 수 있고, Keycloak 또는 PostgreSQL 실패는 `error`/503이다.

## 18. 문제 해결

| 증상 | 원인 | 확인/해결 |
|---|---|---|
| startup 전에 runtime dependency가 503 | 기본 runtime은 lifespan에서 생성 | request는 정상 lifespan 안에서 실행; 단위 테스트는 runtime 주입 |
| required service validation error | required가 enabled에 없음 | 두 목록 정합성 수정 |
| Keycloak client secret 누락 | 기본은 confidential client | secret 제공 또는 public client 명시 |
| PostgreSQL DSN 충돌 | DSN과 개별 필드를 함께 설정 | 개별 필드 권장; 둘 중 하나만 사용 |
| Langfuse 필수값 누락 | enabled 기본값이 true | host/keys 제공 또는 `LANGFUSE_ENABLED=false` |
| NATS auth validation error | 여러 auth mode 또는 user/password 한쪽만 설정 | 정확히 한 방식 사용 |
| production SSL validation error | insecure transport 설정 | Keycloak verify SSL, MinIO/Milvus secure 활성화 |
| `.env.example`을 복사했는데 반영 안 됨 | 자동 dotenv loading 없음 | 실행 도구에서 명시적으로 environment 주입 |

## 19. 관련 문서

- Python/HTTP 공개 API와 상태 계약: [`api.md`](api.md)
- 복사 가능한 앱·dependency·확장 예제: [`examples.md`](examples.md)
- 전체 환경변수 template: [`.env.example`](../.env.example)
