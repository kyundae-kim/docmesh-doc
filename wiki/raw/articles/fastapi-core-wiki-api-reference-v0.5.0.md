---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/API-Reference-v0.5.0.md
ingested: 2026-07-20
sha256: 42f354633f8a81c2f41925e883433916c428a4b59a2a5fd8aab7d42d5c3d2c71
---
# fastapi-core API Reference

> 문서 리비전: 2026-07-19
>
> 대상 릴리스: `fastapi-core 0.5.0`
>
> 상태: current-implementation
>
> 기준: `fastapi_core`의 `__all__`, 의도적으로 공개된 설정 entrypoint, 생성 OpenAPI, `test_fastapi_core`

---

## 1. 공개 API 정책

이 문서는 현재 구현된 공개 Python API와 내장 HTTP API의 기준 문서다.

- **1차 공개 API**: `fastapi_core.__all__`
- **FastAPI 공개 API**: `fastapi_core.dependencies.__all__`, `fastapi_core.schemas.__all__`, `fastapi_core.routers.__all__`
- **명시적 고급 API**: `fastapi_core.extensions`, `fastapi_core.readiness`, `fastapi_core.resources`, `fastapi_core.runtime`, `fastapi_core.logging`, `fastapi_core.testing`의 `__all__`
- **설정 entrypoint**: `fastapi_core.config.AppConfig`, `fastapi_core.config.load_app_config`, `fastapi_core.docmesh_settings.load_docmesh_settings`
- **HTTP API**: `create_app()`이 포함하는 router를 생성 OpenAPI로 확인한 method/path

같은 객체가 여러 모듈에서 재노출되면 하나의 API ID를 공유한다. 밑줄로 시작하는 심벌과 `__all__`에 없는 조립 helper는 공개 계약이 아니다. 고급 API는 명시적으로 export되지만 일반 애플리케이션에서는 package root와 dependency API를 먼저 사용한다.

- 실행 예제: [examples.md](examples.md)
- 설정 키와 기본값: [config.md](config.md)
- 구현 요구사항: [srs.md](srs.md)

## 2. 전체 추적성 매트릭스

### 2.1 애플리케이션, 확장, 오류

| API ID | 공개 심벌 | 책임 | 소스 | 대표 테스트 | 예제 | 설정 |
|---|---|---|---|---|---|---|
| `API-APP-001` | `fastapi_core.create_app` | FastAPI 앱 조립 | `fastapi_core/factory.py` | `test_factory.py`, `test_public_api.py` | [EX-APP-001](examples.md#ex-app-001) | [CFG-APP](config.md#cfg-app) |
| `API-RES-001` | `fastapi_core.ManagedResource` (`fastapi_core.resources.ManagedResource`, `fastapi_core.extensions.ManagedResource`) | 사용자 자원의 생성·점검·종료 선언 | `fastapi_core/resources.py` | `test_extensions.py` | [EX-RES-001](examples.md#ex-res-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-RES-002` | `fastapi_core.ResourceKey` (`fastapi_core.resources.ResourceKey`) | typed managed-resource dependency | `fastapi_core/resources.py` | `test_extensions.py` | [EX-RES-001](examples.md#ex-res-001) | 해당 없음 |
| `API-READY-001` | `fastapi_core.ReadinessCheckSpec` (`fastapi_core.extensions.ReadinessCheckSpec`, `fastapi_core.readiness.ReadinessCheckSpec`) | readiness check 명세 | `fastapi_core/readiness.py` | `test_public_api.py`, `test_extensions.py` | [EX-READY-001](examples.md#ex-ready-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-READY-002` | `fastapi_core.register_readiness_check` (`fastapi_core.extensions.register_readiness_check`, `fastapi_core.readiness.register_readiness_check`) | 앱 registry에 check 등록 | `fastapi_core/readiness.py` | `test_extensions.py` | [EX-READY-001](examples.md#ex-ready-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-ERR-001` | `fastapi_core.ErrorMapping` | 예외를 오류 응답 의미로 변환 | `fastapi_core/http.py` | `test_http.py` | [EX-ERR-001](examples.md#ex-err-001) | 해당 없음 |
| `API-ERR-002` | `fastapi_core.ErrorRenderer` | 오류 envelope renderer 타입 | `fastapi_core/http.py` | `test_http.py` | [EX-ERR-002](examples.md#ex-err-002) | 해당 없음 |
| `API-ERR-003` | `fastapi_core.register_error_mapper` | domain 예외 handler 등록 | `fastapi_core/http.py` | `test_http.py` | [EX-ERR-001](examples.md#ex-err-001) | 해당 없음 |

### 2.2 Dependency와 인증·인가

| API ID | 공개 심벌 | 반환/책임 | 소스 | 대표 테스트 | 예제 | 설정 |
|---|---|---|---|---|---|---|
| `API-DEP-001` | `fastapi_core.dependencies.get_config` | `AppConfig` | `dependencies/config.py` | `test_dependencies.py` | [EX-DEP-001](examples.md#ex-dep-001) | [CFG-APP](config.md#cfg-app) |
| `API-DEP-002` | `fastapi_core.dependencies.get_settings` | `ServiceConfigs` | `dependencies/config.py` | `test_dependencies.py` | [EX-DEP-001](examples.md#ex-dep-001) | [CFG-SERVICES](config.md#cfg-services) |
| `API-DEP-003` | `fastapi_core.dependencies.get_service_runtime` | `ServiceRuntime` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-001](examples.md#ex-dep-001) | [CFG-RUNTIME](config.md#cfg-runtime) |
| `API-DEP-004` | `fastapi_core.dependencies.get_service_client` | 이름 기반 wrapper/builder dependency factory | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-002](examples.md#ex-dep-002) | [CFG-RUNTIME](config.md#cfg-runtime) |
| `API-DEP-005` | `fastapi_core.dependencies.get_keycloak_auth_service` | `KeycloakAuthService` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-DEP-006` | `fastapi_core.dependencies.get_postgres_engine` | SQLAlchemy `Engine` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-POSTGRES](config.md#cfg-postgres) |
| `API-DEP-007` | `fastapi_core.dependencies.get_sqlite_engine` | SQLAlchemy `Engine` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-SQLITE](config.md#cfg-sqlite) |
| `API-DEP-008` | `fastapi_core.dependencies.get_minio_client` | `Minio` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-MINIO](config.md#cfg-minio) |
| `API-DEP-009` | `fastapi_core.dependencies.get_milvus_client` | `MilvusClient` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-MILVUS](config.md#cfg-milvus) |
| `API-DEP-010` | `fastapi_core.dependencies.get_ollama_client` | Ollama `Client` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-OLLAMA](config.md#cfg-ollama) |
| `API-DEP-011` | `fastapi_core.dependencies.get_langfuse_client` | `Langfuse` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-LANGFUSE](config.md#cfg-langfuse) |
| `API-DEP-012` | `fastapi_core.dependencies.get_nats_connection_builder` | `NatsConnectionBuilder` | `dependencies/services.py` | `test_dependencies.py` | [EX-DEP-003](examples.md#ex-dep-003) | [CFG-NATS](config.md#cfg-nats) |
| `API-DEP-013` | `fastapi_core.dependencies.get_resource` | 이름 기반 managed-resource dependency factory | `dependencies/services.py` | `test_extensions.py` | [EX-RES-001](examples.md#ex-res-001) | 해당 없음 |
| `API-AUTH-001` | `fastapi_core.dependencies.get_auth_provider` | 앱별 `KeycloakAuthService` | `dependencies/auth.py` | `test_dependencies.py`, `test_auth_router.py` | [EX-AUTH-001](examples.md#ex-auth-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-AUTH-002` | `fastapi_core.dependencies.get_current_user` | 검증된 `AuthenticatedUser` | `dependencies/auth.py` | `test_dependencies.py` | [EX-AUTH-001](examples.md#ex-auth-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-AUTH-003` | `fastapi_core.dependencies.require_roles` | role 검사 dependency factory | `dependencies/auth.py` | `test_dependencies.py` | [EX-AUTH-001](examples.md#ex-auth-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-AUTH-004` | `fastapi_core.dependencies.require_scopes` | OAuth2 scope 검사 dependency factory | `dependencies/auth.py` | `test_dependencies.py` | [EX-AUTH-001](examples.md#ex-auth-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-AUTH-005` | `fastapi_core.dependencies.require_permissions` | role+scope permission 검사 dependency factory | `dependencies/auth.py` | `test_dependencies.py` | [EX-AUTH-001](examples.md#ex-auth-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |

### 2.3 Schema, router, HTTP

| API ID | 공개 심벌/경로 | 계약 | 소스 | 대표 테스트 | 예제 | 설정 |
|---|---|---|---|---|---|---|
| `API-SCHEMA-001` | `fastapi_core.schemas.HealthResponse` | health 응답 | `schemas/health.py` | `test_schemas.py`, `test_health_router.py` | [EX-SCHEMA-001](examples.md#ex-schema-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-SCHEMA-002` | `fastapi_core.schemas.HealthServiceDetail` | 서비스별 health detail | `schemas/health.py` | `test_schemas.py`, `test_health_router.py` | [EX-SCHEMA-001](examples.md#ex-schema-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-SCHEMA-003` | `fastapi_core.schemas.ProblemDetail` | RFC 7807 계열 오류 응답 | `schemas/error.py` | `test_schemas.py`, `test_http.py` | [EX-SCHEMA-001](examples.md#ex-schema-001) | 해당 없음 |
| `API-SCHEMA-004` | `fastapi_core.schemas.TokenResponse` | token 발급 응답 | `schemas/token.py` | `test_schemas.py`, `test_auth_router.py` | [EX-SCHEMA-001](examples.md#ex-schema-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-SCHEMA-005` | `fastapi_core.schemas.UserInfo` | 공개 사용자 DTO | `schemas/user.py` | `test_schemas.py`, `test_auth_router.py` | [EX-SCHEMA-001](examples.md#ex-schema-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-ROUTER-001` | `fastapi_core.routers.auth_router` | `/token`, `/user` router | `routers/auth.py` | `test_auth_router.py` | [EX-ROUTER-001](examples.md#ex-router-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-ROUTER-002` | `fastapi_core.routers.health_router` | liveness/readiness router | `routers/health.py` | `test_health_router.py` | [EX-ROUTER-001](examples.md#ex-router-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-HTTP-001` | `GET /health/liveness` | 프로세스 생존 상태 | `routers/health.py` | `test_health_router.py` | [EX-HTTP-001](examples.md#ex-http-001) | 해당 없음 |
| `API-HTTP-002` | `GET /health/readiness` | 의존성 준비 상태 | `routers/health.py` | `test_health_router.py` | [EX-HTTP-001](examples.md#ex-http-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-HTTP-003` | `POST /token` | OAuth2 password token 발급 | `routers/auth.py` | `test_auth_router.py` | [EX-HTTP-002](examples.md#ex-http-002) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-HTTP-004` | `GET /user` | bearer token의 공개 사용자 정보 | `routers/auth.py` | `test_auth_router.py` | [EX-HTTP-002](examples.md#ex-http-002) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |

### 2.4 설정, 고급 조립, 테스트 지원

| API ID | 공개 심벌 | 책임 | 소스 | 대표 테스트 | 예제 | 설정 |
|---|---|---|---|---|---|---|
| `API-CFG-001` | `fastapi_core.config.AppConfig` | FastAPI 앱 계층 설정 model | `config.py` | `test_config.py` | [EX-CFG-001](examples.md#ex-cfg-001) | [CFG-APP](config.md#cfg-app) |
| `API-CFG-002` | `fastapi_core.config.load_app_config` | 환경 기반 cache 설정 loader | `config.py` | `test_config.py` | [EX-CFG-001](examples.md#ex-cfg-001) | [CFG-APP](config.md#cfg-app) |
| `API-CFG-003` | `fastapi_core.docmesh_settings.load_docmesh_settings` | 선택 서비스 설정 loader | `docmesh_settings.py` | `test_config.py` | [EX-CFG-002](examples.md#ex-cfg-002) | [CFG-SERVICES](config.md#cfg-services) |
| `API-ADV-001` | `fastapi_core.extensions.Check` (`fastapi_core.readiness.Check`) | sync/async readiness callback type | `readiness.py` | `test_extensions.py` | [EX-READY-001](examples.md#ex-ready-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-ADV-002` | `fastapi_core.extensions.ReadinessRegistry` (`fastapi_core.readiness.ReadinessRegistry`) | 앱별 readiness registry | `readiness.py` | `test_extensions.py` | [EX-ADV-001](examples.md#ex-adv-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-ADV-003` | `fastapi_core.extensions.ResourceRegistry` (`fastapi_core.resources.ResourceRegistry`) | managed-resource lifecycle registry | `resources.py` | `test_extensions.py` | [EX-ADV-001](examples.md#ex-adv-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-ADV-004` | `fastapi_core.runtime.assemble_runtime` | `RuntimePlan`에서 runtime 조립 | `runtime.py` | `test_factory.py` | [EX-ADV-002](examples.md#ex-adv-002) | [CFG-RUNTIME](config.md#cfg-runtime) |
| `API-ADV-005` | `fastapi_core.runtime.build_runtime_plan` | `AppConfig`를 `RuntimePlan`으로 변환 | `runtime.py` | `test_factory.py` | [EX-ADV-002](examples.md#ex-adv-002) | [CFG-RUNTIME](config.md#cfg-runtime) |
| `API-ADV-006` | `fastapi_core.runtime.configure_service_runtime` | runtime을 앱 state/readiness/auth에 연결 | `runtime.py` | `test_factory.py`, `test_public_api.py` | [EX-ADV-002](examples.md#ex-adv-002) | [CFG-RUNTIME](config.md#cfg-runtime) |
| `API-ADV-007` | `fastapi_core.logging.JsonLogFormatter` | 구조화 JSON formatter | `logging.py` | `test_function_logging.py` | [EX-LOG-001](examples.md#ex-log-001) | [CFG-LOGGING](config.md#cfg-logging) |
| `API-ADV-008` | `fastapi_core.logging.configure_application_logging` | 앱 logging 초기화 | `logging.py` | `test_function_logging.py`, `test_factory.py` | [EX-LOG-001](examples.md#ex-log-001) | [CFG-LOGGING](config.md#cfg-logging) |
| `API-TEST-001` | `fastapi_core.testing.ResourceLifecycleProbe` | 자원 lifecycle contract probe | `testing.py` | `test_testing.py` | [EX-TEST-001](examples.md#ex-test-001) | 해당 없음 |
| `API-TEST-002` | `fastapi_core.testing.assert_auth_router_contract` | auth router opt-in assertion | `testing.py` | `test_testing.py` | [EX-TEST-001](examples.md#ex-test-001) | [CFG-KEYCLOAK](config.md#cfg-keycloak) |
| `API-TEST-003` | `fastapi_core.testing.assert_health_contract` | health 성공 계약 assertion | `testing.py` | `test_testing.py` | [EX-TEST-001](examples.md#ex-test-001) | [CFG-READINESS](config.md#cfg-readiness) |
| `API-TEST-004` | `fastapi_core.testing.create_empty_runtime` | 외부 서비스가 없는 canonical runtime | `testing.py` | `test_testing.py` | [EX-TEST-001](examples.md#ex-test-001) | [CFG-RUNTIME](config.md#cfg-runtime) |

## 3. 핵심 Python 계약

<a id="api-app-001"></a>
### `API-APP-001` — `create_app`

```python
create_app(
    config: AppConfig | None = None,
    *,
    runtime: ServiceRuntime | None = None,
    lifespan: Callable | None = None,
    include_auth_router: bool = False,
    resources: Sequence[ManagedResource[Any]] = (),
    error_renderer: ErrorRenderer | None = None,
) -> FastAPI
```

- `config=None`이면 cache된 `load_app_config()`를 사용한다.
- 명시적 `runtime`은 재조립하지 않는다. 없으면 lifespan에서 `RuntimePlan`에 따라 조립한다.
- health router는 항상, auth router는 `include_auth_router=True`일 때만 포함한다.
- framework lifespan은 runtime과 managed resource 정리를 소유하며 사용자 lifespan을 그 안에 합성한다.
- 초기 state: `config`, `root_logger`, `service_runtime`, `readiness_registry`, `resource_registry`, `oauth2_scheme`, `error_renderer`.
- Keycloak이 연결되면 `auth_provider`가 추가된다.

### 자원과 readiness

```python
ManagedResource(
    name,
    factory,
    healthcheck=None,
    close=None,
    required=True,
    readiness_timeout_seconds=None,
    redact_errors=True,
)

ResourceKey(name)

register_readiness_check(
    app,
    name,
    check,
    *,
    required=True,
    timeout_seconds=None,
    redact_errors=True,
) -> None
```

- `factory`, `healthcheck`, `close`, readiness `check`는 동기 또는 비동기 결과를 지원한다.
- `ResourceKey[T].dependency(request) -> T`는 registry가 없거나 값이 준비되지 않으면 `503`을 발생시킨다.
- required check 실패는 readiness `503/error`, optional check 실패는 `200/degraded`다.
- `redact_errors=True`이면 외부 응답의 check 오류를 `readiness check failed`로 대체한다.

### 오류 확장

```python
ErrorMapping(
    status_code,
    detail,
    title=None,
    type_uri="about:blank",
    headers=None,
    code=None,
    extensions=None,
)

register_error_mapper(app, exception_type, mapper) -> None
```

`mapper`는 `(Request, Exception) -> ErrorMapping | Awaitable[ErrorMapping]`이다. 기본 renderer는 `ProblemDetail`과 `application/problem+json`을 사용한다. `ErrorRenderer`는 `(Request, ErrorMapping) -> Response | Awaitable[Response]`이며 `create_app(error_renderer=...)`로 교체한다. mapper 결과의 `detail`은 renderer 호출 전에 민감 정보 마스킹을 거친다.

## 4. Dependency 계약

### 공통 상태 접근

```python
get_config(request: Request) -> AppConfig
get_settings(request: Request) -> ServiceConfigs
get_service_runtime(request: Request) -> ServiceRuntime
get_service_client(service_name: str) -> Callable[[Request], object]
get_resource(name: str) -> Callable[[Request], object]
```

- runtime이 준비되지 않았거나 서비스/자원이 활성화되지 않으면 `503 Service Unavailable`.
- typed service dependency에서 wrapper 또는 실제 client 타입이 예상과 다르면 `500 Internal Server Error`.
- `get_service_client(name)`은 일반 서비스에는 `ServiceClientWrapper`, NATS에는 `NatsConnectionBuilder`를 반환할 수 있다.
- `get_settings`는 앱 설정이 아니라 `ServiceRuntime.configs`를 반환한다.

### Typed service dependency

| Dependency | 서비스 이름 | 반환 타입 |
|---|---|---|
| `get_keycloak_auth_service` | `keycloak` | `KeycloakAuthService` |
| `get_postgres_engine` | `postgres` | `sqlalchemy.engine.Engine` |
| `get_sqlite_engine` | `sqlite` | `sqlalchemy.engine.Engine` |
| `get_minio_client` | `minio` | `minio.Minio` |
| `get_milvus_client` | `milvus` | `pymilvus.MilvusClient` |
| `get_ollama_client` | `ollama` | `ollama.Client` |
| `get_langfuse_client` | `langfuse` | `langfuse.Langfuse` |
| `get_nats_connection_builder` | `nats` | `NatsConnectionBuilder` |

### 인증·인가

```python
get_auth_provider(request: Request) -> KeycloakAuthService
async get_current_user(...) -> AuthenticatedUser
require_roles(*roles) -> Callable[..., AuthenticatedUser]
require_scopes(*scopes) -> Callable[..., AuthenticatedUser]
require_permissions(*permissions) -> Callable[..., AuthenticatedUser]
```

- token 누락/검증 실패: `401`과 `WWW-Authenticate: Bearer`.
- role은 realm role과 모든 client role을 합쳐 검사한다.
- scope는 token claim의 공백 구분 `scope` 문자열을 사용한다.
- permission은 role과 scope의 합집합을 사용한다.
- 요구 항목은 모두 포함되어야 하며 부족하면 `403`이다.

## 5. Schema 계약

| Schema | 필드 |
|---|---|
| `HealthResponse` | `status: Literal["ok", "degraded", "error"]`, `details: dict[str, HealthServiceDetail] \| None = None` |
| `HealthServiceDetail` | `ok: bool`, `latency_ms: int \| None = None`, `error: str \| None = None`, `required: bool = False`, `enabled: bool = True` |
| `ProblemDetail` | `type: str = "about:blank"`, `title: str`, `status: int`, `detail: str`, `instance: str`, `correlation_id: str` |
| `TokenResponse` | `access_token: str`, `refresh_token: str \| None = None`, `token_type: str = "bearer"` |
| `UserInfo` | `sub: str`, `username: str`, `email: str \| None = None`, `name: str \| None = None`, `roles: list[str] = []`, `scopes: list[str] = []` |

`get_current_user`는 `AuthenticatedUser`를 반환하며, 내장 `/user` router만 이를 공개 DTO `UserInfo`로 변환한다.

## 6. HTTP 계약

모든 HTTP 응답에는 유효한 요청 `X-Correlation-ID`를 그대로 사용하거나 새 식별자를 생성해 같은 헤더로 반환한다. 기본 오류 content type은 `application/problem+json`이다.

| Method | Path | 기본 포함 | 성공 응답 | 주요 실패 |
|---|---|---:|---|---|
| `GET` | `/health/liveness` | 예 | `200`, `HealthResponse(status="ok")` | 없음 |
| `GET` | `/health/readiness` | 예 | `200/ok`, `200/degraded` | required/overall timeout: `503/error` |
| `POST` | `/token` | 아니오 | `200`, `TokenResponse` | 인증 `401`, 구성 `500`, 일시 장애 `503`, upstream `502`, validation `422` |
| `GET` | `/user` | 아니오 | `200`, `UserInfo` | token 누락/무효 `401`, provider 미준비 `503` |

`AppConfig.token_url`은 OpenAPI OAuth2 password flow의 token URL만 바꾸며 실제 `POST /token` 경로를 변경하지 않는다.

## 7. 고급 API 계약

### Registry

- `ReadinessRegistry(default_timeout_seconds=None)`
  - `register(spec)`, `unregister(name)`, `resolve_spec(name)`
  - `await check(names=None, parallel=False, overall_timeout_seconds=None)`
- `ResourceRegistry(resources, readiness, *, reserved_names=...)`
  - `await start(app)`, `await check_startup(...)`, `require(name)`, `await close()`

일반 소비 코드는 registry를 직접 생성하기보다 `create_app`, `register_readiness_check`, `ManagedResource`, `ResourceKey`를 사용한다.

### Runtime

```python
build_runtime_plan(config: AppConfig) -> RuntimePlan
async assemble_runtime(plan: RuntimePlan | None) -> ServiceRuntime
configure_service_runtime(app: FastAPI, runtime: ServiceRuntime) -> None
```

`configure_service_runtime`은 app state, readiness check, Keycloak provider를 연결한다. 완전한 애플리케이션 lifecycle이 필요하면 이 함수들을 개별 호출하지 말고 `create_app`을 사용한다.

### Logging

```python
JsonLogFormatter(...)
configure_application_logging(config: AppConfig) -> logging.Logger
```

JSON formatter는 `timestamp`, `logger`, `level`, `message`와 존재하는 경우 `function_event`, `event`, `exception`을 기록한다.

### 테스트 지원

- `create_empty_runtime()`: 선택·필수 서비스와 client가 없는 runtime.
- `ResourceLifecycleProbe(value, health_result=True)`: `managed_resource(...)`로 create/check/close 이벤트를 기록한다.
- `assert_health_contract(client)`: 내장 liveness/readiness 성공 계약을 확인한다.
- `assert_auth_router_contract(client, *, included)`: auth route의 opt-in/out을 확인한다.
