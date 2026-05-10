# DocMesh Document Service

MinIO 기반의 문서 파일 저장 서비스입니다.  
파일 업로드, 다운로드, 삭제를 위한 단일 API를 제공합니다.

***

## ✅ 주요 기능

*   파일 업로드
*   파일 조회
*   파일 다운로드
*   파일 삭제
*   인증 기반 접근 제어 (Keycloak + JWT)
*   사용자, 그룹별 파일 관리 및 접근 제어

***

## 📦 API 개요

| Method | Endpoint                   | 설명      |
| ------ | -------------------------- | ------- |
| POST   | `/documents`               | 파일 업로드  |
| GET    | `/documents/{document_id}` | 파일 다운로드 |
| DELETE | `/documents/{document_id}` | 파일 삭제   |

***

## 🏗 아키텍처

*   **Storage**: MinIO (S3 호환)
*   **Auth**: Keycloak (JWT 기반 인증/인가)
*   **연동 예정**
    *   Metadata Service
    *   Audit Service

## 🚀 빠른 시작

### 1. 의존성 설치

```bash
uv sync
```

### 2. 애플리케이션 실행

```bash
fastapi dev
```

### 3. 테스트 실행

```bash
vscode Testing
```

***

## ⚙️ 설정

### 주요 환경 변수

*   `ENVIRONMENT`: dev | test | prod
*   `CONFIG_PATH`: YAML 설정 경로
*   `KEYCLOAK_USERNAME`
*   `KEYCLOAK_PASSWORD`

### 주요 설정 항목

*   인증 (Keycloak 설정)
*   CORS
*   로깅 레벨

## 🎯 설계 원칙

*   파일 저장에만 집중 (Single Responsibility)
*   Stateless 구조로 확장성 고려
*   보안 중심 설계 (Direct Storage 접근 차단)
