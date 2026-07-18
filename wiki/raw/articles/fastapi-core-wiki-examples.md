---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Examples.md
ingested: 2026-07-18
sha256: 34f12a1db95df8ac04efd82a33fd79ce13f819151399a90fa6ee8ef315331887
---
# fastapi-core Examples

> 기준 버전: `fastapi-core 0.3.0`  
> 각 예제 ID는 [`api.md`](api.md)의 공개 API 추적표에서 참조한다.  
> 외부 서비스 예제는 해당 환경변수와 실제 서비스가 준비되어 있어야 한다.

## EX-001. 서비스 없는 최소 앱과 설정 dependency

대상: `create_app`, `AppConfig`, `load_app_config`, `get_config`

```python
# main.py
from fastapi import Depends

from fastapi_core import create_app
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import get_config

config = AppConfig(
    enabled_services=[],
    required_services=[],
    cors_origins=["http://localhost:3000"],
)
app = create_app(config=config, include_auth_router=False)


@app.get("/config")
async def read_config(current: AppConfig = Depends(get_config)) -> dict[str, object]:
    return {
        "root_path": current.root_path,
        "enabled_services": current.enabled_services,
    }
```

실행:

```bash
uv run fastapi dev main.py
curl -i http://127.0.0.1:8000/health/liveness
curl -i http://127.0.0.1:8000/config
```

환경 기반 설정을 사용할 때는 직접 `AppConfig`를 넘기지 않는다.

```python
from fastapi_core import create_app
from fastapi_core.config import load_app_config

config = load_app_config()  # process environment를 읽고 결과를 cache
app = create_app(config=config)
```

`load_app_config.cache_clear()`는 한 process 안에서 환경을 바꾸는 테스트에서만 주로 사용한다.

## EX-002. 현재 사용자와 role/scope/permission 보호

대상: `get_auth_provider`, `get_current_user`, `require_roles`, `require_scopes`, `require_permissions`, `UserInfo`

```python
from docmesh_py_core import AuthenticatedUser
from fastapi import Depends

from fastapi_core import create_app
from fastapi_core.dependencies import (
    get_current_user,
    require_permissions,
    require_roles,
    require_scopes,
)

app = create_app()


@app.get("/me")
async def me(user: AuthenticatedUser = Depends(get_current_user)) -> dict[str, str]:
    return {"sub": user.sub}


@app.get("/admin")
async def admin(
    user: AuthenticatedUser = Depends(require_roles("admin")),
) -> dict[str, str]:
    return {"sub": user.sub}


@app.get("/profile")
async def profile(
    user: AuthenticatedUser = Depends(require_scopes("openid", "profile")),
) -> dict[str, str]:
    return {"sub": user.sub}


@app.post("/documents")
async def create_document(
    user: AuthenticatedUser = Depends(require_permissions("document:write")),
) -> dict[str, str]:
    return {"created_by": user.sub}
```

`require_permissions`는 role과 scope를 합쳐 검사한다. 여러 인자를 전달하면 모두 필요하다. `get_auth_provider`는 보통 직접 주입하지 않고 `get_current_user`를 통해 사용하지만, provider 자체가 필요한 route에서는 다음처럼 쓸 수 있다.

```python
from docmesh_py_core import KeycloakAuthService
from fastapi import Depends
from fastapi_core.dependencies import get_auth_provider


@app.get("/auth-provider")
async def provider_type(
    provider: KeycloakAuthService = Depends(get_auth_provider),
) -> dict[str, str]:
    return {"type": type(provider).__name__}
```

## EX-003. Runtime, 설정 및 서비스 client dependency

대상: 모든 `get_*_client`, engine/builder getter, `get_service_client`, `get_service_runtime`, `get_settings`

```python
from docmesh_py_core import KeycloakAuthService, NatsConnectionBuilder, ServiceConfigs, ServiceRuntime
from fastapi import Depends
from langfuse import Langfuse
from minio import Minio
from ollama import Client as OllamaClient
from pymilvus import MilvusClient
from sqlalchemy.engine import Engine

from fastapi_core import create_app
from fastapi_core.dependencies import (
    get_keycloak_auth_service,
    get_langfuse_client,
    get_milvus_client,
    get_minio_client,
    get_nats_connection_builder,
    get_ollama_client,
    get_postgres_engine,
    get_service_client,
    get_service_runtime,
    get_settings,
    get_sqlite_engine,
)

app = create_app(include_auth_router=False)


@app.get("/runtime")
async def runtime_info(
    runtime: ServiceRuntime = Depends(get_service_runtime),
    settings: ServiceConfigs = Depends(get_settings),
) -> dict[str, object]:
    return {
        "selected": sorted(service.value for service in runtime.selected_services),
        "environment": settings.common.env,
    }


@app.get("/generic-sqlite")
async def generic_sqlite(wrapper=Depends(get_service_client("sqlite"))) -> dict[str, str]:
    # Generic dependency는 DocMesh wrapper/builder를 그대로 반환한다.
    return {"wrapper_type": type(wrapper).__name__}


@app.get("/typed-clients")
async def typed_clients(
    keycloak: KeycloakAuthService = Depends(get_keycloak_auth_service),
    postgres: Engine = Depends(get_postgres_engine),
    sqlite: Engine = Depends(get_sqlite_engine),
    minio: Minio = Depends(get_minio_client),
    milvus: MilvusClient = Depends(get_milvus_client),
    ollama: OllamaClient = Depends(get_ollama_client),
    langfuse: Langfuse = Depends(get_langfuse_client),
    nats: NatsConnectionBuilder = Depends(get_nats_connection_builder),
) -> dict[str, str]:
    return {
        "keycloak": type(keycloak).__name__,
        "postgres": type(postgres).__name__,
        "sqlite": type(sqlite).__name__,
        "minio": type(minio).__name__,
        "milvus": type(milvus).__name__,
        "ollama": type(ollama).__name__,
        "langfuse": type(langfuse).__name__,
        "nats": type(nats).__name__,
    }
```

위 endpoint를 실제 호출하려면 `DOCMESH_SERVICES`에 모든 서비스를 넣고 [`config.md`](config.md)의 필수 환경변수를 제공해야 한다. 일부 서비스만 활성화한 앱에서는 해당 typed dependency만 사용한다. 미활성 서비스는 503을 반환한다.

## EX-004. Custom readiness check

대상: `Check`, `ReadinessCheckSpec`, `ReadinessRegistry`, `register_readiness_check`

권장 등록 방식:

```python
from fastapi_core import create_app, register_readiness_check
from fastapi_core.config import AppConfig
from fastapi_core.extensions import Check

app = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
)


def search_check() -> bool:
    return True


check: Check = search_check
register_readiness_check(
    app,
    "search",
    check,
    required=False,
    timeout_seconds=1.0,
    redact_errors=True,
)
```

고급 registry 방식:

```python
from fastapi_core import ReadinessCheckSpec
from fastapi_core.extensions import ReadinessRegistry

registry = ReadinessRegistry(default_timeout_seconds=2.0)
registry.register(
    ReadinessCheckSpec(
        name="cache",
        check=lambda: True,
        required=True,
    )
)

# lifespan 안의 async code에서:
# result = await registry.check(parallel=True, overall_timeout_seconds=5.0)
registry.unregister("cache")
```

실패 확인:

```bash
curl -i http://127.0.0.1:8000/health/readiness
```

optional check만 실패하면 HTTP 200/`degraded`, required check가 실패하면 HTTP 503/`error`다.

## EX-005. Managed resource와 타입 있는 dependency

대상: `ManagedResource`, `ResourceKey`, `ResourceRegistry`, `get_resource`

```python
from fastapi import Depends, FastAPI

from fastapi_core import ManagedResource, ResourceKey, create_app
from fastapi_core.dependencies import get_resource


class SearchSdk:
    def __init__(self) -> None:
        self.ready = True

    async def aclose(self) -> None:
        self.ready = False


async def create_search_sdk(_app: FastAPI) -> SearchSdk:
    return SearchSdk()


async def check_search_sdk(sdk: SearchSdk) -> bool:
    return sdk.ready


search_sdk = ResourceKey[SearchSdk]("search_sdk")
app = create_app(
    resources=[
        ManagedResource(
            search_sdk,
            factory=create_search_sdk,
            healthcheck=check_search_sdk,
            required=True,
            readiness_timeout_seconds=2.0,
        )
    ],
    include_auth_router=False,
)


@app.get("/search")
async def search(sdk: SearchSdk = Depends(search_sdk.dependency)) -> dict[str, bool]:
    return {"ready": sdk.ready}


@app.get("/search-untyped")
async def search_untyped(sdk=Depends(get_resource("search_sdk"))) -> dict[str, bool]:
    return {"ready": sdk.ready}
```

`ResourceRegistry`는 `app.state.resource_registry`에서 추적할 수 있다. 직접 생성·종료를 제어하는 고급 코드의 메서드 순서는 다음과 같다.

```python
from fastapi_core.extensions import ReadinessRegistry, ResourceRegistry

readiness = ReadinessRegistry()
registry = ResourceRegistry(
    [ManagedResource("search_sdk", factory=create_search_sdk)],
    readiness,
)

# await registry.start(app)
# instance = registry.require("search_sdk")
# await registry.check_startup(parallel=False, overall_timeout_seconds=None)
# await registry.close()
```

일반 애플리케이션에서는 이 호출을 `create_app()` lifespan에 맡긴다.

## EX-006. 도메인 오류 mapper와 custom renderer

대상: `ErrorMapping`, `ErrorRenderer`, `register_error_mapper`, `ProblemDetail`

기본 problem envelope 유지:

```python
from fastapi import Request

from fastapi_core import ErrorMapping, create_app, register_error_mapper
from fastapi_core.config import AppConfig


class DocumentNotFound(Exception):
    pass


app = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
)


def map_document_not_found(
    _request: Request,
    exc: Exception,
) -> ErrorMapping:
    return ErrorMapping(
        status_code=404,
        title="Document not found",
        detail=str(exc),
        type_uri="https://errors.example/document-not-found",
    )


register_error_mapper(app, DocumentNotFound, map_document_not_found)
```

custom envelope 사용:

```python
from fastapi import Request
from fastapi.responses import JSONResponse

from fastapi_core import ErrorMapping, ErrorRenderer, create_app, register_error_mapper
from fastapi_core.config import AppConfig


def render_error(request: Request, mapping: ErrorMapping) -> JSONResponse:
    return JSONResponse(
        status_code=mapping.status_code,
        content={
            "error": {
                "code": mapping.code,
                "message": mapping.detail,
                "correlation_id": request.state.correlation_id,
                "metadata": mapping.extensions,
            }
        },
    )


renderer: ErrorRenderer = render_error
app = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
    error_renderer=renderer,
)
register_error_mapper(
    app,
    DocumentNotFound,
    lambda _request, exc: ErrorMapping(
        status_code=404,
        detail=str(exc),
        code="DOCUMENT_NOT_FOUND",
        extensions={"resource": "document"},
    ),
)
```

mapper와 renderer는 `async def`도 허용한다. renderer가 받는 `mapping.detail`은 이미 민감값 마스킹이 적용된 값이다.

## EX-007. 사용자 lifespan 결합과 고급 `build_lifespan`

대상: `create_app(lifespan=...)`, `lifecycle.build_lifespan`

권장 방식:

```python
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi_core import create_app


@asynccontextmanager
async def service_lifespan(app: FastAPI):
    app.state.domain_ready = True
    yield
    app.state.domain_ready = False


app = create_app(lifespan=service_lifespan)
```

framework는 사용자 lifespan 바깥에서 runtime과 managed resource를 소유하므로 사용자 shutdown 실패 시에도 공통 정리를 시도한다.

고급 직접 조립:

```python
from fastapi import FastAPI
from fastapi_core.config import AppConfig
from fastapi_core.extensions import ReadinessRegistry, ResourceRegistry
from fastapi_core.lifecycle import build_lifespan

config = AppConfig(enabled_services=[], required_services=[])
readiness = ReadinessRegistry()
resources = ResourceRegistry([], readiness)
managed_lifespan = build_lifespan(None, config, None, resources)
app = FastAPI(lifespan=managed_lifespan)
app.state.readiness_registry = readiness
```

직접 조립할 때는 `create_app()`이 자동 설치하는 router, middleware, error handler, state를 직접 구성해야 한다.

## EX-008. Runtime plan, 조립 및 연결

대상: `build_runtime_plan`, `assemble_runtime`, `configure_service_runtime`

```python
from fastapi import FastAPI

from fastapi_core.config import AppConfig
from fastapi_core.extensions import ReadinessRegistry
from fastapi_core.runtime import (
    assemble_runtime,
    build_runtime_plan,
    configure_service_runtime,
)

config = AppConfig(
    enabled_services=["sqlite", "postgres"],
    required_services=["sqlite"],
    service_alternatives=[["sqlite", "postgres"]],
)
plan = build_runtime_plan(config)


async def build_raw_app() -> FastAPI:
    runtime = await assemble_runtime(config)
    app = FastAPI()
    app.state.readiness_registry = ReadinessRegistry(
        default_timeout_seconds=config.readiness_timeout_seconds
    )
    configure_service_runtime(app, runtime)
    return app
```

일반 서비스는 위 함수를 직접 호출하지 않고 `create_app(config)`에 맡긴다. 주입된 runtime의 종료 소유권도 `create_app()` lifespan으로 넘어간다.

## EX-009. Logging API

대상: `JsonLogFormatter`, `configure_application_logging`

```python
import logging

from fastapi_core.config import AppConfig
from fastapi_core.logging import JsonLogFormatter, configure_application_logging

config = AppConfig(
    enabled_services=[],
    required_services=[],
    log_level="INFO",
    log_json=True,
)
root_logger = configure_application_logging(config)
root_logger.info("application_started", extra={"event": {"outcome": "ok"}})

# 개별 handler에 직접 적용하는 경우
handler = logging.StreamHandler()
handler.setFormatter(JsonLogFormatter())
```

`create_app()`은 `configure_application_logging()`을 자동 호출한다.

## EX-010. 공개 schema 생성

대상: 모든 `fastapi_core.schemas` export

```python
from fastapi_core.schemas import (
    HealthResponse,
    HealthServiceDetail,
    ProblemDetail,
    TokenResponse,
    UserInfo,
)

health = HealthResponse(
    status="degraded",
    details={
        "search": HealthServiceDetail(
            ok=False,
            required=False,
            error="readiness check failed",
        )
    },
)
problem = ProblemDetail(
    title="Not Found",
    status=404,
    detail="Document not found",
    instance="/documents/42",
    correlation_id="request-123",
)
token = TokenResponse(access_token="example-token")
user = UserInfo(sub="user-1", username="alice", roles=["reader"])
```

## EX-011. 내장 HTTP API 호출

대상: liveness, readiness, token, user, correlation ID

```bash
# 항상 포함
curl -i http://127.0.0.1:8000/health/liveness
curl -i http://127.0.0.1:8000/health/readiness

# include_auth_router=true일 때 포함
curl -i \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'username=alice' \
  --data-urlencode 'password=example-password' \
  --data-urlencode 'scope=openid profile' \
  http://127.0.0.1:8000/token

curl -i \
  -H 'Authorization: Bearer example-access-token' \
  -H 'X-Correlation-ID: request-123' \
  http://127.0.0.1:8000/user
```

실제 secret을 shell history나 저장소에 남기지 않는다. 운영에서는 secret manager 또는 안전한 process environment 주입을 사용한다.

## EX-012. DocMesh 설정 loader 경계

대상: `build_docmesh_env_overlay`, `load_docmesh_settings`

```python
from fastapi_core.docmesh_settings import (
    build_docmesh_env_overlay,
    load_docmesh_settings,
)

# 현재 process environment의 복사본이며 입력 environment를 변경하지 않는다.
env = build_docmesh_env_overlay()

# 지정한 서비스 설정만 로드한다.
settings = load_docmesh_settings(("sqlite", "nats"))
assert settings.sqlite is not None
assert settings.nats is not None
assert settings.keycloak is None

# 명시적 빈 tuple은 서비스 설정을 하나도 로드하지 않는다.
empty_settings = load_docmesh_settings(())
```

이 loader도 cache되므로 테스트에서 환경을 변경했다면 `load_docmesh_settings.cache_clear()`를 호출한다. 실제 앱 startup은 같은 환경 경계를 통해 DocMesh runtime을 조립한다.

## EX-013. 공개 router 직접 포함

대상: `auth_router`, `health_router`

```python
from fastapi import FastAPI

from fastapi_core.routers import auth_router, health_router

app = FastAPI()
app.include_router(health_router)
app.include_router(auth_router)
```

이 예제는 router export 자체를 보여 주는 최소 조립이다. 인증 provider, runtime state, readiness registry, OAuth2 앱별 설정, correlation ID 및 공통 오류 handler는 별도로 구성되지 않는다. 실제 서비스에서는 다음을 우선한다.

```python
from fastapi_core import create_app

app = create_app()
```

## 예제-API 커버리지 요약

| 예제 | 커버하는 공개 API 영역 |
|---|---|
| EX-001 | 앱 factory, `AppConfig`, config loader/dependency |
| EX-002 | 인증·인가 dependency, 사용자 경계 타입 |
| EX-003 | runtime/config/service dependency 전체 |
| EX-004 | readiness callable/spec/registry/등록 함수 |
| EX-005 | managed resource/key/registry/resource dependency |
| EX-006 | error mapping/renderer/mapper/problem schema |
| EX-007 | 사용자 lifespan과 고급 lifespan builder |
| EX-008 | runtime plan/assembly/configuration |
| EX-009 | logging formatter/configuration |
| EX-010 | 공개 Pydantic schema 전체 |
| EX-011 | 내장 HTTP API 전체와 correlation ID |
| EX-012 | DocMesh 설정 loader 경계 |
| EX-013 | 공개 auth/health router 직접 조립 경계 |

## 검증 명령

```bash
# 공개 export와 signature
uv run pytest test_fastapi_core/test_public_api.py -q

# 예제의 근거가 되는 주요 회귀 테스트
uv run pytest \
  test_fastapi_core/test_factory.py \
  test_fastapi_core/test_dependencies.py \
  test_fastapi_core/test_extensions.py \
  test_fastapi_core/test_http.py \
  -q
```
