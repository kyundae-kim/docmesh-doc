# DocMesh Document Service

DocMesh Document Service는 `dms-core`의 문서 관리 기능을 FastAPI HTTP API로 제공하는 서비스입니다. 문서 본문은 DMS SDK가 주입받은 MinIO object store에 저장하고, 문서 ID·원본 파일명·작성자·checksum·상태·metadata는 metadata store에서 관리합니다.

## 계층 구조

- **API 계층 — FastAPI**
  - `docmesh_doc/router.py`: HTTP route, multipart/query 검증, streaming response
  - `docmesh_doc/schemas.py`: public response allowlist
  - `docmesh_doc/errors.py`: DMS 오류의 HTTP status·제품 envelope·correlation ID 변환
- **Application 계층 — dms-core**
  - `DocumentManagementSDKFactory`가 제공하는 v0.9 public facade를 통해 upload, 목록, metadata/content 조회, 삭제를 수행합니다.
  - `storage_key`와 내부 metadata 모델은 HTTP 응답에 노출하지 않습니다.
- **Host 조립·lifecycle 계층 — FastAPI lifespan**
  - `docmesh_doc/dms_factory.py`가 환경 설정으로 SQLAlchemy `Engine`과 MinIO client를 만들고 DMS factory에 주입합니다.
  - DMS facade에는 전역 `close()`나 `check_health()`가 없으므로 host가 Engine dispose와 readiness 검사를 소유합니다.
  - `create_application(runtime=...)` 또는 `create_application(sdk=...)`로 주입한 자원은 호출자가 소유하며 FastAPI가 닫지 않습니다. 둘 다 생략하면 애플리케이션이 runtime을 조립하고 자신의 lifespan 동안 관리합니다.

## HTTP 표면

- `POST /documents`
- `GET /documents?cursor=&limit=100&status=`
- `GET /documents/{document_id}`
- `GET /documents/{document_id}/content`
- `GET /documents/{document_id}/download?chunk_size=65536`
- `DELETE /documents/{document_id}`
- `DELETE /documents/{document_id}?hard=true`
- `GET /health/liveness`
- `GET /health/readiness`

## 저장소 설정

운영 기본값은 PostgreSQL metadata store이며 MinIO object store가 항상 필요합니다.

```bash
export DMS_METADATA_BACKEND=postgresql
export POSTGRES_HOST=localhost
export POSTGRES_PORT=5432
export POSTGRES_DB=docmesh
export POSTGRES_USER=docmesh
export POSTGRES_PASSWORD='change-me'
export MINIO_ENDPOINT=localhost:9000
export MINIO_ACCESS_KEY=minioadmin
export MINIO_SECRET_KEY='change-me'
export MINIO_BUCKET=documents
export MINIO_SECURE=false
```

로컬 SQLite를 선택할 수 있습니다. SQLite는 metadata store만 대체하고 MinIO는 계속 필요합니다.

```bash
export DMS_METADATA_BACKEND=sqlite
export SQLITE_PATH=./data/docmesh.sqlite3
```

`POSTGRES_DSN`은 현재 host 조립 계약에서 지원하지 않습니다. PostgreSQL 개별 `POSTGRES_*` 설정을 사용합니다.

## 실행 및 검증

```bash
uv run fastapi run
uv run pytest -q
```
