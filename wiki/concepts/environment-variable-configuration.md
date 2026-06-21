---
title: Environment Variable Configuration
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [schema, validation, security, convention]
sources: [raw/articles/docmesh-py-core-config-2026-06-18.md, raw/articles/fastapi-core-config-2026-06-18.md]
confidence: medium
---

# Environment Variable Configuration

환경변수 기반 설정은 이 위키의 문서/메타데이터 서버 설계에서 공통 기반이다. `docmesh-py-core`와 `fastapi-core` 모두 환경변수를 인프라 접속 정보와 런타임 제어의 기본 진입점으로 사용한다.

## 공통 원칙
- URL, 계정, 비밀번호, 토큰, secret key를 코드에 하드코딩하지 않는다.
- 공백 문자열은 값이 없는 것으로 간주한다.
- boolean은 `true` / `false`로 해석한다.
- 숫자형 설정은 허용 범위를 검증한다.
- 민감정보는 Secret Manager, CI secret, 배포 플랫폼의 secret 주입 기능을 사용한다.

## docmesh-py-core 관점
- PostgreSQL은 `POSTGRES_DSN`이 있으면 개별 host/user/password보다 우선한다.
- SQLite는 `SQLITE_PATH=:memory:`를 허용하며 파일 기반 경로 존재성을 검증한다.
- Langfuse는 `LANGFUSE_ENABLED=false`일 때 optional로 비활성화될 수 있다.
- NATS는 인증 방식을 user/password, token, creds file 중 하나로 제한한다.

## fastapi-core 관점
- `EnvConfig`는 `pydantic-settings` 기반이며 `env_nested_delimiter="__"`를 사용한다.
- 기본 `.env` 파일은 루트의 `.env`다.
- 알 수 없는 환경변수는 `extra="ignore"`로 무시한다.
- `DB__URL`이 설정되면 나머지 DB 필드를 무시하고 직접 DSN을 사용한다.
- `NATS__SERVERS`는 콤마 구분 문자열이며 `server_list` 계산 프로퍼티로 정규화된다.

## 문서 서버에서의 의미
문서 바이너리와 메타데이터를 분리 저장하는 시스템은 DB, 객체 저장소, 인증, 이벤트 시스템의 연결 정보를 안전하게 주입해야 한다. 이 규칙은 [[settings]]와 [[env-config]]를 신뢰 가능한 진입점으로 만들고, 민감정보 처리 측면에서는 [[sensitive-data-masking]]과 직접 연결된다.

## 관련 페이지
- [[settings]]
- [[env-config]]
- [[sensitive-data-masking]]
- [[fastapi-core-layered-configuration]]
