# 📄 DocMesh Document Service PRD

**(MinIO 기반 파일 관리 서비스)**

## 1. 개요 (Overview)

### 1.1 목적

Document Service는 조직 내 문서를 **객체 스토리지(MinIO)** 에 안전하게 저장·관리하고,

다른 서비스(Metadata, Search 등)가 참조할 수 있는 **파일 저장의 단일 책임 서비스**를 제공한다. 

### 1.2 서비스 역할 (MSA 내 위치)

- DMS 전체 구조에서 **파일 업로드/다운로드/삭제의 유일한 진입점**
- 파일 바이너리 관리에만 집중 (검색·분류 로직 ❌)

### 1.3 범위 (Scope)

**포함**

- 파일 업로드 / 다운로드
- 파일 삭제 (Soft delete)
- MinIO 버킷 기반 파일 저장
- 파일 식별자(document_id) 생성 및 관리

**제외**

- 메타데이터 관리 (Metadata Service 담당)
- 검색 / 인덱싱
- OCR / AI 처리
- 문서 버전 비교 UX

---

## 2. 목표 (Goals)

- 안정적인 파일 저장소 제공 (데이터 유실 방지)
- 대용량 파일 업로드/다운로드 지원
- 서비스 확장 시 스토리지 독립성 확보 (S3 호환)

---

## 3. 시스템 아키텍처

### 3.1 저장소

- **MinIO (S3-compatible Object Storage)**
- 버킷 단위로 논리적 분리 (예: `documents`)*(버킷 정책/암호화 방식은 인프라 설계에서 결정 — PRD 범위 외)*

### 3.2 연동 서비스

- Auth Service: 사용자 인증/권한 검증
- Metadata Service: 파일 메타데이터 저장
- Audit Service: 파일 접근 로그 기록

---

## 4. 기능 요구사항 (Functional Requirements)

### 4.1 파일 업로드

- 단일 파일 업로드 지원
- 업로드 성공 시 **document_id 반환**
- MinIO Object Key = document_id 기반 생성

**입력**

- 파일(Binary)
- 기본 메타 정보 (filename, content-type)

**출력**

{

"document_id": "string"

}

``

---

### 4.2 파일 다운로드

- document_id 기반 파일 조회
- 권한 없는 요청은 접근 불가
- 원본 파일 그대로 반환

---

### 4.3 파일 삭제 (Soft Delete)

- 실제 MinIO 객체는 유지
- 삭제 플래그만 변경 (Metadata Service와 연계)
- 삭제된 파일은 기본 다운로드 불가

---

### 4.4 파일 접근 제어

- Auth Service를 통한 사용자 인증
- 권한 없는 document_id 접근 차단

---

## 5. API 설계 (초안)

### 5.1 파일 업로드

```
POST /documents
```

**Response**

{

"document_id": "string"

}

---

### 5.2 파일 다운로드

```
GET /documents/{document_id}
```

---

### 5.3 파일 삭제

```
DELETE /documents/{document_id}
```

---

## 6. 비기능 요구사항 (Non-Functional)

### 6.1 성능

- 일반 파일 업로드/다운로드 지연 최소화
- 대용량 파일 업로드 시 스트리밍 방식 권장

### 6.2 확장성

- MinIO scale-out 구조 대응
- Document Service 수평 확장 가능 (Stateless)

### 6.3 보안

- 인증: OAuth2 / SSO
- MinIO 접근은 서비스 계정으로만 허용
- 외부 직접 접근 차단

### 6.4 신뢰성

- 파일 데이터 유실 방지
- 장애 시 재시도 가능 구조

### 6.5 감사성

- 업로드 / 다운로드 / 삭제 이벤트 로그 기록 (Audit Service 연계)

---

## 7. 성공 기준 (Success Metrics)

- 파일 업로드/다운로드 성공률
- 장애 발생 시 데이터 무결성 유지
- 평균 파일 다운로드 응답 안정성

---

## 8. Non-Goals (명확히 제외)

- 파일 내용 검색
- AI 기반 문서 분석
- 메타데이터 편집 UI
- 문서 버전 비교 기능

---

## ✅ 한 줄 요약

👉 **Document Service는 MinIO 기반으로 파일을 안전하게 저장·제공하는 “파일 바이너리 전담 서비스”이다.**