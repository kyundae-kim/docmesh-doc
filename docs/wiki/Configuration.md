# 설정 가이드

## 환경변수 (EnvConfig)

### Keycloak

| 변수 | 설명 |
|------|------|
| `KEYCLOAK__HTTP_URL` | Keycloak HTTP URL |
| `KEYCLOAK__REALM` | Realm 이름 |
| `KEYCLOAK__CLIENT_ID` | 클라이언트 ID |
| `KEYCLOAK__CLIENT_SECRET` | 클라이언트 시크릿 |

### MinIO

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `MINIO__ENDPOINT` | MinIO 엔드포인트 | |
| `MINIO__ACCESS_KEY` | Access Key | |
| `MINIO__SECRET_KEY` | Secret Key | |
| `MINIO__BUCKET` | 버킷 이름 | |
| `MINIO__PRESIGNED_EXPIRES_SEC` | Presigned URL 만료 시간(초) | 900 |

### Database (PostgreSQL)

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `DB__HOST` | DB 호스트 | |
| `DB__PORT` | DB 포트 | |
| `DB__NAME` | DB 이름 | |
| `DB__USER` | DB 사용자 | |
| `DB__PASSWORD` | DB 비밀번호 | |
| `DB__URL` | 직접 DSN 지정 시 위 항목 무시 | |
| `DB__SSLMODE` | SSL 모드 | prefer |
| `DB__POOL_SIZE` | 커넥션 풀 크기 | 5 |

### NATS

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `NATS__SERVERS` | 서버 주소 (쉼표 구분 멀티) | nats://nats:4222 |
| `NATS__NAME` | 클라이언트 이름 | fastapi-core |
| `NATS__CONNECT_TIMEOUT` | 연결 타임아웃(초) | 2 |
| `NATS__MAX_RECONNECT_ATTEMPTS` | 최대 재연결 시도 | 60 |
| `NATS__RECONNECT_TIME_WAIT_MS` | 재연결 대기 시간(ms) | 2000 |
| `NATS__QUEUE_GROUP` | 큐 그룹 이름 | default-workers |

### 기타

| 변수 | 설명 | 기본값 |
|------|------|--------|
| `CONFIG_PATH` | YAML 설정 파일 경로 | .devcontainer/config.yaml |
| `LOGGING__LEVEL` | 로그 레벨 (WARNING/INFO/DEBUG) | DEBUG |

---

## YAML 서비스 설정 (ServiceSettings)

`CONFIG_PATH`(기본: `.devcontainer/config.yaml`)에서 로드된다.

```yaml
cors:
  origins: ["*"]
  credentials: false

auth:
  verify_jwt: true               # JWT 서명 검증 여부
  allow_insecure_jwt_decode: false  # 서명 없이 디코드 허용 (개발용)
  use_introspection: false       # 토큰 인트로스펙션 사용 여부

health:
  check_keycloak: true           # readiness 시 Keycloak 헬스 확인
  check_database: true           # readiness 시 DB 연결 확인
  check_minio: true              # readiness 시 MinIO 연결 확인
```

---

## create_app 파라미터

```python
from fastapi_core import create_app

app = create_app(
    config=None,              # EnvConfig 인스턴스 (None이면 자동 생성)
    settings=None,            # ServiceSettings 인스턴스 (None이면 YAML에서 로드)
    lifespan=None,            # FastAPI lifespan 콜백
    include_auth_router=True  # False로 설정 시 /token, /user 라우트 미포함
)
```

---

[홈으로](./Home.md)
