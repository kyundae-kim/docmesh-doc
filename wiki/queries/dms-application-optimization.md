---
title: dms application optimization
created: 2026-07-26
updated: 2026-08-02
type: query
tags: [dms-core, dms, integration, performance, testing]
sources: [raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-examples-v0.7.0.md]
confidence: high
---

# dms application optimization

## 결론

현재 adapter는 DMS의 public metadata, cursor page, explicit delete, managed SDK lifecycle과 동기 stream 계약을 이미 올바르게 사용한다. 이번 최적화는 이 구조를 유지하면서 본문 전송의 메모리 상한과 통합 검증 안정성을 강화했다. DMS의 일반 실행 원칙은 [[dms-core-usage-patterns]], object/metadata 정합성과 공개 경계는 [[dms-core-document-lifecycle]]에 정리되어 있다.

## 적용한 최적화

- `GET /documents/{document_id}/content`도 `get_document_content_stream()`과 `StreamingResponse`를 사용한다. 전체 object를 `bytes`로 적재하지 않고 inline disposition을 유지한다.
- inline content와 attachment download가 하나의 context-managed stream response 경계를 공유한다. 정상 완료 또는 generator 종료 시 `DocumentContentStream.close()`가 실행된다.
- 공개 `chunk_size`는 1 byte 이상 8 MiB 이하로 제한한다. 비정상적으로 큰 caller-controlled read buffer는 DMS SDK 호출 전에 400으로 거부한다.
- 실제 PostgreSQL·MinIO 통합 테스트 marker를 테스트 모듈에 배치해 `-m 'not integration'` 분리가 실제로 동작하게 했다.
- 통합 테스트의 document ID fixture가 `finally` 성격의 best-effort hard delete를 수행한다. 중간 assertion 실패가 PostgreSQL metadata나 MinIO object를 남기지 않는다.
- 통합 `Location` 검증은 빈 값과 prefix 양쪽에서 동작하도록 application `root_path`를 정규화한다.

## 유지한 경계와 후속 후보

- 업로드는 caller-owned `UploadFile.file`을 동기 `upload_document_stream()`에 전달한다. async upload 전환은 연결 취소와 입력 stream ownership 테스트를 갖춘 별도 변경으로 남긴다.
- DMS environment factory에는 `max_file_size` 입력이 없으므로 HTTP/proxy 업로드 상한의 설정 소유권을 별도로 결정해야 한다.
- `Idempotency-Key`를 공개 API에 추가할 경우 서버가 인증 subject 기반 scope를 결정하고 known-size stream에는 checksum을 요구해야 한다.
- DMS 권장 HTTP projection은 제품 error envelope와 삭제 존재 은닉 정책을 유지한 상태에서 별도 contract 변경으로 검토한다.

## 검증

2026-07-26 검증 당시 설치된 `dms 0.6.0`과 실제 PostgreSQL·MinIO 환경에서 전체 suite가 `61 passed, 1 skipped`로 통과했다. integration selection은 `3 passed, 1 skipped, 58 deselected`였고, unit selection에서는 integration 4개가 정상적으로 제외되었다. 남은 warning은 upstream FastAPI test client의 `httpx2` 전환 경고다. 이 query는 해당 runtime 검증 결과를 보존하며, v0.6.0 raw source set 자체는 삭제되었다.
