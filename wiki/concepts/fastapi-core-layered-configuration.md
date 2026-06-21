---
title: FastAPI Core Layered Configuration
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [configuration, architecture, convention, validation]
sources: [raw/articles/fastapi-core-config-2026-06-18.md, raw/articles/fastapi-core-api-2026-06-18.md]
confidence: medium
---

# FastAPI Core Layered Configuration

`fastapi-core`의 설정 체계는 두 레이어로 나뉜다: 환경변수 기반 `EnvConfig`와 YAML 기반 `ServiceSettings`.

## 두 레이어의 역할 분리
- `EnvConfig`: 외부 서비스 접속 정보, 실행 환경, 로깅, `root_path`, `config_path`
- `ServiceSettings`: CORS, 인증 정책, readiness 정책, lifecycle 정책

## 핵심 계약
- `EnvConfig`는 `pydantic-settings` 기반이며 `env_nested_delimiter="__"`를 사용한다.
- 기본 `.env` 파일은 루트의 `.env`다.
- 알 수 없는 환경변수는 `extra="ignore"`로 무시한다.
- `ServiceSettings.from_yaml(path)`는 YAML 파일이 없어도 예외 대신 기본값을 사용한다.
- 기본 YAML 경로는 `CONFIG_PATH=.devcontainer/config.yaml`이다.

## 설계 의미
이 구조는 비밀값과 인프라 접속 정보는 환경변수에 두고, 서비스 정책은 YAML로 분리하게 만든다. 문서/메타데이터 서버처럼 배포 환경마다 연결 정보가 바뀌지만 인증/health/lifecycle 정책은 버전관리하고 싶은 경우 특히 유용하다.

## 관련 페이지
- [[env-config]]
- [[service-settings]]
- [[application-lifecycle-and-readiness]]
