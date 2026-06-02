# 빠른 시작

## 1. 의존성 설치

```bash
uv sync
```

## 2. 앱 실행

```bash
uv run fastapi dev docmesh_doc/main.py
```

## 3. 테스트 실행

```bash
uv run python -m pytest -q
```

## 4. DB 마이그레이션 적용

```bash
uv run alembic upgrade head
```

## 전제 조건

서비스 실행 전 다음 인프라가 준비되어야 한다:

| 인프라 | 용도 |
|--------|------|
| Keycloak | OAuth2/OIDC 인증 |
| MinIO | 문서 원문 저장 |
| PostgreSQL | 문서 인덱스 및 Metadata 저장 |
| NATS (선택) | 메시징 |

환경변수 설정은 [설정 가이드](./Configuration.md)를 참고하세요.

---

[홈으로](./Home.md)
