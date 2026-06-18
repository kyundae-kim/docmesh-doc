---
title: Settings
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [schema, validation, api, service]
sources: [raw/articles/docmesh-py-core-api-2026-06-18.md, raw/articles/docmesh-py-core-config-2026-06-18.md]
confidence: medium
---

# Settings

`Settings`는 `docmesh-py-core`의 최상위 설정 객체로, 환경변수에서 읽어들인 공통/서비스별 설정을 구조화해 제공한다.

## 역할
- `load_settings(env)`의 반환 타입이다.
- 공통 설정과 서비스별 설정을 한 객체 아래 모은다.
- 애플리케이션 시작 시 1회 로드/검증된 설정을 이후 전체 수명주기 동안 재사용하게 한다.

## 주요 필드
- `settings.common`
- `settings.keycloak`
- `settings.postgres`
- `settings.sqlite`
- `settings.minio`
- `settings.milvus`
- `settings.ollama`
- `settings.langfuse`
- `settings.nats`

## 설정 문서에서 확인된 운영 원칙
- 모든 설정은 환경변수에서 읽는다.
- 공백 문자열은 값이 없는 것으로 간주한다.
- boolean 값은 대소문자와 무관하게 `true` / `false`로 해석한다.
- 숫자형 값은 허용 범위를 검증한다.
- 로컬/개발/스테이징/운영 구분은 코드가 아니라 환경변수로 한다.

## 문서 서버에서의 의미
문서/메타데이터 REST API는 스토리지, 인증, 비동기 메시징, 관측 도구를 함께 사용하므로 설정 객체가 인프라 계약의 중심이 된다. 이 설정은 [[sdk-consumption-pattern]]의 시작점이며, 실제 앱 조립은 [[fastapi-sdk-lifespan-integration]]과 [[service-factory-registry]]를 통해 이뤄진다.

## 관련 페이지
- [[sdk-consumption-pattern]]
- [[service-factory-registry]]
- [[environment-variable-configuration]]
