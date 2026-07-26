---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Configuration-v0.6.0.md
ingested: 2026-07-26
sha256: 898c44f0fb901d6eef599b4371f2c33a48c1307857e346afc3ba523e634e7ec7
---
# 공개 API 레퍼런스와 추적성 매트릭스

이 문서는 `fastapi-core`가 제공하는 현재 공개 Python API와 내장 HTTP API의 기준 문서다. 실행 예제는 [examples.md](./examples.md), 설정 입력은 [config.md](./config.md), 전체 환경변수 템플릿은 [`.env.example`](../.env.example)을 참고한다.

## 공개 범위 정책

- 1차 애플리케이션 API는 `fastapi_core.__all__`이다.
- FastAPI dependency, schema, router, extension, testing API는 각 모듈의 `__all__`로 공개한다.
- `fastapi_core.config.AppConfig`와 `load_app_config()`는 앱 factory가 직접 소비하는 의도된 설정 진입점이다.
- `runtime`, `lifecycle`, `logging`, `function_logging`의 `__all__`은 고급 조립 API다. 일반 서비스는 `create_app()`을 우선한다.
- 같은 객체의 package-root/submodule re-export는 하나의 API ID를 공유한다.
- `_`로 시작하는 이름과 `__all__`에 없는 내부 helper는 호환성 계약이 아니다.

## 추적성 매트릭스

| API ID | 공개 표면 | 책임 | 소스 소유자 | 대표 테스트 | 예제 | 설정 |
| --- | --- | --- | --- | --- | --- | --- |
| `API-APP-001` | `create_app` | FastAPI 앱, middleware, router, lifespan 조립 | `fastapi_core/factory.py` | `test_factory.py` | `EX-APP-001` | `CFG-APP` |
| `API-CFG-001` | `AppConfig`, `load_app_config` | 앱 환경변수 파싱·검증·cache | `fastapi_core/config.py` | `test_config.py` | `EX-CFG-001` | `CFG-APP` |
| `API-MOD-001` | `DomainModule`, `ErrorMapperSpec` | router/dependency/resource/readiness/error mapper 묶음 | `fastapi_core/modules.py` | `test_next_requirements.py` | `EX-MOD-001` | `CFG-NONE` |
| `API-EXT-001` | `ManagedResource`, `ResourceKey`, `ResourceRegistry` | 앱 자원의 생성·조회·readiness·역순 종료 | `fastapi_core/resources.py` | `test_extensions.py` | `EX-RES-001` | `CFG-READINESS` |
| `API-EXT-002` | `Check`, `ReadinessCheckSpec`, `ReadinessRegistry`, `register_readiness_check` | sync/async readiness 등록·집계 | `fastapi_core/readiness.py` | `test_extensions.py`, `test_health_router.py` | `EX-READY-001` | `CFG-READINESS` |
| `API-ERR-001` | `ErrorMapping`, `ErrorRenderer`, `register_error_mapper` | 도메인 예외를 안전한 HTTP 오류로 변환 | `fastapi_core/http.py` | `test_http.py` | `EX-ERR-001` | `CFG-HTTP` |
| `API-DEP-001` | `get_config`, `get_settings` | 앱 설정과 DocMesh 서비스 설정 주입 | `fastapi_core/dependencies/config.py` | `test_dependencies.py` | `EX-DEP-001` | `CFG-APP`, `CFG-SVC` |
| `API-DEP-002` | `get_service_runtime`, `get_service_client` | runtime 및 이름 기반 wrapper 조회 | `fastapi_core/dependencies/services.py` | `test_dependencies.py` | `EX-DEP-001` | `CFG-SVC` |
| `API-DEP-003` | 8개 typed service dependency | SDK client/provider/engine 조회 | `fastapi_core/dependencies/services.py` | `test_dependencies.py` | `EX-DEP-002` | `CFG-SVC` |
| `API-DEP-004` | `get_resource` | 이름 기반 managed resource dependency 생성 | `fastapi_core/dependencies/services.py` | `test_extensions.py` | `EX-RES-001` | `CFG-NONE` |
| `API-AUTH-001` | `get_auth_provider`, `get_current_user` | Keycloak provider와 인증 사용자 주입 | `fastapi_core/dependencies/auth.py` | `test_dependencies.py`, `test_auth_router.py` | `EX-AUTH-001` | `CFG-KEYCLOAK` |
| `API-AUTH-002` | `require_roles`, `require_scopes`, `require_permissions` | route 인가 dependency factory | `fastapi_core/dependencies/auth.py` | `test_dependencies.py` | `EX-AUTH-001` | `CFG-KEYCLOAK` |
| `API-SCHEMA-001` | `HealthResponse`, `HealthServiceDetail` | health 응답 계약 | `fastapi_core/schemas/health.py` | `test_schemas.py`, `test_health_router.py` | `EX-HTTP-001` | `CFG-READINESS` |
| `API-SCHEMA-002` | `TokenResponse`, `UserInfo` | 인증 route 공개 DTO | `fastapi_core/schemas/token.py`, `user.py` | `test_schemas.py`, `test_auth_router.py` | `EX-AUTH-001` | `CFG-KEYCLOAK` |
| `API-SCHEMA-003` | `ProblemDetail` | 기본 `application/problem+json` envelope | `fastapi_core/schemas/error.py` | `test_schemas.py`, `test_http.py` | `EX-ERR-001` | `CFG-HTTP` |
| `API-ROUTER-001` | `health_router` | liveness/readiness router 재사용 | `fastapi_core/routers/health.py` | `test_health_router.py` | `EX-ROUTER-001` | `CFG-READINESS` |
| `API-ROUTER-002` | `auth_router` | token/user router 재사용 | `fastapi_core/routers/auth.py` | `test_auth_router.py` | `EX-ROUTER-001` | `CFG-KEYCLOAK` |
| `API-HTTP-001` | `GET /health/liveness` | 프로세스 생존 확인 | `routers/health.py` | `test_health_router.py` | `EX-HTTP-001` | `CFG-NONE` |
| `API-HTTP-002` | `GET /health/readiness` | 필수/선택 의존성 준비 상태 | `routers/health.py` | `test_health_router.py` | `EX-HTTP-001` | `CFG-READINESS` |
| `API-HTTP-003` | `POST /token` | OAuth2 password form 기반 token 발급 | `routers/auth.py` | `test_auth_router.py` | `EX-AUTH-001` | `CFG-KEYCLOAK` |
| `API-HTTP-004` | `GET /user` | bearer token 사용자 DTO 조회 | `routers/auth.py` | `test_auth_router.py` | `EX-AUTH-001` | `CFG-KEYCLOAK` |
| `API-ADV-001` | runtime 조립 API | 설정을 plan/runtime/readiness로 연결 | `fastapi_core/runtime.py` | `test_factory.py` | `EX-ADV-001` | `CFG-SVC`, `CFG-READINESS` |
| `API-ADV-002` | `build_lifespan` | runtime/resource/custom lifespan 소유권 결합 | `fastapi_core/lifecycle.py` | `test_factory.py`, `test_extensions.py` | `EX-APP-001` | `CFG-READINESS` |
| `API-ADV-003` | logging API | 앱 로깅 및 함수 경계 이벤트 | `fastapi_core/logging.py`, `function_logging.py` | `test_function_logging.py`, `test_factory.py` | `EX-LOG-001` | `CFG-LOG` |
| `API-TEST-001` | `fastapi_core.testing` | 소비사 contract test helper | `fastapi_core/testing.py` | `test_testing.py` | `EX-TEST-001` | `CFG-APP` |

## 1차 애플리케이션 API

### `API-APP-001` — `create_app`

```text
create_app(
    config: AppConfig | None = None,
    *,
    runtime: ServiceRuntime | None = None,
    lifespan: Callable | None = None,
    include_auth_router: bool = False,
    routers: Sequence[APIRouter] = (),
    modules: Sequence[DomainModule] = (),
    resources: Sequence[ManagedResource[Any]] = (),
    error_mappers: Sequence[ErrorMapperSpec] = (),
    error_renderer: ErrorRenderer | None = None,
    auth_provider: Any | None = None,
) -> FastAPI
```

- health router는 항상 포함하고 auth router는 opt-in이다.
- `runtime=None`이면 `enabled_services`로 runtime plan을 만들고 lifespan에서 조립한다.
- `runtime`을 주입하면 그 객체가 권위 있는 runtime이며 framework lifespan이 종료한다.
- `modules`, `resources`, `error_mappers`, router의 이름·경로·operation ID 충돌은 앱 생성 중 거부한다.
- 생성한 앱은 `config`, `root_logger`, `service_runtime`, `readiness_registry`, `resource_registry`, `domain_modules`, `oauth2_scheme`, `error_renderer`, `error_mapper_types` state를 사용한다. 인증 provider가 준비되면 `auth_provider`도 저장한다.
- `TOKEN_URL`은 OpenAPI OAuth2 token URL만 바꾸며 내장 route `/token`은 바꾸지 않는다.

### `API-CFG-001` — 앱 설정

```text
AppConfig(**values)
load_app_config() -> AppConfig
```

`load_app_config()`는 최대 1개 결과를 cache한다. 테스트나 프로세스 내 환경변수 변경 후에는 `load_app_config.cache_clear()`가 필요하다. 필드·alias·검증은 [config.md의 `CFG-APP`](./config.md#cfg-app--appconfig)를 따른다.

## 모듈, 자원, readiness

### `API-MOD-001`

```text
DomainModule(
    name: str,
    routers=(), dependencies=(), resources=(),
    readiness_checks=(), error_mappers=(),
)
ErrorMapperSpec(exception_type: type[Exception], mapper: ErrorMapper)
```

module route에는 `dependencies`가 공통 적용된다. module 이름은 비어 있을 수 없고 앱 안에서 유일해야 한다.

### `API-EXT-001`

```text
ResourceKey(name: str)
ManagedResource(
    name, factory, healthcheck=None, close=None, required=True,
    readiness_timeout_seconds=None, redact_errors=True,
)
```

`ResourceKey[T].dependency`는 typed FastAPI dependency다. 자원은 선언 순서로 생성하고 역순으로 닫는다. 명시적 `close`가 없으면 `aclose()`, `close()` 순으로 탐색한다. `ResourceRegistry`는 고급 registry API이며 `start()`, `check_startup()`, `require()`, `close()`를 제공한다.

### `API-EXT-002`

```text
ReadinessCheckSpec(
    name, check, required=True, timeout_seconds=None, redact_errors=True,
)
register_readiness_check(
    app, name, check, *, required=True,
    timeout_seconds=None, redact_errors=True,
) -> None
```

check는 sync/async 또는 awaitable 반환을 지원한다. `False`는 실패다. `ReadinessRegistry`의 공개 동작은 `register()`, `unregister()`, `resolve_spec()`, `check()`다. 중복·빈 이름과 0 이하 timeout은 거부한다.

## 오류 API

### `API-ERR-001`

```text
ErrorMapping(
    status_code: int,
    detail: str,
    title: str | None = None,
    type_uri: str = "about:blank",
    headers: dict[str, str] | None = None,
    code: str | None = None,
    extensions: dict[str, object] | None = None,
)
register_error_mapper(app, exception_type, mapper) -> None
```

mapper와 renderer는 sync/async를 모두 지원한다. mapper의 `detail`은 renderer 호출 전에 마스킹된다. 기본 renderer는 `ProblemDetail`만 출력하므로 `code`와 `extensions`를 응답에 포함하려면 사용자 `error_renderer`가 이를 소비해야 한다. 같은 예외 타입의 중복 mapper는 거부한다.

## Dependency API

모든 함수는 `fastapi_core.dependencies`에서 import한다.

| API ID | 함수 | 성공 반환 | 실패 |
| --- | --- | --- | --- |
| `API-DEP-001` | `get_config(request)` | `AppConfig` | state가 없으면 cached 환경 설정 |
| `API-DEP-001` | `get_settings(request)` | `ServiceConfigs` | runtime 없음: 503 |
| `API-DEP-002` | `get_service_runtime(request)` | `ServiceRuntime` | 없음: 503 |
| `API-DEP-002` | `get_service_client(name)` | dependency factory → wrapper/builder | 미활성: 503 |
| `API-DEP-004` | `get_resource(name)` | dependency factory → managed instance | 미준비: 503 |
| `API-DEP-003` | `get_keycloak_auth_service` | `KeycloakAuthService` | 미활성 503, 타입 불일치 500 |
| `API-DEP-003` | `get_postgres_engine`, `get_sqlite_engine` | SQLAlchemy `Engine` | 동일 |
| `API-DEP-003` | `get_minio_client` | `Minio` | 동일 |
| `API-DEP-003` | `get_milvus_client` | `MilvusClient` | 동일 |
| `API-DEP-003` | `get_ollama_client` | `ollama.Client` | 동일 |
| `API-DEP-003` | `get_langfuse_client` | `Langfuse` | 동일 |
| `API-DEP-003` | `get_nats_connection_builder` | `NatsConnectionBuilder` | 동일 |
| `API-AUTH-001` | `get_auth_provider`, `get_current_user` | provider, `AuthenticatedUser` | token 없음/무효: 401 |
| `API-AUTH-002` | `require_roles(*roles)` | 인가 dependency factory | 부족: 403 |
| `API-AUTH-002` | `require_scopes(*scopes)` | 인가 dependency factory | 부족: 403 |
| `API-AUTH-002` | `require_permissions(*permissions)` | role 또는 scope 검사 dependency | 부족: 403 |

role은 realm/client role의 합집합, scope는 JWT `claims["scope"]`의 공백 구분 값이다. 모든 인가 dependency는 성공 시 원본 `AuthenticatedUser`를 반환한다.

## Schema 계약

| API ID | schema | 필드 |
| --- | --- | --- |
| `API-SCHEMA-001` | `HealthServiceDetail` | `ok: bool`, `latency_ms: int \| None`, `error: str \| None`, `required=False`, `enabled=True` |
| `API-SCHEMA-001` | `HealthResponse` | `status: "ok" \| "degraded" \| "error"`, `details: dict[str, HealthServiceDetail] \| None` |
| `API-SCHEMA-002` | `TokenResponse` | `access_token: str`, `refresh_token: str \| None`, `token_type="bearer"` |
| `API-SCHEMA-002` | `UserInfo` | `sub`, `username`, optional `email`/`name`, `roles`, `scopes` |
| `API-SCHEMA-003` | `ProblemDetail` | `type`, `title`, `status`, `detail`, `instance`, `correlation_id` |

## 내장 HTTP API

실제 OpenAPI에서 확인한 route다. `root_path`는 배포 prefix 메타데이터이며 아래 route path 자체는 변하지 않는다.

| API ID | method/path | 포함 조건 | 요청 | 성공 | 주요 실패 |
| --- | --- | --- | --- | --- | --- |
| `API-HTTP-001` | `GET /health/liveness` | 항상 | 없음 | `200 {"status":"ok","details":null}` | 없음 |
| `API-HTTP-002` | `GET /health/readiness` | 항상 | 없음 | `200 ok/degraded` | 필수 실패/overall timeout: `503 error` |
| `API-HTTP-003` | `POST /token` | `include_auth_router=True` | OAuth2 form: username/password/scope | `200 TokenResponse` | 인증 401, 설정 500, 일시 503, upstream 502, validation 422 |
| `API-HTTP-004` | `GET /user` | `include_auth_router=True` | bearer token | `200 UserInfo` | token 없음/무효 401 |

모든 응답에는 유효한 입력 `X-Correlation-ID` 또는 새 32자리 hex ID가 같은 이름의 헤더로 포함된다. HTTP/validation/unhandled 오류의 기본 body는 `application/problem+json`이다.

Readiness 상태:

- check가 없거나 전부 성공: `200`, `ok`
- 선택 check만 실패: `200`, `degraded`
- 필수 check 실패 또는 overall timeout: `503`, `error`
- `redact_errors=True`인 실패 detail: `readiness check failed`

## 고급 조립 API

| API ID | 공개 함수/타입 | 계약 |
| --- | --- | --- |
| `API-ADV-001` | `build_runtime_plan(config)` | 서비스 선택, 대안 그룹, startup health 정책을 `RuntimePlan`으로 변환 |
| `API-ADV-001` | `assemble_runtime(plan)` | plan이 있으면 DocMesh runtime 조립, 없으면 빈 runtime 생성 |
| `API-ADV-001` | `configure_service_runtime(app, runtime)` | runtime check를 readiness에 원자적으로 등록하고 Keycloak provider 연결 |
| `API-ADV-002` | `build_lifespan(...)` | runtime → resource → custom lifespan 순으로 시작하고 역방향 정리 |
| `API-ADV-003` | `configure_application_logging(config)` | DocMesh logging을 구성하고 선택적으로 JSON formatter 적용 |
| `API-ADV-003` | `JsonLogFormatter` | timestamp/logger/level/message/function_event/event/exception JSON 출력 |
| `API-ADV-003` | `log_function_boundary(event=None)` | sync/async 함수 start/end/error 구조화 로그 decorator |

## 소비사 테스트 API

| API ID | helper | 용도 |
| --- | --- | --- |
| `API-TEST-001` | `create_empty_runtime()` | 외부 서비스 없는 표준 `ServiceRuntime` |
| `API-TEST-001` | `ResourceLifecycleProbe` | create/check/close 이벤트 기록 managed resource 생성 |
| `API-TEST-001` | `assert_health_contract(client)` | 내장 liveness/readiness 성공 계약 검증 |
| `API-TEST-001` | `assert_auth_router_contract(client, included=...)` | auth route opt-in 검증 |
| `API-TEST-001` | `assert_module_contract(app, module)` | module route/resource/readiness/mapper 설치 검증 |
| `API-TEST-001` | `assert_openapi_contract(app, ...)` | path/method/security scheme/참조/operation ID 검증 |
| `API-TEST-001` | `test_environment(overrides)` | 환경변수와 앱/DocMesh settings cache를 격리 |

## 정확한 공개 import 경로 인벤토리

각 행의 경로는 실제 `__all__` 또는 의도된 config 진입점이다. alias는 같은 API ID를 공유한다.

| API ID | 정확한 import 경로 |
| --- | --- |
| `API-APP-001` | `fastapi_core.create_app`; `fastapi_core.factory.create_app` |
| `API-CFG-001` | `fastapi_core.config.AppConfig`; `fastapi_core.config.load_app_config` |
| `API-MOD-001` | `fastapi_core.DomainModule`; `fastapi_core.modules.DomainModule`; `fastapi_core.ErrorMapperSpec`; `fastapi_core.modules.ErrorMapperSpec` |
| `API-EXT-001` | `fastapi_core.ManagedResource`; `fastapi_core.extensions.ManagedResource`; `fastapi_core.resources.ManagedResource`; `fastapi_core.ResourceKey`; `fastapi_core.resources.ResourceKey`; `fastapi_core.extensions.ResourceRegistry`; `fastapi_core.resources.ResourceRegistry` |
| `API-EXT-002` | `fastapi_core.extensions.Check`; `fastapi_core.readiness.Check`; `fastapi_core.ReadinessCheckSpec`; `fastapi_core.extensions.ReadinessCheckSpec`; `fastapi_core.readiness.ReadinessCheckSpec`; `fastapi_core.extensions.ReadinessRegistry`; `fastapi_core.readiness.ReadinessRegistry`; `fastapi_core.register_readiness_check`; `fastapi_core.extensions.register_readiness_check`; `fastapi_core.readiness.register_readiness_check` |
| `API-ERR-001` | `fastapi_core.ErrorMapping`; `fastapi_core.ErrorRenderer`; `fastapi_core.register_error_mapper` |
| `API-DEP-001` | `fastapi_core.dependencies.get_config`; `fastapi_core.dependencies.get_settings` |
| `API-DEP-002` | `fastapi_core.dependencies.get_service_runtime`; `fastapi_core.dependencies.get_service_client` |
| `API-DEP-003` | `fastapi_core.dependencies.get_keycloak_auth_service`; `fastapi_core.dependencies.get_postgres_engine`; `fastapi_core.dependencies.get_sqlite_engine`; `fastapi_core.dependencies.get_minio_client`; `fastapi_core.dependencies.get_milvus_client`; `fastapi_core.dependencies.get_ollama_client`; `fastapi_core.dependencies.get_langfuse_client`; `fastapi_core.dependencies.get_nats_connection_builder` |
| `API-DEP-004` | `fastapi_core.dependencies.get_resource` |
| `API-AUTH-001` | `fastapi_core.dependencies.get_auth_provider`; `fastapi_core.dependencies.get_current_user` |
| `API-AUTH-002` | `fastapi_core.dependencies.require_roles`; `fastapi_core.dependencies.require_scopes`; `fastapi_core.dependencies.require_permissions` |
| `API-SCHEMA-001` | `fastapi_core.schemas.HealthResponse`; `fastapi_core.schemas.HealthServiceDetail` |
| `API-SCHEMA-002` | `fastapi_core.schemas.TokenResponse`; `fastapi_core.schemas.UserInfo` |
| `API-SCHEMA-003` | `fastapi_core.schemas.ProblemDetail` |
| `API-ROUTER-001` | `fastapi_core.routers.health_router` |
| `API-ROUTER-002` | `fastapi_core.routers.auth_router` |
| `API-ADV-001` | `fastapi_core.runtime.assemble_runtime`; `fastapi_core.runtime.build_runtime_plan`; `fastapi_core.runtime.configure_service_runtime` |
| `API-ADV-002` | `fastapi_core.lifecycle.build_lifespan` |
| `API-ADV-003` | `fastapi_core.logging.JsonLogFormatter`; `fastapi_core.logging.configure_application_logging`; `fastapi_core.function_logging.log_function_boundary` |
| `API-TEST-001` | `fastapi_core.testing.ResourceLifecycleProbe`; `fastapi_core.testing.assert_auth_router_contract`; `fastapi_core.testing.assert_health_contract`; `fastapi_core.testing.assert_module_contract`; `fastapi_core.testing.assert_openapi_contract`; `fastapi_core.testing.create_empty_runtime`; `fastapi_core.testing.test_environment` |

## 변경 검토 규칙

공개 API를 추가·삭제·이동할 때는 같은 변경에서 다음을 함께 갱신한다.

1. 이 문서의 추적성 매트릭스와 정확한 import 경로 인벤토리
2. [examples.md](./examples.md)의 API ID → EX ID coverage
3. [config.md](./config.md)의 관련 `CFG-*` anchor와 환경변수
4. [`.env.example`](../.env.example)의 assignment-shaped key
5. 공개 API/OpenAPI/config/문서 검증 테스트
