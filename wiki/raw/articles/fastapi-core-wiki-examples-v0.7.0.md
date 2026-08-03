---
source_url: https://raw.githubusercontent.com/wiki/kyundae-kim/fastapi-core/Examples-v0.7.0.md
ingested: 2026-08-02
sha256: 235427059b0b62926c2e00ef34e37c57d1ea6bcb2a042e3f946cbaf66715089c
---
# fastapi-core 소비자 예제

> 기준 릴리스: `fastapi-core 0.7.0`

이 페이지는 `docs/examples.md`를 Git wiki용으로 캡처하고, 각 예제에 안정적인 `EX-*` ID를 부여해 [공개 API 추적표](API-Reference-v0.7.0.md#2-전체-공개-api-추적표)와 [설정 추적표](Configuration-v0.7.0.md#10-api-example-config-추적표)를 연결한다. 예제는 네트워크 서비스가 없어도 구조를 확인할 수 있는 형태를 우선하며, 실제 runtime/service 연결은 설정 문서의 선택 서비스 계약을 함께 읽어야 한다.

- API 계약: [fastapi-core API](API-Reference-v0.7.0.md)
- 설정 계약: [fastapi-core config](Configuration-v0.7.0.md)
- 저장소 원문: `docs/examples.md`

## 0. Example coverage registry

| Example ID | 패턴 | 연결 API ID | 설정 anchor | 검증 근거 |
| --- | --- | --- | --- | --- |
| `EX-APP-001` | 서비스 없는 최소 앱과 health | `API-APP-001`, `API-CFG-001`, `API-DEP-002`, `API-HTTP-ROUTE-001` | `CFG-APP-001` | `test_factory.py`, `test_health_router.py` |
| `EX-APP-002` | auth opt-in, bearer user, token/user route | `API-APP-001`, `API-HTTP-006`, `API-HTTP-ROUTE-003`, `API-HTTP-ROUTE-004`, `API-DEP-001`, `API-DEP-003`, `API-DEP-009`, `API-SCHEMA-004`, `API-SCHEMA-005` | `CFG-AUTH-001` | `test_auth_router.py`, `test_dependencies.py` |
| `EX-RES-001` | ResourceBinding과 typed dependency | `API-APP-002`, `API-RES-001`~`004`, `API-DEP-005`, `API-TRAN-001` | `CFG-RES-001`, `CFG-APP-003` | `test_target_contracts.py`, `test_extensions.py` |
| `EX-RES-002` | SDK health outcome와 adapter | `API-READY-002`, `API-READY-003` | `CFG-READY-001` | `test_target_contracts.py` |
| `EX-READY-001` | custom readiness와 응답 상태 | `API-READY-001`, `API-READY-004`~`006`, `API-HTTP-ROUTE-002`, `API-SCHEMA-001`, `API-SCHEMA-002` | `CFG-READY-001` | `test_health_router.py`, `test_extensions.py` |
| `EX-MOD-001` | module transport policy | `API-APP-002`, `API-APP-004`, `API-TRAN-001` | `CFG-APP-003` | `test_target_contracts.py` |
| `EX-MOD-002` | 명시적 module provider convention | `API-APP-003` | 설정 없음 | `test_public_api.py` |
| `EX-ERR-001` | exception mapping과 renderer | `API-HTTP-001`~`005`, `API-SCHEMA-003`, `API-APP-004` | 설정 없음 | `test_http.py`, `test_target_contracts.py` |
| `EX-INVOKE-001` | sync/async resource invocation | `API-INVOKE-001`, `API-RES-002` | 설정 없음 | `test_target_contracts.py` |
| `EX-STREAM-001` | streaming resource close exactly once | `API-STREAM-001` | 설정 없음 | `test_target_contracts.py` |
| `EX-RUNTIME-001` | RuntimePlan과 app runtime wiring | `API-RUNTIME-001`~`003`, `API-LIFE-001`, `API-CFG-002`, `API-TEST-004` | `CFG-RUNTIME-001` | `test_factory.py`, `test_config.py` |
| `EX-DEP-001` | service runtime/client dependency | `API-DEP-004`~`008` | `CFG-SVC-001`, `CFG-RUNTIME-001` | `test_dependencies.py` |
| `EX-TEST-001` | consumer contract test helper | `API-TEST-001`~`005` | `CFG-APP-001` | `test_testing.py`, `test_target_contracts.py` |
| `EX-LOG-001` | function boundary와 application logging | `API-LOG-001`~`003` | `CFG-LOG-001` | `test_function_logging.py`, `test_factory.py` |

<a id="ex-app-001"></a>
## EX-APP-001 — 서비스 없는 최소 앱

외부 service가 필요 없는 첫 실행 경로다. auth는 명시적으로 꺼져 있고 health router만 기본 포함된다.

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

기대 결과:

- `GET /health/liveness` → `200`, status `ok`
- 등록된 readiness check가 없으면 `GET /health/readiness` → `200`, status `ok`

<a id="ex-app-002"></a>
## EX-APP-002 — auth opt-in과 현재 사용자

auth router를 사용하려면 Keycloak runtime/provider가 필요하다. 아래 코드는 provider seam을 보여주는 consumer route 예제다.

```python
from fastapi import APIRouter, Depends
from fastapi_core import create_app
from fastapi_core.dependencies import get_current_user
from fastapi_core.runtime import create_empty_runtime


class FakeAuthProvider:
    def extract_user_info(self, token: str):
        raise NotImplementedError


app = create_app(
    runtime=create_empty_runtime(),
    include_auth_router=True,
    auth_provider=FakeAuthProvider(),
)
router = APIRouter()


@router.get("/me")
async def me(user=Depends(get_current_user)):
    return {"sub": user.sub}


app.include_router(router)
```

실제 운영 앱에서는 `auth_provider=...`를 임의 object로 대체하지 않고 `keycloak`이 enabled/required인 `AppConfig`와 runtime assembly를 사용한다. 내장 endpoint는 `POST /token`, `GET /user`이며 `TOKEN_URL`은 OpenAPI OAuth2 metadata만 바꾼다.

<a id="ex-res-001"></a>
## EX-RES-001 — ResourceBinding과 module

```python
from fastapi import APIRouter, Depends
from fastapi_core import DomainModule, ResourceBinding, TransportPolicy, create_app
from fastapi_core.runtime import create_empty_runtime


class SearchClient:
    async def search(self, query: str) -> list[dict[str, str]]:
        return [{"query": query}]

    async def aclose(self) -> None:
        pass


search_client = ResourceBinding(
    "search-client",
    factory=lambda _app: SearchClient(),
    healthcheck=lambda _client: True,
)
router = APIRouter(prefix="/documents", tags=["documents"])


@router.get("")
async def search(
    query: str,
    client: SearchClient = Depends(search_client.dependency),
):
    return await client.search(query)


module = DomainModule(
    name="documents",
    routers=(router,),
    resources=(search_client,),
    transport_policy=TransportPolicy(validation_status=400),
)
app = create_app(runtime=create_empty_runtime(), modules=(module,))
```

`ResourceBinding`은 resource 생성, dependency 조회, health 등록, 종료를 같은 key로 묶는다. 기존 descriptor가 필요하면 `ManagedResource(...).bind()`를 사용한다.

<a id="ex-res-002"></a>
## EX-RES-002 — SDK health 결과와 adapter

`ok` attribute가 있는 결과는 adapter 없이 해석된다.

```python
from dataclasses import dataclass
from fastapi_core import ResourceBinding


@dataclass
class HealthStatus:
    ok: bool
    detail: str | None = None


class Client:
    pass


client = ResourceBinding(
    "search-client",
    factory=lambda _app: Client(),
    healthcheck=lambda _value: HealthStatus(ok=True, detail="connected"),
)
```

SDK가 opaque result를 반환하지만 strict interpretation이 필요하면 adapter를 명시한다.

```python
strict_client = ResourceBinding(
    "strict-search-client",
    factory=lambda _app: Client(),
    healthcheck=lambda value: value.health(),
    health_result_adapter=lambda result: result.status == "ready",
)
```

<a id="ex-ready-001"></a>
## EX-READY-001 — custom readiness

```python
from fastapi.testclient import TestClient
from fastapi_core import create_app, register_readiness_check
from fastapi_core.runtime import create_empty_runtime

app = create_app(runtime=create_empty_runtime())
register_readiness_check(
    app,
    "document-store",
    lambda: True,
    required=True,
    timeout_seconds=2.0,
)

with TestClient(app) as client:
    response = client.get("/health/readiness")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"
```

check가 `False`를 반환하거나 adapter가 실패로 정규화하면 required service는 503/error, optional service는 200/degraded가 된다. 오류 redaction 기본값은 `True`다.

<a id="ex-mod-001"></a>
## EX-MOD-001 — module transport policy

```python
from fastapi import APIRouter, Depends
from fastapi_core import DomainModule, TransportPolicy, create_app
from fastapi_core.runtime import create_empty_runtime


def require_document_scope() -> None:
    return None


router = APIRouter(prefix="/documents")


@router.get("")
async def list_documents(limit: int) -> list[int]:
    return [limit]


policy = TransportPolicy(
    dependencies=(Depends(require_document_scope),),
    validation_status=400,
    include_synthetic_422=False,
)
module = DomainModule(
    name="documents",
    routers=(router,),
    transport_policy=policy,
)
app = create_app(runtime=create_empty_runtime(), modules=(module,))
```

이 policy는 module route에만 적용된다. runtime validation과 OpenAPI 응답이 같은 policy에서 파생되므로 400 응답과 synthetic 422 제거를 함께 검증할 수 있다.

<a id="ex-mod-002"></a>
## EX-MOD-002 — 명시적 module provider

framework는 provider를 자동 discovery하지 않는다. consumer가 원하는 설정과 의존성을 받아 `DomainModule`을 직접 반환한다.

```python
from fastapi_core import DomainModule


def build_documents_module(settings) -> DomainModule:
    del settings
    return DomainModule(name="documents")
```

<a id="ex-err-001"></a>
## EX-ERR-001 — exception mapping과 renderer

```python
from fastapi import APIRouter
from fastapi_core import (
    ErrorMapping,
    ExceptionMappingTable,
    create_app,
    create_error_renderer,
)
from fastapi_core.runtime import create_empty_runtime


class DocumentNotFound(Exception):
    pass


errors = ExceptionMappingTable(
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
router = APIRouter()


@router.get("/documents/{document_id}")
async def get_document(document_id: str):
    raise DocumentNotFound(document_id)


app = create_app(
    runtime=create_empty_runtime(),
    routers=(router,),
    error_mapping_table=errors,
    error_renderer=create_error_renderer(
        problem_details=False,
        fallback_codes={404: "not_found", 500: "internal_error"},
    ),
)
```

예외 class MRO에서 가장 구체적인 mapping이 선택된다. `headers`와 `extensions`는 renderer에 전달되고, response body와 `X-Correlation-ID` header에는 같은 correlation ID가 들어간다.

<a id="ex-invoke-001"></a>
## EX-INVOKE-001 — sync/async resource invocation

```python
import asyncio

from fastapi_core import ResourceBinding, invoke_resource


class Resource:
    def sync_method(self, value: str) -> str:
        return value

    async def async_method(self, value: str) -> str:
        await asyncio.sleep(0)
        return value


async def main() -> None:
    resource = Resource()
    binding = ResourceBinding("sdk", factory=lambda _app: resource)
    assert await invoke_resource(resource.sync_method, "sync") == "sync"
    assert await binding.call("async_method", "async", instance=resource) == "async"


if __name__ == "__main__":
    asyncio.run(main())
```

sync 함수는 worker thread에서 실행되고 async 함수는 현재 event loop에서 await된다. `timeout_seconds`를 지정하면 timeout은 숨기지 않고 caller에게 전달된다.

<a id="ex-stream-001"></a>
## EX-STREAM-001 — streaming resource close exactly once

```python
from fastapi import APIRouter
from fastapi_core import ManagedStreamingResponse
from fastapi_core.runtime import create_empty_runtime
from fastapi_core import create_app


class ExportResource:
    async def aclose(self) -> None:
        pass


async def chunks():
    yield b"document-1\n"
    yield b"document-2\n"


router = APIRouter()


@router.get("/export")
async def export():
    return ManagedStreamingResponse(
        chunks(),
        resource=ExportResource(),
        media_type="application/x-ndjson",
    )


app = create_app(runtime=create_empty_runtime(), routers=(router,))
```

정상 완료, producer exception, disconnect, cancellation 모두에서 `aclose()` 또는 `close()`를 한 번만 호출한다. sync close는 worker thread에서 실행된다.

<a id="ex-runtime-001"></a>
## EX-RUNTIME-001 — RuntimePlan과 app runtime wiring

```python
from fastapi_core.config import AppConfig
from fastapi_core.runtime import assemble_runtime, build_runtime_plan


config = AppConfig(enabled_services=[], required_services=[])
plan = build_runtime_plan(config)


async def build_empty_runtime():
    runtime = await assemble_runtime(plan)
    assert runtime.selected_services == frozenset()
    return runtime
```

기본 `create_app(config=...)` 경로는 enabled service가 있을 때 lifespan startup에서 같은 plan을 조립한다. explicit `runtime=`을 주입하면 consumer가 소유한 완성 runtime을 사용하되 app의 readiness/resource/lifecycle 연결은 동일하게 유지한다.

환경 기반 DocMesh settings만 읽으려면 다음 진입점을 사용한다.

```python
from fastapi_core.docmesh_settings import load_docmesh_settings

settings = load_docmesh_settings(("sqlite",))
assert settings.sqlite is not None
```

<a id="ex-dep-001"></a>
## EX-DEP-001 — service runtime/client dependency

```python
from fastapi import Depends
from fastapi_core import create_app
from fastapi_core.dependencies import get_service_client, get_service_runtime
from fastapi_core.runtime import create_empty_runtime

app = create_app(runtime=create_empty_runtime())


@app.get("/runtime")
async def runtime_status(runtime=Depends(get_service_runtime)):
    return {"selected_services": [service.value for service in runtime.selected_services]}


# 활성 runtime client가 있는 앱에서는 다음 factory를 route Depends에 사용한다.
get_sqlite = get_service_client("sqlite")
```

typed getter는 service 이름/기대 wrapper type을 중앙화한다. service가 선택되지 않았거나 startup 전이면 503이므로 route가 임의의 `app.state` map을 직접 읽지 않는다.

<a id="ex-test-001"></a>
## EX-TEST-001 — consumer contract test

```python
from fastapi.testclient import TestClient
from fastapi_core import create_app
from fastapi_core.testing import (
    ApplicationContractProfile,
    ResourceLifecycleProbe,
    assert_application_contract,
    assert_auth_router_contract,
    assert_health_contract,
    create_empty_runtime,
)

probe = ResourceLifecycleProbe(value=object())
app = create_app(
    runtime=create_empty_runtime(),
    resources=[probe.managed_resource("sdk")],
)
profile = ApplicationContractProfile(
    expected_paths={"/health/liveness": {"GET"}, "/health/readiness": {"GET"}},
)

with TestClient(app) as client:
    assert_health_contract(client)
    assert_auth_router_contract(client, included=False)
assert_application_contract(app, profile)
```

`assert_application_contract`는 health/auth inclusion, module/resource/readiness/error mapper, OpenAPI path/method/status/security/schema reference를 의미 기반으로 확인한다. `test_environment`는 환경변수와 settings cache를 함께 격리할 때 사용한다.

<a id="ex-log-001"></a>
## EX-LOG-001 — function boundary와 application logging

```python
import logging

from fastapi_core.config import AppConfig
from fastapi_core.function_logging import log_function_boundary
from fastapi_core.logging import (
    JsonLogFormatter,
    configure_application_logging,
)

logger = configure_application_logging(AppConfig(log_level="INFO"))


@log_function_boundary("consumer.operation")
def operation(value: int) -> int:
    return value + 1


assert operation(1) == 2
assert isinstance(JsonLogFormatter(), logging.Formatter)
assert logger.name == "fastapi_core"
```

function decorator는 sync/async 성공과 예외 boundary를 구조화해 기록한다. `AppConfig.log_json`, `log_path`, `log_force`, `access_log_enabled`, `access_log_health_enabled`가 application/access log 설치를 제어한다.

## 11. 예제 변경 시 검증

```bash
uv run --frozen python -c 'import ast, pathlib; files=[pathlib.Path("wiki/raw/articles/fastapi-core-examples-guide-v0.7.0.md")]; text=files[0].read_text(); blocks=[]; in_block=False; current=[]; lang="";
for line in text.splitlines():
    if line.startswith("```"):
        if in_block and lang == "python": blocks.append("\\n".join(current)); current=[]; in_block=False; lang=""
        elif not in_block: in_block=True; lang=line[3:].strip()
    elif in_block: current.append(line)
for block in blocks: ast.parse(block)
print(f"compiled {len(blocks)} python examples")'
```

각 `EX-*`는 API 추적표의 하나 이상의 API ID를 가져야 하며, 예제가 요구하는 외부 서비스/환경변수는 해당 `CFG-*` anchor에서 설명해야 한다. 예제는 source/test 계약과 달라질 경우 먼저 API 문서와 설정 문서를 함께 갱신한다.
