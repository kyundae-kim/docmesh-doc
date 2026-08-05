---
title: dms-core consumer source minimization
created: 2026-08-04
updated: 2026-08-04
type: query
tags: [dms-core, dms, api, integration, architecture, performance, security, testing, dependency]
sources: [raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md]
confidence: high
---

# dms-core consumer source minimization

## 결론

`dms-core` v0.7.0은 이미 소비자 반복을 줄이는 핵심 domain primitive를 상당수 제공한다. `create_sdk_from_clients(...)`/`create_sdk_from_components(...)`, `DmsAssemblyPlan`, `DmsOperationContext`와 scoped facade, public/internal metadata 분리, close-safe content stream, cursor page, `ErrorDescriptor`와 `recommended_http_error(...)`가 그 표면이다. 따라서 가장 큰 개선은 환경변수 factory나 FastAPI를 DMS에 넣는 것이 아니라, 현재 소비자가 이미 가진 primitive를 명시적 bridge에서 한 번만 조립하게 만드는 것이다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

현재 workspace의 실제 소비자 표면은 다음과 같다.

| 영역 | 파일/측정값 | 반복의 성격 |
| --- | --- | --- |
| host assembly | `docmesh_doc/dms_factory.py`: 148줄, `create_dms_sdk()`: 56줄 | 환경 선택, diagnosis, client 생성, DMS 주입, rollback/close |
| DMS HTTP adapter | `application.py`, `router.py`, `document_http.py`, `errors.py`, `dependencies.py`, `schemas.py`, `main.py`: 합계 364줄 | stream response, DTO, 오류 투영, resource/dependency 연결 |
| 전체 관찰 범위 | 위 두 층: 512줄 | package-neutral primitive, framework bridge, 제품 정책이 섞여 있음 |

`uv run` runtime은 `dms 0.7.0`, `docmesh-config 0.1.0`, `docmesh-py-core 0.6.0`, `fastapi-core 0.7.0`을 사용한다. DMS 공개 signature와 실제 import를 확인했고, 전체 소비자 테스트는 `66 passed, 1 skipped`였다.

## 소유권 분류

### DMS core에 둘 package-neutral primitive

여러 host가 반복하고 transport나 제품 정책에 의존하지 않는 다음 불변조건은 DMS가 계속 소유해야 한다.

- 업로드의 metadata 검증, 크기 검증, object/metadata rollback과 consistency error
- public metadata에서 `storage_key`를 제거하는 projection
- sync/async content stream의 정상 완료·오류·취소·조기 close 정리
- cursor의 불투명성, page-size/status 결합, public `DocumentPage`
- `DmsOperationContext`의 created-by, tenant/access, idempotency scope, audit actor 기본값 주입
- `ErrorDescriptor`의 stable code/category/retryability와 secret-safe message
- SDK-owned resource의 역순·멱등 close 및 `HealthStatus`

### 별도 integration bridge에 둘 연결 로직

`dms-core`와 독립적으로 유용한 패키지를 연결하는 반복은 DMS core에 넣지 않는다.

- `docmesh-config`의 `RuntimePlan`/`ServiceConfigs`를 `docmesh-py-core` client로 해석
- PostgreSQL/SQLite 대안 선택, MinIO bucket 확인, legacy `POSTGRES_DSN` 거부
- py-core wrapper에서 concrete client를 꺼내 `create_sdk_from_clients(...)`에 전달
- DMS close callback과 FastAPI `ManagedResource`/readiness를 단일 ownership 경계로 연결
- FastAPI `ManagedStreamingResponse`, typed dependency, router/module 조립

이 반복을 줄이려면 명시적 `dms-host-adapter`와 `dms-fastapi` 같은 bridge를 별도 모듈로 두는 편이 맞다. DMS가 환경을 읽거나 FastAPI를 import하면 한 consumer의 줄 수는 줄어도 재사용 가능한 domain SDK의 경계가 무너진다. [[dms-core-configuration]]과 [[fastapi-core-app-assembly]]의 경계를 유지해야 한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

### 소비자에 남겨야 하는 제품 정책

다음은 source를 줄인다는 이유로 DMS에 올리면 안 된다.

- 인증 주체를 `created_by`/`AccessContext`로 바꾸는 규칙과 hard-delete 권한
- route path, reverse-proxy/root-path, `Location`, `Content-Disposition`, caller-visible chunk limit
- `storage_key` 은닉, 삭제 문서의 존재 은닉, public field alias
- 제품 error code/메시지/envelope/correlation ID와 configuration 오류의 503 정책
- search/filter, presigned URL, broker, standalone HTTP server

실제 runtime에서 DMS의 `recommended_http_error(DocumentDeletedError)`는 409를 권고하지만 현재 제품은 삭제 문서를 404로 은닉한다. `ConfigurationError`도 DMS 권고는 500이고 제품은 503으로 투영한다. 이는 DMS 기능 누락이 아니라 의도적인 product policy 차이이므로 generic HTTP table로 덮어쓰면 안 된다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## 우선순위

### P0 — 새 DMS API보다 기존 surface의 canonical 사용

1. 요청마다 `sdk.scoped(DmsOperationContext(...))`를 만든다. 인증 bridge가 `subject`/tenant/roles와 `created_by`/audit actor를 한 번 변환하면 upload 및 이후 문서 작업에서 반복 인자를 제거할 수 있다. DMS가 FastAPI user type을 알아야 한다는 뜻은 아니다.
2. 삭제 adapter는 이미 존재하는 `delete_document(document_id, hard_delete=...)`를 기본으로 사용한다. hard-delete permission check만 제품/FastAPI에 남기고, soft/hard method 선택 glue는 줄인다.
3. public metadata는 `PublicDocumentMetadata`, `public_metadata(...)`, `to_public_dict()`를 기준으로 소비한다. Pydantic/OpenAPI response model은 FastAPI bridge에 남기되, `storage_key` allowlist를 각 route에서 다시 작성하지 않는다.
4. 오류 adapter는 `error_descriptor()`와 `merge_error_descriptor()`를 먼저 사용하고, 필요한 경우 `recommended_http_error()`의 status/header를 제품 mapping에 반영한다. 제품 envelope와 외부 code만 bridge에서 override한다.
5. output stream은 현재처럼 `DocumentContentStream`과 FastAPI의 `ManagedStreamingResponse`를 한 close boundary로 연결한다. DMS의 `iter_chunks_closing()`/async close를 사용하면 전송 계층이 iterator만 받는 경우에도 정리 불변조건을 보존할 수 있다. 이 원칙은 [[dms-application-optimization]]과 [[dms-core-document-lifecycle]]에 반영되어 있다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

이 P0 작업만으로도 DMS core의 책임을 늘리지 않고 소비자 source를 줄일 수 있다. 특히 현재 `dms_factory.py`의 환경/py-core 조립은 DMS가 해결할 문제가 아니라 재사용 가능한 host bridge가 해결할 문제다. [[docmesh-py-core-consumer-source-minimization]]과 [[docmesh-config-consumer-source-minimization]]의 결론과 일치한다.

### P1 — streaming upload 입력 계약의 기능 대칭

v0.7.0의 `UploadDocumentStreamRequest`는 정확한 양의 크기를 가진 동기 binary stream만 받고, 요청별 checksum·idempotency·unknown-size·async input은 공개 범위 밖이다. 이 제한은 안전하지만, non-seekable HTTP upload나 재시도 가능한 대용량 upload consumer가 bytes buffering 또는 자체 operation protocol을 작성하게 만든다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

다음 additive surface를 검토할 가치가 있다.

- `StreamingUploadOptions` 또는 확장 request에 checksum, idempotency key/scope를 추가
- `size=None`을 허용할 경우 `max_file_size`와 실제 read bytes 상한을 강제
- checksum/fingerprint 확정 전 operation record를 성공으로 보지 않기
- 선언 크기·실제 크기·checksum 불일치 시 object rollback과 명시적인 `ValidationError`/`ConsistencyError`
- caller-owned input stream은 닫지 않고, 오류·취소 시 SDK-owned object와 operation 상태를 정리
- sync/async 입력에 같은 idempotency 및 cancellation 계약을 적용

이는 transport-neutral domain capability이므로 실제 두 개 이상의 consumer가 요구할 때 DMS에 넣을 수 있다. 단순히 `size`를 optional로 바꾸는 것은 충분하지 않으며, bounded read·rollback·operation 상태·close semantics를 함께 contract test로 고정해야 한다.

### P2 — lifecycle binding은 공통 protocol로만 검토

현재 DMS의 `ManagedResource`/`ResourceOwnership`와 FastAPI의 `ManagedResource`/`ResourceBinding`은 각각 유용하지만 서로 다른 lifecycle registry다. DMS가 FastAPI resource를 직접 반환하는 API를 추가하는 대신, 여러 host가 반복을 보일 때 다음처럼 framework-neutral descriptor 또는 bridge helper를 검토한다.

```text
build_dms_resource(sdk, *, name, health_policy)
    -> value + check_health + close/aclose + ownership metadata
```

이 helper는 별도 integration package가 FastAPI `ManagedResource`, 다른 host의 lifecycle, readiness로 변환하는 입력이어야 한다. DMS core에 FastAPI import나 router factory를 넣지 않는다. 현재 한 consumer만으로는 별도 DMS API를 추가할 근거가 약하므로, 먼저 `dms-fastapi` bridge contract test로 반복을 측정한다. [[fastapi-core-consumer-source-minimization]]도 같은 ownership 분리를 권고한다.

### P2 — error catalog는 현재 surface를 보강하되 HTTP를 소유하지 않음

DMS는 이미 모든 `DmsError`에 stable code/category/retryability를 부여하고 `recommended_http_error()`를 제공한다. 따라서 우선순위가 높은 새 exception-to-HTTP table은 필요하지 않다. 여러 consumer가 매번 class MRO와 canonical code를 다시 작성한다는 증거가 생길 때만 다음 additive helper를 검토한다.

- exception class가 아닌 `DmsError`/descriptor 기반의 canonical classification helper
- `external_code`와 safe message만 host가 합성하는 policy object
- retry-after와 status 권고를 함께 검증하는 contract profile

제품의 404 존재 은닉, 503 configuration mapping, correlation ID와 envelope는 계속 host에 남겨야 한다.

## 권장 구현 순서

1. 현재 host를 `scoped` context, `delete_document`, `error_descriptor`, stream close primitive를 사용하는 얇은 adapter로 정리한다.
2. `dms-host-adapter`에서 config/py-core client assembly와 ownership transfer를 재사용하고, DMS core에는 환경 factory를 추가하지 않는다.
3. `dms-fastapi` bridge에서 resource/readiness, streaming response, DTO/schema, product error override를 contract profile로 검증한다.
4. 두 consumer 이상에서 non-seekable/idempotent stream 요구가 확인되면 P1 streaming upload 계약을 설계하고 sync/async, rollback, cancellation 테스트를 먼저 추가한다.
5. 그 이후에도 lifecycle descriptor 반복이 남을 때만 P2 protocol을 추가한다.

## Acceptance tests

- `PublicDocumentMetadata`와 `to_public_dict()`에 `storage_key`가 없고 internal metadata projection만 관리 경계에 남는다.
- stream 정상 소진, read error, client disconnect, cancellation, 조기 close에서 source close가 정확히 한 번 실행된다.
- `DmsOperationContext`의 access/created-by/default metadata가 scoped facade에 적용되고 shared SDK는 변하지 않는다.
- `error_descriptor()`가 storage/configuration 내부 문자열과 secret을 외부에 노출하지 않으며, `merge_error_descriptor()`가 canonical category/retryability를 덮지 않는다.
- `delete_document(hard_delete=...)`가 soft/hard 결과와 access policy를 보존한다.
- optional unknown-size streaming을 도입할 경우 max size 초과, 실제 크기 불일치, checksum 불일치, idempotency conflict/replay, cancellation rollback을 모두 검증한다.
- current workspace regression baseline은 `uv run pytest -q`: `66 passed, 1 skipped, 1 warning`이다.

## 관련 페이지

- [[dms-core]] — DMS SDK 범위와 v0.7 host-injection 경계.
- [[dms-core-usage-patterns]] — upload, stream, scoped facade, error와 lifecycle 사용 패턴.
- [[dms-core-configuration]] — client/component ownership과 환경 설정의 host 경계.
- [[dms-core-document-lifecycle]] — object/metadata 정합성과 stream cleanup.
- [[docmesh-py-core-consumer-source-minimization]] — config/client assembly bridge와 ownership transfer.
- [[docmesh-config-consumer-source-minimization]] — plan/diagnosis/loading 반복 제거.
- [[fastapi-core-app-assembly]] — module/resource/readiness lifecycle.
- [[fastapi-core-consumer-source-minimization]] — FastAPI adapter 반복의 별도 개선안.
