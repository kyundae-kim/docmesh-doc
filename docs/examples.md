# API 사용 예시

## 1. 저장소 환경 준비

최소 PostgreSQL + MinIO 구성입니다.

```env
DMS_METADATA_BACKEND=postgresql
DMS_CONFIGURATION_STRICT=true
POSTGRES_HOST=postgres
POSTGRES_DB=docmesh
POSTGRES_USER=docmesh
POSTGRES_PASSWORD=<secret>
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=documents
MINIO_SECURE=true
```

로컬 SQLite를 선택하려면 PostgreSQL block을 제거하고 다음을 사용합니다.

```env
DMS_METADATA_BACKEND=sqlite
SQLITE_PATH=./data/docmesh.sqlite3
```

## 2. Health 확인

```bash
curl --fail http://127.0.0.1:8000/health/liveness
curl --fail http://127.0.0.1:8000/health/readiness
```

## 3. Token 발급

```bash
curl --request POST http://127.0.0.1:8000/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'username=<username>' \
  --data-urlencode 'password=<password>'
```

reverse proxy prefix가 있으면 `ROOT_PATH`/`TOKEN_URL` 설정에 맞춰 공개 URL을 사용합니다.

## 4. 문서 업로드

```bash
curl --request POST http://127.0.0.1:8000/documents \
  --header 'Authorization: Bearer <access-token>' \
  --form 'file=@./contract.pdf;type=application/pdf' \
  --form 'document_id=contract-2026-0001' \
  --form-string 'metadata={"category":"contract"}'
```

`created_by`는 form field가 아니라 인증 사용자의 `sub`에서 결정됩니다. v0.7.0 stream request에는 checksum form field가 없으며 DMS가 본문 checksum을 metadata에 기록합니다.

## 5. 목록·조회

```bash
curl --fail \
  --header 'Authorization: Bearer <access-token>' \
  'http://127.0.0.1:8000/documents?limit=100'

curl --fail \
  --header 'Authorization: Bearer <access-token>' \
  'http://127.0.0.1:8000/documents/contract-2026-0001'
```

후속 목록 요청은 response의 `next_cursor`를 opaque 값 그대로 전달합니다.

## 6. Streaming download

```bash
curl --fail --location \
  --header 'Authorization: Bearer <access-token>' \
  --output contract.pdf \
  'http://127.0.0.1:8000/documents/contract-2026-0001/download?chunk_size=65536'
```

inline content가 필요하면 `/content`를 사용합니다. stream은 response 종료, client disconnect, producer 오류에서도 underlying resource를 닫습니다.

## 7. 삭제

```bash
# Soft delete
curl --request DELETE \
  --header 'Authorization: Bearer <access-token>' \
  http://127.0.0.1:8000/documents/contract-2026-0001

# Hard delete: document:delete:hard 권한 필요
curl --request DELETE \
  --header 'Authorization: Bearer <access-token>' \
  'http://127.0.0.1:8000/documents/contract-2026-0001?hard=true'
```

## 8. Host assembly 경계

application은 route에서 client를 만들지 않습니다. `docmesh_doc.dms_factory`가 `docmesh-config` 설정을 읽고 `docmesh-py-core` client wrapper를 만든 뒤 `dms.create_sdk_from_clients(...)`에 주입합니다. 생성된 SDK는 `fastapi-core` managed resource가 소유하고 startup/readiness/shutdown lifecycle에 연결됩니다.
