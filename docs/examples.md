# API 사용 예시

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | 구현 기준 |
| 버전 | 0.2 |
| 최종 코드 대조일 | 2026-07-18 |
| 참조 문서 | [API Reference](api.md), [설정 정의서](config.md) |

이 문서는 현재 구현을 호출하는 Bash/`curl` 예시다. 아래 `<access-token>`을 실제 bearer token으로 바꾼다.

## 1. 환경 준비

```bash
export BASE_URL='https://dms.example.com/api'
export USERNAME='alice'
export PASSWORD='<replace-with-password>'
export DOCUMENT_FILE='./contract.pdf'
export DOCUMENT_ID='contract-2026-0001'
export CORRELATION_ID='example-20260718-001'
```

`ROOT_PATH`가 없는 배포는 `BASE_URL`에서 `/api`를 제거한다. secret과 token을 source code나 로그에 남기지 않는다.

## 2. Health (`EX-OPS-001`, `EX-OPS-002`)

```bash
curl --fail --silent --show-error "$BASE_URL/health/liveness" | jq
curl --silent --show-error \
  "$BASE_URL/health/readiness" | jq
```

첫 번째 호출은 `EX-OPS-001`/`API-OPS-001`, 두 번째 호출은 `EX-OPS-002`/`API-OPS-002`다.

liveness는 프로세스 생존만 나타낸다. readiness의 필수 `dms` check는 `sdk.check_health().ok`를 평가하며 기본 응답에는 PostgreSQL·MinIO 하위 detail 대신 `details.dms`가 표시된다.

## 3. 인증 (`EX-AUTH-001`, `EX-AUTH-002`)

```bash
curl --fail --silent --show-error \
  --request POST "$BASE_URL/token" \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode "username=$USERNAME" \
  --data-urlencode "password=$PASSWORD" \
  | jq

curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  "$BASE_URL/user" | jq
```

token 발급은 `EX-AUTH-001`/`API-AUTH-001`, 현재 사용자 조회는 `EX-AUTH-002`/`API-AUTH-002`다.

hard delete에는 `/user` 응답의 `roles`에 `document:delete:hard`가 필요하다.

## 4. 문서 생성

### 4.1 지정 ID와 metadata (`EX-DOC-001`)

```bash
curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --oauth2-bearer TOKEN_VALUE \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form "document_id=$DOCUMENT_ID" \
  --form-string 'metadata={"category":"contract","retention_policy":"standard"}' \
  | jq
```

성공하면 201, `Location: /documents/{document_id}`, 공개 metadata를 반환한다. 현재 `Location`에는 `ROOT_PATH`가 붙지 않는다. `created_by` form field는 없으며 인증 사용자의 `sub`가 기록된다.

### 4.2 SDK 생성 ID (`EX-DOC-002`)

`document_id` form field를 생략하면 SDK가 ID를 생성한다.

```bash
curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --oauth2-bearer TOKEN_VALUE \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form-string 'metadata={"category":"contract"}' \
  | jq
```

### 4.3 checksum 지정 (`EX-DOC-003`)

```bash
CHECKSUM="$(sha256sum "$DOCUMENT_FILE" | cut --delimiter=' ' --fields=1)"

curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --oauth2-bearer TOKEN_VALUE \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form "checksum=$CHECKSUM" \
  | jq
```

## 5. 조회와 다운로드

### 5.1 목록과 metadata (`EX-DOC-004`, `EX-DOC-005`)

```bash
curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  "$BASE_URL/documents?offset=0&limit=100&status=available" | jq

curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

`status`는 `uploaded`, `available`, `deleting`, `deleted`, `failed` 중 하나다. `storage_key`는 응답에 포함되지 않는다.

### 5.2 전체 콘텐츠 (`EX-DOC-006`)

```bash
curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  --output "${DOCUMENT_ID}.content" \
  "$BASE_URL/documents/$DOCUMENT_ID/content"
```

이 endpoint는 content bytes를 한 번에 응답 객체에 적재한다.

### 5.3 Streaming download (`EX-DOC-007`)

```bash
mkdir --parents ./downloads
curl --fail --silent --show-error --location \
  --oauth2-bearer TOKEN_VALUE \
  --remote-name \
  --remote-header-name \
  --output-dir ./downloads \
  "$BASE_URL/documents/$DOCUMENT_ID/download?chunk_size=65536"
```

`chunk_size`는 1 이상의 integer다. 잘못된 값은 `400 VALIDATION_ERROR`다.

## 6. 삭제

### 6.1 Soft delete (`EX-DOC-008`)

```bash
curl --fail --silent --show-error \
  --request DELETE \
  --oauth2-bearer TOKEN_VALUE \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

현재 SDK의 soft delete는 object를 삭제하고 metadata를 `deleted` 상태로 보존한다. 이후 metadata/content/download route는 `404 DOCUMENT_NOT_FOUND`를 반환한다.

### 6.2 Hard delete (`EX-DOC-009`)

```bash
curl --fail --silent --show-error \
  --request DELETE \
  --oauth2-bearer TOKEN_VALUE \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  "$BASE_URL/documents/$DOCUMENT_ID?hard=true" | jq
```

권한이 없으면 문서 존재 여부를 확인하기 전에 `403 FORBIDDEN`이 반환될 수 있다. 성공하면 object와 metadata 행을 제거한다.

## 7. 오류 확인

`curl --fail`은 오류 body 확인에 불편하므로 진단 시 status, header, body를 분리한다.

```bash
ERROR_BODY="$(mktemp)"
ERROR_HEADERS="$(mktemp)"

HTTP_STATUS="$(curl --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  --dump-header "$ERROR_HEADERS" \
  --output "$ERROR_BODY" \
  --write-out '%{http_code}' \
  "$BASE_URL/documents/not-found-example")"

printf 'HTTP status: %s\n' "$HTTP_STATUS"
grep --ignore-case '^X-Correlation-ID:' "$ERROR_HEADERS" || true
jq < "$ERROR_BODY"
rm --force "$ERROR_BODY" "$ERROR_HEADERS"
```

| 코드 | 대응 |
| --- | --- |
| `VALIDATION_ERROR` | 입력값을 수정하고 재요청 |
| `UNAUTHENTICATED` | token 재발급 또는 header 확인 |
| `FORBIDDEN` | 권한 확인 또는 soft delete 사용 |
| `DOCUMENT_NOT_FOUND` | ID와 삭제 상태 확인 |
| `DOCUMENT_ALREADY_EXISTS` | 다른 ID 사용 |
| `METADATA_STORE_ERROR`, `OBJECT_STORAGE_ERROR` | readiness 확인 후 운영자에게 correlation ID 전달 |
| `DOCUMENT_CONSISTENCY_ERROR` | 자동 재시도보다 운영 조사 우선 |

## 8. API 문서와 hosting 예시

### 8.1 OpenAPI schema (`EX-SYS-001`)

```bash
curl --fail --silent --show-error "$BASE_URL/openapi.json" | jq '.paths | keys'
```

### 8.2 Swagger UI와 ReDoc (`EX-SYS-002`, `EX-SYS-003`)

Browser에서 `$BASE_URL/docs`(`API-SYS-002`) 또는 `$BASE_URL/redoc`(`API-SYS-004`)을 연다. Swagger UI의 OAuth2 flow는 `$BASE_URL/docs/oauth2-redirect`(`API-SYS-003`)를 callback으로 간접 사용한다. 운영에서 문서 UI를 외부에 공개하지 않는 경우 reverse proxy에서 세 경로와 `/openapi.json`을 함께 제한한다.

### 8.3 애플리케이션 factory 주입 (`EX-HOST-001`, `EX-HOST-002`)

운영 기본 조립은 process environment를 DMS factory에 전달한다.

```python
from docmesh_doc.application import create_application

app = create_application()
```

테스트 또는 상위 host가 SDK와 앱 설정의 lifecycle을 명시적으로 소유하려면 factory parameter로 주입한다. 주입된 SDK도 managed resource가 종료한다.

```python
from fastapi_core.config import AppConfig

from docmesh_doc.application import create_application

app = create_application(
    sdk,
    config=AppConfig(enabled_services=[], required_services=[]),
    include_auth_router=False,
)
```

### 8.4 ASGI 실행 (`EX-HOST-003`)

```bash
uv run fastapi run docmesh_doc/main.py
```

`pyproject.toml`의 FastAPI entrypoint는 `docmesh_doc.main:app`이다. 실행 전에 [설정 정의서](config.md)의 필수 저장소·인증 설정을 process environment에 주입한다.

## 9. 공개 API 예시 추적성

| API ID | Example ID | 위치 | 설정 그룹 |
| --- | --- | --- | --- |
| `API-AUTH-001` | `EX-AUTH-001` | §3 token 발급 | `CFG-AUTH`, `CFG-HTTP` |
| `API-AUTH-002` | `EX-AUTH-002` | §3 현재 사용자 | `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-001` | `EX-DOC-001` ~ `EX-DOC-003` | §4 | `CFG-DMS`, `CFG-STORAGE`, `CFG-AUTH`, `CFG-HTTP` |
| `API-DOC-002` | `EX-DOC-004` | §5.1 목록 | 동일 |
| `API-DOC-003` | `EX-DOC-005` | §5.1 metadata | 동일 |
| `API-DOC-004` | `EX-DOC-006` | §5.2 | 동일 |
| `API-DOC-005` | `EX-DOC-007` | §5.3 | 동일 |
| `API-DOC-006` | `EX-DOC-008` | §6.1 | 동일 |
| `API-DOC-007` | `EX-DOC-009` | §6.2 | 동일 + Keycloak `document:delete:hard` role |
| `API-OPS-001` | `EX-OPS-001` | §2 첫 번째 호출 | `CFG-HTTP` |
| `API-OPS-002` | `EX-OPS-002` | §2 두 번째 호출 | `CFG-DMS`, `CFG-STORAGE`, `CFG-READINESS` |
| `API-SYS-001` | `EX-SYS-001` | §8.1 | `CFG-HTTP` |
| `API-SYS-002`, `API-SYS-003`, `API-SYS-004` | `EX-SYS-002`, `EX-SYS-003` | §8.2 | `CFG-HTTP`, `CFG-AUTH` |
| `API-HOST-001` | `EX-HOST-001`, `EX-HOST-002` | §8.3 | 모든 설정 그룹 |
| `API-HOST-002` | `EX-HOST-003` | §8.4 | 모든 설정 그룹 |

API 계약과 구현·테스트 근거는 [API Reference §7](api.md#7-공개-api-추적성), 변수별 상세는 [설정 정의서](config.md)를 참조한다.
