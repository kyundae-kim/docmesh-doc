# DocMesh Document Service - WIKI

DocMesh Document Service는 인증된 사용자가 문서를 안전하게 업로드/다운로드/삭제하고,
문서에 연관된 metadata를 CRUD할 수 있는 FastAPI 기반 서비스입니다.

---

## 목차

| 페이지 | 설명 |
|--------|------|
| [개요 및 아키텍처](./Overview.md) | 서비스 목적, 아키텍처 구성, 핵심 동작 |
| [빠른 시작](./QuickStart.md) | 설치, 실행, 테스트 방법 |
| [설정 가이드](./Configuration.md) | 환경변수, YAML 설정, create_app 파라미터 |
| [API 명세 - 인증](./API-Auth.md) | POST /token, GET /user |
| [API 명세 - 문서](./API-Documents.md) | 문서 업로드/다운로드/삭제 |
| [API 명세 - Metadata](./API-Metadata.md) | Metadata CRUD |
| [API 명세 - 헬스체크](./API-Health.md) | /health/live, /health/ready |
| [데이터 모델 및 저장소](./DataModel.md) | DB 스키마, 테이블 구조, 저장소 정책 |
| [DB 마이그레이션](./Migration.md) | Alembic 마이그레이션 가이드 |
| [요구사항 (PRD)](./PRD.md) | 제품 목표, 기능/비기능 요구사항, 성공 기준 |

---

## 서비스 한눈에 보기

```
[Client]
   |
   | Bearer Token (Keycloak)
   v
[DocMesh Document Service (FastAPI)]
   |
   +---> MinIO (문서 원문 저장, Soft Delete)
   |
   +---> PostgreSQL (문서 인덱스 + Metadata, Alembic 관리)
```

- 문서 식별: document_id (UUID)
- 인증: Keycloak OAuth2/OIDC
- 문서 삭제: Soft Delete (MinIO tag `deleted=true`)
- Metadata: 문서당 1건 (1:1)
