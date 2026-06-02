# DB 마이그레이션

PostgreSQL 스키마 변경은 Alembic으로 관리한다.

## 정책

| 환경 | 방식 |
|------|------|
| 개발 환경 | `Base.metadata.create_all()` 허용 (빠른 반복 개발) |
| 프로덕션 | Alembic 마이그레이션만 허용 (`create_all()` 금지) |

## Alembic 도입 이유

- `create_all()`은 기존 테이블의 컬럼 추가/삭제/변경을 감지하지 못한다.
- 프로덕션에서 스키마 변경 이력이 추적되지 않아 롤백이 불가능하다.
- Alembic 마이그레이션 파일은 git으로 버전 관리되어 팀 단위 스키마 변경을 명시적으로 검토할 수 있다.

---

## 프로젝트 구조

```
docmesh_doc/
  models/
    base.py          # 공통 Base 클래스 (DeclarativeBase)
    metadata.py      # DocumentMetadataModel (공통 Base 상속)
alembic/
  env.py
  versions/
    <revision>_initial_schema.py
alembic.ini
```

---

## 명령어 가이드

```bash
# 최초 설정
uv run alembic init alembic

# 마이그레이션 파일 자동 생성
uv run alembic revision --autogenerate -m "initial schema"

# 마이그레이션 적용
uv run alembic upgrade head

# 이전 버전으로 롤백
uv run alembic downgrade -1
```

---

## alembic/env.py 핵심 설정

```python
from docmesh_doc.models.base import Base
from docmesh_doc.models import metadata  # noqa: F401 (모델 임포트로 Base에 등록)

target_metadata = Base.metadata
```

---

## 마이그레이션 환경변수

```
DB__HOST
DB__PORT
DB__NAME
DB__USER
DB__PASSWORD
```

---

[홈으로](./Home.md)
