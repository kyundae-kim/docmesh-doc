# 메시지 정의서

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-12 |
| 참조 문서 | [PRD](prd.md), [SRS](srs.md), [설정 정의서](config.md), [테스트 정의서](test.md) |

## 1. 목적과 범위

이 문서는 DocMesh Document Service에서 `fastapi-core v0.4.0`의 service runtime, readiness, managed lifecycle 확장 지점을 통해 NATS 같은 메시징 서비스를 연동할 때의 책임 경계를 정의한다.

MVP의 문서 upload, 조회, download, soft/hard delete는 동기 HTTP API와 `dms-core` SDK로 수행한다. 문서 event schema, broker publish/subscribe, 비동기 작업 queue 및 webhook 계약은 MVP 범위 밖이다.

## 2. 컴포넌트 책임 경계

| 컴포넌트 | 책임 | 제공하지 않는 것 |
| --- | --- | --- |
| `dms-core` | 문서 lifecycle, metadata/object 정합성, PostgreSQL·MinIO health | broker API, event schema, queue, webhook |
| `fastapi-core` | service 선택, client/builder 조립, dependency, readiness metadata/check, client 정리 | DMS event 계약, publisher/subscriber 업무 로직 |
| DocMesh Document Service | 필요 시 custom lifespan과 application dependency로 연결·발행·구독 정책 구현 | `dms-core`에 메시징 책임 전가 |
| NATS | 선택적으로 구성되는 외부 broker | 문서 저장 정합성 및 DMS API 처리 |

`NATS_SERVERS`가 환경에 존재한다는 사실만으로 DMS SDK 또는 서비스가 메시지를 발행·구독한다고 판단하지 않는다. 실제 메시징 기능은 별도 요구사항, event schema, handler 및 테스트가 추가된 경우에만 활성 기능으로 본다.

## 3. fastapi-core v0.4.0 통합 표면

`fastapi-core`에서 NATS는 독립된 FastAPI route가 아니라 선택 가능한 service client다.

- `AppConfig.enabled_services` / `DOCMESH_SERVICES`: 조립 대상 서비스 목록
- `AppConfig.required_services` / `READINESS_REQUIRED_SERVICES`: 실패 시 readiness 503을 유발할 필수 서비스 목록
- `app.state.service_runtime`: 조립된 client 또는 builder와 lifecycle을 소유하는 runtime
- `app.state.service_runtime.checks`: 실제 생성된 readiness check
- `app.state.service_runtime.selected_services`: 조립 대상으로 선택된 서비스 집합
- `app.state.service_runtime.required_services`: 필수 서비스 집합
- `get_nats_connection_builder()`: NATS connection builder dependency
- custom lifespan: 실제 connection 및 project-specific 자원 관리 확장 지점

`get_nats_connection_builder()`는 연결된 NATS session 자체를 보장하지 않는다. NATS가 활성화되지 않았으면 503을, 등록 객체 타입이 잘못되었으면 500을 반환할 수 있다.

## 4. 설정 계약

NATS를 사용하지 않는 MVP 기본 배포에서는 `nats`를 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`에 넣지 않는다.

NATS를 선택 서비스로 활성화하는 예:

```env
DOCMESH_SERVICES=keycloak,nats
READINESS_REQUIRED_SERVICES=keycloak
NATS_SERVERS=nats://nats.internal:4222
NATS_TOKEN=<secret>
```

NATS를 서비스 기동의 필수 조건으로 사용할 때만 required 목록에 포함한다.

```env
READINESS_REQUIRED_SERVICES=keycloak,nats
```

설정 원칙:

1. `NATS_TOKEN`, password, credentials file 내용은 secret store 또는 권한이 제한된 환경변수로 주입한다.
2. `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`를 빈 문자열로 설정하지 않는다. 기본값을 사용하려면 변수를 제거한다.
3. `enabled_services` metadata와 실제 client/readiness check 생성은 별개다. 설정 객체가 없거나 지원되지 않는 서비스는 enabled metadata에 남아도 check가 생성되지 않을 수 있다.
4. NATS readiness는 PostgreSQL·MinIO를 검사하는 DMS SDK health를 대체하지 않는다.

## 5. Readiness 정책

`GET /health/readiness`는 `NATS_SERVERS`를 직접 읽지 않고 app assembly에서 구성된 state를 사용한다.

| 조건 | HTTP 상태 | `status` |
| --- | --- | --- |
| 모든 실제 check 성공 | 200 | `ok` |
| 선택 NATS check 실패 | 200 | `degraded` |
| 필수 NATS check 실패 | 503 | `error` |

운영 검증에서는 enabled metadata만 확인하지 않고 `app.state.service_runtime.checks`에 `nats` check가 실제 등록되었는지 확인해야 한다.

## 6. Lifecycle 정책

실제 NATS connection, publisher 또는 subscriber가 필요하면 서비스 custom lifespan에서 생성하고 project-specific `app.state` 키 또는 dependency로 제공한다.

```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi_core import create_app


@asynccontextmanager
async def lifespan(app: FastAPI):
    builder = app.state.service_runtime.require("nats")
    connection = await builder.connect()
    app.state.nats_connection = connection
    try:
        yield
    finally:
        await connection.close()
        app.state.nats_connection = None


app = create_app(lifespan=lifespan)
```

위 코드는 lifecycle 구조를 설명하는 예시다. 실제 builder의 연결·종료 method는 잠금된 `docmesh-py-core` public API를 기준으로 구현하고 테스트해야 한다.

`fastapi-core v0.4.0`의 managed lifespan은 service runtime 종료를 소유한다. 다만 custom lifespan에서 직접 생성한 NATS connection은 서비스가 `try/finally`로 정리하고 다음 실패 경로를 테스트해야 한다.

- connection 생성 실패
- subscriber 시작 실패
- 정상 shutdown
- handler 또는 subscriber 예외
- connection close 실패

## 7. Event 계약 정책

MVP에는 표준 event가 없다. 향후 event를 추가할 때는 구현 전에 별도 문서에서 최소 다음을 확정한다.

- subject 및 versioning 규칙
- event ID, 발생 시각, correlation ID
- document ID와 event type
- payload schema와 호환성 정책
- 중복 전달에 대한 idempotency
- ordering 보장 범위
- retry, dead-letter 및 poison-message 정책
- 개인정보·filename·사용자 metadata 노출 정책
- publish 실패가 HTTP transaction에 미치는 영향

문서 본문, access token, credential, 전체 DSN 또는 storage key는 event payload와 broker log에 포함하지 않는다.

## 8. 테스트 요구사항

메시징 기능을 활성화하면 다음을 검증한다.

1. NATS 비활성 상태에서 DMS HTTP lifecycle이 정상 동작한다.
2. 선택 NATS 장애가 readiness 200/degraded를 반환한다.
3. 필수 NATS 장애가 readiness 503/error를 반환한다.
4. enabled metadata뿐 아니라 실제 NATS readiness check가 등록된다.
5. startup, 정상 shutdown 및 예외 경로에서 connection/subscription이 정리된다.
6. dependency가 동일 application lifecycle의 connection을 재사용한다.
7. 오류 response와 log에 token, credential, broker endpoint 상세가 노출되지 않는다.
8. event 기능을 추가한 경우 schema, 중복 처리, publish 실패 및 correlation ID 전달을 계약 테스트로 검증한다.

## 9. 현재 결정

- MVP에서는 NATS를 필수 의존성으로 사용하지 않는다.
- `dms-core`에는 메시징 책임을 추가하지 않는다.
- `fastapi-core`의 NATS builder와 readiness는 hosting-layer 확장 지점으로만 사용한다.
- 표준 document event 및 publisher/subscriber API는 별도 요구사항이 확정될 때 추가한다.
