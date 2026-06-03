# 요구사항 (PRD)

## 1. 목적

DocMesh Document Service는 인증된 사용자가 문서를 안전하게 업로드/다운로드/삭제하고,
문서에 연관된 metadata를 CRUD할 수 있는 API를 제공한다.

---

## 2. 문제 정의

- 서비스별로 인증/스토리지 연동 구현이 중복되면 유지보수 비용이 커진다.
- 사용자별 파일 경계가 명확하지 않으면 접근 통제가 약해진다.
- 삭제 이력/복구 가능성을 고려해 즉시 물리 삭제를 피할 필요가 있다.
- 문서 접근을 `file_path`에 의존하면 경로 변경/이관 시 참조 안정성이 떨어진다.
- 문서와 metadata 관계가 1:1로 고정되어야 하는 도메인에서 별도 맵핑 구조는 복잡도를 높인다.

---

## 3. 제품 목표

- Keycloak 기반 인증을 통과한 사용자만 문서 API 접근 가능
- MinIO 기반 문서 영속 저장
- 문서는 `document_id (UUID)` 기반으로 접근
- Soft Delete 지원
- PostgreSQL 기반 metadata 저장/관리
- 문서와 metadata를 1:1로 관리

---

## 4. 범위

### 포함

- 문서 업로드/다운로드/삭제 API (ID 기반)
- Metadata CRUD API (문서별 1:1)
- 헬스체크 API
- fastapi-core 기반 인증/설정/앱 조립

### 제외 (추후)

- Metadata 고급 검색 (복합 조건/전문 검색)
- Metadata 버전 관리
- Audit/Metadata 외부 서비스 연동

---

## 5. 사용자/이해관계자

| 역할 | 관심사 |
|------|--------|
| 백엔드 개발자 | 문서 저장 API, Metadata API 연동 |
| 플랫폼/운영 | Keycloak·MinIO·PostgreSQL 설정 및 운영 |

---

## 6. 기능 요구사항

1. **문서 업로드** - 인증 필요, 파일 수신, UUID 생성, MinIO 저장 (`deleted=false` 태그)
2. **문서 다운로드** - 인증 필요, document_id로 조회, Soft Delete/미존재 시 404, 파일 스트리밍
3. **문서 삭제** - 인증 필요, Soft Delete (`deleted=true`), 미존재 시 404
4. **Metadata 생성** - 인증 필요, document_id 기준 생성, PostgreSQL 저장, 1:1 제약
5. **Metadata 조회** - 인증 필요, document_id 기준 단건 조회
6. **Metadata 수정** - 인증 필요, document_id 기준 부분 수정 (PATCH)
7. **Metadata 삭제** - 인증 필요, document_id 기준 삭제
8. **헬스체크** - `/health/live`, `/health/ready` 제공

---

## 7. 비기능 요구사항

| 항목 | 내용 |
|------|------|
| 보안 | Bearer 토큰 필수 |
| 확장성 | Stateless 구조 유지 |
| 신뢰성 | Soft Delete 일관 동작, Metadata 트랜잭션 일관성 보장 |
| 운영성 | 환경변수/YAML 기반 설정 |
| 성능 | 문서 조회 시 Metadata 단건 조회가 과도한 추가 쿼리를 유발하지 않도록 구현 |
| 마이그레이션 | 프로덕션 DB 스키마 변경은 Alembic으로 버전 관리, `create_all()` 금지 |

---

## 8. 성공 기준

- 핵심 API (문서 업로드/다운로드/삭제) 정상 동작
- Metadata CRUD API 정상 동작
- 문서 접근이 `document_id` 기준으로 동작
- 문서-Metadata 1:1 제약 보장
- 권한 체크 (role/scope) 정상 동작
- 자동 테스트 통과

---

[홈으로](./Home.md)
