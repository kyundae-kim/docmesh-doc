---
title: Sensitive Data Masking
created: 2026-06-18
updated: 2026-06-18
type: concept
tags: [logging, privacy, auth, convention]
sources: [raw/articles/docmesh-py-core-api-2026-06-18.md, raw/articles/docmesh-py-core-config-2026-06-18.md, raw/articles/dms-core-sdk-interface-2026-06-18.md]
confidence: medium
---

# Sensitive Data Masking

`mask_sensitive_value(raw)`는 DSN, URL, query string, 일반 문자열에서 password, secret, token, api_key 계열 민감정보를 마스킹하는 보안 유틸리티다.

## 권장 사용 시점
- 로그 출력 전
- 예외 메시지 노출 전
- 운영 화면에 연결 정보나 오류를 보여주기 전

## 설정 문서에서 강화된 운영 규칙
- `.env` 파일을 쓰더라도 실제 비밀정보 파일은 git에 포함하지 않는다.
- 예외 메시지에 비밀번호, secret, token, 전체 DSN/URI를 그대로 포함하지 않는다.
- DSN/URI 출력이 필요하면 사용자명/비밀번호/token/query 민감값을 마스킹한다.
- Access Token, Refresh Token, ID Token 원문은 로그/트레이싱에 기록하지 않는다.

## SDK 인터페이스에서 보강된 로깅 규칙
- structured logging의 extra field는 `dms_` prefix를 사용한다.
- 예: `dms_event`, `dms_document_id`, `dms_storage_key`, `dms_duration_ms`, `dms_error_type`
- raw token과 document content는 로그에 남기지 않는다.

## 문서 서버에서의 의미
문서/메타데이터 서버는 DB DSN, MinIO credential, Keycloak token, 내부 API key를 다룰 수 있으므로 예외/로그 경로에서 비밀값 누출을 막는 규칙이 중요하다. 인증 계층은 [[keycloak-auth-service]]와 연결되고, 전체 초기화/운영 흐름은 [[sdk-consumption-pattern]] 안에서 이 유틸리티를 공통적으로 활용할 수 있다. 문서 도메인에서는 [[document-management-sdk]]와 [[document-storage-key-policy]]가 추가로 어떤 필드를 로그에 남기고 남기지 말아야 하는지 경계를 정해준다. 설정 주입 원칙은 [[environment-variable-configuration]]과 함께 봐야 한다.

## 관련 페이지
- [[keycloak-auth-service]]
- [[sdk-consumption-pattern]]
- [[document-management-sdk]]
- [[document-storage-key-policy]]
- [[environment-variable-configuration]]
