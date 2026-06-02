# API 명세 - 헬스체크

## GET /health/live

서비스 생존 여부를 확인한다 (Liveness).

**응답 200:**

```json
{ "status": "ok" }
```

---

## GET /health/ready

서비스 준비 여부를 확인한다 (Readiness).
YAML 설정에서 체크 항목(Keycloak, DB, MinIO)을 제어할 수 있다.

**응답 200:**

```json
{ "status": "ok" }
```

**YAML 설정:**

```yaml
health:
  check_keycloak: true   # Keycloak 헬스 확인
  check_database: true   # DB 연결 확인
  check_minio: true      # MinIO 연결 확인
```

---

[홈으로](./Home.md) | [이전: Metadata API](./API-Metadata.md)
