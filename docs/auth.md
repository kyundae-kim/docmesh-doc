# Authentication Design

## 1. 목적

본 문서는 `fastapi-core` 호스트 위에서 DMS 서비스 모드를 운영할 때의 인증 설계를 정의한다.

핵심 목표는 다음과 같다.

- `fastapi-core`의 기존 인증 체계를 재사용한다.
- DMS SDK의 선택적 auth helper 계약을 유지한다.
- 서비스 모드의 요청 인증과 SDK helper 인증을 분리해 이해한다.
- `created_by`와 사용자 정보를 안전하게 연결한다.

---

## 2. 인증 책임 분리

## 2.1 요청 인증

HTTP 요청 수준 인증은 `fastapi-core`가 담당한다.

예시 dependency:

- `get_current_user`
- `require_permissions(...)`

이 계층의 목적:

- Bearer token 검증
- 현재 사용자 식별
- 역할(role) / 스코프(scope) 기반 접근 제어

## 2.2 SDK auth helper

DMS SDK의 auth helper는 선택적 기능이다.

지원 계약:
- `fetch_access_token(scope=None)`
- `get_authenticated_user(token)`

이 계층의 목적:

- service-to-service 토큰 발급
- SDK 소비 코드에서 토큰 해석/사용자 추출 보조

즉, **HTTP 요청 인증과 SDK auth helper는 같은 인증 도메인을 사용하지만 역할은 다르다.**

---

## 3. 현재 인터페이스 차이

DMS가 기대하는 auth service 프로토콜은 다음과 같다.

- `fetch_access_token(...)`
- `extract_user_info(token)`

반면 `fastapi-core` auth provider는 현재 아래 중심 메서드를 가진다.

- `authenticate(...)`
- `refresh_access_token(...)`
- `decode_token(...)`
- `decode_token_insecure(...)`
- `introspect_token(...)`
- `to_user(...)`

따라서 서비스 모드에서는 **adapter가 필요**하다.

---

## 4. 권장 adapter 설계

## 4.1 역할

`FastapiCoreAuthAdapter`는 `fastapi-core` provider를 DMS `AuthService` 프로토콜에 맞춘다.

## 4.2 최소 인터페이스

```python
class FastapiCoreAuthAdapter:
    def __init__(self, provider):
        self.provider = provider

    def fetch_access_token(self, *, scope: str | None = None):
        ...

    def extract_user_info(self, token: str):
        ...
```

## 4.3 동작 원칙

### fetch_access_token

- provider의 password grant 또는 service credential 경로를 사용한다.
- DMS SDK가 기대하는 결과 타입으로 정규화한다.
- provider 설정 오류는 `ConfigurationError`로 이어져야 한다.
- 인증 실패는 `AuthenticationError`로 이어져야 한다.

### extract_user_info

- token 검증 또는 introspection 수행
- provider의 `to_user(...)`로 사용자 정보 변환
- DMS SDK가 기대하는 사용자 타입으로 정규화

---

## 5. 엔드포인트 보호 정책

## 5.1 공개 가능 엔드포인트

운영 정책에 따라 아래는 공개 또는 내부 전용으로 둘 수 있다.

- `GET /health/liveness`
- `GET /health/readiness`
- `GET /documents/health`

## 5.2 인증 필요 엔드포인트

아래는 기본적으로 인증 필요 엔드포인트로 간주한다.

- `POST /documents`
- `GET /documents/{document_id}/metadata`
- `GET /documents/{document_id}/content`
- `GET /documents/{document_id}/stream`
- `DELETE /documents/{document_id}`

## 5.3 권한 예시

권장 예시:

| 작업 | 예시 권한 |
|---|---|
| 업로드 | `documents:write` |
| metadata 조회 | `documents:read` |
| content 다운로드 | `documents:read` |
| 삭제 | `documents:delete` |
| health detail 조회 | `documents:admin` |

실제 role/scope 명명은 플랫폼 정책에 따른다.

---

## 6. created_by 연계 정책

## 6.1 기본 원칙

`created_by`는 다음 우선순위로 결정한다.

1. 내부 정책상 서버 강제 주입값
2. 인증 사용자 정보 (`user.sub`, `user.username`, `user.email` 등)
3. 명시 요청 필드
4. 없으면 `null`

권장 정책은 **클라이언트가 준 `created_by`보다 인증 사용자 정보를 우선**하는 것이다.

## 6.2 권장 저장 값

권장 저장 후보:

- `sub` : 가장 안정적인 사용자 식별자
- `preferred_username` 또는 `username` : 사람이 읽기 쉬운 보조 값

단일 문자열 필드만 유지한다면 `sub`를 우선 권장한다.

---

## 7. 오류 처리

## 7.1 인증 실패

- 잘못된/만료된 token → `401 Unauthorized`
- 필요한 권한 부족 → `403 Forbidden`
- auth provider 미설정 → `500 Internal Server Error` 또는 startup 실패

## 7.2 SDK helper 오류

- auth adapter 미조립 상태에서 helper 호출 → `ConfigurationError`
- 토큰 검증 실패 → `AuthenticationError`
- provider 설정 오류 → `ConfigurationError`

---

## 8. 보안 요구사항

- raw access token / refresh token을 로그에 남기지 않는다.
- document content를 인증 디버깅 로그에 포함하지 않는다.
- insecure decode 모드는 로컬 개발/테스트 이외에는 기본 비활성 권장
- service credential 사용 시 secret은 환경/시크릿 저장소에서 관리

---

## 9. 테스트 포인트

최소 테스트 항목:

- 인증 없는 모드에서 공개 엔드포인트 접근 가능 여부
- 보호 엔드포인트의 미인증 접근 차단
- 권한 부족 시 403
- auth adapter의 token → user 변환
- `created_by`가 인증 사용자 정보와 정렬되는지 검증
- SDK helper 비활성/활성 경로 검증

---

## 10. 결정 요약

- HTTP 요청 인증은 `fastapi-core`가 담당한다.
- DMS는 요청 인증을 재구현하지 않는다.
- DMS SDK helper는 adapter를 통해 `fastapi-core` auth provider와 연결한다.
- 서비스 모드에서는 인증 사용자 정보가 `created_by`와 연결될 수 있어야 한다.
- 로그와 오류 모델은 토큰/문서 본문 유출 없이 유지되어야 한다.
