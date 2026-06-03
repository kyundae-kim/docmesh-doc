# API 명세 - 문서

문서는 `file_path`가 아닌 `document_id (UUID)`로 접근한다.
모든 엔드포인트는 Bearer 토큰 인증이 필요하다.

---

## POST /documents

문서를 업로드하고 document_id를 발급받는다.

**요청:** `multipart/form-data`

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| file | binary | 필수 | 업로드할 파일 |
| filename | string | 선택 | 원본 파일명 보관 용도 |

**응답 201:**

```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "filename": "example.txt"
}
```

**오류:**

| 코드 | 설명 |
|------|------|
| 400 | 요청 검증 실패 |
| 401 | 인증 실패 |

---

## GET /documents/{document_id}

문서를 다운로드한다.

**Path Parameter:**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| document_id | UUID | 문서 식별자 |

**응답 200:**

- Body: 파일 바이너리
- Headers:
  - `Content-Type: <원본 타입>`
  - `Content-Disposition: attachment; filename="..."`

**오류:**

| 코드 | 설명 |
|------|------|
| 404 | 문서 없음 또는 Soft Delete 상태 |

---

## DELETE /documents/{document_id}

문서를 Soft Delete한다. 물리 삭제가 아니라 MinIO 태그 `deleted=true`로 마킹한다.

**Path Parameter:**

| 파라미터 | 타입 | 설명 |
|---------|------|------|
| document_id | UUID | 문서 식별자 |

**응답 204:** No Content

**오류:**

| 코드 | 설명 |
|------|------|
| 404 | 문서 없음 |

---

[홈으로](./Home.md) | [이전: 인증 API](./API-Auth.md) | [다음: Metadata API](./API-Metadata.md)
