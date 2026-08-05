---
title: dms-core usage patterns
created: 2026-07-11
updated: 2026-08-04
type: concept
tags: [dms-core, dms, document, storage, workflow, testing, integration]
sources: [raw/articles/dms-core-api-v0.2.0.md, raw/articles/dms-core-api-v0.3.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-config-v0.3.0.md, raw/articles/dms-core-examples-v0.2.0.md, raw/articles/dms-core-examples-v0.3.0.md]
confidence: medium
---

# dms-core usage patterns

DMS v0.7.0의 기본 사용 흐름은 호스트가 만든 client 또는 storage component를 sync/async factory에 주입하고, upload → metadata/content 조회 → delete → `close()`/`aclose()` 순서로 리소스를 정리하는 것이다. 운영 코드에서는 context manager를 우선 사용하고, caller-owned와 SDK-owned 자원을 명시적으로 구분해야 한다. 이전 버전의 environment factory 흐름은 historical example로만 읽는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## Upload and retrieval

`UploadDocumentRequest`에 content, filename, content type과 선택적 metadata/created_by/checksum을 넣어 업로드한다. document ID를 생략하면 SDK가 생성한다. 대용량 콘텐츠는 전체 bytes를 가져오는 API보다 `get_document_content_stream(...)`와 `iter_chunks()`를 우선하고, stream도 반드시 close해야 한다. 공개 모델과 검증 세부 사항은 [[dms-core]] 및 [[dms-core-document-lifecycle]]에 정리한다. ^[raw/articles/dms-core-api-v0.2.0.md]

v0.3.0에서는 `UploadDocumentStreamRequest`로 알려진 양의 `size`와 `BinaryIO` stream을 전달해 전체 본문을 메모리에 올리지 않고 업로드할 수 있다. SDK는 실제 bytes와 선택 SHA-256 checksum을 검증하며, 크기/체크섬 불일치 시 생성된 object를 rollback하고 `ValidationError`를 낸다. `idempotency_key`는 `created_by`(없으면 `anonymous`) 범위에서 영속 처리되며, streaming 멱등 요청은 소비 전 fingerprint 확정을 위한 checksum이 필요하다. metadata 검증은 object 저장 전에 일어나므로 요청 metadata에는 JSON-serializable 값·문자열 top-level key·크기/깊이 제한을 지키고 credential 성격의 키를 넣지 않아야 한다. ^[raw/articles/dms-core-api-v0.3.0.md]

실행 예제는 파일 stream이 upload 호출 내내 열려 있어야 하고 `size`/`chunk_size`가 양수여야 함을 확인한다. 목록 API는 생성 시각·document ID 내림차순의 기본 정렬과 `DocumentStatus` 상태 필터만 제공하므로, 업무 검색이나 복합 필터가 필요한 application은 별도 query contract를 설계해야 한다. ^[raw/articles/dms-core-examples-v0.3.0.md]


v0.7.0에서는 known-size sync binary stream만 직접 upload 입력으로 공개한다. unknown-size stream과 async input stream upload는 범위 밖이며, async facade는 동기 adapter 작업을 worker thread에서 실행한다. 이미 시작한 변경 작업이 취소되면 정합성 경계까지 완료한 뒤 취소를 전파할 수 있으므로 operation 또는 metadata 조회로 최종 상태를 확인해야 한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

v0.7.0 Examples는 `DmsAssemblyPlan`의 access policy와 operation observer, `scoped(context)` facade, `ManagedResource` reverse cleanup, reset/recovery plan, 기능별 runtime-checkable protocol, structured error descriptor와 HTTP 권고 변환을 host integration contract로 보여 준다. 일반 결과에는 `storage_key`를 넣지 않고 internal metadata/recovery 경로에서만 관리한다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

현재 adapter는 inline content와 attachment download 모두 `get_document_content_stream()`을 사용하고 하나의 context-managed response 경계에서 chunk를 전달한다. caller가 지정하는 read buffer는 1 byte~8 MiB로 제한해 전체 object 적재와 비정상적으로 큰 단일 read를 피한다. 통합 테스트는 실제 PostgreSQL·MinIO 문서를 fixture cleanup으로 제거하며 marker selection과 root-path-aware `Location`을 검증한다. 적용 범위와 후속 후보는 [[dms-application-optimization]]에 기록한다.

소비자 source를 더 줄일 때는 DMS가 환경변수나 FastAPI를 소유하도록 확장하기보다 scoped facade, `delete_document(...)`, `error_descriptor(...)`, stream cleanup primitive를 host bridge에서 재사용한다. config/client assembly와 제품 HTTP 정책을 분리하는 판단은 [[dms-core-consumer-source-minimization]]에 기록한다.

## Assembly choices

v0.7.0의 현재 public assembly는 `create_sdk_from_clients(...)`, `create_sdk_from_components(...)`와 각 async factory다. host는 환경·secret을 읽어 client/component를 만든 뒤 DMS에 주입하며, DMS가 environment를 자동 로드하지 않는다. PostgreSQL/SQLite metadata store와 MinIO 조합을 어떻게 만들지는 host configuration boundary에서 결정하고, DMS에는 `DmsAssemblyPlan`으로 startup/metadata/access policy를 전달한다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

v0.3.0의 `create_sdk_from_environment(...)`와 component assembly는 해당 버전의 historical assembly path다. v0.7.0 문서만으로 이 legacy factory가 계속 공개된다고 추론하지 않는다. ^[raw/articles/dms-core-config-v0.3.0.md]

v0.3.0의 component assembly는 `max_file_size`, persistent idempotency용 `operation_store`, `metadata_validator`, metadata size/depth 한계를 선택적으로 받을 수 있다. 환경 조립에서는 backend를 명시하거나 strict automatic selection을 적용해 테스트 fixture와 실제 배포가 같은 storage 선택을 하도록 만든다. ^[raw/articles/dms-core-config-v0.3.0.md]

## HTTP integration boundary

FastAPI route는 request parsing, SDK error-to-HTTP mapping, streaming response 변환을 책임지고, SDK는 문서 도메인 작업을 담당하도록 분리한다. SDK 생성·close는 [[fastapi-core-app-assembly]]의 custom lifespan/state 경계와 맞춰야 하며, `fastapi-core`의 application layer 역할은 [[fastapi-core]]를 따른다.

v0.7.0 Configuration은 이 경계를 더 엄격히 한다. FastAPI가 engine/MinIO client 또는 component를 만들고 `ManagedResource` ownership, health check, close callback을 DMS plan/resource로 연결해야 하며, DMS의 비공개 환경 factory를 app bootstrap으로 가정하지 않는다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md]

## Policy, reset, and observability

host authorization은 `AccessContext`와 `DocumentAccessPolicy`로, tenant/작성자/idempotency scope/audit actor 주입은 `DmsOperationContext`와 scoped facade로 표현한다. `clear_all_data()`와 `initialize_for_data_load()`는 문서 하나의 delete와 다른 전역 reset이며, 부분 실패 시 `DataResetError.result`와 `failed_stores`를 보존한다. operation observer와 recovery audit hook은 best-effort라서 callback 실패가 본래 작업 결과를 바꾸지 않는다. ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md] ^[raw/articles/dms-core-wiki-examples-v0.7.0.md]

## Error handling focus

서비스는 validation, duplicate document, configuration, storage, consistency, not-found error를 구분해 처리해야 한다. 특히 `chunk_size <= 0`은 `ValidationError`이며, stream/SDK close 누락은 리소스 정리 문제를 만들 수 있다. ^[raw/articles/dms-core-examples-v0.2.0.md]

## Sources

- `raw/articles/dms-core-api-v0.2.0.md`
- `raw/articles/dms-core-api-v0.3.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/dms-core-wiki-configuration-v0.7.0.md`
- `raw/articles/dms-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-config-v0.3.0.md`
- `raw/articles/dms-core-examples-v0.2.0.md`
- `raw/articles/dms-core-examples-v0.3.0.md`
