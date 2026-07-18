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

## 2. Health

```bash
curl --fail --silent --show-error "$BASE_URL/health/liveness" | jq
curl --silent --show-error \
  "$BASE_URL/health/readiness" | jq
```

liveness는 프로세스 생존만 나타낸다. readiness의 필수 `dms` check는 `sdk.check_health().ok`를 평가하며 기본 응답에는 PostgreSQL·MinIO 하위 detail 대신 `details.dms`가 표시된다.

## 3. 인증

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

hard delete에는 `/user` 응답의 `roles`에 `document:delete:hard`가 필요하다.

## 4. 문서 생성

### 4.1 지정 ID와 metadata

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

### 4.2 SDK 생성 ID

`document_id` form field를 생략하면 SDK가 ID를 생성한다.

```bash
curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --oauth2-bearer TOKEN_VALUE \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form-string 'metadata={"category":"contract"}' \
  | jq
```

### 4.3 checksum 지정

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

### 5.1 목록과 metadata

```bash
curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  "$BASE_URL/documents?offset=0&limit=100&status=available" | jq

curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

`status`는 `uploaded`, `available`, `deleting`, `deleted`, `failed` 중 하나다. `storage_key`는 응답에 포함되지 않는다.

### 5.2 전체 콘텐츠

```bash
curl --fail --silent --show-error \
  --oauth2-bearer TOKEN_VALUE \
  --output "${DOCUMENT_ID}.content" \
  "$BASE_URL/documents/$DOCUMENT_ID/content"
```

이 endpoint는 content bytes를 한 번에 응답 객체에 적재한다.

### 5.3 Streaming download

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

### 6.1 Soft delete

```bash
curl --fail --silent --show-error \
  --request DELETE \
  --oauth2-bearer TOKEN_VALUE \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

현재 SDK의 soft delete는 object를 삭제하고 metadata를 `deleted` 상태로 보존한다. 이후 metadata/content/download route는 `404 DOCUMENT_NOT_FOUND`를 반환한다.

### 6.2 Hard delete

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
