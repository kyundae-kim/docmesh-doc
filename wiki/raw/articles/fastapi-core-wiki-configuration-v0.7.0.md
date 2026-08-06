---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Configuration-v0.7.0.md
ingested: 2026-08-02
sha256: c3121122f8bc158b0669428ad4489ea6fb7addcb45e4cc54d3fa246b7f10dd07
---
# fastapi-core 설정 가이드

> 기준 릴리스: `fastapi-core 0.7.0`

이 페이지는 `docs/config.md`를 Git wiki용으로 확장 캡처한 설정 계약이다. 앱 설정(`AppConfig`)과 DocMesh service 설정(`ServiceConfigs`)을 분리하고, 설정을 소비하는 runtime/dependency, 대응 example, `.env.example` key까지 `CFG-*` anchor로 추적한다.

- API 계약: [fastapi-core API](API-Reference-v0.7.0.md)
- 소비자 예제: [fastapi-core examples](Examples-v0.7.0.md)
- 저장소 템플릿: `.env.example`
- upstream 설정 모델: `docmesh_config` v0.1.0 (`pyproject.toml`의 `docmesh-config` v0.1.0 pin)

## 1. 설정 경계

- `fastapi-core`는 `.env` 파일을 자동으로 읽는 loader가 아니다. shell, container, deployment platform 또는 별도 dotenv loader가 값을 process environment에 주입해야 한다.
- `AppConfig`는 FastAPI app 조립, CORS, OAuth2 metadata, readiness, startup healthcheck, logging policy를 소유한다.
- `docmesh_config.ServiceConfigs`는 선택된 Keycloak/PostgreSQL/SQLite/MinIO/Milvus/Ollama/Langfuse/NATS client 설정을 소유한다.
- `load_docmesh_settings(enabled_services)`는 선택 집합을 `docmesh_config.load_service_configs(services=...)`에 전달하며 process environment를 임시로 변경하지 않는다.
- runtime assembly가 만든 `ServiceRuntime.configs`가 실제 request dependency에서 반환되는 service settings다. 임의의 `app.state` map을 직접 읽지 않는다.
- secrets, token, password, DSN, endpoint credential을 문서/로그에 실제 값으로 남기지 않는다.

<a id="cfg-app-001"></a>
## CFG-APP-001 — AppConfig 필드와 환경변수

`fastapi_core.config.AppConfig`는 field name과 대문자 environment alias를 모두 받는다. 같은 입력에서 field name이 alias보다 우선한다. CSV field의 process 환경변수 빈 문자열은 빈 목록으로 해석되지만, 직접 생성자에 `""`을 넣는 것은 validation error다.

| field | type | default | environment alias | runtime usage |
| --- | --- | --- | --- | --- |
| `root_path` | `str` | `""` | `ROOT_PATH` | `FastAPI(root_path=...)` |
| `token_url` | `str` | `"/token"` | `TOKEN_URL` | 앱별 OAuth2 password flow metadata |
| `cors_origins` | `list[str]` | wildcard list ["*"] | `CORS_ORIGINS` | CORS allow origins; comma-separated |
| `cors_credentials` | `bool` | `False` | `CORS_CREDENTIALS` | CORS credentials |
| `readiness_parallel` | `bool` | `False` | `READINESS_PARALLEL` | readiness check scheduling |
| `readiness_timeout_seconds` | `float or None` | `None` | `READINESS_TIMEOUT_SECONDS` | per-service/default readiness timeout; 지정 시 `> 0` |
| `readiness_overall_timeout_seconds` | `float or None` | `None` | `READINESS_OVERALL_TIMEOUT_SECONDS` | 전체 readiness timeout; 지정 시 `> 0` |
| `service_alternatives` | `list[list[str]]` | `[]` | `DOCMESH_SERVICE_ALTERNATIVES` | 각 group에서 하나 이상 선택되는 `one_of` policy |
| `startup_healthcheck` | `bool` | `False` | `DOCMESH_HEALTHCHECK_ENABLED` | runtime startup healthcheck on/off |
| `startup_failure_mode` | `StartupFailureMode` | `FAIL` | `DOCMESH_STARTUP_FAILURE_MODE` | startup healthcheck 실패 처리; `fail`/`report` |
| `startup_healthcheck_attempts` | `int` | `1` | `DOCMESH_STARTUP_HEALTHCHECK_ATTEMPTS` | 최소 `1` |
| `startup_healthcheck_retry_delay_seconds` | `float` | `0` | `DOCMESH_STARTUP_HEALTHCHECK_RETRY_DELAY_SECONDS` | 최소 `0` |
| `log_level` | `str or None` | `"WARNING"` | `DOCMESH_LOG_LEVEL` | application logging level |
| `log_path` | `str or None` | `None` | `APP_LOG_PATH` | file handler 경로 |
| `log_json` | `bool` | `True` | `APP_LOG_JSON` | JSON formatter 선택 |
| `log_force` | `bool` | `False` | `APP_LOG_FORCE` | 기존 logging handler 재설정 |
| `access_log_enabled` | `bool` | `True` | `ACCESS_LOG_ENABLED` | `AccessLogMiddleware` 설치 |
| `access_log_health_enabled` | `bool` | `False` | `ACCESS_LOG_HEALTH_ENABLED` | health route access log 포함 |
| `enabled_services` | `list[str]` | `[]` | `DOCMESH_SERVICES` | runtime plan에 포함할 service |
| `required_services` | `list[str]` | `[]` | `READINESS_REQUIRED_SERVICES` | enabled service의 subset이어야 함 |

<a id="cfg-app-002"></a>
## CFG-APP-002 — AppConfig 로딩과 validation

- `load_app_config()`는 `@lru_cache(maxsize=1)`인 process-level loader다. 테스트나 환경 전환에서는 `load_app_config.cache_clear()`를 호출한다.
- `.env` 자동 로딩은 하지 않는다. `SettingsConfigDict`의 dotenv source는 명시적 external loader가 연결된 경우의 source일 뿐 저장소 `.env`를 implicit하게 읽는 계약이 아니다.
- `cors_origins`, `enabled_services`, `required_services`는 쉼표로 나눈다. 공백 항목은 제거한다.
- `DOCMESH_SERVICE_ALTERNATIVES`는 `postgres,sqlite;minio,milvus`처럼 세미콜론으로 group, 쉼표로 service를 나눈다.
- `required_services`가 `enabled_services`에 포함되지 않으면 생성이 거부된다.
- readiness timeout은 지정 시 양수여야 한다.
- startup healthcheck attempts는 1 이상, retry delay는 0 이상이어야 한다.
- service 이름은 runtime plan 생성 시 `docmesh_config.Service.parse`로 검증된다.

<a id="cfg-app-003"></a>
## CFG-APP-003 — module/transport 조립 경계

`AppConfig`는 앱 전역 policy를 소유하지만 `DomainModule`, `TransportPolicy`, router/resource 목록은 `create_app(...)` 인자로 명시적으로 조립한다. module 설정은 environment key를 직접 만들지 않는다.

- `DomainModule.transport_policy`는 해당 module route의 dependency, validation status, common error response와 OpenAPI metadata를 결정한다.
- `create_app(transport_policy=...)`는 직접 전달한 router에만 앱 기본 policy를 적용한다. health/auth built-in router에는 domain policy가 자동 전파되지 않는다.
- policy를 생략하면 FastAPI 기본 validation `422`를 유지한다. `validation_status=400`과 `include_synthetic_422=False`는 함께 설정할 수 있다.
- module/resource 이름 충돌과 route/policy 충돌은 startup 전에 validation error가 된다.

대응 API/예제:

- API: `API-APP-002`~`004`, `API-TRAN-001`
- Example: [EX-MOD-001](Examples-v0.7.0.md#ex-mod-001), [EX-MOD-002](Examples-v0.7.0.md#ex-mod-002)
- Tests: `test_fastapi_core/test_target_contracts.py`, `test_fastapi_core/test_factory.py`

<a id="cfg-ready-001"></a>
## CFG-READY-001 — readiness/startup 정책

`AppConfig` 값은 `fastapi_core.runtime.build_runtime_plan`에서 `docmesh_config.RuntimePlan`으로 변환된다.

- `readiness_parallel` → `HealthcheckPolicy.parallel`
- `readiness_timeout_seconds` → per-service/default timeout
- `readiness_overall_timeout_seconds` → overall timeout
- `startup_healthcheck` → `HealthcheckPolicy.on_startup`
- `startup_failure_mode` → `HealthcheckPolicy.failure_mode`
- `startup_healthcheck_attempts` → `HealthcheckPolicy.attempts`
- `startup_healthcheck_retry_delay_seconds` → `HealthcheckPolicy.retry_delay_seconds`
- managed resource의 `readiness_timeout_seconds`는 해당 resource check에만 적용되는 local override다.

대응 API/예제:

- API: `API-READY-001`~`006`, `API-HTTP-ROUTE-002`, `API-SCHEMA-001`~`002`
- Example: [EX-READY-001](Examples-v0.7.0.md#ex-ready-001)
- Tests: `test_fastapi_core/test_health_router.py`, `test_fastapi_core/test_extensions.py`, `test_fastapi_core/test_config.py`

<a id="cfg-auth-001"></a>
## CFG-AUTH-001 — Keycloak/auth router 조건

`create_app(include_auth_router=True)`의 기본 runtime path는 다음을 요구한다.

- `keycloak`이 `DOCMESH_SERVICES`에 포함
- `keycloak`이 `READINESS_REQUIRED_SERVICES`에도 포함
- Keycloak 설정 진단이 성공
- explicit runtime path에서는 auth provider가 runtime에서 노출되거나 `auth_provider=`로 명시되어야 함

내장 API는 `POST /token`, `GET /user`다. `TOKEN_URL`은 OAuth2 OpenAPI flow의 metadata만 변경하며 내장 route path를 변경하지 않는다.

Keycloak service model의 상세 key와 기본값은 [CFG-SVC-KEYCLOAK](#cfg-svc-keycloak)을 참고한다. 대응 API/예제는 `API-DEP-001`, `API-DEP-003`, `API-DEP-009`, `API-HTTP-ROUTE-003`~`004`, [EX-APP-002](Examples-v0.7.0.md#ex-app-002)다.

<a id="cfg-log-001"></a>
## CFG-LOG-001 — application/access logging

- `DOCMESH_LOG_LEVEL` → `AppConfig.log_level`
- `APP_LOG_PATH` → optional file output
- `APP_LOG_JSON` → `JsonLogFormatter` 사용 여부
- `APP_LOG_FORCE` → 기존 handler 재설정 여부
- `ACCESS_LOG_ENABLED` → access log middleware on/off
- `ACCESS_LOG_HEALTH_ENABLED` → `/health/*` access event 포함 여부

`log_function_boundary`의 function start/end/error event와 HTTP correlation ID는 logging 설정과 별도지만 같은 application observability surface로 함께 추적한다. 대응 예제는 [EX-LOG-001](Examples-v0.7.0.md#ex-log-001)이다.

<a id="cfg-runtime-001"></a>
## CFG-RUNTIME-001 — runtime 조립과 settings ownership

```python
from fastapi_core.config import AppConfig
from fastapi_core.docmesh_settings import load_docmesh_settings
from fastapi_core.runtime import assemble_runtime, build_runtime_plan

config = AppConfig(
    enabled_services=[],
    required_services=[],
)
plan = build_runtime_plan(config)
settings = load_docmesh_settings(("sqlite",))
```

- 기본 `create_app(config=...)`는 enabled service가 있을 때 lifespan startup에서 `build_runtime_plan` → async `assemble_runtime`를 호출한다.
- explicit `runtime=`은 완성된 `ServiceRuntime`을 주입하는 seam이며 app state/readiness/lifecycle wiring은 동일하다.
- `load_docmesh_settings(())`는 명시적으로 service를 선택하지 않은 `ServiceConfigs`를 반환한다. `None`은 upstream loader에 선택 정책을 맡긴다.
- `get_config(request)`는 `app.state.config`를 반환하고 없을 때 `load_app_config()`로 fallback한다.
- `get_settings(request)`는 `get_service_runtime(request).configs`를 반환한다.

대응 API/예제는 `API-RUNTIME-001`~`003`, `API-CFG-001`~`002`, `API-DEP-002`, `API-DEP-007`~`008`, [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001)이다.

<a id="cfg-res-001"></a>
## CFG-RES-001 — managed resource 설정 경계

`ManagedResource`와 `ResourceBinding`은 environment key를 직접 읽지 않는다. factory가 service/resource를 만들고, `create_app`의 `ResourceRegistry`가 startup, readiness, dependency, reverse shutdown을 소유한다.

따라서 이 API의 config anchor는 `설정 없음`이 아니라 **앱 resource factory가 사용하는 service 설정과 lifecycle 정책**이다.

- resource 자체: `API-RES-001`~`004`, `API-DEP-005`
- runtime policy: `CFG-READY-001`, `CFG-RUNTIME-001`
- consumer pattern: [EX-RES-001](Examples-v0.7.0.md#ex-res-001)

<a id="cfg-svc-001"></a>
## CFG-SVC-001 — DocMesh service model inventory

`load_docmesh_settings()`가 반환하는 `ServiceConfigs`는 `common`과 아래 optional service model을 가진 dataclass다. `DOCMESH_SERVICES`/`enabled_services`로 선택한 모델만 runtime에 포함한다.

| service field | model | environment prefix | required baseline | runtime consumer |
| --- | --- | --- | --- | --- |
| `common` | `CommonConfig` | `DOCMESH_` | 없음 | runtime plan/security diagnosis |
| `keycloak` | `KeycloakConfig` | `KEYCLOAK_` | `URL`, `REALM`, `CLIENT_ID`; confidential mode는 secret | auth provider/token/JWKS |
| `postgres` | `PostgresConfig` | `POSTGRES_` | `HOST`, `DB`, `USER`, `PASSWORD` | PostgreSQL engine dependency |
| `sqlite` | `SqliteConfig` | `SQLITE_` | `PATH` | SQLite engine dependency |
| `minio` | `MinioConfig` | `MINIO_` | `ENDPOINT`, `ACCESS_KEY`, `SECRET_KEY` | MinIO client dependency |
| `milvus` | `MilvusConfig` | `MILVUS_` | `ENDPOINT` | Milvus client dependency |
| `ollama` | `OllamaConfig` | `OLLAMA_` | `HOST` | Ollama client dependency |
| `langfuse` | `LangfuseConfig` | `LANGFUSE_` | enabled mode의 host/public/secret key | Langfuse client dependency |
| `nats` | `NatsConfig` | `NATS_` | `SERVERS` | NATS connection builder dependency |

<a id="cfg-svc-common"></a>
### CFG-SVC-COMMON — CommonConfig

- `env` → `DOCMESH_ENV`, default `development`
- `security_mode` → `DOCMESH_SECURITY_MODE`, default unset
- `production_aliases` → `DOCMESH_PRODUCTION_ALIASES`, default `prod,production`

`prod`/`production` alias 또는 명시적인 production security mode는 TLS/certificate와 placeholder credential guardrail을 활성화한다.

<a id="cfg-svc-keycloak"></a>
### CFG-SVC-KEYCLOAK — KeycloakConfig

모델 필드와 environment key는 다음과 같다.

| field | environment key | default/condition |
| --- | --- | --- |
| `url` | `KEYCLOAK_URL` | required |
| `realm` | `KEYCLOAK_REALM` | required |
| `client_id` | `KEYCLOAK_CLIENT_ID` | required |
| `client_secret` | `KEYCLOAK_CLIENT_SECRET` | confidential mode에서 required; `client_public=true`면 optional |
| `verify_ssl` | `KEYCLOAK_VERIFY_SSL` | `True` |
| `audience` | `KEYCLOAK_AUDIENCE` | `None` |
| `token_grant_type` | `KEYCLOAK_TOKEN_GRANT_TYPE` | `password` |
| `token_scope` | `KEYCLOAK_TOKEN_SCOPE` | `None` |
| `token_username` | `KEYCLOAK_TOKEN_USERNAME` | `None` |
| `token_password` | `KEYCLOAK_TOKEN_PASSWORD` | `None` |
| `request_timeout_seconds` | `KEYCLOAK_REQUEST_TIMEOUT_SECONDS` | `10` |
| `max_retries` | `KEYCLOAK_MAX_RETRIES` | `3` |
| `jwks_cache_ttl_seconds` | `KEYCLOAK_JWKS_CACHE_TTL_SECONDS` | `300` |
| `provisioning_enabled` | `KEYCLOAK_PROVISIONING_ENABLED` | `False` |
| `provisioning_dry_run` | `KEYCLOAK_PROVISIONING_DRY_RUN` | `False` |
| `admin_realm` | `KEYCLOAK_ADMIN_REALM` | `master` |
| `admin_client_id` | `KEYCLOAK_ADMIN_CLIENT_ID` | `admin-cli` |
| `admin_client_secret` | `KEYCLOAK_ADMIN_CLIENT_SECRET` | `None` |
| `admin_username` | `KEYCLOAK_ADMIN_USERNAME` | `None` |
| `admin_password` | `KEYCLOAK_ADMIN_PASSWORD` | `None` |
| `realm_enabled` | `KEYCLOAK_REALM_ENABLED` | `True` |
| `realm_display_name` | `KEYCLOAK_REALM_DISPLAY_NAME` | `None` |
| `client_public` | `KEYCLOAK_CLIENT_PUBLIC` | `False` |
| `client_redirect_uris` | `KEYCLOAK_CLIENT_REDIRECT_URIS` | empty list |
| `client_web_origins` | `KEYCLOAK_CLIENT_WEB_ORIGINS` | empty list |
| `realm_roles` | `KEYCLOAK_REALM_ROLES` | empty list |
| `client_roles` | `KEYCLOAK_CLIENT_ROLES` | empty list |

Provisioning enabled 시 admin auth는 `ADMIN_CLIENT_SECRET` 또는 `ADMIN_USERNAME`+`ADMIN_PASSWORD` 중 정확히 하나여야 한다. production에서는 `KEYCLOAK_VERIFY_SSL=true`가 필요하다.

<a id="cfg-svc-postgres"></a>
### CFG-SVC-POSTGRES — PostgresConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `host` | `POSTGRES_HOST` | required |
| `port` | `POSTGRES_PORT` | `5432` |
| `db` | `POSTGRES_DB` | required |
| `user` | `POSTGRES_USER` | required |
| `password` | `POSTGRES_PASSWORD` | required |
| `sslmode` | `POSTGRES_SSLMODE` | `prefer` |
| `connect_timeout_seconds` | `POSTGRES_CONNECT_TIMEOUT_SECONDS` | `10` |
| `pool_size` | `POSTGRES_POOL_SIZE` | `5` |
| `max_overflow` | `POSTGRES_MAX_OVERFLOW` | `10` |
| `pool_pre_ping` | `POSTGRES_POOL_PRE_PING` | `False` |
| `pool_recycle_seconds` | `POSTGRES_POOL_RECYCLE_SECONDS` | `-1` |
| `echo` | `POSTGRES_ECHO` | `False` |
| `application_name` | `POSTGRES_APPLICATION_NAME` | `None` |

`POSTGRES_DSN`은 현재 설정 계약에 없다. 개별 field를 주입하고 `get_postgres_engine` 또는 runtime assembly가 SQLAlchemy engine을 만든다.

<a id="cfg-svc-sqlite"></a>
### CFG-SVC-SQLITE — SqliteConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `path` | `SQLITE_PATH` | required; local smoke test는 `:memory:` 가능 |
| `readonly` | `SQLITE_READONLY` | `False` |
| `enable_wal` | `SQLITE_ENABLE_WAL` | `False` |
| `busy_timeout_ms` | `SQLITE_BUSY_TIMEOUT_MS` | `5000` |
| `check_same_thread` | `SQLITE_CHECK_SAME_THREAD` | `False` |
| `echo` | `SQLITE_ECHO` | `False` |

<a id="cfg-svc-minio"></a>
### CFG-SVC-MINIO — MinioConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `endpoint` | `MINIO_ENDPOINT` | required |
| `access_key` | `MINIO_ACCESS_KEY` | required |
| `secret_key` | `MINIO_SECRET_KEY` | required |
| `secure` | `MINIO_SECURE` | `True`; production에서 true |
| `cert_check` | `MINIO_CERT_CHECK` | `True`; production에서 true |
| `region` | `MINIO_REGION` | `None` |
| `bucket` | `MINIO_BUCKET` | `None` |
| `request_timeout_seconds` | `MINIO_REQUEST_TIMEOUT_SECONDS` | `30` |
| `max_retries` | `MINIO_MAX_RETRIES` | `3` |

`MILVUS_URI`는 문서화하지 않는다. canonical key는 `MINIO_ENDPOINT`와 별개로 Milvus의 `MILVUS_ENDPOINT`다.

<a id="cfg-svc-milvus"></a>
### CFG-SVC-MILVUS — MilvusConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `endpoint` | `MILVUS_ENDPOINT` | required |
| `token` | `MILVUS_TOKEN` | `None` |
| `db_name` | `MILVUS_DB_NAME` | `default` |
| `collection` | `MILVUS_COLLECTION` | `None` |
| `secure` | `MILVUS_SECURE` | `False`; production에서 true |
| `connect_timeout_seconds` | `MILVUS_CONNECT_TIMEOUT_SECONDS` | `10` |
| `request_timeout_seconds` | `MILVUS_REQUEST_TIMEOUT_SECONDS` | `30` |
| `max_retries` | `MILVUS_MAX_RETRIES` | `3` |

<a id="cfg-svc-ollama"></a>
### CFG-SVC-OLLAMA — OllamaConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `host` | `OLLAMA_HOST` | required |
| `verify_ssl` | `OLLAMA_VERIFY_SSL` | `True`; production에서 true |
| `follow_redirects` | `OLLAMA_FOLLOW_REDIRECTS` | `True` |
| `generation_model` | `OLLAMA_GENERATION_MODEL` | `None` |
| `embedding_model` | `OLLAMA_EMBEDDING_MODEL` | `None` |
| `request_timeout_seconds` | `OLLAMA_REQUEST_TIMEOUT_SECONDS` | `120` |
| `max_retries` | `OLLAMA_MAX_RETRIES` | `2` |

<a id="cfg-svc-langfuse"></a>
### CFG-SVC-LANGFUSE — LangfuseConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `enabled` | `LANGFUSE_ENABLED` | `True` |
| `host` | `LANGFUSE_HOST` | `None` |
| `public_key` | `LANGFUSE_PUBLIC_KEY` | `None` |
| `secret_key` | `LANGFUSE_SECRET_KEY` | `None` |
| `release` | `LANGFUSE_RELEASE` | `None` |
| `environment` | `LANGFUSE_ENVIRONMENT` | `None` |
| `request_timeout_seconds` | `LANGFUSE_REQUEST_TIMEOUT_SECONDS` | `10` |
| `max_retries` | `LANGFUSE_MAX_RETRIES` | `3` |
| `debug` | `LANGFUSE_DEBUG` | `False` |
| `tracing_enabled` | `LANGFUSE_TRACING_ENABLED` | `True` |
| `flush_at` | `LANGFUSE_FLUSH_AT` | `None` |
| `flush_interval_seconds` | `LANGFUSE_FLUSH_INTERVAL_SECONDS` | `None` |
| `sample_rate` | `LANGFUSE_SAMPLE_RATE` | `None` |

활성 Langfuse mode의 host/public/secret key 요구 여부는 선택 service 설정 진단에서 확인한다.

<a id="cfg-svc-nats"></a>
### CFG-SVC-NATS — NatsConfig

| field | environment key | default/condition |
| --- | --- | --- |
| `servers` | `NATS_SERVERS` | optional model field; 선택한 NATS runtime에는 server 필요 |
| `user` | `NATS_USER` | `None` |
| `password` | `NATS_PASSWORD` | `None` |
| `token` | `NATS_TOKEN` | `None` |
| `creds_file` | `NATS_CREDS_FILE` | `None` |
| `name` | `NATS_NAME` | `docmesh-config` |
| `connect_timeout_seconds` | `NATS_CONNECT_TIMEOUT_SECONDS` | `10` |
| `max_reconnect_attempts` | `NATS_MAX_RECONNECT_ATTEMPTS` | `10` |
| `reconnect_time_wait_seconds` | `NATS_RECONNECT_TIME_WAIT_SECONDS` | `2.0` |
| `ping_interval_seconds` | `NATS_PING_INTERVAL_SECONDS` | `120` |
| `max_outstanding_pings` | `NATS_MAX_OUTSTANDING_PINGS` | `2` |
| `no_echo` | `NATS_NO_ECHO` | `False` |

NATS 인증 방식은 user/password, token, creds file 중 하나만 선택한다. 실제 persistent connection의 생성과 drain ownership은 consumer `ManagedResource`/lifespan이 담당한다.

<a id="cfg-svc-env"></a>
## CFG-SVC-ENV — 전체 environment key inventory

아래 목록은 저장소의 [`.env.example`](`.env.example`)와 현재 settings model field를 맞춘 것이다. 주석이 붙은 service block은 해당 service를 `DOCMESH_SERVICES`에 선택할 때만 활성화한다.

```dotenv
# FastAPI application
ROOT_PATH=
TOKEN_URL=/token
CORS_ORIGINS=*
CORS_CREDENTIALS=false
READINESS_PARALLEL=false
READINESS_TIMEOUT_SECONDS=
READINESS_OVERALL_TIMEOUT_SECONDS=
DOCMESH_SERVICE_ALTERNATIVES=
DOCMESH_HEALTHCHECK_ENABLED=false
DOCMESH_STARTUP_FAILURE_MODE=fail
DOCMESH_STARTUP_HEALTHCHECK_ATTEMPTS=1
DOCMESH_STARTUP_HEALTHCHECK_RETRY_DELAY_SECONDS=0
DOCMESH_LOG_LEVEL=WARNING
APP_LOG_PATH=
APP_LOG_JSON=true
APP_LOG_FORCE=false
ACCESS_LOG_ENABLED=true
ACCESS_LOG_HEALTH_ENABLED=false
DOCMESH_SERVICES=
READINESS_REQUIRED_SERVICES=

# Common
DOCMESH_ENV=development
DOCMESH_SECURITY_MODE=
DOCMESH_PRODUCTION_ALIASES=prod,production

# Keycloak
KEYCLOAK_URL=
KEYCLOAK_REALM=
KEYCLOAK_CLIENT_ID=
KEYCLOAK_CLIENT_SECRET=
KEYCLOAK_VERIFY_SSL=true
KEYCLOAK_AUDIENCE=
KEYCLOAK_TOKEN_GRANT_TYPE=password
KEYCLOAK_TOKEN_SCOPE=
KEYCLOAK_TOKEN_USERNAME=
KEYCLOAK_TOKEN_PASSWORD=
KEYCLOAK_REQUEST_TIMEOUT_SECONDS=10
KEYCLOAK_MAX_RETRIES=3
KEYCLOAK_JWKS_CACHE_TTL_SECONDS=300
KEYCLOAK_PROVISIONING_ENABLED=false
KEYCLOAK_PROVISIONING_DRY_RUN=false
KEYCLOAK_ADMIN_REALM=master
KEYCLOAK_ADMIN_CLIENT_ID=admin-cli
KEYCLOAK_ADMIN_CLIENT_SECRET=
KEYCLOAK_ADMIN_USERNAME=
KEYCLOAK_ADMIN_PASSWORD=
KEYCLOAK_REALM_ENABLED=true
KEYCLOAK_REALM_DISPLAY_NAME=
KEYCLOAK_CLIENT_PUBLIC=false
KEYCLOAK_CLIENT_REDIRECT_URIS=
KEYCLOAK_CLIENT_WEB_ORIGINS=
KEYCLOAK_REALM_ROLES=
KEYCLOAK_CLIENT_ROLES=

# PostgreSQL
POSTGRES_HOST=
POSTGRES_PORT=5432
POSTGRES_DB=
POSTGRES_USER=
POSTGRES_PASSWORD=
POSTGRES_SSLMODE=prefer
POSTGRES_CONNECT_TIMEOUT_SECONDS=10
POSTGRES_POOL_SIZE=5
POSTGRES_MAX_OVERFLOW=10
POSTGRES_POOL_PRE_PING=false
POSTGRES_POOL_RECYCLE_SECONDS=-1
POSTGRES_ECHO=false
POSTGRES_APPLICATION_NAME=

# SQLite
SQLITE_PATH=:memory:
SQLITE_READONLY=false
SQLITE_ENABLE_WAL=false
SQLITE_BUSY_TIMEOUT_MS=5000
SQLITE_CHECK_SAME_THREAD=false
SQLITE_ECHO=false

# MinIO
MINIO_ENDPOINT=
MINIO_ACCESS_KEY=
MINIO_SECRET_KEY=
MINIO_SECURE=true
MINIO_CERT_CHECK=true
MINIO_REGION=
MINIO_BUCKET=
MINIO_REQUEST_TIMEOUT_SECONDS=30
MINIO_MAX_RETRIES=3

# Milvus
MILVUS_ENDPOINT=
MILVUS_TOKEN=
MILVUS_DB_NAME=default
MILVUS_COLLECTION=
MILVUS_SECURE=false
MILVUS_CONNECT_TIMEOUT_SECONDS=10
MILVUS_REQUEST_TIMEOUT_SECONDS=30
MILVUS_MAX_RETRIES=3

# Ollama
OLLAMA_HOST=
OLLAMA_VERIFY_SSL=true
OLLAMA_FOLLOW_REDIRECTS=true
OLLAMA_GENERATION_MODEL=
OLLAMA_EMBEDDING_MODEL=
OLLAMA_REQUEST_TIMEOUT_SECONDS=120
OLLAMA_MAX_RETRIES=2

# Langfuse
LANGFUSE_ENABLED=true
LANGFUSE_HOST=
LANGFUSE_PUBLIC_KEY=
LANGFUSE_SECRET_KEY=
LANGFUSE_RELEASE=
LANGFUSE_ENVIRONMENT=
LANGFUSE_REQUEST_TIMEOUT_SECONDS=10
LANGFUSE_MAX_RETRIES=3
LANGFUSE_DEBUG=false
LANGFUSE_TRACING_ENABLED=true
LANGFUSE_FLUSH_AT=
LANGFUSE_FLUSH_INTERVAL_SECONDS=
LANGFUSE_SAMPLE_RATE=

# NATS
NATS_SERVERS=
NATS_USER=
NATS_PASSWORD=
NATS_TOKEN=
NATS_CREDS_FILE=
NATS_NAME=docmesh-py-core
NATS_CONNECT_TIMEOUT_SECONDS=10
NATS_MAX_RECONNECT_ATTEMPTS=10
NATS_RECONNECT_TIME_WAIT_SECONDS=2.0
NATS_PING_INTERVAL_SECONDS=120
NATS_MAX_OUTSTANDING_PINGS=2
NATS_NO_ECHO=false
```

<a id="cfg-security-001"></a>
## CFG-SECURITY-001 — production과 secret 처리

production 판정 시 선택 service가 다음 보안 조건을 만족해야 한다.

- `KEYCLOAK_VERIFY_SSL=true`
- `MINIO_SECURE=true`, `MINIO_CERT_CHECK=true`
- `MILVUS_SECURE=true`
- `OLLAMA_VERIFY_SSL=true`
- placeholder secret/endpoint를 사용하지 않음

실제 secret은 Git에 추가하지 않는다. `.env.example`에는 empty placeholder와 example endpoint만 남기고, deployment secret store가 process environment를 주입한다.

## 10. API → example → config 추적표

| API family | API ID | consumer example | config anchor |
| --- | --- | --- | --- |
| app factory/config | `API-APP-001`, `API-CFG-001` | [EX-APP-001](Examples-v0.7.0.md#ex-app-001), [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-APP-001](#cfg-app-001), [CFG-RUNTIME-001](#cfg-runtime-001) |
| resource/lifecycle | `API-RES-001`~`004`, `API-STREAM-001`, `API-INVOKE-001` | [EX-RES-001](Examples-v0.7.0.md#ex-res-001), [EX-INVOKE-001](Examples-v0.7.0.md#ex-invoke-001), [EX-STREAM-001](Examples-v0.7.0.md#ex-stream-001) | [CFG-RES-001](#cfg-res-001), [CFG-READY-001](#cfg-ready-001) |
| readiness/health | `API-READY-001`~`006`, `API-HTTP-ROUTE-001`~`002`, `API-SCHEMA-001`~`002` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](#cfg-ready-001) |
| auth/dependency | `API-DEP-001`~`009`, `API-HTTP-ROUTE-003`~`004`, `API-SCHEMA-004`~`005` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002), [EX-DEP-001](Examples-v0.7.0.md#ex-dep-001) | [CFG-AUTH-001](#cfg-auth-001), [CFG-SVC-KEYCLOAK](#cfg-svc-keycloak) |
| module/transport | `API-APP-002`~`004`, `API-TRAN-001` | [EX-MOD-001](Examples-v0.7.0.md#ex-mod-001), [EX-MOD-002](Examples-v0.7.0.md#ex-mod-002) | [CFG-APP-003](#cfg-app-003) |
| error/http | `API-HTTP-001`~`005`, `API-SCHEMA-003` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음; [CFG-APP-001](#cfg-app-001)의 correlation/access log만 간접 영향 |
| runtime/testing/logging | `API-RUNTIME-001`~`003`, `API-LIFE-001`, `API-TEST-001`~`005`, `API-LOG-001`~`003` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001), [EX-TEST-001](Examples-v0.7.0.md#ex-test-001), [EX-LOG-001](Examples-v0.7.0.md#ex-log-001) | [CFG-RUNTIME-001](#cfg-runtime-001), [CFG-LOG-001](#cfg-log-001) |
| service client dependencies | `API-DEP-004`~`008` | [EX-DEP-001](Examples-v0.7.0.md#ex-dep-001) | [CFG-SVC-001](#cfg-svc-001), `CFG-SVC-*` model sections |

## 11. 설정 변경 시 검증

```bash
uv run --frozen pytest -q test_fastapi_core/test_config.py test_fastapi_core/test_dependencies.py
uv run --frozen python -c 'from fastapi_core.config import AppConfig; print(sorted(AppConfig.model_fields))'
```

마지막 명령의 field 목록과 이 문서의 `CFG-APP-001` 표, `.env.example`의 assignment-shaped key를 함께 비교한다. service model을 변경하면 해당 `CFG-SVC-*` section, `.env.example`, runtime/dependency example, API trace row를 같은 변경에서 갱신한다.
