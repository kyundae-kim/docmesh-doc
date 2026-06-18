---
title: EnvConfig
created: 2026-06-18
updated: 2026-06-18
type: entity
tags: [schema, validation, api, configuration]
sources: [raw/articles/fastapi-core-api-2026-06-18.md, raw/articles/fastapi-core-config-2026-06-18.md]
confidence: medium
---

# EnvConfig

`EnvConfig`는 `fastapi-core` 애플리케이션에서 런타임 환경설정을 담는 상태 객체다.

## 역할
- `app.state.config`에 저장되는 표준 설정 객체다.
- `get_config()`가 기본적으로 이 객체를 조회/생성한다.
- `create_app()`와 dependency 계층이 공통으로 참조하는 진입점이다.

## 사용 계약
- `set_config(app, config)`로 주입 가능
- `get_config(request)`는 state에 없으면 `EnvConfig()`를 생성해 저장
- `set_auth_provider`, `set_db_engine`, `set_minio_client` 등 다수 dependency setter가 `config=` 경로를 받을 수 있다

## 설정 문서에서 확인된 세부 규칙
- `pydantic-settings` 기반이며 `env_nested_delimiter="__"`를 사용한다.
- 기본 `.env` 파일은 루트의 `.env`다.
- 알 수 없는 환경변수는 `extra="ignore"`로 무시한다.
- `CONFIG_PATH` 기본값은 `.devcontainer/config.yaml`이다.
- `DB__URL`이 설정되면 개별 DB 필드보다 우선한다.
- `NATS__SERVERS`는 콤마 구분 문자열이며 `server_list` 계산 프로퍼티로 정규화된다.

## 문서 서버에서의 의미
문서 서버에서 root path, Keycloak/DB/MinIO 등 인프라 연결, readiness 구성은 모두 이 런타임 설정과 엮인다. [[service-settings]]와 함께 앱 생성과 lifespan 초기화의 두 축을 이룬다.

## 관련 페이지
- [[service-settings]]
- [[fastapi-core-dependency-policy]]
- [[application-lifecycle-and-readiness]]
- [[fastapi-core-layered-configuration]]
