---
title: FastAPI Core Dependency Policy
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [api, architecture, convention, async]
sources: [raw/articles/fastapi-core-api-2026-06-18.md, raw/articles/fastapi-core-config-2026-06-18.md]
confidence: medium
---

# FastAPI Core Dependency Policy

`fastapi-core`는 FastAPI dependency를 모두 함수형 API로 두고, 대부분의 getter/setter를 registry-backed 서비스 해석과 app state 캐시에 연결한다.

## 핵심 규칙
- 공개 dependency는 함수형 API다.
- `Get*Dependency` callable class와 `get_* = Get*Dependency()` alias는 공개 API가 아니다.
- 대부분의 dependency는 `docmesh_bridge`를 통해 registry-backed 서비스 해석을 사용한다.
- 예외적으로 `async_milvus_client`는 dependency 계층에서도 `create_async_milvus_client(config.milvus)`를 직접 사용한다.

## 표준 state 키
- `app.state.config`
- `app.state.settings`
- `app.state.auth_provider`
- `app.state.db_engine`
- `app.state.minio_client`
- `app.state.milvus_client`
- `app.state.async_milvus_client`
- `app.state.ollama_client`
- `app.state.langfuse_client`
- `app.state.nats_client`

## 설정 문서에서 보강된 의미
이 dependency 계층은 `EnvConfig`와 `ServiceSettings`의 이중 설정 모델 위에서 동작한다. 또한 `use_docmesh_registry`는 registry 사용 자체를 끄는 플래그가 아니라 startup에서 registry를 선행 부트스트랩할지까지 포함하는 lifecycle 정책이다.

## 설계 의미
이 정책은 라우터가 직접 클라이언트를 생성하지 않고, 의존성을 상태와 registry 경계 뒤로 숨기게 만든다. 문서/메타데이터 REST API에서 테스트 대체, startup 초기화, 캐시된 서비스 재사용을 일관되게 하기 좋다.

## 관련 페이지
- [[env-config]]
- [[service-settings]]
- [[application-lifecycle-and-readiness]]
- [[fastapi-core-layered-configuration]]
