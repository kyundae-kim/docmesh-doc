---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Examples-v0.6.0.md
ingested: 2026-07-26
sha256: f94a9d72e002c6365a4166cdf574cb9a0f72492a76eb02a57fcd56945bb7d484
---
# 공개 API 사용 예제

이 문서는 [API 레퍼런스](./api.md)의 안정적인 `API-*` ID를 실행 패턴 `EX-*`에 연결한다. 환경변수는 [config.md](./config.md)와 [`.env.example`](../.env.example)을 따른다.

## 예제 coverage

| 예제 ID | 다루는 API ID | 목적 |
| --- | --- | --- |
| `EX-APP-001` | `API-APP-001`, `API-ADV-002`, `API-HTTP-001`, `API-HTTP-002` | 외부 서비스 없는 앱과 실제 lifespan |
| `EX-CFG-001` | `API-CFG-001` | 환경 설정 로딩과 cache 격리 |
| `EX-DEP-001` | `API-DEP-001`, `API-DEP-002` | 설정/runtime/generic client 주입 |
| `EX-DEP-002` | `API-DEP-003` | 8개 typed service dependency |
| `EX-AUTH-001` | `API-AUTH-001`, `API-AUTH-002`, `API-SCHEMA-002`, `API-HTTP-003`, `API-HTTP-004` | auth route와 role/scope 인가 |
| `EX-RES-001` | `API-EXT-001`, `API-DEP-004` | typed managed resource lifecycle |
| `EX-READY-001` | `API-EXT-002` | 선택 readiness check 등록 |
| `EX-MOD-001` | `API-MOD-001` | domain module 단위 조립 |
| `EX-ERR-001` | `API-ERR-001`, `API-SCHEMA-003` | domain 오류 mapping/renderer |
| `EX-ROUTER-001` | `API-ROUTER-001`, `API-ROUTER-002` | router 객체 재사용 경계 |
| `EX-HTTP-001` | `API-SCHEMA-001`, `API-HTTP-001`, `API-HTTP-002` | health HTTP 계약 |
| `EX-ADV-001` | `API-ADV-001` | runtime plan과 prebuilt runtime 연결 |
| `EX-LOG-001` | `API-ADV-003` | JSON logging과 함수 경계 로그 |
| `EX-TEST-001` | `API-TEST-001` | 소비사 contract test |

## `EX-APP-001` — 서비스 없는 최소 앱

`main.py`:

```python
from fastapi_core import create_app
from fastapi_core.config import AppConfig

app = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
)
```

```bash
uv run fastapi dev main.py
curl -i http://127.0.0.1:8000/health/liveness
curl -i http://127.0.0.1:8000/health/readiness
```

기본 앱도 lifespan 진입 시 빈 `ServiceRuntime`을 생성하고 종료 시 닫는다. `/token`, `/user`는 auth router를 opt-in하기 전에는 404다.

사용자 lifespan을 결합할 수 있다. framework가 runtime/resource를 먼저 시작하고 사용자 lifespan을 실행하며, 종료 시 사용자 lifespan → resource → runtime 순서로 정리한다.

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi_core import create_app


@asynccontextmanager
async def lifespan(app: FastAPI):
    app.state.worker_ready = True
    yield
    app.state.worker_ready = False


app = create_app(lifespan=lifespan)
```

## `EX-CFG-001` — 환경 설정

실제 배포에서는 shell/container/platform이 `.env.example`의 값을 프로세스 환경에 주입해야 한다. 라이브러리는 `.env`를 자동 로드하지 않는다.

```python
from fastapi_core.config import load_app_config

config = load_app_config()
print(config.enabled_services, config.required_services)
```

테스트에서 환경을 바꾸면 제공 helper가 두 settings cache를 함께 격리한다.

```python
from fastapi_core.config import load_app_config
from fastapi_core.testing import test_environment

with test_environment(
    {
        "DOCMESH_SERVICES": "",
        "READINESS_REQUIRED_SERVICES": "",
        "CORS_ORIGINS": "https://api.example.com",
    }
):
    config = load_app_config()
    assert config.enabled_services == []
    assert config.cors_origins == ["https://api.example.com"]
```

## `EX-DEP-001` — 설정, runtime, generic client

```python
from typing import Annotated

from docmesh_py_core import ServiceConfigs, ServiceRuntime
from fastapi import APIRouter, Depends
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import (
    get_config,
    get_service_client,
    get_service_runtime,
    get_settings,
)

router = APIRouter()


@router.get("/runtime")
async def runtime_info(
    config: Annotated[AppConfig, Depends(get_config)],
    settings: Annotated[ServiceConfigs, Depends(get_settings)],
    runtime: Annotated[ServiceRuntime, Depends(get_service_runtime)],
) -> dict[str, object]:
    return {
        "enabled": config.enabled_services,
        "selected": sorted(service.value for service in runtime.selected_services),
        "environment": settings.common.env,
    }


sqlite_wrapper = get_service_client("sqlite")


@router.get("/sqlite-ready")
async def sqlite_ready(client=Depends(sqlite_wrapper)) -> dict[str, bool]:
    client.check()
    return {"ok": True}
```

Generic dependency는 DocMesh wrapper 또는 NATS builder를 반환한다. SDK 원객체가 필요하면 typed dependency를 사용한다.

## `EX-DEP-002` — typed service dependency

| 서비스 | dependency | 반환 타입 |
| --- | --- | --- |
| Keycloak | `get_keycloak_auth_service` | `KeycloakAuthService` |
| PostgreSQL | `get_postgres_engine` | `sqlalchemy.Engine` |
| SQLite | `get_sqlite_engine` | `sqlalchemy.Engine` |
| MinIO | `get_minio_client` | `Minio` |
| Milvus | `get_milvus_client` | `MilvusClient` |
| Ollama | `get_ollama_client` | `ollama.Client` |
| Langfuse | `get_langfuse_client` | `Langfuse` |
| NATS | `get_nats_connection_builder` | `NatsConnectionBuilder` |

```python
from typing import Annotated

from fastapi import APIRouter, Depends
from fastapi_core.dependencies import get_postgres_engine
from sqlalchemy import text
from sqlalchemy.engine import Engine

router = APIRouter()


@router.get("/database/ping")
def database_ping(
    engine: Annotated[Engine, Depends(get_postgres_engine)],
) -> dict[str, int]:
    with engine.connect() as connection:
        value = connection.execute(text("SELECT 1")).scalar_one()
    return {"value": value}
```

다른 typed dependency도 같은 `Depends(get_*_client)` 패턴을 사용한다. 서비스 미활성은 503, wrapper/원객체 타입 불일치는 500이다.

## `EX-AUTH-001` — 인증과 인가

Auth router는 Keycloak을 enabled/required로 선언해야 한다.

```python
from typing import Annotated

from docmesh_py_core import AuthenticatedUser
from fastapi import APIRouter, Depends
from fastapi_core import create_app
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import (
    get_current_user,
    require_permissions,
    require_roles,
    require_scopes,
)

router = APIRouter()


@router.get("/me")
async def me(
    user: Annotated[AuthenticatedUser, Depends(get_current_user)],
) -> dict[str, str]:
    return {"sub": user.sub}


@router.get("/admin")
async def admin(
    user: Annotated[AuthenticatedUser, Depends(require_roles("admin"))],
) -> dict[str, str]:
    return {"sub": user.sub}


@router.get("/documents")
async def documents(
    user: Annotated[
        AuthenticatedUser,
        Depends(require_scopes("documents:read")),
    ],
) -> dict[str, str]:
    return {"sub": user.sub}


@router.post("/documents")
async def create_document(
    user: Annotated[
        AuthenticatedUser,
        Depends(require_permissions("documents:write")),
    ],
) -> dict[str, str]:
    return {"sub": user.sub}


app = create_app(
    config=AppConfig(
        enabled_services=["keycloak"],
        required_services=["keycloak"],
    ),
    include_auth_router=True,
    routers=[router],
)
```

호출 예:

```bash
curl -X POST http://127.0.0.1:8000/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'username=alice&password=secret&scope=openid profile'
curl http://127.0.0.1:8000/user -H 'Authorization: Bearer <access-token>'
```

`get_auth_provider()`는 주입된 `app.state.auth_provider`를 우선하고, 없으면 runtime의 Keycloak wrapper를 해제해 cache한다.

## `EX-RES-001` — typed managed resource

```python
from dataclasses import dataclass
from typing import Annotated

from fastapi import APIRouter, Depends, FastAPI
from fastapi_core import ManagedResource, ResourceKey, create_app


@dataclass
class SearchClient:
    ready: bool = True

    async def aclose(self) -> None:
        self.ready = False


search = ResourceKey[SearchClient]("search")


async def create_search(_app: FastAPI) -> SearchClient:
    return SearchClient()


async def check_search(client: SearchClient) -> bool:
    return client.ready


router = APIRouter()


@router.get("/search/status")
async def search_status(
    client: Annotated[SearchClient, Depends(search.dependency)],
) -> dict[str, bool]:
    return {"ready": client.ready}


app = create_app(
    routers=[router],
    resources=[
        ManagedResource(
            search,
            factory=create_search,
            healthcheck=check_search,
            required=True,
            readiness_timeout_seconds=2,
        )
    ],
)
```

동적 문자열 dependency가 필요하면 `Depends(get_resource("search"))`를 사용할 수 있다.

## `EX-READY-001` — 독립 readiness check

```python
from fastapi_core import create_app, register_readiness_check

app = create_app()


async def optional_search_check() -> bool:
    return True


register_readiness_check(
    app,
    "search",
    optional_search_check,
    required=False,
    timeout_seconds=1,
    redact_errors=True,
)
```

선택 check만 실패하면 `/health/readiness`는 HTTP 200과 `degraded`를 반환한다. `redact_errors=False`는 내부 오류가 외부 응답에 노출될 수 있으므로 신뢰 경계 안에서만 사용한다.

## `EX-MOD-001` — domain module

```python
from fastapi import APIRouter
from fastapi_core import (
    DomainModule,
    ErrorMapperSpec,
    ErrorMapping,
    ReadinessCheckSpec,
    create_app,
)


class CatalogError(Exception):
    pass


router = APIRouter(prefix="/catalog")


@router.get("/items")
async def items() -> list[dict[str, str]]:
    return []


module = DomainModule(
    name="catalog",
    routers=[router],
    readiness_checks=[
        ReadinessCheckSpec("catalog-cache", lambda: True, required=False)
    ],
    error_mappers=[
        ErrorMapperSpec(
            CatalogError,
            lambda _request, exc: ErrorMapping(503, str(exc)),
        )
    ],
)

app = create_app(modules=[module])
```

module은 route, 공통 dependency, managed resource, readiness, error mapper를 하나의 충돌 검증 단위로 묶는다.

## `EX-ERR-001` — 오류 mapper와 renderer

기본 problem detail:

```python
from fastapi import Request
from fastapi_core import ErrorMapping, create_app, register_error_mapper


class DocumentNotFound(Exception):
    pass


app = create_app()


def map_not_found(_request: Request, exc: Exception) -> ErrorMapping:
    return ErrorMapping(
        status_code=404,
        title="Document not found",
        detail=str(exc),
        type_uri="https://errors.example/document-not-found",
    )


register_error_mapper(app, DocumentNotFound, map_not_found)
```

`code`와 `extensions`를 실제 응답에 쓰는 사용자 renderer:

```python
from fastapi import Request
from fastapi.responses import JSONResponse
from fastapi_core import ErrorMapping, create_app


def render_error(request: Request, mapping: ErrorMapping) -> JSONResponse:
    return JSONResponse(
        status_code=mapping.status_code,
        content={
            "code": mapping.code,
            "message": mapping.detail,
            "correlation_id": request.state.correlation_id,
            "metadata": mapping.extensions,
        },
    )


app = create_app(error_renderer=render_error)
```

## `EX-ROUTER-001` — 공개 router 객체

`create_app()`는 health router를 이미 포함하고 auth router를 `include_auth_router`로 제어하므로 같은 router를 `routers=`에 다시 넘기면 중복 route 오류다. 공개 router 객체는 별도 FastAPI 앱을 직접 조립해야 하는 고급 사용처에 제공한다.

```python
from fastapi import FastAPI
from fastapi_core.routers import health_router

app = FastAPI()
app.include_router(health_router)
```

`auth_router`는 `oauth2_scheme`, `get_auth_provider`, 표준 오류 처리 등 `create_app()`이 구성하는 경계에 의존한다. 가능하면 `create_app(include_auth_router=True)`를 사용한다.

## `EX-HTTP-001` — health 계약 확인

```bash
curl -sS http://127.0.0.1:8000/health/liveness
curl -sS http://127.0.0.1:8000/health/readiness
```

```json
{"status":"ok","details":null}
```

실패 detail 예:

```json
{
  "status": "error",
  "details": {
    "postgres": {
      "ok": false,
      "latency_ms": 10,
      "error": "readiness check failed",
      "required": true,
      "enabled": true
    }
  }
}
```

## `EX-ADV-001` — runtime plan과 주입

일반적으로 `create_app()`이 이 경로를 소유한다. 테스트나 상위 조립기가 이미 runtime을 소유한 경우에만 직접 사용한다.

```python
from fastapi_core import create_app
from fastapi_core.config import AppConfig
from fastapi_core.runtime import assemble_runtime, build_runtime_plan


async def build_app():
    config = AppConfig(
        enabled_services=["sqlite"],
        required_services=["sqlite"],
    )
    plan = build_runtime_plan(config)
    runtime = await assemble_runtime(plan)
    return create_app(config=config, runtime=runtime)
```

반환된 앱의 lifespan이 주입한 runtime을 닫으므로 호출자가 중복 종료하지 않는다. 기존 앱에 runtime을 후결합해야 하는 고급 경로는 `configure_service_runtime(app, runtime)`이며, readiness 이름 충돌과 check 부재를 원자적으로 검증한다.

## `EX-LOG-001` — application/function logging

```python
import logging

from fastapi_core.config import AppConfig
from fastapi_core.function_logging import log_function_boundary
from fastapi_core.logging import configure_application_logging

configure_application_logging(
    AppConfig(log_level="INFO", log_json=True, log_force=True)
)


@log_function_boundary("documents.load")
def load_document(document_id: str) -> str:
    logging.getLogger(__name__).info(
        "document_loaded",
        extra={"event": {"document_id": document_id}},
    )
    return document_id
```

`JsonLogFormatter`는 `configure_application_logging()`이 `log_json=True`일 때 handler에 자동 적용한다.

## `EX-TEST-001` — 소비사 contract test

```python
from fastapi.testclient import TestClient
from fastapi_core import create_app
from fastapi_core.testing import (
    ResourceLifecycleProbe,
    assert_auth_router_contract,
    assert_health_contract,
    assert_openapi_contract,
    create_empty_runtime,
)


def test_service_app_contract() -> None:
    probe = ResourceLifecycleProbe(value=object())
    app = create_app(
        runtime=create_empty_runtime(),
        resources=[probe.managed_resource("sdk")],
    )

    assert_openapi_contract(
        app,
        expected_paths={
            "/health/liveness": {"GET"},
            "/health/readiness": {"GET"},
        },
    )

    with TestClient(app) as client:
        assert_health_contract(client)
        assert_auth_router_contract(client, included=False)

    assert probe.events == ["create:sdk", "check:sdk", "close:sdk"]
```

Domain module 소비사는 `assert_module_contract(app, module)`로 설치를 검증할 수 있다.
