# 설정 정의서

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 참조 문서 | [PRD](prd.md), [SRS](srs.md), [API Reference](api.md) |

## 1. 목적과 원칙

이 문서는 DocMesh Document Service를 PostgreSQL metadata store와 MinIO object store 조합으로 실행하기 위한 환경 설정을 정의한다.

- 모든 runtime, 개발, 테스트, 배포 환경에서 metadata store는 PostgreSQL만 사용한다.
- 모든 환경에서 문서 본문 저장소는 MinIO다.
- PostgreSQL·MinIO 설정은 서비스 startup 전에 검증하며, 둘 중 하나라도 준비되지 않으면 서비스는 ready 상태가 되면 안 된다.
- secret은 source code나 문서의 실제 값으로 제공하지 않는다. 배포 플랫폼의 secret store 또는 권한이 제한된 환경변수로 주입한다.
- `fastapi-core` 개발 fallback은 운영 설정으로 사용하지 않는다.

## 2. 설정 로딩 및 우선순위

서비스는 컨테이너 environment 또는 실행 프로세스 environment에서 값을 읽는다. Docker Compose 배포는 `docker-compose.yml`의 `document.env_file`로 `.release/.env`를 주입한다.

권장 우선순위는 다음과 같다.

1. 배포 플랫폼의 secret/environment 주입
2. 배포별 권한 제한 env file (예: `.release/.env`)
3. 개발 환경의 로컬 env file (Git 제외)
4. 코드의 안전한 비밀값 없는 기본값

운영 환경에서 `POSTGRES_DSN`, `MINIO_SECRET_KEY`, `KEYCLOAK_CLIENT_SECRET`의 기본값을 두거나 source code에 기록해서는 안 된다.

## 3. 필수 설정

다음 변수는 서비스의 document lifecycle에 필수다. 값이 없거나 빈 문자열이면 startup 실패 또는 readiness 실패로 처리해야 한다.

| 변수 | 필수 | 예시 형식 | 설명 |
| --- | --- | --- | --- |
| `POSTGRES_DSN` | 예 | `postgresql://<user>:<password>@postgres:5432/docmesh` | PostgreSQL metadata store 연결 문자열 |
| `MINIO_ENDPOINT` | 예 | `minio.internal:9000` | MinIO endpoint. scheme은 포함하지 않는다. |
| `MINIO_ACCESS_KEY` | 예 | `<access-key>` | MinIO access key |
| `MINIO_SECRET_KEY` | 예 | `<secret-key>` | MinIO secret key |
| `MINIO_BUCKET` | 예 | `documents` | 문서 본문을 보관할 bucket 이름 |

### 3.1 PostgreSQL

`POSTGRES_DSN`은 PostgreSQL database, user, password, host, port를 모두 포함하는 연결 문자열이다.

- metadata에는 문서 ID, 원본 filename, content type, 크기, 상태, MinIO `storage_key`, 생성·수정·삭제 시각, 생성자, checksum, 사용자 정의 metadata가 저장된다.
- PostgreSQL user는 필요한 schema/table에 대한 최소 권한만 가져야 한다.
- TLS·인증서·연결 timeout 같은 세부 연결 정책은 사용하는 PostgreSQL driver와 배포 플랫폼 정책에 맞춰 DSN 또는 별도 배포 구성으로 설정한다.
- DSN 전체 문자열은 로그, API 오류 response, issue, shell history에 남기지 않는다.

### 3.2 MinIO

`MINIO_ENDPOINT`는 DNS 이름과 port로 설정한다. TLS 여부는 `MINIO_SECURE`로 지정한다.

- bucket은 서비스 startup 전에 존재하고 접근 가능해야 한다.
- 서비스의 MinIO credential에는 대상 bucket에 대한 읽기·쓰기·삭제 권한이 필요하다.
- 업무 metadata인 filename, `created_by`, 사용자 정의 metadata는 MinIO object metadata가 아니라 PostgreSQL metadata에 저장한다.
- 실제 endpoint, access key, secret key는 API response와 structured log에 포함해서는 안 된다.

## 4. 선택 설정

### 4.1 DMS SDK 설정

| 변수 | 기본값 | 권장값 | 설명 |
| --- | --- | --- | --- |
| `DOCMESH_ENV` | 환경별 | `prod`, `staging`, `development`, `test` 중 하나 | 실행 환경 식별자 |
| `DOCMESH_HEALTHCHECK_ENABLED` | `true` | `true` | SDK 생성 시 PostgreSQL·MinIO health check 수행 |
| `MINIO_SECURE` | 구현 기본값 따름 | 운영 `true`, 신뢰된 로컬 통합 환경은 `false` 가능 | MinIO TLS 사용 여부 |

`DOCMESH_HEALTHCHECK_ENABLED=false`는 단위 테스트에서 명시적으로 격리할 때만 허용한다. integration, staging, production 환경에는 사용하지 않는다.

### 4.2 FastAPI 애플리케이션 설정

`fastapi-core.create_app(...)`은 다음 앱 설정을 읽는다.

| 변수 | 기본값 | 운영 권장값 | 설명 |
| --- | --- | --- | --- |
| `ROOT_PATH` | 빈 문자열 | reverse proxy prefix와 동일한 값 | 공개 API 앞 경로. 예: `/dms` |
| `TOKEN_URL` | `/token` | `ROOT_PATH`를 포함한 token URI | OpenAPI OAuth2 password flow의 token URL |
| `CORS_ORIGINS` | 패키지 기본값 | 명시 origin CSV | 허용 origin 목록 |
| `CORS_CREDENTIALS` | `false` | 필요한 경우에만 `true` | cross-origin credential 허용 여부 |
| `READINESS_PARALLEL` | `false` | 서비스 check 수에 따라 결정 | readiness check 병렬 실행 여부 |
| `DOCMESH_LOG_LEVEL` | `WARNING` | `INFO` | application log level |
| `APP_LOG_PATH` | 없음 | 플랫폼 로그 수집 경로 또는 미설정 | 선택 file log 경로 |
| `APP_LOG_JSON` | `true` | `true` | JSON structured logging 사용 여부 |
| `APP_LOG_FORCE` | `false` | `false` | root logger 강제 재구성 여부 |
| `DOCMESH_SERVICES` | 패키지 기본값 | 활성 외부 service client 목록 | `fastapi-core` service client 구성 대상 |
| `READINESS_REQUIRED_SERVICES` | 패키지 기본값 | 실패 시 503을 유발할 service 목록 | 공통 service-client readiness 정책 |

#### `ROOT_PATH`와 `TOKEN_URL`

Docker Compose의 Traefik route가 `PathPrefix(`/dms`)`이면 다음처럼 설정한다.

```env
ROOT_PATH=/dms
TOKEN_URL=/dms/token
```

이때 API consumer의 문서 URI는 `/dms/documents/{document_id}`, token URI는 `/dms/token`이다. reverse proxy path와 `ROOT_PATH`가 다르면 OpenAPI와 실제 URL이 불일치할 수 있다.

#### CORS 보안 정책

- `CORS_ORIGINS`는 쉼표 구분 origin 목록이다.
- `CORS_CREDENTIALS=true`이면 wildcard origin을 사용해서는 안 된다.
- 운영 environment에서는 최소한 서비스 UI/API consumer의 HTTPS origin만 허용한다.

```env
CORS_ORIGINS=https://app.example.com,https://admin.example.com
CORS_CREDENTIALS=true
```

### 4.3 인증 설정

MVP의 `/token`, `/user`, 보호된 document route는 Keycloak 인증을 사용하므로 다음 설정이 필수다. 값이 없거나 빈 문자열이면 서비스는 startup을 실패해야 한다.

| 변수 | 필수 조건 | 설명 |
| --- | --- | --- |
| `KEYCLOAK_URL` | 예 | Keycloak base URL |
| `KEYCLOAK_REALM` | 예 | 인증 realm |
| `KEYCLOAK_CLIENT_ID` | 예 | OAuth2 client ID |
| `KEYCLOAK_CLIENT_SECRET` | 예 | OAuth2 client secret |

`KEYCLOAK_CLIENT_SECRET`은 반드시 secret store 또는 권한이 제한된 environment로 주입한다. hard delete role `document:delete:hard`는 Keycloak role mapping에서 부여한다.

### 4.4 선택 외부 서비스

`DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`는 `fastapi-core`가 관리하는 공통 service client 정책을 제어한다. 이 설정은 DMS의 PostgreSQL·MinIO health check를 대체하지 않는다.

- DMS 서비스가 Keycloak 외의 공통 서비스와 연결하지 않으면 해당 service를 활성화하지 않는다.
- NATS, vector search, LLM observability와 같은 추가 서비스는 MVP document lifecycle의 필수 의존성이 아니다.
- 선택 service가 실패했을 때 readiness가 `degraded`를 반환하도록 하려면 해당 service는 enabled이되 required 목록에서 제외한다.
- PostgreSQL 또는 MinIO failure는 언제나 DMS 필수 dependency failure로 처리하고 readiness 503을 반환해야 한다.

## 5. 환경별 설정 예시

다음 예시의 `<...>` 값은 실제 secret이 아니다. 배포 시 secret manager 또는 권한 제한 env file의 실제 값으로 대체한다.

### 5.1 로컬 통합 개발

로컬 통합 개발도 PostgreSQL과 MinIO를 사용한다.

```env
DOCMESH_ENV=development
DOCMESH_HEALTHCHECK_ENABLED=true
POSTGRES_DSN=postgresql://docmesh:<password>@postgres:5432/docmesh
MINIO_ENDPOINT=minio:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=documents
MINIO_SECURE=false

ROOT_PATH=
TOKEN_URL=/token
CORS_ORIGINS=http://localhost:3000
CORS_CREDENTIALS=false
READINESS_PARALLEL=false
DOCMESH_LOG_LEVEL=INFO
APP_LOG_JSON=true

DOCMESH_SERVICES=keycloak
READINESS_REQUIRED_SERVICES=keycloak
KEYCLOAK_URL=http://keycloak:8080
KEYCLOAK_REALM=docmesh
KEYCLOAK_CLIENT_ID=docmesh-document-service
KEYCLOAK_CLIENT_SECRET=<client-secret>
```

### 5.2 Reverse proxy를 통한 운영 배포

현재 Docker Compose는 document service를 Traefik의 `/dms` prefix로 노출한다. PostgreSQL은 같은 backend network에 있으며 MinIO endpoint는 배포 network에서 도달 가능해야 한다.

```env
DOCMESH_ENV=prod
DOCMESH_HEALTHCHECK_ENABLED=true
POSTGRES_DSN=postgresql://docmesh:<password>@postgres:5432/docmesh
MINIO_ENDPOINT=minio.internal:9000
MINIO_ACCESS_KEY=<access-key>
MINIO_SECRET_KEY=<secret-key>
MINIO_BUCKET=documents
MINIO_SECURE=true

ROOT_PATH=/dms
TOKEN_URL=/dms/token
CORS_ORIGINS=https://app.example.com,https://admin.example.com
CORS_CREDENTIALS=true
READINESS_PARALLEL=true
DOCMESH_LOG_LEVEL=INFO
APP_LOG_JSON=true

DOCMESH_SERVICES=keycloak
READINESS_REQUIRED_SERVICES=keycloak
KEYCLOAK_URL=https://identity.example.com
KEYCLOAK_REALM=docmesh
KEYCLOAK_CLIENT_ID=docmesh-document-service
KEYCLOAK_CLIENT_SECRET=<client-secret>
```

## 6. 배포 설정 점검

### 6.1 시작 전 점검

1. `POSTGRES_DSN`이 비어 있지 않고 대상 PostgreSQL server에 연결 가능한지 확인한다.
2. `MINIO_ENDPOINT`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`, `MINIO_BUCKET`이 모두 설정되었는지 확인한다.
3. MinIO bucket이 존재하며 credential이 읽기·쓰기·삭제 권한을 가지는지 확인한다.
4. `DOCMESH_HEALTHCHECK_ENABLED=true`인지 확인한다.
5. reverse proxy prefix가 있으면 `ROOT_PATH`와 `TOKEN_URL`이 그 prefix를 반영하는지 확인한다.
6. `CORS_CREDENTIALS=true`일 때 `CORS_ORIGINS`에 wildcard가 없는지 확인한다.
7. `.release/.env`와 secret manager가 Git 추적·로그·image layer에 포함되지 않는지 확인한다.

### 6.2 기동 후 점검

```bash
curl --fail --silent --show-error \
  --header 'Accept: application/json' \
  https://dms.example.com/dms/health/liveness

curl --fail --silent --show-error \
  --header 'Accept: application/json' \
  https://dms.example.com/dms/health/readiness
```

- liveness가 200이면 프로세스가 HTTP 요청을 처리할 수 있다.
- readiness가 200이면 PostgreSQL과 MinIO를 포함한 필수 의존성이 준비된 상태다.
- readiness가 503이면 document upload/download/delete를 수행하지 말고 response `details`와 correlation ID를 기반으로 장애를 조사한다.

## 7. 설정 오류와 대응

| 증상 | 가능한 원인 | 대응 |
| --- | --- | --- |
| startup 실패 | `POSTGRES_DSN` 또는 MinIO 필수 변수 누락 | 누락·공백 변수를 수정하고 재배포 |
| readiness 503 | PostgreSQL 또는 MinIO 연결/권한/bucket 문제 | network, credential, bucket, dependency health를 점검 |
| API가 proxy prefix 없이 생성됨 | `ROOT_PATH` 불일치 | proxy public path와 `ROOT_PATH`를 동일하게 수정 |
| Swagger/OpenAPI token URL이 틀림 | `TOKEN_URL`이 `ROOT_PATH`를 반영하지 않음 | 공개 token URI로 수정 |
| browser에서 CORS 실패 | origin 누락 또는 credential 정책 불일치 | `CORS_ORIGINS`와 `CORS_CREDENTIALS`를 함께 점검 |
| 401 또는 token 발급 실패 | Keycloak 설정/secret 문제 | `KEYCLOAK_*` 값과 client role mapping 확인 |
| readiness degraded | 선택 공통 service 실패 | 해당 service가 업무상 선택 항목인지 판단하고 service 상태 또는 required 정책 점검 |

## 8. 보안 운영 규칙

1. `.release/.env`와 로컬 env file은 Git에 추가하지 않는다.
2. `POSTGRES_DSN`, `MINIO_SECRET_KEY`, `KEYCLOAK_CLIENT_SECRET`은 로그, API response, ticket, shell history에 노출하지 않는다.
3. secret rotation 시 PostgreSQL, MinIO, Keycloak credential을 각각 갱신하고 readiness 및 인증 flow를 검증한다.
4. 운영 CORS origin은 HTTPS origin으로 제한하고, credential 사용 시 wildcard origin을 금지한다.
5. PostgreSQL과 MinIO는 public internet에 직접 노출하지 않고 service network 또는 private endpoint를 통해 접근하게 한다.
6. startup과 readiness 오류의 조사에는 secret 값 대신 `X-Correlation-ID`와 마스킹된 service detail을 사용한다.

## 9. 추적성

| 항목 | 관련 요구사항/문서 |
| --- | --- |
| PostgreSQL 및 MinIO 필수 구성 | SRS-STO-001 ~ SRS-STO-007 |
| 환경변수·secret 정책 | SRS-CFG-001 ~ SRS-CFG-004 |
| readiness 정책 | SRS-OPS-001 ~ SRS-OPS-005 |
| API 공개 경로 | [API Reference](api.md) §1, §5 |
| API 호출 예시 | [API 사용 예시](examples.md) |
