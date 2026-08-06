---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/API-Reference-v0.7.0.md
ingested: 2026-08-02
sha256: 1525e0e121884525eefb2b547ad2025c409c12c2e321c808ab95d54ab617d8ff
---
# fastapi-core 공개 API 레퍼런스

> 기준 릴리스: `fastapi-core 0.7.0`
>
> 상태: current-implementation

이 페이지는 `docs/api.md`를 Git wiki에서 조회할 수 있도록 캡처한 API 레퍼런스다. 단순 사용 설명에 그치지 않고 package-root와 공개 submodule의 `__all__`, 의도적으로 공개한 설정 진입점, 생성된 OpenAPI route를 **API → source → test → example → config**로 추적한다.

- 소비자 예제: [fastapi-core examples](Examples-v0.7.0.md)
- 설정 계약: [fastapi-core config](Configuration-v0.7.0.md)
- 저장소 원문: `docs/api.md`
- 요구사항 경계: `docs/srs.md`, `docs/prd.md`

## 1. 공개 import 경계

신규 소비자는 다음 경계를 우선 사용한다.

```python
from fastapi_core import create_app, ResourceBinding
from fastapi_core.dependencies import get_current_user
from fastapi_core.schemas import ProblemDetail
```

- `fastapi_core.__all__`: 앱 factory와 핵심 extension의 package-root 계약
- `fastapi_core.dependencies.__all__`: FastAPI dependency 계약
- `fastapi_core.schemas.__all__`: HTTP request/response schema 계약
- `fastapi_core.extensions`, `resources`, `readiness`, `modules`, `runtime`, `logging`, `testing` 등의 `__all__`: 명시적으로 공개한 고급/소비자 테스트 계약
- `fastapi_core.config.AppConfig`, `fastapi_core.config.load_app_config`, `fastapi_core.docmesh_settings.load_docmesh_settings`: 설정을 위해 의도적으로 공개한 진입점

같은 object의 re-export는 한 API ID를 공유한다. 표에 기록한 모든 exact import path는 실제 source owner와 연결되며, package-root에 재노출되지 않은 임의의 underscore helper나 `__all__`가 없는 구현 모듈의 내부 이름은 호환성 있는 public API가 아니다.

## 2. 전체 공개 API 추적표

각 행은 하나의 안정적인 API ID다. 한 행에 여러 import path가 있으면 같은 object의 re-export이며, 별도 API로 중복 집계하지 않는다. `설정 없음`은 설정을 읽지 않는다는 의미이며, 해당 API가 실행되는 example과 test는 여전히 기록한다.

<!-- PUBLIC_API_TRACEABILITY_START -->
| API ID | 공개 심볼 및 exact import path | source owner | representative test | example | config |
| --- | --- | --- | --- | --- | --- |
| `API-APP-001` | `fastapi_core.create_app`; `fastapi_core.factory.create_app` | `fastapi_core/factory.py:create_app` | `test_fastapi_core/test_factory.py`; `test_fastapi_core/test_public_api.py` | [EX-APP-001](Examples-v0.7.0.md#ex-app-001), [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-APP-001](Configuration-v0.7.0.md#cfg-app-001) |
| `API-APP-002` | `fastapi_core.DomainModule`; `fastapi_core.modules.DomainModule` | `fastapi_core/modules.py:30` | `test_fastapi_core/test_target_contracts.py` | [EX-MOD-001](Examples-v0.7.0.md#ex-mod-001) | [CFG-APP-003](Configuration-v0.7.0.md#cfg-app-003) |
| `API-APP-003` | `fastapi_core.DomainModuleProvider`; `fastapi_core.modules.DomainModuleProvider` | `fastapi_core/modules.py:24` | `test_fastapi_core/test_public_api.py` | [EX-MOD-002](Examples-v0.7.0.md#ex-mod-002) | 설정 없음 |
| `API-APP-004` | `fastapi_core.ErrorMapperSpec`; `fastapi_core.modules.ErrorMapperSpec` | `fastapi_core/modules.py:18` | `test_fastapi_core/test_target_contracts.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-RES-001` | `fastapi_core.ManagedResource`; `fastapi_core.extensions.ManagedResource`; `fastapi_core.resources.ManagedResource` | `fastapi_core/resources.py:63` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_extensions.py` | [EX-RES-001](Examples-v0.7.0.md#ex-res-001), [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | [CFG-RES-001](Configuration-v0.7.0.md#cfg-res-001) |
| `API-RES-002` | `fastapi_core.ResourceBinding`; `fastapi_core.extensions.ResourceBinding`; `fastapi_core.resources.ResourceBinding` | `fastapi_core/resources.py:89` | `test_fastapi_core/test_target_contracts.py` | [EX-RES-001](Examples-v0.7.0.md#ex-res-001), [EX-INVOKE-001](Examples-v0.7.0.md#ex-invoke-001) | [CFG-RES-001](Configuration-v0.7.0.md#cfg-res-001) |
| `API-RES-003` | `fastapi_core.ResourceKey`; `fastapi_core.resources.ResourceKey` | `fastapi_core/resources.py:35` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_dependencies.py` | [EX-RES-001](Examples-v0.7.0.md#ex-res-001) | 설정 없음 |
| `API-RES-004` | `fastapi_core.extensions.ResourceRegistry`; `fastapi_core.resources.ResourceRegistry` | `fastapi_core/resources.py:151` | `test_fastapi_core/test_public_api.py`; `test_fastapi_core/test_testing.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | [CFG-RES-001](Configuration-v0.7.0.md#cfg-res-001) |
| `API-READY-001` | `fastapi_core.extensions.Check`; `fastapi_core.readiness.Check` | `fastapi_core/readiness.py:17` | `test_fastapi_core/test_extensions.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | 설정 없음 |
| `API-READY-002` | `fastapi_core.HealthOutcome`; `fastapi_core.extensions.HealthOutcome`; `fastapi_core.readiness.HealthOutcome` | `fastapi_core/readiness.py:22` | `test_fastapi_core/test_target_contracts.py` | [EX-RES-002](Examples-v0.7.0.md#ex-res-002) | 설정 없음 |
| `API-READY-003` | `fastapi_core.HealthResultAdapter`; `fastapi_core.extensions.HealthResultAdapter`; `fastapi_core.readiness.HealthResultAdapter` | `fastapi_core/readiness.py:18` | `test_fastapi_core/test_target_contracts.py` | [EX-RES-002](Examples-v0.7.0.md#ex-res-002) | 설정 없음 |
| `API-READY-004` | `fastapi_core.ReadinessCheckSpec`; `fastapi_core.extensions.ReadinessCheckSpec`; `fastapi_core.readiness.ReadinessCheckSpec` | `fastapi_core/readiness.py:29` | `test_fastapi_core/test_public_api.py`; `test_fastapi_core/test_extensions.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-READY-005` | `fastapi_core.extensions.ReadinessRegistry`; `fastapi_core.readiness.ReadinessRegistry` | `fastapi_core/readiness.py:95` | `test_fastapi_core/test_public_api.py`; `test_fastapi_core/test_health_router.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-READY-006` | `fastapi_core.register_readiness_check`; `fastapi_core.extensions.register_readiness_check`; `fastapi_core.readiness.register_readiness_check` | `fastapi_core/readiness.py:200` | `test_fastapi_core/test_public_api.py`; `test_fastapi_core/test_extensions.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-HTTP-001` | `fastapi_core.ErrorMapping`; `fastapi_core.http.ErrorMapping` | `fastapi_core/http.py:31` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-HTTP-002` | `fastapi_core.ErrorRenderer` | `fastapi_core/http.py:43` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-HTTP-003` | `fastapi_core.ExceptionMappingTable`; `fastapi_core.http.ExceptionMappingTable` | `fastapi_core/http.py:150` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-HTTP-004` | `fastapi_core.create_error_renderer`; `fastapi_core.http.create_error_renderer` | `fastapi_core/http.py:264` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-HTTP-005` | `fastapi_core.register_error_mapper`; `fastapi_core.http.register_error_mapper` | `fastapi_core/http.py:446` | `test_fastapi_core/test_target_contracts.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-HTTP-006` | `fastapi_core.routers.auth_router`; `fastapi_core.routers.health_router` | `fastapi_core/routers/__init__.py:1` | `test_fastapi_core/test_auth_router.py`; `test_fastapi_core/test_health_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001), [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-HTTP-ROUTE-001` | `GET /health/liveness` | `fastapi_core/routers/health.py:66` | `test_fastapi_core/test_health_router.py`; `test_fastapi_core/test_testing.py` | [EX-APP-001](Examples-v0.7.0.md#ex-app-001) | 설정 없음 |
| `API-HTTP-ROUTE-002` | `GET /health/readiness` | `fastapi_core/routers/health.py:72` | `test_fastapi_core/test_health_router.py`; `test_fastapi_core/test_extensions.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-HTTP-ROUTE-003` | `POST /token` | `fastapi_core/routers/auth.py:96` | `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-HTTP-ROUTE-004` | `GET /user` | `fastapi_core/routers/auth.py:121` | `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-INVOKE-001` | `fastapi_core.invoke_resource`; `fastapi_core.invocation.invoke_resource` | `fastapi_core/invocation.py:15` | `test_fastapi_core/test_target_contracts.py` | [EX-INVOKE-001](Examples-v0.7.0.md#ex-invoke-001) | 설정 없음 |
| `API-STREAM-001` | `fastapi_core.ManagedStreamingResponse`; `fastapi_core.streaming.ManagedStreamingResponse` | `fastapi_core/streaming.py:14` | `test_fastapi_core/test_target_contracts.py` | [EX-STREAM-001](Examples-v0.7.0.md#ex-stream-001) | 설정 없음 |
| `API-TRAN-001` | `fastapi_core.TransportPolicy`; `fastapi_core.transport.TransportPolicy` | `fastapi_core/transport.py:25` | `test_fastapi_core/test_target_contracts.py` | [EX-MOD-001](Examples-v0.7.0.md#ex-mod-001) | [CFG-APP-003](Configuration-v0.7.0.md#cfg-app-003) |
| `API-RUNTIME-001` | `fastapi_core.runtime.assemble_runtime` | `fastapi_core/runtime.py:65` | `test_fastapi_core/test_factory.py`; `test_fastapi_core/test_config.py` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-RUNTIME-002` | `fastapi_core.runtime.build_runtime_plan` | `fastapi_core/runtime.py:36` | `test_fastapi_core/test_config.py`; `test_fastapi_core/test_factory.py` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-RUNTIME-003` | `fastapi_core.runtime.configure_service_runtime` | `fastapi_core/runtime.py:72` | `test_fastapi_core/test_factory.py`; `test_fastapi_core/test_dependencies.py` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-LIFE-001` | `fastapi_core.lifecycle.build_lifespan` | `fastapi_core/lifecycle.py:42` | `test_fastapi_core/test_factory.py`; integration lifespan tests | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-LOG-001` | `fastapi_core.logging.JsonLogFormatter` | `fastapi_core/logging.py:12` | `test_fastapi_core/test_function_logging.py` | [EX-LOG-001](Examples-v0.7.0.md#ex-log-001) | [CFG-LOG-001](Configuration-v0.7.0.md#cfg-log-001) |
| `API-LOG-002` | `fastapi_core.logging.configure_application_logging` | `fastapi_core/logging.py:32` | `test_fastapi_core/test_factory.py`; `test_fastapi_core/test_function_logging.py` | [EX-LOG-001](Examples-v0.7.0.md#ex-log-001) | [CFG-LOG-001](Configuration-v0.7.0.md#cfg-log-001) |
| `API-LOG-003` | `fastapi_core.function_logging.log_function_boundary` | `fastapi_core/function_logging.py:13` | `test_fastapi_core/test_function_logging.py` | [EX-LOG-001](Examples-v0.7.0.md#ex-log-001) | [CFG-LOG-001](Configuration-v0.7.0.md#cfg-log-001) |
| `API-CFG-001` | `fastapi_core.config.AppConfig`; `fastapi_core.config.load_app_config` | `fastapi_core/config.py:45`, `fastapi_core/config.py:203` | `test_fastapi_core/test_config.py` | [EX-APP-001](Examples-v0.7.0.md#ex-app-001), [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-APP-001](Configuration-v0.7.0.md#cfg-app-001) |
| `API-CFG-002` | `fastapi_core.docmesh_settings.load_docmesh_settings` | `fastapi_core/docmesh_settings.py:11` | `test_fastapi_core/test_config.py` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-DEP-001` | `fastapi_core.dependencies.get_auth_provider` | `fastapi_core/dependencies/auth.py` | `test_fastapi_core/test_dependencies.py`; `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-DEP-002` | `fastapi_core.dependencies.get_config` | `fastapi_core/dependencies/config.py` | `test_fastapi_core/test_dependencies.py`; `test_fastapi_core/test_health_router.py` | [EX-APP-001](Examples-v0.7.0.md#ex-app-001) | [CFG-APP-001](Configuration-v0.7.0.md#cfg-app-001) |
| `API-DEP-003` | `fastapi_core.dependencies.get_current_user` | `fastapi_core/dependencies/auth.py` | `test_fastapi_core/test_dependencies.py`; `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-DEP-004` | `fastapi_core.dependencies.get_keycloak_auth_service`, `get_postgres_engine`, `get_sqlite_engine`, `get_minio_client`, `get_milvus_client`, `get_ollama_client`, `get_langfuse_client`, `get_nats_connection_builder` | `fastapi_core/dependencies/services.py` | `test_fastapi_core/test_dependencies.py` | [EX-DEP-001](Examples-v0.7.0.md#ex-dep-001) | [CFG-SVC-001](Configuration-v0.7.0.md#cfg-svc-001) |
| `API-DEP-005` | `fastapi_core.dependencies.get_resource` | `fastapi_core/dependencies/services.py` | `test_fastapi_core/test_dependencies.py`; `test_fastapi_core/test_target_contracts.py` | [EX-RES-001](Examples-v0.7.0.md#ex-res-001) | [CFG-RES-001](Configuration-v0.7.0.md#cfg-res-001) |
| `API-DEP-006` | `fastapi_core.dependencies.get_service_client` | `fastapi_core/dependencies/services.py` | `test_fastapi_core/test_dependencies.py` | [EX-DEP-001](Examples-v0.7.0.md#ex-dep-001) | [CFG-SVC-001](Configuration-v0.7.0.md#cfg-svc-001) |
| `API-DEP-007` | `fastapi_core.dependencies.get_service_runtime` | `fastapi_core/dependencies/services.py` | `test_fastapi_core/test_dependencies.py` | [EX-DEP-001](Examples-v0.7.0.md#ex-dep-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-DEP-008` | `fastapi_core.dependencies.get_settings` | `fastapi_core/dependencies/config.py` | `test_fastapi_core/test_dependencies.py`; `test_fastapi_core/test_config.py` | [EX-RUNTIME-001](Examples-v0.7.0.md#ex-runtime-001) | [CFG-SVC-001](Configuration-v0.7.0.md#cfg-svc-001) |
| `API-DEP-009` | `fastapi_core.dependencies.require_permissions`, `require_roles`, `require_scopes` | `fastapi_core/dependencies/auth.py` | `test_fastapi_core/test_dependencies.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-SCHEMA-001` | `fastapi_core.schemas.HealthResponse` | `fastapi_core/schemas/health.py` | `test_fastapi_core/test_schemas.py`; `test_fastapi_core/test_health_router.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-SCHEMA-002` | `fastapi_core.schemas.HealthServiceDetail` | `fastapi_core/schemas/health.py` | `test_fastapi_core/test_schemas.py`; `test_fastapi_core/test_health_router.py` | [EX-READY-001](Examples-v0.7.0.md#ex-ready-001) | [CFG-READY-001](Configuration-v0.7.0.md#cfg-ready-001) |
| `API-SCHEMA-003` | `fastapi_core.schemas.ProblemDetail` | `fastapi_core/schemas/error.py` | `test_fastapi_core/test_schemas.py`; `test_fastapi_core/test_http.py` | [EX-ERR-001](Examples-v0.7.0.md#ex-err-001) | 설정 없음 |
| `API-SCHEMA-004` | `fastapi_core.schemas.TokenResponse` | `fastapi_core/schemas/token.py` | `test_fastapi_core/test_schemas.py`; `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-SCHEMA-005` | `fastapi_core.schemas.UserInfo` | `fastapi_core/schemas/user.py` | `test_fastapi_core/test_schemas.py`; `test_fastapi_core/test_auth_router.py` | [EX-APP-002](Examples-v0.7.0.md#ex-app-002) | [CFG-AUTH-001](Configuration-v0.7.0.md#cfg-auth-001) |
| `API-TEST-001` | `fastapi_core.testing.ApplicationContractProfile` | `fastapi_core/testing.py:25` | `test_fastapi_core/test_testing.py`; `test_fastapi_core/test_target_contracts.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | 설정 없음 |
| `API-TEST-002` | `fastapi_core.testing.ResourceLifecycleProbe` | `fastapi_core/testing.py:50` | `test_fastapi_core/test_testing.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | 설정 없음 |
| `API-TEST-003` | `fastapi_core.testing.assert_auth_router_contract`, `assert_application_contract`, `assert_health_contract`, `assert_module_contract`, `assert_openapi_contract` | `fastapi_core/testing.py:98`, `:142`, `:217` | `test_fastapi_core/test_testing.py`; `test_fastapi_core/test_target_contracts.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | 설정 없음 |
| `API-TEST-004` | `fastapi_core.testing.create_empty_runtime` | `fastapi_core/runtime.py:59` (re-exported by `testing.py`) | `test_fastapi_core/test_testing.py`; `test_fastapi_core/test_factory.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | [CFG-RUNTIME-001](Configuration-v0.7.0.md#cfg-runtime-001) |
| `API-TEST-005` | `fastapi_core.testing.test_environment` | `fastapi_core/testing.py:115` | `test_fastapi_core/test_testing.py`; `test_fastapi_core/test_config.py` | [EX-TEST-001](Examples-v0.7.0.md#ex-test-001) | [CFG-APP-001](Configuration-v0.7.0.md#cfg-app-001) |
<!-- PUBLIC_API_TRACEABILITY_END -->

`API-HTTP-ROUTE-001`~`004`는 설치 시 생성되는 OpenAPI에서 다음 명령으로 확인한 built-in inventory다.

```python
from fastapi_core import create_app
from fastapi_core.runtime import create_empty_runtime

app = create_app(
    runtime=create_empty_runtime(),
    include_auth_router=True,
    auth_provider=object(),
)
assert set(app.openapi()["paths"]) == {
    "/health/liveness",
    "/health/readiness",
    "/token",
    "/user",
}
```

## 3. 애플리케이션 조립

```python
from fastapi_core import create_app

app = create_app(
    routers=(),
    modules=(),
    resources=(),
    transport_policy=None,
    error_mapping_table=None,
)
```

현재 `create_app` signature:

```python
def create_app(
    config: AppConfig | None = None,
    *,
    runtime: ServiceRuntime | None = None,
    lifespan: Callable | None = None,
    include_auth_router: bool = False,
    routers: Sequence[APIRouter] = (),
    modules: Sequence[DomainModule] = (),
    resources: Sequence[ManagedResource[Any] | ResourceBinding[Any]] = (),
    error_mappers: Sequence[ErrorMapperSpec] = (),
    error_renderer: ErrorRenderer | None = None,
    auth_provider: Any | None = None,
    transport_policy: TransportPolicy | None = None,
    error_mapping_table: ExceptionMappingTable | None = None,
) -> FastAPI:
    ...
```

입력 계약:

- `resources`: `ManagedResource[T]` 또는 `ResourceBinding[T]`의 순서 있는 목록
- `modules`: `DomainModule`의 순서 있는 목록. module 이름은 중복될 수 없다.
- `routers`: 직접 전달하는 `APIRouter` 목록. route/method와 operation ID 중복은 거부된다.
- `transport_policy`: 직접 전달한 router에 적용할 앱 기본 transport policy
- `error_mappers`: 예외 class와 mapper의 선언 목록
- `error_mapping_table`: table-driven exception mapping
- `error_renderer`: 앱 기본 error renderer
- `lifespan`: 사용자 lifespan. framework가 runtime/resource cleanup을 감싼다.

앱 생성 후 consumer가 의존할 수 있는 state:

- 항상 생성: `app.state.config`, `root_logger`, `service_runtime`, `readiness_registry`, `resource_registry`, `resource_bindings`, `domain_modules`, `transport_policy`, `transport_policies`, `error_mapping_table`, `oauth2_scheme`, `error_renderer`(handler 설치 결과)
- 조건부 생성: configured Keycloak/runtime 또는 explicit `auth_provider`가 있으면 `app.state.auth_provider`
- 폐기된 계약: `app.state.settings`, `app.state.service_clients`, 평탄한 readiness state key에 직접 의존하지 않는다.

기본 health router는 항상 포함하고, auth router는 `include_auth_router=True`일 때만 포함한다. health/auth router에는 domain module의 transport policy가 자동 전파되지 않는다.

## 4. Managed resource와 typed dependency

```python
from fastapi import APIRouter, Depends
from fastapi_core import ResourceBinding

class DocumentStore:
    def search(self, query: str) -> list[dict[str, object]]:
        return [{"query": query}]

    def close(self) -> None:
        pass


document_store = ResourceBinding(
    "document-store",
    factory=lambda _app: DocumentStore(),
    healthcheck=lambda store: True,
    required=True,
)

router = APIRouter()

@router.get("/documents")
async def list_documents(
    store: DocumentStore = Depends(document_store.dependency),
):
    return store.search("*")
```

`ResourceBinding`은 registration descriptor와 typed dependency를 하나로 묶는다. 기존 `ManagedResource(...).bind()`는 canonical `ResourceBinding`으로 변환한다. `create_app(resources=[...])`는 두 입력 타입을 모두 받고 다음 순서로 종료한다.

1. `aclose()`가 있으면 await
2. 없고 `close()`가 있으면 worker thread에서 실행
3. 여러 resource는 역순으로 종료
4. startup 중 실패하면 이미 생성된 resource를 rollback
5. readiness check와 close는 중복 실행하지 않음

`ResourceBinding.call`과 `invoke_resource`는 coroutine을 직접 await하고 sync callable을 worker thread에서 실행한다. sync callable이 awaitable을 반환해도 끝까지 await한다. `timeout_seconds`는 양수일 때만 허용되고 초과 시 `asyncio.TimeoutError`를 전달한다.

```python
result = await document_store.call(
    "search",
    "invoice",
    instance=store,
    timeout_seconds=2.0,
)
```

## 5. Readiness contract

```python
from fastapi_core import register_readiness_check

register_readiness_check(
    app,
    "document-store",
    lambda: store.ping(),
    required=True,
    timeout_seconds=2.0,
    redact_errors=True,
)
```

`ReadinessCheckSpec`는 `name`, `check`, `required`, `timeout_seconds`, `redact_errors`, `health_result_adapter`를 가진다. check 결과의 계약은 다음과 같다.

- `True`, `None`: 성공
- `False`: 실패
- `HealthOutcome` 또는 `ok` attribute: `ok` 값으로 정규화
- `HealthCheckResult`/`ServiceHealthStatus`: 구조화된 service detail로 보존
- SDK의 opaque sentinel: 0.6 호환을 위해 허용; 엄격하게 해석하려면 `health_result_adapter`를 제공

내장 route 결과:

- `GET /health/liveness`: `200`, `{"status": "ok", "details": null}`
- `GET /health/readiness`: 모두 성공이면 `200 + ok`, optional 실패만 있으면 `200 + degraded`, required 실패 또는 overall timeout이면 `503 + error`
- per-service timeout은 해당 service detail의 실패로 변환되며, overall timeout은 전체 `503`으로 반환
- required 실패여도 다른 service의 전체 detail을 보존

## 6. DomainModule과 TransportPolicy

```python
from fastapi import APIRouter, Depends
from fastapi_core import DomainModule, TransportPolicy
from fastapi_core.schemas import ProblemDetail

router = APIRouter(prefix="/documents", tags=["documents"])

policy = TransportPolicy(
    dependencies=(Depends(require_document_scope),),
    validation_status=400,
    include_synthetic_422=False,
    common_error_response_model=ProblemDetail,
    common_error_statuses=(400, 401, 403, 500),
)

module = DomainModule(
    name="documents",
    routers=(router,),
    resources=(document_store,),
    transport_policy=policy,
)
```

`TransportPolicy`의 주요 필드:

- `dependencies`: module route에만 적용되는 공통 security/auth dependency
- `validation_status`, `validation_response_model`: request validation 오류 계약
- `common_error_response_model`, `common_error_statuses`: 공통 오류 OpenAPI 응답
- `fallback_response_model`: fallback 오류 응답 모델
- `responses`: 추가 FastAPI response metadata
- `error_renderer`: 해당 route의 renderer
- `include_synthetic_422`: OpenAPI synthetic 422 유지 여부

동일 policy는 runtime validation handler와 OpenAPI response 생성에 함께 사용된다. `validation_status=400`과 `include_synthetic_422=False`를 사용하면 module route의 invalid request가 400으로 반환되고 synthetic 422가 제거된다. policy를 생략하면 FastAPI의 422 기본 계약을 유지한다. 서로 다른 module이 충돌하는 policy 값을 선언하면 앱 조립 전에 거부한다.

`DomainModuleProvider`는 자동 discovery가 아닌 명시적 callable convention이다.

```python
from fastapi_core import DomainModule

def build_documents_module(settings) -> DomainModule:
    return DomainModule(name="documents")
```

## 7. Error mapping과 renderer

```python
from fastapi_core import ErrorMapping, ExceptionMappingTable, create_app

class DocumentNotFound(Exception):
    pass

error_table = ExceptionMappingTable(
    {
        DocumentNotFound: ErrorMapping(
            status_code=404,
            detail="Document not found",
            code="document_not_found",
        ),
    },
    fallback=ErrorMapping(
        status_code=500,
        detail="Request failed",
        code="request_failed",
    ),
)

app = create_app(error_mapping_table=error_table)
```

- exception class MRO에서 가장 구체적인 mapping을 선택
- mapping callable은 sync/async 모두 허용하고 `ErrorMapping`을 반환해야 함
- 중복 선언과 `Exception` mapping + fallback의 unreachable 조합은 생성 시 거부
- `headers`, `code`, `extensions`는 renderer까지 보존

표준 renderer는 조합 가능한 factory다.

```python
from fastapi_core import create_error_renderer

renderer = create_error_renderer(
    problem_details=False,
    fallback_codes={404: "not_found", 500: "internal_error"},
)
app = create_app(error_renderer=renderer)
```

기본 renderer는 `application/problem+json`과 RFC 7807 계열 `ProblemDetail`을 사용한다. envelope mode에서는 안전한 `error` 객체를 반환한다. correlation ID는 body와 `X-Correlation-ID` response header에 함께 제공되며, 민감한 exception detail은 mask 정책을 통과한다. domain error는 `register_error_mapper(app, exception_type, mapper)` 또는 `ErrorMapperSpec`으로 route 표면에 연결한다.

## 8. Auth dependency와 내장 auth API

`include_auth_router=True`이면 Keycloak provider가 필요하며 `keycloak`은 enabled/required 서비스여야 한다. 기본 OAuth2 scheme은 앱별로 생성되고 `AppConfig.token_url`을 OpenAPI password flow metadata에 반영한다. 단, 내장 route path는 항상 `POST /token`이다.

- `get_current_user`: bearer token을 검증하고 `AuthenticatedUser`를 정보 손실 없이 반환
- `require_roles(*roles)`: realm/client role을 확인하는 dependency factory
- `require_scopes(*scopes)`: token scope를 확인하는 dependency factory
- `require_permissions(*permissions)`: role 또는 scope permission을 확인하는 dependency factory
- token provider 오류는 401/500/502/503으로 매핑하고 `WWW-Authenticate: Bearer`를 포함
- `GET /user`는 `AuthenticatedUser`를 `UserInfo` DTO로 변환

서비스 dependency는 `ServiceRuntime`을 유일한 runtime 상태 소유자로 사용한다.

```python
from fastapi import APIRouter, Depends
from fastapi_core.dependencies import get_service_client, get_current_user

router = APIRouter()

@router.get("/me")
async def me(user=Depends(get_current_user)):
    return {"sub": user.sub}

get_sqlite = get_service_client("sqlite")
```

typed getter는 `get_keycloak_auth_service`, `get_postgres_engine`, `get_sqlite_engine`, `get_minio_client`, `get_milvus_client`, `get_ollama_client`, `get_langfuse_client`, `get_nats_connection_builder`다. 서비스가 비활성/미준비면 503, wrapper/client type이 예상과 다르면 500을 반환한다.

## 9. Schema와 HTTP response

| schema | 필드와 의미 |
| --- | --- |
| `HealthResponse` | `status`: `ok`, `degraded`, `error`; `details`: service별 `HealthServiceDetail` 또는 `None` |
| `HealthServiceDetail` | `ok`, `latency_ms`, `error`, `required`, `enabled` |
| `TokenResponse` | `access_token`, optional `refresh_token`, `token_type` 기본 `bearer` |
| `UserInfo` | `sub`, `username`, optional `email`/`name`, `roles`, `scopes` |
| `ProblemDetail` | `type`, `title`, `status`, `detail`, `instance`, `correlation_id` |

## 10. Streaming과 lifecycle

```python
from fastapi_core import ManagedStreamingResponse

async def stream_documents():
    yield b"document-1\n"
    yield b"document-2\n"

response = ManagedStreamingResponse(
    stream_documents(),
    resource=store,
    media_type="application/x-ndjson",
)
```

sync/async iterator와 기존 `StreamingResponse`의 status, headers, media type, background metadata를 보존한다. producer 정상 종료, producer exception, client disconnect 및 cancellation에서도 resource를 정확히 한 번 닫는다. sync close는 worker thread에서 실행한다.

`fastapi_core.runtime`의 advanced assembly API는 `build_runtime_plan(AppConfig)`, `assemble_runtime(RuntimePlan | None)`, `configure_service_runtime(FastAPI, ServiceRuntime)`이다. 이 함수들은 package-root 주 진입점이 아니라 명시적 runtime extension이며, app factory가 사용하는 동일한 `ServiceRuntime`/readiness ownership을 공유한다. `build_lifespan(...)`은 custom lifespan과 framework cleanup을 결합하는 low-level extension이다.

## 11. Consumer contract testing과 logging

```python
from fastapi_core.testing import (
    ApplicationContractProfile,
    assert_application_contract,
)

profile = ApplicationContractProfile(
    module_names=("documents",),
    expected_paths={"/documents": {"GET"}},
    expected_responses={("/documents", "GET"): (400, 500)},
    validation_status=400,
    include_synthetic_422=False,
)

assert_application_contract(app, profile)
```

`fastapi_core.testing`은 health/auth/module/OpenAPI의 의미 기반 contract assertion, `ResourceLifecycleProbe`, `create_empty_runtime`, 격리된 `test_environment`를 제공한다. 전체 OpenAPI JSON snapshot이 아니라 path/method/status/security scheme/operation ID/schema reference를 검증한다.

`log_function_boundary(event=None)`는 sync/async function의 start/end/error boundary를 기록하며, `configure_application_logging(AppConfig)`와 `JsonLogFormatter`는 application log 출력 계약을 담당한다. access log와 correlation ID middleware의 동작은 `create_app`가 설정 값에 따라 설치한다.

## 12. 공개 API 검증 규칙

문서를 갱신할 때 다음 source-derived 검사를 다시 실행한다.

```bash
uv run --frozen python -c 'import fastapi_core, fastapi_core.dependencies as d, fastapi_core.schemas as s; print(fastapi_core.__all__); print(d.__all__); print(s.__all__)'
uv run --frozen pytest -q test_fastapi_core/test_public_api.py test_fastapi_core/test_target_contracts.py
```

- package-root와 공개 submodule의 `__all__`에서 빠진 이름이 없어야 한다.
- re-export는 중복 ID를 만들지 않고 exact import path를 모두 남긴다.
- OpenAPI에서 built-in method/path가 빠지지 않아야 한다.
- 각 API ID가 example, representative test, config 또는 `설정 없음`으로 연결되어야 한다.
- 현재 구현에 없는 compatibility alias나 삭제된 `app.state` key는 public API로 문서화하지 않는다.
