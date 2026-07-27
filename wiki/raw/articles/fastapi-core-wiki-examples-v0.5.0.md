---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Examples-v0.5.0.md
ingested: 2026-07-20
sha256: b66757d1ea565683008c2da5ca48dec653c0cea7624710137670ea2034b877b3
---
# fastapi-core Examples

> 문서 리비전: 2026-07-19
>
> 대상 릴리스: `fastapi-core 0.5.0`
>
> 상태: current-implementation
>
> 원칙: 예제 ID는 [API 추적성 매트릭스](api.md#2-전체-추적성-매트릭스)에서 참조하는 안정적인 식별자다.

---

## 1. 예제 실행 전제

저장소 checkout에서는 기존 환경을 사용해 다음과 같이 실행한다.

```bash
.venv/bin/python example.py
```

서비스 없는 예제는 외부 인프라가 필요 없다. Keycloak, PostgreSQL, MinIO 등 외부 서비스를 사용하는 예제는 [config.md](config.md)의 해당 서비스 설정을 프로세스 환경에 주입해야 한다. `.env.example`은 자동 로드되지 않는다.

## 2. 애플리케이션과 설정

<a id="ex-app-001"></a>
### `EX-APP-001` — 서비스 없는 최소 앱

```python
from fastapi_core import create_app
from fastapi_core.config import AppConfig

app = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
)
```

실행 후 확인:

```bash
.venv/bin/fastapi dev main.py
curl -i http://127.0.0.1:8000/health/liveness
curl -i http://127.0.0.1:8000/health/readiness
```

두 health endpoint는 외부 서비스 없이 `200`과 `status="ok"`를 반환한다.

<a id="ex-cfg-001"></a>
### `EX-CFG-001` — 직접 설정과 환경 설정

직접 생성한 `AppConfig`는 테스트와 명시적인 앱 조립에 적합하다.

```python
from fastapi_core import create_app
from fastapi_core.config import AppConfig

config = AppConfig(
    root_path="/api",
    cors_origins=["https://app.example.com"],
    enabled_services=["sqlite"],
    required_services=["sqlite"],
    startup_healthcheck=True,
)
app = create_app(config=config)
```

환경변수를 사용할 때는 loader cache를 고려한다.

```python
import os

from fastapi_core.config import load_app_config

os.environ["DOCMESH_SERVICES"] = ""
os.environ["READINESS_REQUIRED_SERVICES"] = ""
load_app_config.cache_clear()
config = load_app_config()
assert config.enabled_services == []
```

<a id="ex-cfg-002"></a>
### `EX-CFG-002` — 선택한 DocMesh 서비스 설정 읽기

```python
from fastapi_core.docmesh_settings import load_docmesh_settings

load_docmesh_settings.cache_clear()
settings = load_docmesh_settings(("sqlite",))
assert settings.sqlite is not None
assert settings.keycloak is None
```

`load_docmesh_settings(())`는 모든 서비스 설정이 `None`인 명시적 빈 선택이다. `None`은 DocMesh loader의 기본 서비스 선택을 사용한다.

## 3. Dependency

<a id="ex-dep-001"></a>
### `EX-DEP-001` — 앱 설정, 서비스 설정, runtime 주입

```python
from fastapi import Depends, FastAPI
from docmesh_py_core import ServiceConfigs, ServiceRuntime

from fastapi_core import create_app
from fastapi_core.config import AppConfig
from fastapi_core.dependencies import get_config, get_service_runtime, get_settings
from fastapi_core.testing import create_empty_runtime

app: FastAPI = create_app(
    config=AppConfig(enabled_services=[], required_services=[]),
    runtime=create_empty_runtime(),
)

@app.get("/runtime-info")
async def runtime_info(
    config: AppConfig = Depends(get_config),
    settings: ServiceConfigs = Depends(get_settings),
    runtime: ServiceRuntime = Depends(get_service_runtime),
) -> dict[str, object]:
    return {
        "root_path": config.root_path,
        "selected_services": sorted(str(item) for item in runtime.selected_services),
        "has_common_settings": settings.common is not None,
    }
```

<a id="ex-dep-002"></a>
### `EX-DEP-002` — 이름 기반 service client

`get_service_client(name)`은 DocMesh wrapper 자체가 필요한 고급 사용 경로다. 일반 route에서는 다음 절의 typed dependency를 우선한다.

```python
from fastapi import Depends
from docmesh_py_core import ServiceClientWrapper

from fastapi_core.dependencies import get_service_client

@app.get("/raw-postgres")
async def raw_postgres(
    wrapper: ServiceClientWrapper = Depends(get_service_client("postgres")),
) -> dict[str, str]:
    return {"wrapper_type": type(wrapper).__name__}
```

서비스가 활성화되지 않았으면 이 dependency는 `503`을 반환한다.

<a id="ex-dep-003"></a>
### `EX-DEP-003` — typed service client

```python
from fastapi import Depends
from sqlalchemy.engine import Engine

from fastapi_core.dependencies import get_postgres_engine

@app.get("/database-dialect")
async def database_dialect(
    engine: Engine = Depends(get_postgres_engine),
) -> dict[str, str]:
    return {"dialect": engine.dialect.name}
```

동일 패턴으로 아래 dependency를 사용한다.

| 서비스 | Dependency | 반환 객체 |
|---|---|---|
| Keycloak | `get_keycloak_auth_service` | `KeycloakAuthService` |
| PostgreSQL | `get_postgres_engine` | SQLAlchemy `Engine` |
| SQLite | `get_sqlite_engine` | SQLAlchemy `Engine` |
| MinIO | `get_minio_client` | `Minio` |
| Milvus | `get_milvus_client` | `MilvusClient` |
| Ollama | `get_ollama_client` | Ollama `Client` |
| Langfuse | `get_langfuse_client` | `Langfuse` |
| NATS | `get_nats_connection_builder` | `NatsConnectionBuilder` |

```python
from fastapi_core.dependencies import (
    get_keycloak_auth_service,
    get_langfuse_client,
    get_milvus_client,
    get_minio_client,
    get_nats_connection_builder,
    get_ollama_client,
    get_postgres_engine,
    get_sqlite_engine,
)
```

## 4. 인증과 인가

<a id="ex-auth-001"></a>
### `EX-AUTH-001` — 현재 사용자, role, scope, permission

```python
from fastapi import Depends
from docmesh_py_core import AuthenticatedUser

from fastapi_core.dependencies import (
    get_auth_provider,
    get_current_user,
    require_permissions,
    require_roles,
    require_scopes,
)

@app.get("/me")
async def me(
    user: AuthenticatedUser = Depends(get_current_user),
) -> dict[str, str]:
    return {"sub": user.sub}

@app.get("/admin")
async def admin(
    user: AuthenticatedUser = Depends(require_roles("admin")),
) -> dict[str, str]:
    return {"sub": user.sub}

@app.get("/documents")
async def documents(
    user: AuthenticatedUser = Depends(require_scopes("documents:read")),
) -> dict[str, str]:
    return {"sub": user.sub}

@app.delete("/documents/{document_id}")
async def delete_document(
    document_id: str,
    user: AuthenticatedUser = Depends(
        require_permissions("documents:delete")
    ),
) -> dict[str, str]:
    return {"document_id": document_id, "deleted_by": user.sub}
```

`get_auth_provider`는 보통 직접 주입할 필요가 없으며 `get_current_user`와 내장 auth router가 내부에서 사용한다. 앱 생성 시 `include_auth_router=True`이고 `keycloak` 서비스가 활성화되어야 내장 `/token`, `/user`를 정상 사용할 수 있다.

## 5. Managed resource와 readiness

<a id="ex-res-001"></a>
### `EX-RES-001` — typed managed resource

```python
from dataclasses import dataclass

from fastapi import Depends, FastAPI

from fastapi_core import ManagedResource, ResourceKey, create_app
from fastapi_core.dependencies import get_resource
from fastapi_core.testing import create_empty_runtime

@dataclass
class SearchClient:
    ready: bool = True

    async def aclose(self) -> None:
        self.ready = False

search_key = ResourceKey[SearchClient]("search")

async def create_search(_app: FastAPI) -> SearchClient:
    return SearchClient()

async def check_search(client: SearchClient) -> bool:
    return client.ready

app = create_app(
    runtime=create_empty_runtime(),
    resources=[
        ManagedResource(
            name=search_key,
            factory=create_search,
            healthcheck=check_search,
            required=True,
            readiness_timeout_seconds=1.0,
        )
    ],
)

@app.get("/search-status")
async def search_status(
    client: SearchClient = Depends(search_key.dependency),
) -> dict[str, bool]:
    return {"ready": client.ready}

@app.get("/search-status-untyped")
async def search_status_untyped(
    client: SearchClient = Depends(get_resource("search")),
) -> dict[str, bool]:
    return {"ready": client.ready}
```

framework는 lifespan 진입 시 자원을 만들고, readiness에 healthcheck를 연결하며, 종료 시 역순으로 닫는다.

<a id="ex-ready-001"></a>
### `EX-READY-001` — 사용자 정의 readiness check

```python
from fastapi_core import ReadinessCheckSpec, register_readiness_check
from fastapi_core.readiness import Check

async def search_ready() -> bool:
    return True

check: Check = search_ready
spec = ReadinessCheckSpec(
    name="search",
    check=check,
    required=False,
    timeout_seconds=0.5,
    redact_errors=True,
)

register_readiness_check(
    app,
    spec.name,
    spec.check,
    required=spec.required,
    timeout_seconds=spec.timeout_seconds,
    redact_errors=spec.redact_errors,
)
```

중복 이름, 빈 이름, 0 이하 timeout은 `ValueError`다.

## 6. 오류 응답

<a id="ex-err-001"></a>
### `EX-ERR-001` — domain 예외 매핑

```python
from fastapi import Request

from fastapi_core import ErrorMapping, register_error_mapper

class DocumentNotFound(Exception):
    pass


def map_document_error(
    _request: Request,
    exc: Exception,
) -> ErrorMapping:
    return ErrorMapping(
        status_code=404,
        title="Document not found",
        detail=str(exc),
        type_uri="https://errors.example/document-not-found",
        code="DOCUMENT_NOT_FOUND",
        extensions={"resource": "document"},
    )

register_error_mapper(app, DocumentNotFound, map_document_error)

@app.get("/documents/{document_id}")
async def read_document(document_id: str) -> dict[str, str]:
    raise DocumentNotFound(document_id)
```

mapper는 `async def`도 가능하다. `detail`은 응답 renderer에 전달되기 전에 민감 정보 마스킹을 거친다.

<a id="ex-err-002"></a>
### `EX-ERR-002` — custom 오류 renderer

```python
from fastapi import Request
from fastapi.responses import JSONResponse, Response

from fastapi_core import ErrorMapping, ErrorRenderer, create_app
from fastapi_core.testing import create_empty_runtime


def render_error(request: Request, mapping: ErrorMapping) -> Response:
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
    runtime=create_empty_runtime(),
    error_renderer=renderer,
)
```

## 7. Schema와 router

<a id="ex-schema-001"></a>
### `EX-SCHEMA-001` — 공개 schema 생성

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
            error="readiness check failed",
            required=False,
        )
    },
)
problem = ProblemDetail(
    title="Not Found",
    status=404,
    detail="Document not found",
    instance="/documents/42",
    correlation_id="request-42",
)
token = TokenResponse(access_token="example-token")
user = UserInfo(sub="42", username="reader", roles=["reader"])
```

<a id="ex-router-001"></a>
### `EX-ROUTER-001` — 공개 router 확인과 조립 경계

```python
from fastapi_core.routers import auth_router, health_router

health_paths = {route.path for route in health_router.routes}
auth_paths = {route.path for route in auth_router.routes}

assert health_paths == {"/health/liveness", "/health/readiness"}
assert auth_paths == {"/token", "/user"}
```

일반 애플리케이션은 router를 직접 mount하지 않고 `create_app(include_auth_router=...)`를 사용한다. 직접 mount하면 `app.state.config`, readiness registry, OAuth2 scheme, error handler와 service runtime을 소비 애플리케이션이 모두 구성해야 한다.

## 8. HTTP 호출

<a id="ex-http-001"></a>
### `EX-HTTP-001` — liveness와 readiness

```bash
curl -sS http://127.0.0.1:8000/health/liveness
curl -sS http://127.0.0.1:8000/health/readiness
```

정상 기본 응답:

```json
{"status":"ok","details":null}
```

<a id="ex-http-002"></a>
### `EX-HTTP-002` — token과 사용자 정보

```bash
TOKEN_RESPONSE="$(curl -sS -X POST http://127.0.0.1:8000/token \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'username=reader' \
  --data-urlencode 'password=example-password' \
  --data-urlencode 'scope=openid profile')"

ACCESS_TOKEN="$(printf '%s' "$TOKEN_RESPONSE" | jq -r .access_token)"
curl -sS http://127.0.0.1:8000/user \
  -H "Authorization: Bearer $ACCESS_TOKEN"
```

실제 password와 token을 명령 기록이나 문서에 저장하지 않는다.

## 9. 고급 조립 API

<a id="ex-adv-001"></a>
### `EX-ADV-001` — registry 직접 사용

```python
from fastapi_core.extensions import (
    ReadinessCheckSpec,
    ReadinessRegistry,
    ResourceRegistry,
)

async def run_checks() -> None:
    readiness = ReadinessRegistry(default_timeout_seconds=1.0)
    readiness.register(
        ReadinessCheckSpec(name="cache", check=lambda: True, required=False)
    )
    resources = ResourceRegistry((), readiness)

    result = await readiness.check(parallel=True)
    assert result.ok is True
    try:
        resources.require("missing")
    except KeyError:
        pass  # registry의 저수준 계약: 없는 이름은 KeyError
```

`ReadinessRegistry`와 `ResourceRegistry`는 고급 조립용이다. 일반 route에서는 `register_readiness_check`, `ManagedResource`, `ResourceKey`를 사용한다.

<a id="ex-adv-002"></a>
### `EX-ADV-002` — runtime plan과 연결

```python
from fastapi import FastAPI

from fastapi_core.config import AppConfig
from fastapi_core.readiness import ReadinessRegistry
from fastapi_core.runtime import (
    assemble_runtime,
    build_runtime_plan,
    configure_service_runtime,
)

async def assemble_for_custom_host() -> FastAPI:
    config = AppConfig(enabled_services=[], required_services=[])
    plan = build_runtime_plan(config)
    runtime = await assemble_runtime(plan)

    app = FastAPI()
    app.state.readiness_registry = ReadinessRegistry()
    configure_service_runtime(app, runtime)
    return app
```

이 저수준 예제는 middleware, router, 오류 처리와 runtime 종료를 구성하지 않는다. 실제 서비스 앱에서는 `create_app(config=config)`가 동일 기능과 lifecycle을 완전하게 조립한다.

<a id="ex-log-001"></a>
### `EX-LOG-001` — logging 초기화

```python
import logging

from fastapi_core.config import AppConfig
from fastapi_core.logging import JsonLogFormatter, configure_application_logging

config = AppConfig(log_level="INFO", log_json=True)
root_logger = configure_application_logging(config)
formatter = JsonLogFormatter()
record = logging.LogRecord("example", logging.INFO, __file__, 1, "ready", (), None)
assert '"message": "ready"' in formatter.format(record)
```

`create_app`은 이 초기화를 자동으로 수행한다.

## 10. 소비사 contract test

<a id="ex-test-001"></a>
### `EX-TEST-001` — 실제 lifespan 검증

```python
from fastapi.testclient import TestClient

from fastapi_core import create_app
from fastapi_core.testing import (
    ResourceLifecycleProbe,
    assert_auth_router_contract,
    assert_health_contract,
    create_empty_runtime,
)


def test_fastapi_core_contract() -> None:
    probe = ResourceLifecycleProbe(value=object())
    app = create_app(
        runtime=create_empty_runtime(),
        resources=[probe.managed_resource("sdk")],
        include_auth_router=False,
    )

    with TestClient(app) as client:
        assert_health_contract(client)
        assert_auth_router_contract(client, included=False)
        assert probe.events == ["create:sdk", "check:sdk"]

    assert probe.events == ["create:sdk", "check:sdk", "close:sdk"]
```

## 11. 예제 커버리지

| API 분류 | 예제 ID |
|---|---|
| 앱 factory | `EX-APP-001` |
| 앱/DocMesh 설정 | `EX-CFG-001`, `EX-CFG-002` |
| 공통·이름 기반·typed dependency | `EX-DEP-001`, `EX-DEP-002`, `EX-DEP-003` |
| 인증·인가 dependency | `EX-AUTH-001` |
| managed resource | `EX-RES-001` |
| readiness | `EX-READY-001` |
| 오류 mapper/renderer | `EX-ERR-001`, `EX-ERR-002` |
| schema/router | `EX-SCHEMA-001`, `EX-ROUTER-001` |
| 내장 HTTP route | `EX-HTTP-001`, `EX-HTTP-002` |
| 고급 registry/runtime/logging | `EX-ADV-001`, `EX-ADV-002`, `EX-LOG-001` |
| 테스트 지원 | `EX-TEST-001` |
