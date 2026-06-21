# API Specification

## 1. 목적

본 문서는 `docs/srs.md` 기준의 **DMS 서비스 모드 HTTP API**를 정의한다.

이 API는 `fastapi-core`가 생성한 FastAPI 앱 안에서 동작하는 것을 전제로 하며, 내부적으로 DMS SDK를 호출한다.

---

## 2. 공통 원칙

- Base path는 서비스별 정책에 따라 결정하되, 예시에서는 `/documents`를 사용한다.
- JSON 응답은 snake_case를 기본으로 한다.
- 다운로드 API는 JSON 대신 바이너리/stream 응답을 반환할 수 있다.
- 인증이 필요한 엔드포인트는 `fastapi-core` dependency와 정렬한다.
- 예외는 SDK 오류를 HTTP 오류로 매핑한다.

---

## 3. 엔드포인트 목록

| Method | Path | 설명 |
|---|---|---|
| `POST` | `/documents` | 문서 업로드 |
| `GET` | `/documents/{document_id}/metadata` | 문서 metadata 조회 |
| `GET` | `/documents/{document_id}/content` | 문서 content 다운로드 |
| `GET` | `/documents/{document_id}/stream` | 문서 stream 다운로드 |
| `DELETE` | `/documents/{document_id}` | soft delete |
| `DELETE` | `/documents/{document_id}?hard_delete=true` | hard delete |
| `GET` | `/documents/health` | DMS 레벨 health |

---

## 4. 데이터 모델

## 4.1 DocumentMetadataResponse

```json
{
  "document_id": "doc-123",
  "original_filename": "report.pdf",
  "content_type": "application/pdf",
  "file_size": 1048576,
  "storage_key": "documents/doc-123/report.pdf",
  "status": "available",
  "created_at": "2026-06-18T10:00:00Z",
  "updated_at": "2026-06-18T10:00:00Z",
  "checksum": "...",
  "deleted_at": null,
  "created_by": "alice",
  "extra_metadata": {
    "team": "platform"
  }
}
```

## 4.2 UploadDocumentResponse

```json
{
  "document_id": "doc-123",
  "storage_key": "documents/doc-123/report.pdf",
  "created": true,
  "metadata": {
    "document_id": "doc-123",
    "original_filename": "report.pdf",
    "content_type": "application/pdf",
    "file_size": 1048576,
    "storage_key": "documents/doc-123/report.pdf",
    "status": "available",
    "created_at": "2026-06-18T10:00:00Z",
    "updated_at": "2026-06-18T10:00:00Z",
    "checksum": "...",
    "deleted_at": null,
    "created_by": "alice",
    "extra_metadata": {
      "team": "platform"
    }
  }
}
```

## 4.3 DeleteDocumentResponse

```json
{
  "document_id": "doc-123",
  "deleted": true,
  "hard_deleted": false,
  "status": "deleted"
}
```

## 4.4 HealthResponse

```json
{
  "ok": true,
  "checked_at": "2026-06-18T10:00:00Z",
  "services": [
    {
      "service": "postgres",
      "ok": true,
      "latency_ms": 2.1,
      "error": null
    },
    {
      "service": "minio",
      "ok": true,
      "latency_ms": 8.3,
      "error": null
    }
  ]
}
```

---

## 5. POST /documents

## 목적

문서를 업로드하고 metadata를 저장한다.

## Request

### Content-Type

`multipart/form-data`

### Form fields

| 필드 | 타입 | 필수 | 설명 |
|---|---|---:|---|
| `file` | binary | Y | 업로드할 파일 |
| `document_id` | string | N | 직접 지정할 문서 식별자 |
| `content_type` | string | N | 미지정 시 파일/헤더 기반 추론 가능 |
| `created_by` | string | N | 생성자 식별자 |
| `metadata` | JSON string | N | 추가 메타데이터 |

### 예시

```bash
curl -X POST http://localhost:8000/documents \
  -F "file=@./report.pdf" \
  -F 'metadata={"team":"platform"}' \
  -F "created_by=alice"
```

## Response

- `201 Created`
- Body: `UploadDocumentResponse`

## 오류

| 상태 코드 | 조건 |
|---|---|
| `400` | 잘못된 입력, 빈 파일, 잘못된 metadata 형식 |
| `401` | 인증 필요 / 인증 실패 |
| `409` | 중복 `document_id` |
| `500` | storage / metadata / consistency 오류 |

---

## 6. GET /documents/{document_id}/metadata

## 목적

문서 metadata를 조회한다.

## Response

- `200 OK`
- Body: `DocumentMetadataResponse`

## 오류

| 상태 코드 | 조건 |
|---|---|
| `404` | 문서 없음 |
| `500` | metadata backend 오류 |

### 예시

```bash
curl http://localhost:8000/documents/doc-123/metadata
```

---

## 7. GET /documents/{document_id}/content

## 목적

문서 content 전체를 한 번에 반환한다.

## Response

- `200 OK`
- Body: 바이너리
- Headers 예시:
  - `Content-Type: application/pdf`
  - `Content-Disposition: attachment; filename="report.pdf"`
  - `ETag` 또는 checksum 기반 헤더는 선택 사항

## 오류

| 상태 코드 | 조건 |
|---|---|
| `404` | 문서 없음 |
| `500` | object missing, consistency 오류, storage 오류 |

---

## 8. GET /documents/{document_id}/stream

## 목적

대용량 파일을 stream 방식으로 반환한다.

## Query Parameters

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---|---|---:|---:|---|
| `chunk_size` | integer | N | `65536` | stream chunk size |

## Response

- `200 OK`
- streaming response
- `Content-Type`과 `Content-Disposition`은 content API와 동일한 원칙을 따른다.

## 오류

| 상태 코드 | 조건 |
|---|---|
| `400` | `chunk_size <= 0` |
| `404` | 문서 없음 |
| `500` | stream object 없음, consistency 오류 |

---

## 9. DELETE /documents/{document_id}

## 목적

문서를 삭제한다.

기본 동작은 soft delete다.

## Query Parameters

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---|---|---:|---:|---|
| `hard_delete` | boolean | N | `false` | true면 metadata row도 제거 |

## Response

- `200 OK`
- Body: `DeleteDocumentResponse`

## 오류

| 상태 코드 | 조건 |
|---|---|
| `404` | 문서 없음 |
| `500` | storage 오류 / consistency 오류 |

### 예시

```bash
curl -X DELETE "http://localhost:8000/documents/doc-123"
curl -X DELETE "http://localhost:8000/documents/doc-123?hard_delete=true"
```

---

## 10. GET /documents/health

## 목적

DMS 레벨의 런타임 health check 결과를 반환한다.

## Response

- `200 OK`
- Body: `HealthResponse`

주의:
- 이 API는 host-level readiness와 별도다.
- readiness는 `fastapi-core`가 책임지고, 이 엔드포인트는 DMS 상세 진단을 위한 용도로 쓴다.

---

## 11. 오류 응답 규약

권장 오류 응답 형식:

```json
{
  "error": {
    "type": "DocumentNotFoundError",
    "message": "Document not found: doc-123"
  }
}
```

## 예외 매핑

| SDK 예외 | HTTP 상태 |
|---|---:|
| `ValidationError` | `400` |
| `AuthenticationError` | `401` |
| `DocumentNotFoundError` | `404` |
| `DuplicateDocumentError` | `409` |
| `ConfigurationError` | `500` |
| `StorageError` | `500` |
| `MetadataStoreError` | `500` |
| `ConsistencyError` | `500` |
| `HealthCheckFailedError` | `503` 또는 내부 운영 정책에 따름 |

---

## 12. 구현 메모

권장 구현 흐름:

- router는 HTTP parsing/response formatting만 담당
- 실제 비즈니스 호출은 `dms_sdk` 또는 `dms_service`로 위임
- 인증 사용 시 `fastapi-core` dependency를 사용
- `created_by`는 명시 입력 또는 인증 사용자 정보에서 보완 가능
- stream 응답은 `StreamingResponse` 기반 구현을 권장
