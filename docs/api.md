# API Reference

## 범위와 인증

DocMesh Document Service의 기본 route prefix는 `/`이며, reverse proxy에서 `ROOT_PATH=/dms`를 사용하면 공개 URL에도 `/dms`를 포함합니다. 문서 route는 bearer token 인증이 필요합니다. 인증 router를 포함한 기본 앱은 `/token`과 `/user`를 제공하고, embedding/test 앱은 `include_auth_router=False`로 만들 수 있습니다.

## 공통 응답

### 성공

문서 metadata는 다음 공개 필드를 사용합니다.

- `document_id`
- `original_filename`
- `content_type`
- `file_size`
- `status`
- `created_at`
- `updated_at`
- `deleted_at`
- `created_by`
- `checksum`
- `metadata`

내부 `storage_key`는 HTTP response에 노출하지 않습니다. stream upload에서 `checksum`은 dms-core v0.7.0이 본문으로부터 파생합니다.

### 오류

모든 오류는 다음 envelope을 사용합니다.

```json
{
  "error": {
    "code": "DOCUMENT_NOT_FOUND",
    "message": "Document was not found.",
    "correlation_id": "request-1"
  }
}
```

대표적인 status/code 매핑은 다음과 같습니다.

| Status | Code | 의미 |
| ---: | --- | --- |
| 400 | `VALIDATION_ERROR` | 입력 또는 multipart metadata 오류 |
| 401 | `UNAUTHENTICATED` | bearer token 없음/무효 |
| 403 | `FORBIDDEN` | 권한 부족 |
| 404 | `DOCUMENT_NOT_FOUND` | 존재하지 않거나 soft-deleted 문서 |
| 409 | `DOCUMENT_ALREADY_EXISTS` / `IDEMPOTENCY_CONFLICT` | 중복 또는 멱등성 충돌 |
| 413 | `DOCUMENT_TOO_LARGE` | 설정된 크기 초과 |
| 425 | `IDEMPOTENCY_IN_PROGRESS` | 같은 업로드가 진행 중 |
| 500 | `DOCUMENT_CONSISTENCY_ERROR` / `INTERNAL_ERROR` | 정합성 또는 미분류 내부 오류 |
| 503 | `DEPENDENCY_UNAVAILABLE` / storage 오류 | 필수 의존성 장애 |

`X-Correlation-ID`가 있으면 오류 response의 `correlation_id`와 로그 상관관계에 사용합니다.

## 문서 endpoint

### `POST /documents`

`multipart/form-data` 요청입니다.

| Field | Required | 설명 |
| --- | --- | --- |
| `file` | yes | 비어 있지 않은 파일. filename과 content type이 필요합니다. |
| `document_id` | no | 사용자 지정 문서 ID. 빈 문자열은 미지정으로 정규화합니다. |
| `metadata` | no | JSON object 문자열. 기본값은 `{}`입니다. |

v0.7.0의 `UploadDocumentStreamRequest`에는 client-supplied `checksum` field가 없으므로 checksum form field를 전달하지 않습니다. 업로드는 `upload_document_stream(...)`으로 실행되며 성공 시 `201`, public metadata와 생성 metadata URL의 `Location` header를 반환합니다.

### `GET /documents`

Query parameter:

- `cursor`: 이전 response의 `next_cursor`
- `limit`: `1`~`1000`, 기본 `100`
- `status`: dms-core `DocumentStatus` filter

응답은 `items`, `next_cursor`, `has_more`를 포함합니다. cursor는 opaque 값으로 취급합니다.

### `GET /documents/{document_id}`

문서 public metadata를 반환합니다. soft-deleted 문서는 일반 단건 조회에서 `404 DOCUMENT_NOT_FOUND`입니다.

### `GET /documents/{document_id}/content`

문서 본문을 inline streaming response로 반환합니다. 전체 본문을 애플리케이션 메모리에 적재하지 않으며 `Content-Length`, content type과 inline `Content-Disposition`을 설정합니다.

### `GET /documents/{document_id}/download`

attachment streaming response입니다. `chunk_size`는 기본 64 KiB, 허용 범위는 1 byte~8 MiB입니다. filename은 RFC 5987 UTF-8 형식으로 encoding합니다.

### `DELETE /documents/{document_id}`

기본 동작은 soft delete입니다. `?hard=true`는 hard-delete 권한이 있는 사용자만 사용할 수 있습니다. 응답은 `document_id`, `deleted`, `hard_deleted`, `status`를 포함합니다.

## 관련 문서

- [설정 정의서](config.md)
- [API 사용 예시](examples.md)
- [소프트웨어 요구사항 정의서](srs.md)
- [테스트 정의서](test.md)
