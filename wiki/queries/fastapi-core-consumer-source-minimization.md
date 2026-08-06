---
title: fastapi-core consumer source minimization
created: 2026-08-04
updated: 2026-08-04
type: query
tags: [fastapi-core, fastapi, integration, architecture, performance, testing, dependency, security]
sources: [raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md]
confidence: high
---

# fastapi-core consumer source minimization

## Conclusion

`fastapi-core` v0.7.0의 가장 큰 개선점은 새로운 `create_app` 변형을 추가하는 것이 아니라, 이미 공개된 **resource binding, transport policy, error table/renderer, sync invocation, contract-test profile**을 소비 애플리케이션이 일관되게 사용하도록 만드는 것이다. 현재 DMS consumer는 module-first 조립과 managed streaming은 이미 채택했지만, resource dependency descriptor, HTTP 오류/OpenAPI 정책, 동기 SDK 호출, contract assertion에는 아직 반복 adapter 코드가 남아 있다. 현재 조립 경계는 [[fastapi-core-app-assembly]], DMS SDK와 host의 ownership 경계는 [[dms-core-configuration]] 및 [[docmesh-py-core-consumer-source-minimization]]과 함께 읽어야 한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

## Current consumer surface

설치 runtime은 `fastapi-core 0.7.0`, `dms 0.7.0`이었다. 로컬 consumer의 관련 source는 다음과 같다.

| 영역 | 파일/LOC | 현재 구현 | 이미 존재하는 fastapi-core 표면 |
| --- | ---: | --- | --- |
| app/module/resource assembly | `docmesh_doc/application.py` 50 | `DomainModule`, `ManagedResource`, DMS factory, custom renderer를 직접 조립 | `DomainModule`, `ResourceBinding`, `create_app` |
| typed resource dependency | `docmesh_doc/dependencies.py` 15 | `ResourceKey`와 `ManagedResource.name`을 별도로 선언 | `ResourceBinding.dependency` |
| HTTP route/stream/SDK call | `docmesh_doc/router.py` 129 | router-level responses, `run_in_threadpool`, DMS-specific stream header helper | `TransportPolicy`, `invoke_resource`, `ManagedStreamingResponse` |
| error mapping/rendering | `docmesh_doc/errors.py` 96 | MRO 순회, status-code table, JSON envelope renderer를 직접 구현 | `ExceptionMappingTable`, `create_error_renderer`, `ErrorMapping` |
| product DTO | `docmesh_doc/schemas.py` 48 | public metadata alias와 DMS response shape | 제품/bridge 책임; upstream으로 이동하지 않음 |
| application contract tests | `test_docmesh_doc/test_application.py` 190 | health/auth/module/OpenAPI를 여러 assertion으로 분산 | `ApplicationContractProfile`, `assert_application_contract` |

이 consumer surface는 `dms_factory.py`의 DMS/config/client assembly 148줄과 별개다. DMS SDK factory와 storage policy를 `fastapi-core`에 넣으면 framework가 domain/config 계층을 소유하게 되므로, FastAPI 개선은 HTTP/resource bridge에 한정해야 한다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## Runtime evidence

설치본에서 다음 public signature를 확인했다.

- `create_app(config=None, *, runtime=None, lifespan=None, include_auth_router=False, routers=(), modules=(), resources=(), error_mappers=(), error_renderer=None, auth_provider=None, transport_policy=None, error_mapping_table=None)`
- `ResourceBinding(key, factory, healthcheck=None, close=None, required=True, readiness_timeout_seconds=None, redact_errors=True, health_result_adapter=None)`
- `TransportPolicy(..., validation_status=None, validation_response_model=None, common_error_response_model=None, fallback_response_model=None, responses={}, error_renderer=None)`
- `ExceptionMappingTable.from_specs(...)`, `create_error_renderer(...)`, `invoke_resource(...)`

실행 probe 결과도 공개 문서와 일치했다.

- `TransportPolicy(validation_status=400, include_synthetic_422=False)`는 invalid request를 `400`으로 반환하고 OpenAPI에 `200/400/500`을 생성하며 synthetic `422`를 제거했다.
- `ExceptionMappingTable`은 `ValueError`를 `418/TEAPOT`으로 매핑했고, `create_error_renderer(problem_details=False)`는 현재 consumer의 `{error: {code, message, correlation_id}}` 형태와 correlation header를 생성했다.
- `ResourceBinding.call()`/`invoke_resource()`는 sync SDK method를 worker thread에서 실행했다.
- readiness는 `False`와 `.ok=False` 결과를 실패로 처리하고, opaque sentinel은 하위 호환을 위해 성공으로 허용했다.
- `ResourceRegistry`는 생성 순서의 역순으로 close하고 startup 실패 시 이미 생성한 resource를 rollback했다.

Probe에는 credential, 실제 외부 endpoint, secret 값이 포함되지 않았다. 설치 runtime과 로컬 consumer를 근거로 한 결과이며, 문서 예제만으로 추정한 API가 아니다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

## Prioritized improvements

### P0 — consumer가 즉시 채택할 수 있는 표면

1. **`ResourceBinding`으로 DMS resource 등록과 dependency를 합친다.**

   현재 `DMS_RESOURCE = ResourceKey[...]`와 `ManagedResource(name=DMS_RESOURCE, ...)`가 같은 이름을 별도로 표현한다. `ResourceBinding` 하나에 factory, healthcheck, close/required 정책을 두고 `DMS_RESOURCE.dependency`를 route dependency와 module resource registration 양쪽에서 사용하면 key drift와 descriptor 중복을 없앨 수 있다. DMS SDK의 실제 factory는 계속 host bridge에 두고, FastAPI는 결과 SDK의 lifecycle만 소유한다.

2. **`DomainModule.transport_policy`로 validation/OpenAPI 정책을 한 번 선언한다.**

   현재 document router의 `400`/`default` response metadata와 runtime validation status가 별도 코드에 있다. `TransportPolicy(validation_status=400, validation_response_model=ErrorResponse, fallback_response_model=ErrorResponse, include_synthetic_422=False, ...)`를 module에 부여하면 runtime handler와 generated OpenAPI가 같은 정책을 소비한다. health/auth router에는 module policy가 자동 전파되지 않으므로 기존 built-in route 계약도 보존된다. 제품의 응답 model/status 선택은 host policy로 남는다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-examples-v0.7.0.md]

3. **DMS 예외의 mechanics를 table/renderer에 위임한다.**

   `ERRORS`의 DMS-specific status/code/detail은 제품 정책이므로 유지하되, 수동 `type(exc).__mro__` 순회는 `ExceptionMappingTable`로, JSON envelope와 correlation ID 처리는 `create_error_renderer(problem_details=False, fallback_codes=...)`로 옮긴다. 정확한 validation message/code가 제품 계약이면 `RequestValidationError` mapper만 유지하고, 일반 DMS exception mapper는 제거할 수 있다. 이렇게 하면 mapping policy와 HTTP rendering mechanics가 분리된다.

4. **sync DMS method는 `invoke_resource` 또는 binding의 `call`을 사용한다.**

   현재 async delete route가 `run_in_threadpool`을 직접 호출한다. `await DMS_RESOURCE.call(method_name, document_id, instance=sdk, timeout_seconds=...)` 또는 `await invoke_resource(delete, document_id)`를 사용하면 sync/async 판별, worker thread, awaitable 반환, timeout 규칙을 공통화할 수 있다. timeout 값과 hard-delete permission은 제품 policy로 남긴다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

### P1 — 반복 consumer가 생길 때 upstream/bridge로 승격할 후보

- **`TransportPolicy.responses`의 string key 계약을 정합화한다.** 현재 annotation은 `Mapping[int, ...]`이지만 FastAPI의 `"default"` response key를 consumer가 사용한다. `Mapping[int | str, ...]`를 명시하고 mixed-key conflict sort를 안전하게 처리하면 policy로 default response까지 이동할 수 있다. 이 변경은 additive type/runtime contract이며, product error body를 framework에 하드코딩하지 않는다.
- **계약 테스트를 profile 하나로 모은다.** `ApplicationContractProfile`에 module name, path/method, response status, auth, resource, readiness, mapper와 security dependency 조건을 선언하고 `assert_application_contract()`를 호출한다. 현재처럼 health/auth/module/OpenAPI assertion을 각각 반복하는 setup은 줄이되, DMS factory 실패, SDK close failure, stream cancellation 같은 domain-specific safety test는 별도로 유지한다.
- **DMS health 결과는 bridge adapter로 구조화한다.** `ManagedResource.healthcheck`에서 무조건 `.ok`만 추출하면 DMS 내부 service detail이 사라진다. `fastapi-core`의 `HealthOutcome`/`HealthResultAdapter`는 generic 계약으로 유지하고, `dms.HealthStatus`의 nested services를 `HealthCheckResult`로 변환하는 코드는 DMS/FastAPI bridge에 둔다.
- **표준 error renderer에 validation mapping hook이 반복될 때만 추가한다.** 현재 renderer는 형식과 masking을 해결하지만 제품별 validation detail/code는 결정하지 않는다. 여러 consumer가 같은 validation mapping boilerplate를 반복할 때 additive hook을 검토하되, 제품 오류 code/message를 fastapi-core 기본값으로 고정하지 않는다.

## Keep out of fastapi-core

다음은 source를 줄인다는 이유로 upstream에 넣지 않는다.

- `DMS_METADATA_BACKEND`, PostgreSQL/SQLite 선택, MinIO bucket, `DmsAssemblyPlan`, DMS SDK factory와 storage client ownership
- route path, reverse-proxy `ROOT_PATH`, `Location` 생성, filename/content-disposition, download chunk ceiling
- public metadata allowlist, `storage_key` exclusion, cursor/list response shape
- hard-delete permission, tenant/authorization policy, existence hiding
- DMS exception의 제품 code/message/status와 correlation envelope의 제품 필드
- NATS publisher/subscriber flow, DMS domain lifecycle, broker policy
- DMS-specific `DocumentMetadataResponse`/`DocumentPageResponse` schema

이 항목들은 FastAPI framework bridge 또는 애플리케이션 product policy다. 특히 DMS는 host가 environment/secret을 읽어 client/component를 만들고 SDK에 주입하는 계약이므로, `fastapi-core`가 DMS 환경 factory를 제공한다고 확장해서는 안 된다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## Recommended sequence

1. 먼저 `ResourceBinding`, module `TransportPolicy`, `create_error_renderer`, `ExceptionMappingTable`, `invoke_resource`를 기존 consumer에 적용하고, 제품 HTTP contract를 snapshot/semantic test로 고정한다.
2. `ApplicationContractProfile`을 contract test에 추가해 module/resource/readiness/OpenAPI assertion을 하나의 선언으로 묶는다. lifecycle failure, DMS error projection, stream cleanup test는 유지한다.
3. `TransportPolicy.responses`의 `default` type/conflict 문제를 upstream patch로 보완하고, 해당 patch는 package test와 consumer OpenAPI contract로 검증한다.
4. nested DMS health detail이 실제 운영에 필요할 때만 별도 DMS/FastAPI health adapter를 추가한다.
5. 변경 후 `uv run pytest -q`, targeted application contract tests, `git diff --check`, OpenAPI `422` 부재/400 응답, sync SDK thread boundary, resource close-once/rollback을 함께 검증한다.

## Related pages

- [[fastapi-core]]
- [[fastapi-core-app-assembly]]
- [[fastapi-core-configuration]]
- [[fastapi-core-usage-patterns]]
- [[fastapi-core-application-optimization]]
- [[dms-core-configuration]]
- [[dms-core-document-lifecycle]]
- [[docmesh-py-core-consumer-source-minimization]]
