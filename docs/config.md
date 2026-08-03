# 설정 정의서

## 설정 ownership

DMS v0.7.0은 환경변수에서 database/object-store client를 직접 만들지 않습니다. 설정과 lifecycle은 다음 경계를 따릅니다.

| 계층 | 책임 |
| --- | --- |
| `fastapi-core` `AppConfig` | `ROOT_PATH`, `TOKEN_URL`, CORS, auth router, application logging, service-runtime/readiness 정책 |
| `docmesh-config` | process environment 기반 common/service config, 선택 서비스 loader, network-free diagnosis |
| `docmesh_doc.dms_factory` | `DMS_METADATA_BACKEND`, strict 선택, legacy DSN 거부, client factory 호출과 DMS plan 조립 |
| `docmesh-py-core` | 검증된 `PostgresConfig`/`SqliteConfig`/`MinioConfig`로 SQLAlchemy·MinIO wrapper 생성 |
| `dms` | 이미 생성된 client/component를 받아 document SDK·metadata/object lifecycle 제공 |

`.env` 파일은 자동으로 읽지 않습니다. shell, container runtime 또는 secret manager가 process environment로 값을 주입해야 합니다. secret과 실제 endpoint를 source control에 저장하지 않습니다.

## DMS host 설정

| 변수 | 기본/필수 | 설명 |
| --- | --- | --- |
| `DMS_METADATA_BACKEND` | `postgresql` | `postgresql` 또는 `sqlite`만 허용합니다. |
| `DMS_CONFIGURATION_STRICT` | `false` | `true`이면 PostgreSQL/SQLite 대안이 동시에 설정된 경우 조립을 거부합니다. 값은 `true`/`false`여야 합니다. |
| `POSTGRES_DSN` | 사용하지 않음 | v0.7 host adapter가 조립 전에 거부합니다. 개별 `POSTGRES_*` 필드를 사용합니다. |
| `MINIO_BUCKET` | 필수 | DMS object store bucket입니다. |

DMS package 자체는 위 `DMS_*` 변수나 `POSTGRES_DSN`을 읽지 않습니다. 이 변수들은 제품 host adapter의 policy입니다.

## PostgreSQL metadata store

`DMS_METADATA_BACKEND=postgresql`일 때 다음 개별 필드를 제공합니다.

```env
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=docmesh
POSTGRES_USER=docmesh
POSTGRES_PASSWORD=<secret>
```

선택 connection/pool 설정은 `docmesh-config`의 `PostgresConfig`가 소유합니다. 비밀번호와 connection URL은 로그에 출력하지 않습니다.

## SQLite metadata store

로컬 개발에서만 다음과 같이 선택합니다.

```env
DMS_METADATA_BACKEND=sqlite
DMS_CONFIGURATION_STRICT=true
SQLITE_PATH=./data/docmesh.sqlite3
```

SQLite는 metadata store만 대체합니다. 본문 저장소는 여전히 MinIO가 필요합니다. `SQLITE_READONLY`, WAL, busy timeout 등 세부 옵션은 설치된 `docmesh-config`/`docmesh-py-core` 버전의 config field를 기준으로 주입합니다.

## MinIO object store

```env
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=documents
MINIO_SECURE=true
MINIO_CERT_CHECK=true
```

운영에서는 TLS와 인증서 검증을 사용하고 최소 권한 bucket/account를 적용합니다. DMS startup health가 bucket의 모든 업무 권한을 보장하지 않으므로 배포 전 실제 read/write/delete 권한을 별도로 확인합니다.

## FastAPI application

```env
ROOT_PATH=/dms
TOKEN_URL=/dms/token
CORS_ORIGINS=https://example.com
CORS_CREDENTIALS=false
DOCMESH_SERVICES=keycloak
READINESS_REQUIRED_SERVICES=keycloak
```

`TOKEN_URL`은 OpenAPI OAuth2 password flow URL이고 실제 token route는 `/token`입니다. `ROOT_PATH`는 reverse proxy 외부 prefix입니다. DMS aggregate health는 `dms` managed resource의 required readiness check이며 FastAPI service-runtime health와 중복해서 조립하지 않습니다.

## 설정 오류

- backend가 `postgresql`/`sqlite`가 아니면 host factory가 실패합니다.
- 선택 backend의 필수 field가 없으면 `docmesh-config` loader가 실패합니다.
- `MINIO_BUCKET`이 없으면 DMS SDK 조립이 실패합니다.
- `POSTGRES_DSN`이 있으면 개별 field가 함께 있어도 host factory가 실패합니다.
- startup factory 오류는 애플리케이션 startup을 중단하고, 실행 중 필수 health 오류는 readiness `503`으로 투영됩니다.
