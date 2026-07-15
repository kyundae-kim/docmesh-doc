# API 사용 예시

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 참조 문서 | [API Reference](api.md), [SRS](srs.md) |

이 문서는 DocMesh Document Service API의 대표적인 호출 흐름을 `curl`로 보여 준다. 세부 request/response schema와 모든 오류 코드는 [API Reference](api.md)를 따른다.

## 1. 사전 준비

예시는 Bash, `curl`, `jq`를 사용한다. API는 PostgreSQL에 metadata를, MinIO에 문서 본문을 저장하는 구성에서 실행 중이어야 한다.

```bash
export BASE_URL='https://dms.example.com/api'
export USERNAME='alice'
export PASSWORD='<replace-with-password>'
export DOCUMENT_FILE='./contract.pdf'
export DOCUMENT_ID='contract-2026-0001'
export CORRELATION_ID='example-20260711-001'
```

`ROOT_PATH`를 사용하지 않는 배포에서는 `BASE_URL`에서 `/api`를 제거한다. password와 access token은 shell history, source code, 로그에 남기지 않는다.

## 2. 서비스 상태 확인

### 2.1 Liveness 확인

프로세스가 HTTP 요청을 처리할 수 있는지만 확인한다. PostgreSQL과 MinIO 상태는 확인하지 않는다.

```bash
curl --fail --silent --show-error \
  --header 'Accept: application/json' \
  "$BASE_URL/health/liveness" | jq
```

성공 예시:

```json
{
  "status": "ok",
  "details": null
}
```

### 2.2 Readiness 확인

Readiness는 PostgreSQL과 MinIO를 필수 의존성으로 검사한다. 배포나 작업 실행 전에는 liveness보다 readiness 결과를 기준으로 한다.

```bash
curl --silent --show-error \
  --header 'Accept: application/json' \
  --write-out '\nHTTP status: %{http_code}\n' \
  "$BASE_URL/health/readiness" | jq
```

정상 상태는 200 및 `status: "ok"`이다. PostgreSQL 또는 MinIO가 준비되지 않으면 503 및 `status: "error"`를 반환한다.

## 3. 인증 및 현재 사용자 확인

### 3.1 Access token 발급

`POST /token`은 OAuth2 password grant form을 사용한다. 실제 자격 증명은 terminal history에 남지 않도록 환경변수, secret store 또는 안전한 입력 방식으로 제공한다.

```bash
export ACCESS_TOKEN="$({
  curl --fail --silent --show-error \
    --request POST "$BASE_URL/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD"
} | jq --raw-output '.access_token')"

test -n "$ACCESS_TOKEN" && test "$ACCESS_TOKEN" != 'null'
```

`ACCESS_TOKEN`은 이후 예시의 bearer token으로 사용한다.

### 3.2 현재 사용자와 권한 확인

```bash
curl --fail --silent --show-error \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header 'Accept: application/json' \
  "$BASE_URL/user" | jq
```

hard delete를 실행하려면 response의 `roles`에 `document:delete:hard`가 있어야 한다.

```json
{
  "sub": "user-123",
  "username": "alice",
  "roles": ["document:delete:hard"],
  "scopes": ["documents:read", "documents:write"]
}
```

## 4. 문서 생성

`POST /documents`는 multipart/form-data 요청을 받는다. `file`의 이름과 MIME type이 문서 metadata로 기록되며, `created_by`는 인증된 사용자의 `sub`에서 설정된다.

### 4.1 호출자가 document ID를 지정하는 업로드

```bash
curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form "document_id=$DOCUMENT_ID" \
  --form-string 'metadata={"category":"contract","retention_policy":"standard"}' \
  | jq
```

성공 시 201과 함께 `DocumentMetadata`를 반환한다.

```json
{
  "document_id": "contract-2026-0001",
  "original_filename": "contract.pdf",
  "content_type": "application/pdf",
  "file_size": 24576,
  "status": "available",
  "created_at": "2026-07-11T09:30:00Z",
  "updated_at": "2026-07-11T09:30:00Z",
  "deleted_at": null,
  "created_by": "user-123",
  "checksum": "[SHA-256]",
  "metadata": {
    "category": "contract",
    "retention_policy": "standard"
  }
}
```

### 4.2 서버 생성 document ID를 사용하는 업로드

`document_id` form field를 생략하면 SDK가 문서 ID를 생성한다. 응답의 `document_id`를 다음 요청에 사용한다.

```bash
DOCUMENT_ID="$({
  curl --fail --silent --show-error \
    --request POST "$BASE_URL/documents" \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --form "file=@$DOCUMENT_FILE;type=application/pdf" \
    --form-string 'metadata={"category":"contract"}'
} | jq --raw-output '.document_id')"

printf 'Created document ID: %s\n' "$DOCUMENT_ID"
```

### 4.3 checksum을 지정하는 업로드

호출자가 SHA-256 checksum을 이미 알고 있다면 `checksum` form field로 전달할 수 있다.

```bash
CHECKSUM="$(sha256sum "$DOCUMENT_FILE" | cut --delimiter=' ' --fields=1)"

curl --fail --silent --show-error \
  --request POST "$BASE_URL/documents" \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --form "file=@$DOCUMENT_FILE;type=application/pdf" \
  --form "checksum=$CHECKSUM" \
  | jq
```

지정한 `document_id`가 이미 존재하면 서비스는 `409 DOCUMENT_ALREADY_EXISTS`를 반환한다.

## 5. 문서 조회

### 5.1 문서 목록 조회

`offset` 기본값은 `0`, `limit` 기본값은 `100`이다. `status`에는 `uploaded`, `available`, `deleting`, `deleted`, `failed` 중 하나를 선택해서 전달할 수 있다.

```bash
curl --fail --silent --show-error \
  --header "Authorization: Bearer *** \
  --header 'Accept: application/json' \
  "$BASE_URL/documents?offset=0&limit=100&status=available" | jq
```

응답은 `DocumentMetadata` 객체 배열이며 각 항목에 내부 `storage_key`를 포함하지 않는다.

### 5.2 Metadata 조회

```bash
curl --fail --silent --show-error \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header 'Accept: application/json' \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

`storage_key`는 내부 저장소 식별자이므로 response에 포함되지 않는다.

### 5.3 전체 콘텐츠 조회

작은 문서는 `/content` endpoint로 단일 response body를 받아 파일로 저장할 수 있다. 대용량 문서에는 다음 절의 streaming download를 사용한다.

```bash
curl --fail --silent --show-error \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --output "${DOCUMENT_ID}.content" \
  "$BASE_URL/documents/$DOCUMENT_ID/content"
```

response의 `Content-Type`, `Content-Length`, `Content-Disposition` header는 저장된 문서의 content type, 크기, 원본 파일명을 반영한다.

### 5.4 Streaming download

`/download` endpoint는 본문을 chunk 단위로 전송한다. `curl --remote-header-name`은 서버의 `Content-Disposition` filename을 사용한다.

```bash
curl --fail --silent --show-error --location \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --remote-header-name \
  --output-dir ./downloads \
  "$BASE_URL/documents/$DOCUMENT_ID/download?chunk_size=65536"
```

`chunk_size`는 양의 정수여야 한다. `0`, 음수, 정수가 아닌 값은 `400 VALIDATION_ERROR`를 반환한다.

## 6. 문서 삭제

### 6.1 Soft delete

기본 삭제는 MinIO object를 유지하고 PostgreSQL metadata의 상태를 `deleted`로, `deleted_at`을 삭제 시각으로 갱신한다. soft-deleted 문서는 일반 조회 및 download에서 `404 DOCUMENT_NOT_FOUND`로 처리된다.

```bash
curl --fail --silent --show-error \
  --request DELETE \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

성공 예시:

```json
{
  "document_id": "contract-2026-0001",
  "deleted": true,
  "hard_deleted": false,
  "status": "deleted"
}
```

### 6.2 Hard delete

hard delete는 MinIO object와 PostgreSQL metadata 행을 제거한다. 이 작업에는 `document:delete:hard` 권한이 필요하다.

> **주의:** hard delete는 MVP에서 복구할 수 없다. 일반 문서 정리에는 soft delete를 우선 사용한다.

```bash
curl --fail --silent --show-error \
  --request DELETE \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --header "X-Correlation-ID: $CORRELATION_ID" \
  "$BASE_URL/documents/$DOCUMENT_ID?hard=true" | jq
```

권한이 없으면 `403 FORBIDDEN`을 반환한다. 성공 후 metadata 조회와 콘텐츠 조회는 `404 DOCUMENT_NOT_FOUND`를 반환한다.

## 7. 오류 response 확인 및 진단

`curl --fail`은 4xx/5xx response body를 출력하지 않고 종료하므로, 오류 response와 correlation ID를 확인할 때는 response header와 body를 별도 파일로 저장한다.

```bash
ERROR_BODY="$(mktemp)"
ERROR_HEADERS="$(mktemp)"

HTTP_STATUS="$(curl --silent --show-error \
  --request GET \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --dump-header "$ERROR_HEADERS" \
  --output "$ERROR_BODY" \
  --write-out '%{http_code}' \
  "$BASE_URL/documents/not-found-example")"

printf 'HTTP status: %s\n' "$HTTP_STATUS"
printf 'Correlation ID: '
grep --ignore-case '^X-Correlation-ID:' "$ERROR_HEADERS" || true
jq < "$ERROR_BODY"

rm --force "$ERROR_BODY" "$ERROR_HEADERS"
```

404 오류 response 예시:

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "example-20260711-001"
  }
}
```

대표적인 오류 처리 방법:

| 코드 | 일반 원인 | 호출자 조치 |
| --- | --- | --- |
| `VALIDATION_ERROR` | 잘못된 form field, metadata JSON, `chunk_size` | request 값을 수정 후 재시도 |
| `UNAUTHENTICATED` | token 누락·만료·검증 실패 | token을 다시 발급하고 Authorization header 갱신 |
| `FORBIDDEN` | hard delete 권한 없음 | 권한이 있는 계정 또는 soft delete 사용 |
| `DOCUMENT_NOT_FOUND` | 존재하지 않거나 soft-deleted 문서 | document ID와 업무 상태 확인 |
| `DOCUMENT_ALREADY_EXISTS` | 지정 ID 중복 | 새 document ID 사용 또는 기존 문서 조회 |
| `METADATA_STORE_ERROR` / `OBJECT_STORAGE_ERROR` | PostgreSQL 또는 MinIO 일시 장애 | correlation ID를 포함해 운영팀에 전달하고 readiness 확인 |
| `DOCUMENT_CONSISTENCY_ERROR` | metadata/object 상태 불일치 | 재시도하지 말고 correlation ID를 포함해 운영팀에 전달 |

## 8. 전체 lifecycle 예시

다음은 인증된 사용자가 문서를 올린 뒤 metadata를 조회하고 streaming download를 수행한 다음 soft delete하는 순서다.

```bash
export ACCESS_TOKEN="$({
  curl --fail --silent --show-error \
    --request POST "$BASE_URL/token" \
    --header 'Content-Type: application/x-www-form-urlencoded' \
    --data-urlencode "username=$USERNAME" \
    --data-urlencode "password=$PASSWORD"
} | jq --raw-output '.access_token')"

DOCUMENT_ID="$({
  curl --fail --silent --show-error \
    --request POST "$BASE_URL/documents" \
    --header "Authorization: Bearer $ACCESS_TOKEN" \
    --form "file=@$DOCUMENT_FILE;type=application/pdf" \
    --form-string 'metadata={"category":"contract"}'
} | jq --raw-output '.document_id')"

curl --fail --silent --show-error \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq

curl --fail --silent --show-error --location \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  --remote-header-name \
  --output-dir ./downloads \
  "$BASE_URL/documents/$DOCUMENT_ID/download"

curl --fail --silent --show-error \
  --request DELETE \
  --header "Authorization: Bearer $ACCESS_TOKEN" \
  "$BASE_URL/documents/$DOCUMENT_ID" | jq
```

## 9. 운영 시 유의 사항

1. readiness가 503이면 upload, download, delete 작업을 수행하지 말고 PostgreSQL·MinIO 상태를 먼저 복구한다.
2. 오류 조사에는 `X-Correlation-ID` 또는 오류 body의 `correlation_id`를 사용한다.
3. `created_by`는 인증 주체에서 설정되므로 client form field로 보내지 않는다.
4. 파일 본문, access token, password, MinIO credential, PostgreSQL DSN을 로그나 issue에 첨부하지 않는다.
5. hard delete는 복구할 수 없으므로 권한과 대상 document ID를 확인한 뒤 실행한다.
