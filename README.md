# DocMesh Document Service

MinIO 기반 파일 저장을 담당하는 DocMesh Document Service입니다.

이 서비스는 문서 바이너리의 업로드, 다운로드, 삭제(Soft Delete)를 단일 진입점으로 제공하는 것을 목표로 합니다.

## PRD 기반 서비스 정의

- 목적: 조직 내 문서를 객체 스토리지(MinIO)에 안전하게 저장하고, 다른 서비스가 참조할 수 있는 파일 저장 전담 서비스를 제공
- 역할: 파일 업로드/다운로드/삭제의 유일한 진입점
- 원칙: 파일 바이너리 관리에 집중하고 메타데이터/검색/AI 처리는 범위에서 제외

### 포함 범위 (In Scope)

- 파일 업로드/다운로드
- 파일 삭제(Soft Delete)
- MinIO 버킷 기반 저장
- document_id 생성 및 관리

### 제외 범위 (Out of Scope)

- 메타데이터 관리
- 검색/인덱싱
- OCR/AI 처리
- 문서 버전 비교 UX

## 목표 API 스펙 (PRD 초안)

- POST /documents: 파일 업로드 후 document_id 반환
- GET /documents/{document_id}: 파일 다운로드
- DELETE /documents/{document_id}: 파일 Soft Delete

업로드 응답 예시:

```json
{
  "document_id": "string"
}
```

## PRD 요구사항 반영 현황

| PRD 항목 | 상태 | 반영 내용 |
| --- | --- | --- |
| 파일 업로드 (`POST /documents`) | Implemented (MVP) | 단일 파일 업로드 후 `document_id` 반환 |
| 파일 다운로드 (`GET /documents/{document_id}`) | Implemented (MVP) | 인증 사용자 대상 원본 파일 반환 |
| 파일 삭제 (`DELETE /documents/{document_id}`) | Implemented (MVP) | 서비스 레이어 soft delete 처리 |
| 접근 제어 (Auth Service) | Implemented | Keycloak 기반 JWT 검증/역할/스코프 체크 구현 |
| 헬스체크/운영성 | Implemented | `/health/live`, `/health/ready` 제공 |
| Metadata/Audit 연동 | Planned | 삭제 플래그/이벤트 로그 연계 예정 |
| MinIO 영속 저장소 연동 | Planned | 현재는 인메모리 저장, 다음 단계에서 MinIO 연동 |

## 현재 구현 상태

현재 코드는 인증/보안 및 헬스체크 기반 위에 Document API MVP가 추가된 상태입니다.

### 현재 제공 엔드포인트

- POST /token
- GET /user
- POST /documents
- GET /documents/{document_id}
- DELETE /documents/{document_id}
- POST /example
- GET /example
- GET /example/scope
- DELETE /example
- GET /health/live
- GET /health/ready

### 현재 상태 요약

- 구현 완료: Keycloak 기반 인증/인가, JWT 검증, 역할/스코프 체크, 헬스체크, Document API MVP(인메모리)
- 다음 단계: MinIO 연동 영속화, Metadata/Audit 연계

## 아키텍처 개요

- 저장소: MinIO(S3 호환 Object Storage)
- 연동 대상:
  - Auth Service(Keycloak): 인증/권한 검증
  - Metadata Service: 파일 메타데이터 및 삭제 플래그 관리
  - Audit Service: 업로드/다운로드/삭제 이벤트 로그 기록

## 프로젝트 구조

- docmesh_doc/
  - main.py: FastAPI 앱 엔트리포인트
  - factory.py: 앱 조립(설정 로딩, 미들웨어, 라우트 등록)
  - core/
    - config.py: 환경 변수 + YAML 설정 모델
    - security.py: 인증 제공자 및 JWT 처리
    - logging.py: 로깅 초기화
    - exceptions.py: 예외 타입/핸들러
  - dependencies/
    - config.py: 설정 DI
    - security.py: 인증/인가 DI
  - routes/
    - auth.py: 인증 및 권한 예제 엔드포인트
    - health.py: liveness/readiness 엔드포인트
  - services/
    - security.py: 인증 서비스 레이어
  - schemas/
    - health.py, token.py, user.py: 응답 스키마
- test_docmesh_doc/: 계층별 테스트

## 빠른 시작

### 1) 가상환경 활성화

```bash
source .venv/bin/activate
```

### 2) 의존성 설치

```bash
pip install -e .
```

### 3) 애플리케이션 실행

```bash
fastapi dev docmesh_doc/main.py
```

또는

```bash
uvicorn docmesh_doc.main:app --reload
```

### 4) 테스트 실행

```bash
pytest
```

## 설정

환경 변수(기본값은 core/config.py 기준):

- ENVIRONMENT: dev | test | prod (기본값: dev)
- CONFIG_PATH: 서비스 YAML 설정 경로 (기본값: .devcontainer/config.yaml)
- KEYCLOAK_USERNAME: 기본 테스트 계정
- KEYCLOAK_PASSWORD: 기본 테스트 비밀번호

YAML 설정 파일(.devcontainer/config.yaml) 주요 키:

- logging.level
- cors.origins
- cors.credentials
- auth.verify_jwt
- auth.allow_insecure_jwt_decode
- keycloak.http_url
- keycloak.manage_url
- keycloak.realm
- keycloak.client_id
- keycloak.client_secret

## 비기능 요구사항 (PRD)

- 성능: 대용량 파일 스트리밍 처리 고려
- 확장성: Stateless 수평 확장, MinIO scale-out 대응
- 보안: OAuth2/SSO, MinIO 직접 접근 차단
- 신뢰성: 데이터 유실 방지, 장애 재시도 가능 구조
- 감사성: 업로드/다운로드/삭제 이벤트 로깅

## 성공 기준 (Success Metrics)

- 파일 업로드/다운로드 성공률
- 장애 발생 시 데이터 무결성 유지
- 평균 파일 다운로드 응답 안정성

## Non-Goals

- 파일 내용 검색
- AI 기반 문서 분석
- 메타데이터 편집 UI
- 문서 버전 비교 기능

## 로드맵

1. MinIO 클라이언트 도입 및 버킷 전략 수립
2. POST /documents 구현(document_id 생성 및 저장)
3. GET /documents/{document_id} 구현(권한 검증 포함)
4. DELETE /documents/{document_id} 구현(Soft Delete 연계)
5. Metadata/Audit 서비스 연동
6. 대용량 파일 스트리밍 및 장애 복구 시나리오 보강
