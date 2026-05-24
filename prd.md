# PRD - DocMesh Document Service

## 1. 목적

DocMesh Document Service는 인증된 사용자가 문서를 안전하게 업로드/다운로드/삭제할 수 있는 파일 전용 API를 제공한다.

## 2. 문제 정의

- 서비스별로 인증/스토리지 연동 구현이 중복되면 유지보수 비용이 커진다.
- 사용자별 파일 경계가 명확하지 않으면 접근 통제가 약해진다.
- 삭제 이력/복구 가능성을 고려해 즉시 물리 삭제를 피할 필요가 있다.

## 3. 제품 목표

- Keycloak 기반 인증을 통과한 사용자만 문서 API 접근 가능
- MinIO 기반 영속 저장
- 사용자별 네임스페이스 분리 (`{username}/{file_path}`)
- Soft Delete 지원

## 4. 범위

### 포함

- 문서 업로드/다운로드/삭제 API
- 헬스체크 API
- fastapi-core 기반 인증/설정/앱 조립

### 제외(추후)

- 문서 메타데이터 검색/필터링
- 버전 관리
- Audit/Metadata 외부 서비스 연동

## 5. 사용자/이해관계자

- 백엔드 개발자: 문서 저장 API 연동
- 플랫폼/운영: Keycloak·MinIO 설정 및 운영

## 6. 기능 요구사항

1) 업로드
- 인증 필요
- `file_path` + 파일 본문 수신
- MinIO에 저장, `deleted=false` 태그 기록

2) 다운로드
- 인증 필요
- Soft Delete 또는 미존재 시 404
- 파일 스트리밍 응답

3) 삭제
- 인증 필요
- 물리 삭제 대신 `deleted=true` 설정
- 미존재 시 404

4) 헬스체크
- `/health/live`, `/health/ready` 제공

## 7. 비기능 요구사항

- 보안: Bearer 토큰 필수
- 확장성: Stateless 구조 유지
- 신뢰성: Soft Delete 일관 동작
- 운영성: 환경변수/YAML 기반 설정

## 8. 성공 기준

- 핵심 API(업로드/다운로드/삭제) 정상 동작
- 권한 체크(role/scope) 정상 동작
- 자동 테스트 통과
