# 테스트 가이드 - DocMesh Document Service

## 1. 목적

이 문서는 문서 서비스의 테스트를
- Mock 테스트(단위/격리)
- 연동 테스트(통합/E2E 성격)
로 분리해 작성하는 기준을 정의한다.

## 2. 실행 방법

### 2.1 Mock 테스트

외부 의존성(MinIO, Postgres, Auth Provider)을 mock/stub 처리한 테스트.

```bash
uv sync
uv run python -m pytest -q -m "not integration"
```

### 2.2 연동 테스트

실제 MinIO/Postgres(테스트용 인스턴스)와 연동해 검증하는 테스트.

```bash
uv sync
uv run python -m pytest -q -m integration
```

### 2.3 전체 테스트

```bash
uv sync
uv run python -m pytest -q
```

## 3. 테스트 전략

### 3.1 Mock 테스트 범위

- 라우트 입력/출력 스키마 검증
- 상태 코드 검증(200/201/204/400/404/409)
- 권한 실패/성공 분기 검증
- 서비스 레이어 호출 여부 및 인자 검증
- 예외 처리 및 에러 포맷 검증

### 3.2 연동 테스트 범위

- 문서 업로드/다운로드/삭제의 실 저장소 동작 검증
- metadata CRUD의 실 DB 반영 검증
- `document_id` 기반 접근 경로 검증
- 문서-metadata 1:1 제약(중복 생성 409) 검증
- Soft Delete 이후 조회 차단 검증

## 4. 테스트 구조

- `test_docmesh_doc/routes/test_documents.py`
  - Mock: 문서 업로드/다운로드/삭제 (ID 기반), 에러 케이스
  - 연동: MinIO 실제 업로드/다운로드/Soft Delete
- `test_docmesh_doc/routes/test_document_metadata.py`
  - Mock: metadata CRUD, 요청 검증 실패 케이스
  - 연동: Postgres 반영, 1:1 제약(409)
- `test_docmesh_doc/routes/test_health.py`
  - Mock: `/health/live`, `/health/ready`
- `test_docmesh_doc/dependencies/test_security.py`
  - Mock: role/scope 권한 체크
- `test_docmesh_doc/services/test_security.py`
  - Mock: auth provider 생성 기본 검증

## 5. 핵심 검증 시나리오

1) 문서 API (ID 기반)
- 업로드 201 + `document_id` 반환
- 다운로드(`GET /documents/{document_id}`) 200
- 삭제(`DELETE /documents/{document_id}`) 204
- 삭제 후 재조회 404

2) metadata API (문서별 1:1)
- 생성(`POST /documents/{document_id}/metadata`) 201
- 조회(`GET /documents/{document_id}/metadata`) 200
- 수정(`PATCH /documents/{document_id}/metadata`) 200
- 삭제(`DELETE /documents/{document_id}/metadata`) 204
- 이미 metadata 존재 시 재생성 409

3) 권한/에러
- 인증 실패 401
- 권한 부족 403 + `insufficient_scope`
- 미존재 문서/metadata 404
- 잘못된 payload 400

## 6. 마커 및 실행 규칙

- Mock 테스트: `@pytest.mark.unit` 또는 `@pytest.mark.mock`
- 연동 테스트: `@pytest.mark.integration`
- CI 권장:
  1) PR 단계: mock 테스트 우선 실행
  2) main 병합 전/야간: 연동 테스트 포함 전체 실행

## 7. 환경 의존성

- Mock 테스트: 외부 인프라 없이 실행 가능
- 연동 테스트: MinIO/Postgres 테스트 인스턴스 필요
- 연동 환경 미구성 시 integration 테스트는 skip 처리

## 8. 테스트 데이터/격리 전략

- 각 테스트는 고유 `document_id`/테스트 파일명/metadata payload 사용
- 연동 테스트 종료 후 생성 데이터 정리
- 가능하면 트랜잭션 롤백 또는 테스트 전용 스키마 사용

## 9. 향후 보강 항목

- `/token`, `/user` 엔드포인트 연동 테스트 강화
- 장애 주입(스토리지/DB 일시 실패) 회복 시나리오
- 대용량 파일 + 동시 요청 성능/안정성 검증
