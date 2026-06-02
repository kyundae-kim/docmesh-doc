# API 명세 - Metadata

Metadata는 PostgreSQL에 저장되며, 문서와 1:1 관계를 가진다.
모든 엔드포인트는 Bearer 토큰 인증이 필요하다.

---

## POST /documents/{document_id}/metadata

특정 문서의 metadata를 생성한다. 문서당 1건만 허용(1:1 제약).

**요청 Body:**

```json
{
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  }
}
```

**응답 201:**

```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:01:00Z"
}
```

**오류:**

| 코드 | 설명 |
|------|------|
| 400 | 요청 검증 실패 |
| 404 | 문서 없음 |
| 409 | 이미 metadata가 존재함 (1:1 제약) |

---

## GET /documents/{document_id}/metadata

특정 문서의 metadata를 조회한다.

**응답 200:**

```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 1
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:01:00Z"
}
```

**오류:**

| 코드 | 설명 |
|------|------|
| 404 | 문서 또는 metadata 없음 |

---

## PATCH /documents/{document_id}/metadata

특정 문서의 metadata를 부분 수정한다.

**요청 Body:**

```json
{
  "metadata_value": {
    "category": "architecture",
    "priority": 2
  }
}
```

**응답 200:**

```json
{
  "document_id": "f8be42e8-c34d-4f39-9f2d-d4067c9f19e2",
  "metadata_value": {
    "category": "architecture",
    "priority": 2
  },
  "created_at": "2026-05-26T05:01:00Z",
  "updated_at": "2026-05-26T05:10:00Z"
}
```

**오류:**

| 코드 | 설명 |
|------|------|
| 400 | 요청 검증 실패 |
| 404 | 문서 또는 metadata 없음 |

---

## DELETE /documents/{document_id}/metadata

특정 문서의 metadata를 삭제한다.

**응답 204:** No Content

**오류:**

| 코드 | 설명 |
|------|------|
| 404 | 문서 또는 metadata 없음 |

---

[홈으로](./Home.md) | [이전: 문서 API](./API-Documents.md) | [다음: 헬스체크 API](./API-Health.md)
