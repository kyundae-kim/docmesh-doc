---
title: fastapi-core application optimization
created: 2026-07-26
updated: 2026-07-26
type: query
tags: [fastapi-core, fastapi, integration, performance, testing]
sources: [raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-examples-v0.6.0.md]
confidence: high
---

# fastapi-core application optimization

## 결론

현재 소비 애플리케이션의 핵심 구조는 이미 `fastapi-core 0.6.0`의 권장 경계와 일치한다. 문서 router, typed DMS resource, readiness와 error mapper를 하나의 `DomainModule`로 묶고 package가 lifecycle을 소유하게 한 구조를 유지하는 것이 대규모 재조립보다 안전하다. 관련 조립 원칙은 [[fastapi-core-app-assembly]], 공개 사용 패턴은 [[fastapi-core-usage-patterns]]에 정리되어 있다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

## 적용한 최적화

- 업로드 `Location`을 하드코딩하지 않고 FastAPI route reverse lookup으로 생성한다. 이 경로는 `AppConfig.root_path`를 반영하므로 `/dms` 같은 reverse-proxy prefix에서도 올바르다.
- document router가 제품 오류 envelope를 OpenAPI의 `400` 및 fallback response로 선언한다. 이 선언은 runtime에서 400으로 정규화되는 validation 오류와 맞지 않던 기본 422 문서를 제거한다.
- `fastapi_core.testing.assert_openapi_contract`로 document path, method, OAuth2 scheme, operation-ID 고유성과 schema reference를 검증하고, 제품 오류 response도 별도로 검사한다. ^[raw/articles/fastapi-core-wiki-examples-v0.6.0.md]
- 조건부 async 권한 검사를 수행하는 delete route는 동기 DMS SDK 삭제 I/O를 FastAPI thread pool로 넘겨 event loop를 차단하지 않는다.

## 유지한 경계와 후속 후보

- DMS SDK는 계속 required `ManagedResource`로 관리하고 `ResourceKey` dependency로만 접근한다.
- readiness timeout은 `AppConfig`의 per-check/overall 설정으로 배포에서 명시해야 한다. 고정 timeout을 adapter에 중복 하드코딩하지 않는다.
- sync DMS 호출의 async 전환은 stream 완료·예외·취소 cleanup test를 먼저 갖춘 별도 변경으로 남긴다.

## 검증

`fastapi-core 0.6.0`과 `dms 0.6.0` 설치 환경에서 전체 suite가 `59 passed, 1 skipped`로 통과했다. 남은 warning은 upstream FastAPI test client의 `httpx2` 전환 경고다.
