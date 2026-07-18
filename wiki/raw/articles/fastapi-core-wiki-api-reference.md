---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/API-Reference.md
ingested: 2026-07-18
sha256: e63403d7258d83c27f02ae31ea1f598b1cb95b68197aa349095b004fd80f28b4
---
# fastapi-core API Reference

> 기준 버전: `fastapi-core 0.3.0`  
> 기준 소스: 현재 저장소의 `fastapi_core/`와 `test_fastapi_core/`  
> 목적: DocMesh Py Core 기반 서비스를 FastAPI로 노출할 때 사용할 **현재 구현 공개 API**를 추적 가능하게 정의한다.

## 1. 공개 API 정책

이 문서에서 공개 API는 다음 순서로 판정한다.

1. `fastapi_core.__all__`: 최상위 권장 API
2. `fastapi_core.dependencies.__all__`, `fastapi_core.schemas.__all__`: FastAPI dependency와 응답 schema
3. 하위 모듈의 명시적 `__all__`: 고급 조립·확장 API
4. 설정 진입점인 `fastapi_core.config.AppConfig`, `load_app_config`
5. `create_app()`이 기본 제공하는 HTTP endpoint

이 목록에 없고 이름이 `_`로 시작하거나 내부 조립을 위해서만 존재하는 symbol은 공개 API가 아니다. 특히 제거된 `settings` 주입 인자, `app.state.settings`, `app.state.service_clients`, `build_injected_service_runtime()`, `build_service_clients()`는 제공하지 않는다.

- 일반 애플리케이션은 최상위 API와 dependency API를 우선 사용한다.
- `runtime`, `lifecycle`, `logging`, registry 클래스는 커스텀 프레임워크 조립을 위한 고급 API다.
- DocMesh Py Core의 클래스는 이 패키지의 소유 API가 아니다. 다만 dependency 반환형과 runtime 주입 계약에서 경계 타입으로 사용한다.

## 2. 추적 규칙

각 API에는 안정적인 문서 ID를 부여한다. 표의 `구현`과 `검증`은 소스 및 대표 테스트를 가리키고, `예제`는 [`examples.md`](examples.md)의 실행 패턴을 가리킨다.

### 2.1 최상위 공개 API

| ID | 공개 API | 역할 | 구현 | 대표 검증 | 예제 |
|---|---|---|---|---|---|
| API-APP-001 | `create_app` | 앱 factory | `fastapi_core/factory.py` | `test_factory.py`, `test_public_api.py` | EX-001, EX-007 |
| API-EXT-001 | `ManagedResource` | 사용자 자원 lifecycle 선언 | `fastapi_core/resources.py` | `test_extensions.py` | EX-005 |
| API-EXT-002 | `ResourceKey` | 타입 있는 자원 key/dependency | `fastapi_core/resources.py` | `test_extensions.py` | EX-005 |
| API-EXT-003 | `ReadinessCheckSpec` | readiness check 선언 | `fastapi_core/readiness.py` | `test_public_api.py`, `test_extensions.py` | EX-004 |
| API-EXT-004 | `register_readiness_check` | 앱 readiness check 등록 | `fastapi_core/readiness.py` | `test_extensions.py` | EX-004 |
| API-ERR-001 | `ErrorMapping` | 예외를 응답 정보로 매핑 | `fastapi_core/http.py` | `test_http.py`, `test_public_api.py` | EX-006 |
| API-ERR-002 | `ErrorRenderer` | 오류 응답 renderer 타입 | `fastapi_core/http.py` | `test_http.py` | EX-006 |
| API-ERR-003 | `register_error_mapper` | 도메인 예외 handler 등록 | `fastapi_core/http.py` | `test_http.py`, `test_public_api.py` | EX-006 |

### 2.2 Dependency 공개 API

| ID | 공개 API | 반환/역할 | 실패 계약 | 대표 검증 | 예제 |
|---|---|---|---|---|---|
| API-DEP-001 | `get_config` | `AppConfig` | 앱 state가 없으면 cached loader 사용 | `test_config.py`, `test_dependencies.py` | EX-001 |
| API-DEP-002 | `get_settings` | runtime의 `ServiceConfigs` | runtime 부재 시 503 | `test_dependencies.py` | EX-003 |
| API-DEP-003 | `get_service_runtime` | `ServiceRuntime` | 503 `Service runtime is not available` | `test_dependencies.py` | EX-003 |
| API-DEP-004 | `get_service_client(name)` | generic wrapper/builder dependency | 미활성 서비스 503 | `test_dependencies.py` | EX-003 |
| API-DEP-005 | `get_keycloak_auth_service` | `KeycloakAuthService` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-006 | `get_postgres_engine` | SQLAlchemy `Engine` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-007 | `get_sqlite_engine` | SQLAlchemy `Engine` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-008 | `get_minio_client` | `Minio` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-009 | `get_milvus_client` | `MilvusClient` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-010 | `get_ollama_client` | `ollama.Client` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-011 | `get_langfuse_client` | `Langfuse` | 미활성 503, wrapper 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-012 | `get_nats_connection_builder` | `NatsConnectionBuilder` | 미활성 503, 타입 불일치 500 | `test_dependencies.py` | EX-003 |
| API-DEP-013 | `get_resource(name)` | lifecycle 자원 dependency | 자원 부재 503 | `test_extensions.py` | EX-005 |
| API-DEP-014 | `get_auth_provider` | cached `KeycloakAuthService` | keycloak 미활성 시 서비스 dependency 실패 | `test_dependencies.py` | EX-002 |
| API-DEP-015 | `get_current_user` | `AuthenticatedUser` | token 없음/무효 401 + Bearer header | `test_dependencies.py` | EX-002 |
| API-DEP-016 | `require_roles(*roles)` | role authorization dependency | 하나라도 없으면 403 | `test_dependencies.py` | EX-002 |
| API-DEP-017 | `require_scopes(*scopes)` | OAuth2 scope dependency | 하나라도 없으면 403 | `test_dependencies.py` | EX-002 |
| API-DEP-018 | `require_permissions(*permissions)` | role 또는 scope 통합 검사 | 하나라도 없으면 403 | `test_dependencies.py` | EX-002 |

### 2.3 Schema 공개 API

| ID | Schema | 구현 | 사용 endpoint | 예제 |
|---|---|---|---|---|
| API-SCHEMA-001 | `HealthResponse` | `schemas/health.py` | liveness, readiness | EX-010, EX-011 |
| API-SCHEMA-002 | `HealthServiceDetail` | `schemas/health.py` | readiness detail | EX-010, EX-011 |
| API-SCHEMA-003 | `ProblemDetail` | `schemas/error.py` | 기본 오류 envelope | EX-006, EX-010 |
| API-SCHEMA-004 | `TokenResponse` | `schemas/token.py` | `POST /token` | EX-010, EX-011 |
| API-SCHEMA-005 | `UserInfo` | `schemas/user.py` | `GET /user` | EX-002, EX-010 |

### 2.4 Router 공개 API

| ID | 공개 API | 포함 endpoint | 구현 | 예제 |
|---|---|---|---|---|
| API-ROUTER-001 | `auth_router` | `POST /token`, `GET /user` | `routers/auth.py`, `routers/__init__.py` | EX-013 |
| API-ROUTER-002 | `health_router` | `GET /health/liveness`, `GET /health/readiness` | `routers/health.py`, `routers/__init__.py` | EX-013 |

### 2.5 고급 모듈 API

| ID | 모듈 API | 역할 | 예제 |
|---|---|---|---|
| API-ADV-001 | `extensions.Check` | sync/async readiness callable 타입 | EX-004 |
| API-ADV-002 | `extensions.ReadinessRegistry` | check 등록·실행 registry | EX-004 |
| API-ADV-003 | `extensions.ResourceRegistry` | managed resource 인스턴스 registry | EX-005 |
| API-ADV-004 | `runtime.build_runtime_plan` | `AppConfig` → `RuntimePlan` | EX-008 |
| API-ADV-005 | `runtime.assemble_runtime` | 환경으로 `ServiceRuntime` 비동기 조립 | EX-008 |
| API-ADV-006 | `runtime.configure_service_runtime` | runtime과 readiness를 앱에 연결 | EX-008 |
| API-ADV-007 | `lifecycle.build_lifespan` | framework-owned lifespan 생성 | EX-007 |
| API-ADV-008 | `logging.JsonLogFormatter` | 구조화 JSON formatter | EX-009 |
| API-ADV-009 | `logging.configure_application_logging` | 앱 logging 구성 | EX-009 |
| API-CFG-001 | `config.AppConfig` | FastAPI 조립 설정 모델 | EX-001, [`config.md`](config.md) |
| API-CFG-002 | `config.load_app_config` | process env 기반 cached loader | EX-001, [`config.md`](config.md) |
| API-CFG-003 | `docmesh_settings.build_docmesh_env_overlay` | process environment 복사본 생성 | EX-012, [`config.md`](config.md) |
| API-CFG-004 | `docmesh_settings.load_docmesh_settings` | 선택 서비스의 `ServiceConfigs` load/cache | EX-012, [`config.md`](config.md) |

`readiness`, `resources`, `extensions` 모듈에서 재노출되는 같은 객체는 동일 API ID로 추적한다. 예를 들어 `fastapi_core.ManagedResource`, `fastapi_core.extensions.ManagedResource`, `fastapi_core.resources.ManagedResource`는 같은 클래스다.

기계적 export 대조를 위한 canonical symbol 이름은 다음과 같다. 표에서는 문맥을 위해 모듈 prefix나 인자를 함께 쓴 경우에도 아래 이름과 같은 API를 뜻한다.

- dependency factory: `get_resource`, `get_service_client`
- readiness callable alias: `Check`
- lifecycle: `build_lifespan`
- logging: `configure_application_logging`
- runtime: `assemble_runtime`, `build_runtime_plan`, `configure_service_runtime`
- 설정 경계: `build_docmesh_env_overlay`, `load_docmesh_settings`
- router: `auth_router`, `health_router`

## 3. 애플리케이션 factory

<a id="api-app-001"></a>
### 3.1 `create_app`

```python
def create_app(
    config: AppConfig | None = None,
    *,
    runtime: ServiceRuntime | None = None,
    lifespan: Callable | None = None,
    include_auth_router: bool = True,
    resources: Sequence[ManagedResource[Any]] = (),
    error_renderer: ErrorRenderer | None = None,
) -> FastAPI
```

| 인자 | 의미 |
|---|---|
| `config` | 앱 조립 설정. 생략하면 `load_app_config()` 사용 |
| `runtime` | 테스트·호스트 앱이 미리 만든 DocMesh `ServiceRuntime`; 생략하면 startup에서 환경 기반 조립 |
| `lifespan` | framework lifecycle 안쪽에서 실행할 사용자 lifespan |
| `include_auth_router` | `POST /token`, `GET /user` 포함 여부 |
| `resources` | 선언형 사용자 자원 목록. 선언 순서로 생성하고 역순으로 종료 |
| `error_renderer` | 모든 표준/등록 오류에 적용할 sync/async renderer |

항상 health router, CORS middleware, correlation-ID middleware, problem handler를 설치한다. 인증 router는 설정에 따라 선택한다.

### 3.2 Lifecycle 순서

1. 주입 runtime 사용 또는 환경 기반 runtime 조립
2. runtime client를 readiness registry에 연결
3. `startup_healthcheck=true`이면 runtime startup check
4. managed resource를 선언 순서대로 생성
5. 필요 시 required resource startup check
6. 사용자 lifespan 진입
7. 사용자 lifespan 종료
8. managed resource 역순 종료
9. service runtime 종료

시작 중 실패하면 생성된 자원을 rollback한다. 사용자 shutdown이 실패해도 framework-owned 자원/runtime 정리를 시도한다.

### 3.3 `app.state` 계약

| 키 | 타입/시점 | 설명 |
|---|---|---|
| `config` | `AppConfig`, 생성 즉시 | 앱 설정 |
| `root_logger` | `logging.Logger`, 생성 즉시 | 구성된 root logger |
| `service_runtime` | `ServiceRuntime \| None`; startup 후 runtime | 유일한 서비스 상태 소유자 |
| `readiness_registry` | `ReadinessRegistry` | 서비스/자원/custom check registry |
| `resource_registry` | `ResourceRegistry` | managed resource registry |
| `oauth2_scheme` | `OAuth2PasswordBearer` | 앱별 token URL을 갖는 security scheme |
| `error_renderer` | `ErrorRenderer` | 오류 렌더링 함수 |
| `auth_provider` | Keycloak 활성화 후 | Keycloak client cache |

`request.state.correlation_id`는 HTTP 요청마다 설정된다. 폐기된 `app.state.settings`, `app.state.service_clients`에 의존하지 않는다.

다음 legacy flat state도 공개 계약이 아니며 생성되지 않는다: `readiness_checks`, `readiness_services`, `required_services`, `readiness_parallel`, `readiness_timeout_seconds`, `readiness_overall_timeout_seconds`. Readiness 상태와 정책은 `app.state.readiness_registry` 및 `app.state.config`에서 접근한다.

## 4. Dependency 상세 계약

### 4.1 설정과 runtime

- `get_config(request)`는 `request.app.state.config`를 우선 반환한다.
- `get_settings(request)`는 `get_service_runtime(request).configs`를 반환한다.
- `get_service_runtime(request)`는 lifespan이 소유한 runtime만 반환한다. 기본 runtime은 lifespan 진입 전에 존재하지 않을 수 있다.
- `get_service_client(name)`는 DocMesh wrapper 또는 NATS builder를 그대로 반환한다.
- typed getter는 wrapper의 `.client`를 구체 타입으로 반환한다. NATS만 builder를 직접 반환한다.

서비스가 없으면 503, 예상 wrapper/builder 타입이 아니면 500이다. 모든 오류는 기본적으로 `ProblemDetail` envelope로 렌더링된다.

### 4.2 인증과 인가

- `get_current_user`는 Bearer token을 Keycloak provider로 검증한다.
- realm role과 모든 client role은 중복 제거 후 순서를 보존한다.
- scope는 token claim의 공백 구분 `scope` 문자열에서 읽는다.
- `require_roles`와 `require_scopes`는 전달된 모든 값이 있어야 성공한다.
- `require_permissions`는 role과 scope를 합친 권한 집합에서 모든 값을 검사한다.
- `require_scopes`는 OpenAPI OAuth2 security requirement에도 scope를 기록한다.

## 5. 확장 API

### 5.1 `ReadinessCheckSpec`와 `register_readiness_check`

```python
ReadinessCheckSpec(
    name: str,
    check: Check,
    required: bool = True,
    timeout_seconds: float | None = None,
    redact_errors: bool = True,
)
```

`check`는 sync 또는 async callable이다. 반환값 `False`는 실패다. `HealthCheckResult`를 반환하면 `parent.child` 이름으로 상세 상태를 보존한다. required 실패는 readiness 503/`error`, optional 실패는 200/`degraded`다. timeout은 check별 값이 우선하고, 없으면 앱 기본값을 사용한다.

이름은 비어 있을 수 없고 중복 등록은 `ValueError`다. `redact_errors=true`가 기본이며 외부 오류 문자열을 응답에 직접 노출하지 않는다.

### 5.2 `ReadinessRegistry`

공개 메서드:

| 메서드 | 계약 |
|---|---|
| `register(spec)` | spec 검증 후 등록; 빈/중복 이름 또는 0 이하 timeout 거부 |
| `unregister(name)` | 존재하면 제거, 없어도 오류 없음 |
| `resolve_spec(name)` | exact name 또는 structured child의 parent spec 반환 |
| `await check(names=None, parallel=False, overall_timeout_seconds=None)` | 선택 check 실행 후 `HealthCheckResult` 반환; required 실패 시 `HealthCheckError` |

대부분의 앱은 registry를 직접 조작하지 않고 `register_readiness_check()`를 사용한다.

### 5.3 `ManagedResource`, `ResourceKey`, `ResourceRegistry`

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
```

- factory, healthcheck, close는 sync/async 모두 가능하다.
- `close`를 생략하면 인스턴스의 `aclose()` 후 `close()` 순서로 탐색한다.
- healthcheck가 있으면 같은 이름의 readiness check가 자동 등록된다.
- `ResourceKey(name).dependency`와 `get_resource(name)`는 같은 registry에서 인스턴스를 해석한다.
- 미생성/미등록 자원 접근은 503이다.
- 빈 이름, 중복 이름, 예약된 `app.state` 이름, 0 이하 timeout은 거부한다.

`ResourceRegistry` 공개 메서드는 `start(app)`, `check_startup(...)`, `require(name)`, `close()`다. 일반 앱은 `create_app(resources=...)`에 위임한다.

## 6. 오류 및 요청 추적 API

### 6.1 Correlation ID

모든 HTTP 응답에 `X-Correlation-ID`가 포함된다.

- 허용 형식: `[A-Za-z0-9._:-]{1,128}`
- 유효한 요청 header는 그대로 사용한다.
- 누락되거나 유효하지 않으면 32자리 hex ID를 생성한다.
- 값은 `request.state.correlation_id`에서 접근한다.

### 6.2 `ErrorMapping`

```python
ErrorMapping(
    status_code: int,
    detail: str,
    title: str | None = None,
    type_uri: str = "about:blank",
    headers: dict[str, str] | None = None,
    code: str | None = None,
    extensions: dict[str, object] | None = None,
)
```

기본 renderer는 `status_code`, `detail`, `title`, `type_uri`, `headers`를 사용한다. `code`와 `extensions`는 custom renderer를 위한 metadata다. renderer에 전달되기 전 `detail`의 민감값이 마스킹된다.

`register_error_mapper(app, ExceptionType, mapper)`의 mapper는 `(Request, Exception) -> ErrorMapping | Awaitable[ErrorMapping]`이다. `ErrorRenderer`는 `(Request, ErrorMapping) -> Response | Awaitable[Response]`다.

### 6.3 기본 오류 envelope

Content-Type은 `application/problem+json`이다.

```json
{
  "type": "about:blank",
  "title": "Bad Request",
  "status": 400,
  "detail": "safe detail",
  "instance": "/path",
  "correlation_id": "request-123"
}
```

- HTTP exception: 원래 status/header 유지, detail 마스킹
- request validation: 422, `Request validation failed`
- 처리되지 않은 예외: 500, `Internal Server Error`
- 표준 밖 status code: title은 `HTTP Error`

## 7. Schema 계약

### 7.1 `HealthResponse`

| 필드 | 타입 | 필수/기본값 |
|---|---|---|
| `status` | `"ok" \| "degraded" \| "error"` | 필수 |
| `details` | `dict[str, HealthServiceDetail] \| None` | `None` |

### 7.2 `HealthServiceDetail`

| 필드 | 타입 | 기본값 |
|---|---|---|
| `ok` | `bool` | 필수 |
| `latency_ms` | `int \| None` | `None` |
| `error` | `str \| None` | `None` |
| `required` | `bool` | `False` |
| `enabled` | `bool` | `True` |

### 7.3 `ProblemDetail`

`type="about:blank"`, `title`, `status`, `detail`, `instance`, `correlation_id`를 가진다. `title` 이하 다섯 필드는 필수다.

### 7.4 `TokenResponse`

`access_token`은 필수다. `refresh_token=None`, `token_type="bearer"`가 기본값이다.

### 7.5 `UserInfo`

`sub`, `username`은 필수다. `email`, `name`은 nullable이고, `roles`, `scopes`는 기본 빈 목록이다.

## 8. HTTP API

| ID | Method/path | 활성 조건 | 성공 응답 | 주요 실패 |
|---|---|---|---|---|
| API-HTTP-001 | `GET /health/liveness` | 항상 | 200 `HealthResponse(status="ok")` | 없음 |
| API-HTTP-002 | `GET /health/readiness` | 항상 | 200 `ok` 또는 optional 실패 시 `degraded` | required/overall timeout 503 `error` |
| API-HTTP-003 | `POST /token` | `include_auth_router=true` | 200 `TokenResponse` | 401 인증 실패, 500 설정/예상 밖 오류, 502 upstream, 503 temporary |
| API-HTTP-004 | `GET /user` | `include_auth_router=true` | 200 `UserInfo` | token 없음/무효 401 |

`create_app()`은 FastAPI 기본 문서 route인 `GET /openapi.json`, `GET /docs`, `GET /docs/oauth2-redirect`, `GET /redoc`도 유지한다. 이 네 route는 fastapi-core 고유 endpoint가 아니라 FastAPI의 기본 문서 UI surface다.

현재 generated OpenAPI는 readiness의 런타임 503과 `/token`의 upstream 401/500/502/503을 모두 response schema로 선언하지 않는다. 실제 구현의 오류 계약은 이 문서와 회귀 테스트를 기준으로 한다.

### 8.1 `POST /token`

OAuth2 password form(`application/x-www-form-urlencoded`)을 받는다.

- 입력: `username`, `password`, 선택 `scope`
- token type은 소문자로 정규화한다.
- 실패 응답에는 `WWW-Authenticate: Bearer`가 포함된다.

`TOKEN_URL`은 OpenAPI OAuth2 scheme의 token URL을 바꾸지만 실제 내장 route path `/token`을 이동시키지는 않는다. 다른 경로가 필요하면 별도 router를 제공해야 한다.

### 8.2 Readiness 판정

| 상태 | HTTP | 조건 |
|---|---:|---|
| `ok` | 200 | 모든 check 성공 또는 check 없음 |
| `degraded` | 200 | optional check만 실패 |
| `error` | 503 | required check 실패 또는 overall timeout |

## 9. 고급 조립 API

### 9.1 Runtime

- `build_runtime_plan(config)`는 활성/필수/대안 서비스와 healthcheck 정책을 DocMesh `RuntimePlan`으로 변환한다.
- `await assemble_runtime(config)`는 현재 process environment로 runtime을 조립한다. 서비스가 명시적으로 비어 있으면 빈 runtime을 만든다.
- `configure_service_runtime(app, runtime)`은 runtime을 `app.state`에 저장하고 각 client check를 readiness registry에 등록한다. Keycloak provider는 RS256만 허용하도록 구성한다.

### 9.2 Lifespan

`build_lifespan(lifespan, config, runtime, resources)`는 `create_app()`이 사용하는 framework-owned context manager factory다. 직접 호출할 때도 runtime/resource 종료 소유권이 이 lifespan에 있음을 전제로 해야 한다.

### 9.3 Logging

- `configure_application_logging(config)`는 DocMesh logging 설정을 호출하고, `log_json=true`이면 모든 root handler에 `JsonLogFormatter`를 적용한다.
- `JsonLogFormatter`는 `timestamp`, `logger`, `level`, `message`와 선택 `function_event`, `event`, `exception`을 JSON으로 직렬화한다.

### 9.4 Router 직접 조립

`fastapi_core.routers.__all__`은 `auth_router`, `health_router`를 공개한다. 직접 `include_router()`할 수 있지만 이 방식만으로는 `create_app()`이 설치하는 runtime state, OAuth2 scheme override, CORS, correlation ID, problem handler, logging 및 lifespan이 구성되지 않는다. 전체 계약이 필요하면 `create_app()`을 사용한다.

## 10. 설정 API 연결

`AppConfig` 전체 필드, 환경변수 alias, validation과 DocMesh 서비스별 설정은 [`config.md`](config.md)에서 관리한다. 복사 가능한 조립·dependency·확장 예제는 [`examples.md`](examples.md)에서 관리한다.
