# 데이터 모델 및 저장소

## 저장소 정책

| 데이터 | 저장소 | 비고 |
|--------|--------|------|
| 문서 원문 | MinIO | Soft Delete 시 `deleted=true` 태그 |
| 문서 인덱스 | PostgreSQL | documents 테이블 |
| Metadata | PostgreSQL | document_metadata 테이블 |

---

## DB 테이블 스키마

### documents

| 컬럼 | 타입 | 설명 |
|------|------|------|
| id | UUID (PK) | 문서 식별자 |
| owner_username | TEXT | 소유자 사용자명 |
| object_key | TEXT (UNIQUE) | MinIO 객체 키 (`{username}/{document_id}`) |
| original_filename | TEXT | 원본 파일명 |
| content_type | TEXT | MIME 타입 |
| created_at | TIMESTAMPTZ | 생성 일시 |
| updated_at | TIMESTAMPTZ | 수정 일시 |

### document_metadata

| 컬럼 | 타입 | 설명 |
|------|------|------|
| document_id | UUID (PK, FK -> documents.id) | 문서 식별자 |
| metadata_value | JSONB | 메타데이터 값 |
| created_at | TIMESTAMPTZ | 생성 일시 |
| updated_at | TIMESTAMPTZ | 수정 일시 |

---

## ORM 모델 구조

```
docmesh_doc/models/
  base.py       # 공통 Base 클래스 (DeclarativeBase)
  document.py   # Document 모델 (Base 상속)
  metadata.py   # DocumentMetadata 모델 (Base 상속)
```

모든 ORM 모델은 `base.py`의 공통 `Base`를 상속한다.
서비스 파일 내부에 로컬 `Base`를 선언하지 않는다.

---

## Soft Delete 동작

문서 삭제 시 MinIO 객체를 물리 삭제하지 않고 태그로 마킹한다:

- 삭제 전: `deleted=false`
- 삭제 후: `deleted=true`

다운로드 시 `deleted=true` 상태이면 404를 반환한다.

---

[홈으로](./Home.md)
