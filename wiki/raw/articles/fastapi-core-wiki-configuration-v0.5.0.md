---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Configuration-v0.5.0.md
ingested: 2026-07-20
sha256: a4753066bfd8524233cc165d30e13a9fa5656a3010d4e9da769bebe7a620bf02
---
# fastapi-core Configuration Reference

> 문서 리비전: 2026-07-19
>
> 대상 릴리스: `fastapi-core 0.5.0`
>
> 상태: current-implementation
>
> 기준: `fastapi_core.config.AppConfig`, 설치된 `docmesh-py-core 0.4.0` 설정 model, `.env.example`, 설정 회귀 테스트

---

## 1. 설정 소유권과 로딩 경로

`fastapi-core`의 설정은 두 계층으로 나뉜다.

1. **앱 계층** — `AppConfig`: FastAPI root path, CORS, readiness 정책, startup 정책, logging, 활성/필수 서비스 선택을 소유한다.
2. **서비스 계층** — DocMesh `ServiceConfigs`: Keycloak, PostgreSQL, SQLite, MinIO, Milvus, Ollama, Langfuse, NATS의 접속 설정을 소유한다.

실행 경로는 다음과 같다.

```text
process environment
  ├─ load_app_config() ──> AppConfig ──> create_app()/build_runtime_plan()
  └─ docmesh-py-core load_service_configs()
       └─ ServiceConfigs ──> ServiceRuntime.configs ──> get_settings()
```

- `AppConfig`와 서비스 설정은 프로세스 환경을 읽는다.
- 저장소의 `.env.example`은 **예시 계약이며 자동으로 로드되지 않는다**.
- dotenv가 필요하면 shell, 컨테이너, 배포 플랫폼 또는 소비 애플리케이션이 명시적으로 환경에 주입해야 한다.
- `load_app_config()`와 `load_docmesh_settings()`는 process 내에서 cache된다. 테스트에서 환경변수를 바꾸면 각 함수의 `cache_clear()`를 호출한다.
- `create_app(config=...)`에 직접 전달한 값이 있으면 해당 `AppConfig`가 환경 loader보다 우선한다.

<a id="cfg-app"></a>
## 2. `CFG-APP` — FastAPI 앱 설정

### 2.1 전체 필드

| Config ID | Python 필드 | 환경변수 | 타입 | 기본값 | 소비 지점 |
|---|---|---|---|---|---|
| `CFG-APP-001` | `root_path` | `ROOT_PATH` | `str` | `""` | `FastAPI(root_path=...)` |
| `CFG-APP-002` | `token_url` | `TOKEN_URL` | `str` | `"/token"` | 앱별 OAuth2/OpenAPI password flow URL |
| `CFG-APP-003` | `cors_origins` | `CORS_ORIGINS` | `list[str]` | `["*"]` | CORS allow origins |
| `CFG-APP-004` | `cors_credentials` | `CORS_CREDENTIALS` | `bool` | `False` | CORS credentials |
| `CFG-APP-005` | `readiness_parallel` | `READINESS_PARALLEL` | `bool` | `False` | startup 및 HTTP readiness 병렬 실행 |
| `CFG-APP-006` | `readiness_timeout_seconds` | `READINESS_TIMEOUT_SECONDS` | `float \| None` | `None` | check별 기본 timeout |
| `CFG-APP-007` | `readiness_overall_timeout_seconds` | `READINESS_OVERALL_TIMEOUT_SECONDS` | `float \| None` | `None` | readiness 전체 timeout |
| `CFG-APP-008` | `service_alternatives` | `DOCMESH_SERVICE_ALTERNATIVES` | `list[list[str]]` | `[]` | runtime `one_of` 그룹 |
| `CFG-APP-009` | `startup_healthcheck` | `DOCMESH_HEALTHCHECK_ENABLED` | `bool` | `False` | startup healthcheck 활성화 |
| `CFG-APP-010` | `startup_failure_mode` | `DOCMESH_STARTUP_FAILURE_MODE` | `StartupFailureMode` | `fail` | startup 실패 정책: `fail`, `report` |
| `CFG-APP-011` | `startup_healthcheck_attempts` | `DOCMESH_STARTUP_HEALTHCHECK_ATTEMPTS` | `int` | `1` | startup check 최대 시도 횟수 |
| `CFG-APP-012` | `startup_healthcheck_retry_delay_seconds` | `DOCMESH_STARTUP_HEALTHCHECK_RETRY_DELAY_SECONDS` | `float` | `0` | 시도 사이 지연 |
| `CFG-APP-013` | `log_level` | `DOCMESH_LOG_LEVEL` | `str \| None` | `"WARNING"` | root logger level |
| `CFG-APP-014` | `log_path` | `APP_LOG_PATH` | `str \| None` | `None` | log file path |
| `CFG-APP-015` | `log_json` | `APP_LOG_JSON` | `bool` | `True` | JSON formatter 사용 여부 |
| `CFG-APP-016` | `log_force` | `APP_LOG_FORCE` | `bool` | `False` | 기존 logging handler 강제 재구성 |
| `CFG-APP-017` | `enabled_services` | `DOCMESH_SERVICES` | `list[str]` | `[]` | runtime에 조립할 서비스 |
| `CFG-APP-018` | `required_services` | `READINESS_REQUIRED_SERVICES` | `list[str]` | `[]` | 실패 시 readiness 오류가 되는 서비스 |

### 2.2 값 형식과 검증

- `CORS_ORIGINS`, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`는 쉼표 구분 CSV다.
- 위 세 환경변수의 명시적인 빈 값(`KEY=`)은 빈 목록으로 해석된다.
- 같은 필드에 Python 생성자로 빈 문자열을 직접 전달하면 validation error다. 직접 생성할 때는 `[]`를 사용한다.
- `DOCMESH_SERVICE_ALTERNATIVES`는 `;`로 그룹을, `,`로 그룹 내 서비스를 구분한다.
  - 예: `postgres,sqlite;minio,milvus`
- 모든 `required_services`는 `enabled_services`에도 있어야 한다.
- readiness timeout은 지정 시 `0`보다 커야 한다.
- startup healthcheck 시도 횟수는 `1` 이상, 재시도 지연은 `0` 이상이어야 한다.
- 알 수 없는 서비스 이름과 잘못된 대안 그룹은 `RuntimePlan` 생성 과정에서 거부된다.
- `TOKEN_URL`은 OpenAPI scheme만 변경하며 내장 `POST /token` path는 변경하지 않는다.

<a id="cfg-readiness"></a>
### 2.3 `CFG-READINESS` — 상태 판정

| 조건 | HTTP readiness 결과 |
|---|---|
| check 없음 또는 모두 성공 | `200`, `status="ok"` |
| optional check만 실패 | `200`, `status="degraded"` |
| required check 실패 | `503`, `status="error"` |
| overall timeout | `503`, `status="error"` |

`ManagedResource.readiness_timeout_seconds` 또는 `register_readiness_check(timeout_seconds=...)`가 설정되면 app 기본 timeout보다 우선한다.

<a id="cfg-logging"></a>
### 2.4 `CFG-LOGGING` — logging

`create_app()`은 앱 생성 중 `configure_application_logging(config)`을 호출한다. `APP_LOG_JSON=true`이면 handler formatter를 `JsonLogFormatter`로 바꾼다. 빈 `APP_LOG_PATH`는 환경 파싱 결과에 따라 빈 문자열이 될 수 있으므로 파일 logging을 사용하지 않을 때는 변수를 제거하는 구성이 명확하다.

<a id="cfg-runtime"></a>
## 3. `CFG-RUNTIME` — 서비스 선택과 runtime

지원 서비스 이름:

| 이름 | typed dependency | 서비스 설정 anchor |
|---|---|---|
| `keycloak` | `get_keycloak_auth_service` | [CFG-KEYCLOAK](#cfg-keycloak) |
| `postgres` | `get_postgres_engine` | [CFG-POSTGRES](#cfg-postgres) |
| `sqlite` | `get_sqlite_engine` | [CFG-SQLITE](#cfg-sqlite) |
| `minio` | `get_minio_client` | [CFG-MINIO](#cfg-minio) |
| `milvus` | `get_milvus_client` | [CFG-MILVUS](#cfg-milvus) |
| `ollama` | `get_ollama_client` | [CFG-OLLAMA](#cfg-ollama) |
| `langfuse` | `get_langfuse_client` | [CFG-LANGFUSE](#cfg-langfuse) |
| `nats` | `get_nats_connection_builder` | [CFG-NATS](#cfg-nats) |

서비스 없는 안전한 baseline:

```bash
DOCMESH_SERVICES=
READINESS_REQUIRED_SERVICES=
```

예를 들어 SQLite를 필수 서비스로 활성화한다.

```bash
DOCMESH_SERVICES=sqlite
READINESS_REQUIRED_SERVICES=sqlite
SQLITE_PATH=:memory:
```

`runtime=`을 `create_app`에 직접 전달하면 주입한 `ServiceRuntime`의 selected/required 서비스와 client가 실제 runtime 상태의 기준이다. `AppConfig`는 여전히 HTTP와 readiness 실행 정책을 제공한다.

<a id="cfg-services"></a>
## 4. `CFG-SERVICES` — DocMesh 서비스 설정

아래 설정은 `docmesh-py-core 0.4.0`이 소유한다. `fastapi-core`는 활성 서비스만 loader에 전달하고 결과를 `ServiceRuntime.configs`에 보존한다. route에서는 `get_settings()`로 읽는다.

표의 **필수**는 해당 서비스가 활성화될 때 model 생성에 필요한 필드다. `None` 기본값이어도 다른 필드와의 조합 검증으로 필요할 수 있는 값은 설명에 조건을 적었다.

<a id="cfg-common"></a>
### 4.1 공통 (`DOCMESH_`)

| Config ID | 환경변수 | 타입 | 기본값 | 설명 |
|---|---|---|---|---|
| `CFG-COMMON-001` | `DOCMESH_ENV` | `str` | `development` | 실행 환경 이름 |
| `CFG-COMMON-002` | `DOCMESH_SECURITY_MODE` | `development \| production \| None` | `None` | 명시적 보안 검증 모드 |
| `CFG-COMMON-003` | `DOCMESH_PRODUCTION_ALIASES` | `list[str]` | `prod,production` | production으로 간주할 환경 alias |

운영 환경에서는 `DOCMESH_ENV` 또는 `DOCMESH_SECURITY_MODE`를 명시해 production 보안 검증이 적용되도록 한다.

<a id="cfg-keycloak"></a>
### 4.2 `CFG-KEYCLOAK` (`KEYCLOAK_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-KEYCLOAK-001` | `KEYCLOAK_URL` | `str` | 필수 | Keycloak base URL |
| `CFG-KEYCLOAK-002` | `KEYCLOAK_REALM` | `str` | 필수 | realm |
| `CFG-KEYCLOAK-003` | `KEYCLOAK_CLIENT_ID` | `str` | 필수 | OAuth client ID |
| `CFG-KEYCLOAK-004` | `KEYCLOAK_CLIENT_SECRET` | `str \| None` | `None` | confidential client에서 필요 |
| `CFG-KEYCLOAK-005` | `KEYCLOAK_VERIFY_SSL` | `bool` | `true` | TLS 인증서 검증 |
| `CFG-KEYCLOAK-006` | `KEYCLOAK_AUDIENCE` | `str \| None` | `None` | token audience |
| `CFG-KEYCLOAK-007` | `KEYCLOAK_TOKEN_GRANT_TYPE` | `str` | `password` | token grant type |
| `CFG-KEYCLOAK-008` | `KEYCLOAK_TOKEN_SCOPE` | `str \| None` | `None` | 기본 token scope |
| `CFG-KEYCLOAK-009` | `KEYCLOAK_TOKEN_USERNAME` | `str \| None` | `None` | service password grant username |
| `CFG-KEYCLOAK-010` | `KEYCLOAK_TOKEN_PASSWORD` | `str \| None` | `None` | service password grant password |
| `CFG-KEYCLOAK-011` | `KEYCLOAK_REQUEST_TIMEOUT_SECONDS` | `int` | `10` | 요청 timeout |
| `CFG-KEYCLOAK-012` | `KEYCLOAK_MAX_RETRIES` | `int` | `3` | 최대 재시도 |
| `CFG-KEYCLOAK-013` | `KEYCLOAK_JWKS_CACHE_TTL_SECONDS` | `int` | `300` | JWKS cache TTL |
| `CFG-KEYCLOAK-014` | `KEYCLOAK_PROVISIONING_ENABLED` | `bool` | `false` | realm/client provisioning |
| `CFG-KEYCLOAK-015` | `KEYCLOAK_PROVISIONING_DRY_RUN` | `bool` | `false` | provisioning dry-run |
| `CFG-KEYCLOAK-016` | `KEYCLOAK_ADMIN_REALM` | `str` | `master` | 관리자 realm |
| `CFG-KEYCLOAK-017` | `KEYCLOAK_ADMIN_CLIENT_ID` | `str` | `admin-cli` | 관리자 client ID |
| `CFG-KEYCLOAK-018` | `KEYCLOAK_ADMIN_CLIENT_SECRET` | `str \| None` | `None` | service-account 관리자 인증 |
| `CFG-KEYCLOAK-019` | `KEYCLOAK_ADMIN_USERNAME` | `str \| None` | `None` | password 관리자 인증 |
| `CFG-KEYCLOAK-020` | `KEYCLOAK_ADMIN_PASSWORD` | `str \| None` | `None` | password 관리자 인증 |
| `CFG-KEYCLOAK-021` | `KEYCLOAK_REALM_ENABLED` | `bool` | `true` | provisioning realm 활성 상태 |
| `CFG-KEYCLOAK-022` | `KEYCLOAK_REALM_DISPLAY_NAME` | `str \| None` | `None` | realm 표시 이름 |
| `CFG-KEYCLOAK-023` | `KEYCLOAK_CLIENT_PUBLIC` | `bool` | `false` | public client 여부 |
| `CFG-KEYCLOAK-024` | `KEYCLOAK_CLIENT_REDIRECT_URIS` | `list[str]` | `[]` | redirect URI 목록 |
| `CFG-KEYCLOAK-025` | `KEYCLOAK_CLIENT_WEB_ORIGINS` | `list[str]` | `[]` | web origin 목록 |
| `CFG-KEYCLOAK-026` | `KEYCLOAK_REALM_ROLES` | `list[str]` | `[]` | provisioning realm role 목록 |
| `CFG-KEYCLOAK-027` | `KEYCLOAK_CLIENT_ROLES` | `list[str]` | `[]` | provisioning client role 목록 |

provisioning 관리자 인증은 client secret 방식 또는 username/password 방식 중 하나만 선택한다. secret과 password는 문서, 로그, shell history에 실제 값을 남기지 않는다.

<a id="cfg-postgres"></a>
### 4.3 `CFG-POSTGRES` (`POSTGRES_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-POSTGRES-001` | `POSTGRES_HOST` | `str` | 필수 | host |
| `CFG-POSTGRES-002` | `POSTGRES_PORT` | `int` | `5432` | port |
| `CFG-POSTGRES-003` | `POSTGRES_DB` | `str` | 필수 | database |
| `CFG-POSTGRES-004` | `POSTGRES_USER` | `str` | 필수 | user |
| `CFG-POSTGRES-005` | `POSTGRES_PASSWORD` | `str` | 필수 | password |
| `CFG-POSTGRES-006` | `POSTGRES_SSLMODE` | `str` | `prefer` | PostgreSQL SSL mode |
| `CFG-POSTGRES-007` | `POSTGRES_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 연결 timeout |
| `CFG-POSTGRES-008` | `POSTGRES_POOL_SIZE` | `int` | `5` | pool size |
| `CFG-POSTGRES-009` | `POSTGRES_MAX_OVERFLOW` | `int` | `10` | pool overflow |

`POSTGRES_DSN`은 현재 계약이 아니다. 개별 접속 항목을 사용한다.

<a id="cfg-sqlite"></a>
### 4.4 `CFG-SQLITE` (`SQLITE_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-SQLITE-001` | `SQLITE_PATH` | `str` | 필수 | DB path, 예: `:memory:` |
| `CFG-SQLITE-002` | `SQLITE_READONLY` | `bool` | `false` | read-only 연결 |
| `CFG-SQLITE-003` | `SQLITE_ENABLE_WAL` | `bool` | `false` | WAL 활성화 |
| `CFG-SQLITE-004` | `SQLITE_BUSY_TIMEOUT_MS` | `int` | `5000` | busy timeout(ms) |

<a id="cfg-minio"></a>
### 4.5 `CFG-MINIO` (`MINIO_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-MINIO-001` | `MINIO_ENDPOINT` | `str` | 필수 | `host:port` endpoint |
| `CFG-MINIO-002` | `MINIO_ACCESS_KEY` | `str` | 필수 | access key |
| `CFG-MINIO-003` | `MINIO_SECRET_KEY` | `str` | 필수 | secret key |
| `CFG-MINIO-004` | `MINIO_SECURE` | `bool` | `true` | TLS 사용 |
| `CFG-MINIO-005` | `MINIO_REGION` | `str \| None` | `None` | region |
| `CFG-MINIO-006` | `MINIO_BUCKET` | `str \| None` | `None` | 기본 bucket |
| `CFG-MINIO-007` | `MINIO_REQUEST_TIMEOUT_SECONDS` | `int` | `30` | 요청 timeout |
| `CFG-MINIO-008` | `MINIO_MAX_RETRIES` | `int` | `3` | 최대 재시도 |

<a id="cfg-milvus"></a>
### 4.6 `CFG-MILVUS` (`MILVUS_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-MILVUS-001` | `MILVUS_URI` | `str` | 필수 | Milvus URI |
| `CFG-MILVUS-002` | `MILVUS_TOKEN` | `str \| None` | `None` | 인증 token |
| `CFG-MILVUS-003` | `MILVUS_DB_NAME` | `str` | `default` | database name |
| `CFG-MILVUS-004` | `MILVUS_COLLECTION` | `str \| None` | `None` | 기본 collection |
| `CFG-MILVUS-005` | `MILVUS_SECURE` | `bool` | `false` | TLS/security mode |
| `CFG-MILVUS-006` | `MILVUS_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 연결 timeout |
| `CFG-MILVUS-007` | `MILVUS_REQUEST_TIMEOUT_SECONDS` | `int` | `30` | 요청 timeout |
| `CFG-MILVUS-008` | `MILVUS_MAX_RETRIES` | `int` | `3` | 최대 재시도 |

<a id="cfg-ollama"></a>
### 4.7 `CFG-OLLAMA` (`OLLAMA_`)

| Config ID | 환경변수 | 타입 | 기본값/필수 | 설명 |
|---|---|---|---|---|
| `CFG-OLLAMA-001` | `OLLAMA_HOST` | `str` | 필수 | Ollama base URL |
| `CFG-OLLAMA-002` | `OLLAMA_GENERATION_MODEL` | `str \| None` | `None` | 기본 생성 model |
| `CFG-OLLAMA-003` | `OLLAMA_EMBEDDING_MODEL` | `str \| None` | `None` | 기본 embedding model |
| `CFG-OLLAMA-004` | `OLLAMA_REQUEST_TIMEOUT_SECONDS` | `int` | `120` | 요청 timeout |
| `CFG-OLLAMA-005` | `OLLAMA_MAX_RETRIES` | `int` | `2` | 최대 재시도 |

<a id="cfg-langfuse"></a>
### 4.8 `CFG-LANGFUSE` (`LANGFUSE_`)

| Config ID | 환경변수 | 타입 | 기본값 | 설명 |
|---|---|---|---|---|
| `CFG-LANGFUSE-001` | `LANGFUSE_ENABLED` | `bool` | `true` | client 활성 상태 |
| `CFG-LANGFUSE-002` | `LANGFUSE_HOST` | `str \| None` | `None` | Langfuse host |
| `CFG-LANGFUSE-003` | `LANGFUSE_PUBLIC_KEY` | `str \| None` | `None` | public key |
| `CFG-LANGFUSE-004` | `LANGFUSE_SECRET_KEY` | `str \| None` | `None` | secret key |
| `CFG-LANGFUSE-005` | `LANGFUSE_RELEASE` | `str \| None` | `None` | release label |
| `CFG-LANGFUSE-006` | `LANGFUSE_ENVIRONMENT` | `str \| None` | `None` | environment label |
| `CFG-LANGFUSE-007` | `LANGFUSE_REQUEST_TIMEOUT_SECONDS` | `int` | `10` | 요청 timeout |
| `CFG-LANGFUSE-008` | `LANGFUSE_MAX_RETRIES` | `int` | `3` | 최대 재시도 |

Langfuse 서비스를 활성화하고 `LANGFUSE_ENABLED=true`로 사용할 때는 host, public key, secret key를 함께 제공한다.

<a id="cfg-nats"></a>
### 4.9 `CFG-NATS` (`NATS_`)

| Config ID | 환경변수 | 타입 | 기본값 | 설명 |
|---|---|---|---|---|
| `CFG-NATS-001` | `NATS_SERVERS` | `list[str]` | `[]` | server URL 목록 |
| `CFG-NATS-002` | `NATS_USER` | `str \| None` | `None` | user 인증 |
| `CFG-NATS-003` | `NATS_PASSWORD` | `str \| None` | `None` | user password |
| `CFG-NATS-004` | `NATS_TOKEN` | `str \| None` | `None` | token 인증 |
| `CFG-NATS-005` | `NATS_CREDS_FILE` | `str \| None` | `None` | credentials file |
| `CFG-NATS-006` | `NATS_NAME` | `str` | `docmesh-py-core` | connection name |
| `CFG-NATS-007` | `NATS_CONNECT_TIMEOUT_SECONDS` | `int` | `10` | 연결 timeout |
| `CFG-NATS-008` | `NATS_MAX_RECONNECT_ATTEMPTS` | `int` | `10` | 최대 재연결 횟수 |

인증은 token, user/password, credentials file 중 최대 하나의 방식을 선택한다. user 방식을 선택하면 user와 password를 함께 제공한다.

## 5. 배포 예시

### 5.1 외부 서비스 없는 개발 baseline

```bash
ROOT_PATH=
TOKEN_URL=/token
CORS_ORIGINS=http://localhost:3000
CORS_CREDENTIALS=false
DOCMESH_SERVICES=
READINESS_REQUIRED_SERVICES=
DOCMESH_HEALTHCHECK_ENABLED=false
```

### 5.2 Keycloak + PostgreSQL

```bash
DOCMESH_SERVICES=keycloak,postgres
READINESS_REQUIRED_SERVICES=keycloak,postgres
DOCMESH_HEALTHCHECK_ENABLED=true
DOCMESH_STARTUP_FAILURE_MODE=fail

KEYCLOAK_URL=https://keycloak.example.com
KEYCLOAK_REALM=docmesh
KEYCLOAK_CLIENT_ID=service-api
KEYCLOAK_CLIENT_SECRET=[REDACTED]
KEYCLOAK_CLIENT_PUBLIC=false

POSTGRES_HOST=postgres.example.com
POSTGRES_PORT=5432
POSTGRES_DB=docmesh
POSTGRES_USER=docmesh
POSTGRES_PASSWORD=[REDACTED]
```

### 5.3 PostgreSQL 또는 SQLite 대안

```bash
DOCMESH_SERVICES=sqlite
READINESS_REQUIRED_SERVICES=sqlite
DOCMESH_SERVICE_ALTERNATIVES=postgres,sqlite
SQLITE_PATH=/data/app.db
```

각 대안 그룹은 선택 서비스 중 최소 하나가 포함되어야 한다.

## 6. 운영 체크리스트

- 실제 credential은 `.env.example`, Git, 문서, 로그에 저장하지 않는다.
- credential-dependent 서비스를 `DOCMESH_SERVICES`에 활성화했다면 필요한 credential도 같은 배포 단위에서 주입한다.
- `READINESS_REQUIRED_SERVICES`가 `DOCMESH_SERVICES`의 부분집합인지 확인한다.
- production에서는 TLS 검증을 끄지 않고 production 보안 mode를 명시한다.
- `.env.example`을 shell에 직접 source하기보다 배포 도구의 환경 주입 기능을 사용한다.
- 환경변수 변경 후 장기 실행 process를 재시작한다. loader cache는 실행 중 자동 갱신되지 않는다.
- 설정이 적용됐는지는 secret을 출력하지 말고 `/health/readiness`와 구조화된 startup log로 검증한다.
