# 테스트 가이드 - DocMesh Document Service

## 1. 목적

이 문서는 현재 코드 기준 테스트 범위, 실행 방법, 케이스 의도를 정의한다.

## 2. 실행 방법

```bash
uv sync
uv run python -m pytest -q
```

## 3. 테스트 구조

- `test_docmesh_doc/routes/test_documents.py`
  - 문서 업로드/다운로드
  - Soft Delete
  - 미존재 삭제 404
- `test_docmesh_doc/routes/test_health.py`
  - `/health/live`
  - `/health/ready`
- `test_docmesh_doc/dependencies/test_security.py`
  - role/scope 권한 체크 성공/실패
- `test_docmesh_doc/services/test_security.py`
  - auth provider 생성 기본 검증

## 4. 핵심 검증 시나리오

1) 업로드 후 다운로드
- 업로드 200
- 다운로드 200
- 본문/Content-Type 검증

2) Soft Delete
- 삭제 204
- 동일 파일 재조회 404

3) 미존재 삭제
- 404 반환

4) 헬스체크
- live/ready 각각 200 + 예상 JSON

5) 권한 체크
- 필요한 role/scope 만족 시 통과
- 부족 시 403 + `insufficient_scope`

## 5. 환경 의존성

- 문서 라우트 테스트는 MinIO 접근 필요
- MinIO 미접근 시 해당 모듈은 `pytest.skip` 처리

## 6. 향후 보강 항목

- `/token`, `/user` 엔드포인트 통합 테스트
- 대용량 파일 업로드/다운로드 성능 테스트
- 권한 케이스(role/scope 조합) 확장
- 실패 시나리오(잘못된 토큰, MinIO 장애) 확장
