# DocMesh Document Service

DocMesh Document Service는 문서 본문과 metadata를 일관된 HTTP API로 관리하는 FastAPI 서비스입니다. 문서 본문은 DMS SDK가 구성한 MinIO object store에 저장하고, 문서 ID·원본 파일명·작성자·checksum·상태·사용자 metadata는 PostgreSQL metadata store에서 관리합니다.

## 주요 기능

- `multipart/form-data` 기반 문서 업로드
- 문서 목록 및 metadata 조회
- 전체 콘텐츠 조회와 chunk 기반 streaming download
- object를 제거하고 metadata를 보존하는 soft delete
- 권한이 있는 사용자를 위한 hard delete
- OAuth2 bearer 인증과 Keycloak 사용자/role 연동
- 표준 오류 envelope와 `X-Correlation-ID`
- DMS SDK를 반영하는 liveness/readiness endpoint
- OpenAPI, Swagger UI, ReDoc 제공

## 아키텍처

```text
API Consumer
    │ HTTP / OAuth2 bearer
    ▼
DocMesh Document Service
    ├─ fastapi-core
    │    app factory, auth, health, readiness, error rendering
    └─ dms-core
         document lifecycle, consistency, streaming, health
              ├─ PostgreSQL: document metadata
              └─ MinIO: document content
```

애플리케이션은 `docmesh_doc.application.create_application()`에서 조립됩니다. DMS SDK는 managed resource로 생성되어 전체 lifespan 동안 재사용되며, 애플리케이션 종료 시 함께 닫힙니다. 기본 ASGI entrypoint는 `docmesh_doc.main:app`입니다.

## 요구 사항

- Python 3.11 이상
- [uv](https://docs.astral.sh/uv/)
- PostgreSQL
- MinIO 및 문서 bucket
- Keycloak

PostgreSQL·MinIO·Keycloak은 애플리케이션 기동 전에 접근 가능한 상태여야 합니다. 실제 credential은 source code나 Git에 저장하지 말고 환경변수 또는 secret manager로 주입합니다.

## 설치

### 저장소를 clone해서 설치

개발하거나 테스트를 실행하려면 저장소를 clone한 뒤 project environment를 동기화합니다.

```bash
git clone https://github.com/kyundae-kim/docmesh-doc.git
cd docmesh-doc
uv sync
```

`uv sync`는 `pyproject.toml`에 고정된 `dms-core`, `fastapi-core`, `docmesh-py-core` Git ref를 설치합니다.

### GitHub에서 직접 설치

Source checkout 없이 GitHub branch, tag 또는 commit에서 직접 설치할 수도 있습니다. 먼저 가상환경을 만든 뒤 Git dependency URL을 `uv pip install`에 전달합니다.

```bash
uv venv
uv pip install \
  "docmesh-doc @ git+https://github.com/kyundae-kim/docmesh-doc.git@v0.2.0"
```

설치한 애플리케이션은 import entrypoint로 실행합니다.

```bash
uv run --no-project python -m fastapi run \
  --entrypoint docmesh_doc.main:app \
  --host 0.0.0.0 \
  --port 8000
```

URL 마지막의 `dms-core-v0.4.0`은 설치할 Git ref입니다. 재현 가능한 운영 배포에서는 이동 가능한 branch보다 release tag 또는 commit SHA를 사용하는 것이 좋습니다.

## 설정

서비스는 DMS SDK 설정을 process environment에서 직접 읽습니다. `.env` 파일을 만들기만 해서는 DMS 설정이 자동으로 적용되지 않으므로, 실행 전에 환경변수로 export하거나 배포 도구의 environment/secret 기능으로 주입해야 합니다.

최소 저장소 설정은 다음과 같습니다.

```env
DMS_METADATA_BACKEND=postgresql
DMS_CONFIGURATION_STRICT=true

POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=docmesh
POSTGRES_USER=docmesh
POSTGRES_PASSWORD=<password>

MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=documents
MINIO_SECURE=false
```

인증을 포함한 기본 애플리케이션에는 Keycloak 설정도 필요합니다.

```env
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=docmesh
KEYCLOAK_CLIENT_ID=docmesh-document-service
KEYCLOAK_CLIENT_SECRET=<client-secret>

DOCMESH_SERVICES=keycloak
READINESS_REQUIRED_SERVICES=keycloak
TOKEN_URL=/token
```

Reverse proxy가 `/dms` prefix로 서비스를 노출한다면 공개 경로와 OAuth2 token URL을 함께 설정합니다.

```env
ROOT_PATH=/dms
TOKEN_URL=/dms/token
```

> PostgreSQL 개별 필드와 deprecated `POSTGRES_DSN`을 함께 전달하면 DMS 설정 검증이 실패합니다. 이 서비스의 권장 구성에서는 `POSTGRES_DSN`을 설정하지 않습니다.

전체 변수, 기본값, CORS, readiness 및 운영 보안 정책은 [설정 정의서](docs/config.md)를 참조하세요.

## 실행

### 개발 서버

필수 환경변수를 현재 shell에 export한 뒤 실행합니다.

```bash
uv run python -m fastapi dev docmesh_doc/main.py
```

기본 주소는 `http://127.0.0.1:8000`입니다. `ROOT_PATH`를 설정했다면 consumer URL에도 같은 prefix를 사용합니다.

### 운영 서버

```bash
uv run python -m fastapi run docmesh_doc/main.py \
  --host 0.0.0.0 \
  --port 8000
```

### Docker Compose

저장소의 `docker-compose.yml`은 독립형 로컬 stack이 아니라 배포용 조립 예시입니다. 다음 항목을 미리 준비해야 합니다.

- `.release/.env`
- 외부 Docker network `docmesh-infra_net`
- 해당 network에서 접근 가능한 Traefik, MinIO, Keycloak

준비가 끝난 뒤 실행합니다.

```bash
docker compose up --build
```

Compose 파일은 document service와 PostgreSQL만 생성합니다. MinIO·Keycloak·Traefik은 외부 인프라를 사용합니다.

## API 빠른 시작

기본 API 경로는 다음과 같습니다. 모든 document API에는 bearer token이 필요합니다.

| 기능 | Method | Path |
| --- | --- | --- |
| Token 발급 | `POST` | `/token` |
| 현재 사용자 | `GET` | `/user` |
| 문서 업로드 | `POST` | `/documents` |
| 문서 목록 | `GET` | `/documents` |
| Metadata 조회 | `GET` | `/documents/{document_id}` |
| 전체 콘텐츠 | `GET` | `/documents/{document_id}/content` |
| Streaming download | `GET` | `/documents/{document_id}/download` |
| Soft delete | `DELETE` | `/documents/{document_id}` |
| Hard delete | `DELETE` | `/documents/{document_id}?hard=true` |
| Liveness | `GET` | `/health/liveness` |
| Readiness | `GET` | `/health/readiness` |

### 상태 확인

```bash
curl --fail http://127.0.0.1:8000/health/liveness
curl --fail http://127.0.0.1:8000/health/readiness
```

### Token 발급

```bash
curl --request POST http://127.0.0.1:8000/token \
  --header 'Content-Type: application/x-www-form-urlencoded' \
  --data-urlencode 'username=<username>' \
  --data-urlencode 'password=<password>'
```

### 문서 업로드

```bash
curl --request POST http://127.0.0.1:8000/documents \
  --oauth2-bearer '<access-token>' \
  --form 'file=@./contract.pdf;type=application/pdf' \
  --form 'document_id=contract-2026-0001' \
  --form-string 'metadata={"category":"contract"}'
```

업로드의 `created_by`는 요청 form field가 아니라 인증 사용자의 `sub`에서 결정됩니다. 내부 `storage_key`는 공개 metadata response에 포함되지 않습니다.

### 문서 다운로드

```bash
curl --fail --location \
  --oauth2-bearer '<access-token>' \
  --output contract.pdf \
  'http://127.0.0.1:8000/documents/contract-2026-0001/download?chunk_size=65536'
```

### 문서 삭제

```bash
# Soft delete
curl --request DELETE \
  --oauth2-bearer '<access-token>' \
  http://127.0.0.1:8000/documents/contract-2026-0001

# Hard delete: document:delete:hard role 필요
curl --request DELETE \
  --oauth2-bearer '<access-token>' \
  'http://127.0.0.1:8000/documents/contract-2026-0001?hard=true'
```

Soft delete는 object를 삭제하고 metadata를 `deleted` 상태로 보존합니다. 이후 일반 metadata/content/download API는 해당 문서를 `404 DOCUMENT_NOT_FOUND`로 처리합니다.

더 많은 호출 예시는 [API 사용 예시](docs/examples.md), 전체 request/response 및 오류 계약은 [API Reference](docs/api.md)를 참조하세요.

## API 문서

서버 실행 후 다음 경로를 사용할 수 있습니다.

- OpenAPI schema: `/openapi.json`
- Swagger UI: `/docs`
- ReDoc: `/redoc`

운영 환경에서 이 경로를 외부에 공개할지는 reverse proxy 정책으로 통제하세요.

## 테스트

전체 테스트를 실행합니다.

```bash
uv run pytest
```

외부 저장소가 필요 없는 테스트만 실행하려면 다음 marker 식을 사용합니다.

```bash
uv run pytest -m 'not integration'
```

실제 PostgreSQL·MinIO가 준비된 환경에서 통합 테스트만 실행할 수 있습니다.

```bash
uv run pytest -m integration
```

일부 hard-delete 통합 테스트는 test user에게 `document:delete:hard` role이 없으면 skip됩니다.

## 프로젝트 구조

```text
docmesh_doc/
├── application.py       # FastAPI app 및 DMS managed resource 조립
├── dependencies.py      # 인증 사용자와 DMS SDK dependency
├── document_http.py     # HTTP 입력 검증 및 download header 정책
├── errors.py            # 오류 mapping과 공통 response renderer
├── main.py              # ASGI entrypoint
├── router.py            # /documents route
└── schemas.py           # 공개 response schema

test_docmesh_doc/        # 단위/API/통합 테스트
docs/                    # 제품·요구사항·API·설정·테스트 문서
wiki/                    # upstream package 조사와 근거 자료
```

## 문서

| 문서 | 내용 |
| --- | --- |
| [제품 요구사항 정의서](docs/prd.md) | 제품 목표, 범위, 사용자 흐름, 수용 기준 |
| [소프트웨어 요구사항 정의서](docs/srs.md) | 아키텍처, 저장소, 보안, API 및 품질 요구사항 |
| [API Reference](docs/api.md) | 공개 HTTP/hosting API, schema, 오류 및 추적성 |
| [API 사용 예시](docs/examples.md) | API별 `curl`과 hosting 예시 |
| [설정 정의서](docs/config.md) | 환경변수, secret, reverse proxy 및 readiness 정책 |
| [메시징 정의서](docs/messaging.md) | 현재 메시징 경계와 비범위 |
| [테스트 정의서](docs/test.md) | 요구사항별 테스트 범위와 release gate |

## 현재 알려진 제약

- 업로드 성공 response의 `Location` header는 현재 `ROOT_PATH`를 포함하지 않고 `/documents/{document_id}` 형식으로 생성됩니다.
- 런타임 request validation은 `400 VALIDATION_ERROR`로 정규화되지만 생성 OpenAPI에는 FastAPI 기본 422 response가 남아 있습니다.
- 전체 콘텐츠 API는 bytes를 한 번에 메모리에 적재하므로 큰 문서는 streaming download API를 사용해야 합니다.
- MinIO health check는 bucket별 읽기·쓰기·삭제 권한까지 보장하지 않으므로 배포 전 별도 확인이 필요합니다.
