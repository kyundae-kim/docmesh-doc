# DocMesh Document Service PRD

## 1. 개요

DocMesh Document Service는 MinIO(S3 호환)를 사용해 사용자별 파일을 저장/조회/삭제(Soft Delete)하는 FastAPI 서비스다.

현재 구현은 "개발 완료된 동작"을 기준으로 하며, 아래 내용은 코드 베이스 현행 상태를 반영한다.

## 2. 제품 목표

- 사용자 인증 기반 문서 API 제공
- MinIO 객체 스토리지 기반 파일 영속화
- 사용자별 논리 경로 분리
- 삭제 이력 보존을 위한 Soft Delete 지원

## 3. 아키텍처

### 3.1 애플리케이션

- 프레임워크: FastAPI
- 앱 생성: `docmesh_doc.factory:create_app`
- 라우트 구성: Health, Auth, Documents
- 예외 처리: `AuthError`를 공통 JSON 포맷으로 반환

### 3.2 스토리지

- 저장소: MinIO
- 버킷: 환경변수/설정 기반(`minio.bucket_name`, 기본값 `docmesh`)
- 버킷 미존재 시 자동 생성
- Object Key 정책: `{username}/{file_path}`

### 3.3 인증/인가

- OAuth2 Bearer 토큰 (`tokenUrl=/token`)
- Keycloak provider 기반 인증/토큰 디코딩
- 문서 API는 인증 사용자 컨텍스트 기반 접근

## 4. 도메인 모델

### 4.1 파일 식별 방식

- API 입력/응답 경로 식별자: `file_path`
- 내부 저장소 키: `{username}/{file_path}`

### 4.2 Soft Delete 방식

- MinIO 객체는 물리 삭제하지 않음
- 객체 태그 `deleted=true`로 상태 전환
- 조회 시 `deleted=true`면 미존재와 동일하게 404 처리

## 5. 기능 요구사항

### 5.1 토큰 발급 (개발용)

- 엔드포인트: `POST /token`
- 입력: form-data `username`, `password`
- 출력: `access_token`, `token_type`, `refresh_token`, `expires_in`, `refresh_expires_in`, `scope`
- 실패 시 AuthError 포맷 반환

### 5.2 사용자 정보 조회 (개발용)

- 엔드포인트: `GET /user`
- 설명: 현재 토큰의 사용자 정보를 반환 (개발 목적)

### 5.3 문서 업로드

- 엔드포인트: `POST /documents`
- 인증: 필요(Bearer)
- 입력:
	- form-data `file_path` (필수)
	- form-data `file` (필수)
- 처리:
	- 사용자명은 `preferred_username` 우선, 없으면 `sub` 사용
	- 업로드 시 metadata에 `filename`, `file_path` 저장
	- 태그 `deleted=false` 저장
- 출력:
	- `{"file_path": "{file_path}"}`

### 5.4 문서 다운로드

- 엔드포인트: `GET /documents/{file_path:path}`
- 인증: 필요(Bearer)
- 처리:
	- 사용자별 object key로 조회
	- 없거나 soft-deleted면 404
	- 파일 스트림 방식으로 응답 전달
- 응답 헤더:
	- `Content-Disposition: attachment; filename="..."`
	- `Content-Type`: 원본 파일의 content-type

### 5.5 문서 삭제 (Soft Delete)

- 엔드포인트: `DELETE /documents/{file_path:path}`
- 인증: 필요(Bearer)
- 처리:
	- 객체 존재 시 `deleted=true`로 태그 업데이트
	- 미존재 시 404
- 응답: 204 No Content

### 5.6 헬스체크

- `GET /health/live` -> `{"status": "live"}`
- `GET /health/ready` -> `{"status": "ready"}`
- 현재 readiness는 외부 의존성 활성 점검 없이 통과하도록 구현됨

### 5.7 권한 샘플 엔드포인트

- `POST /example` (`create` role 필요)
- `GET /example` (`read` role 필요)
- `DELETE /example` (`delete` role 필요)
- `GET /example/scope` (`profile` scope 필요)

## 6. API 요약

| Method | Endpoint | Auth | 설명 |
| --- | --- | --- | --- |
| POST | `/token` | No | Keycloak 토큰 발급 |
| GET | `/user` | Yes | 현재 사용자 정보 조회(개발용) |
| POST | `/documents` | Yes | 파일 업로드 |
| GET | `/documents/{file_path:path}` | Yes | 파일 다운로드 |
| DELETE | `/documents/{file_path:path}` | Yes | 파일 Soft Delete |
| GET | `/health/live` | No | Liveness |
| GET | `/health/ready` | No | Readiness |

## 7. 오류 응답 규격

인증/인가 관련 오류는 아래 포맷을 사용한다.

```json
{
	"error": "string",
	"error_description": "string"
}
```

대표 오류:

- 401 `invalid_token` 또는 `invalid_grant`
- 403 `insufficient_scope`
- 502/504 인증 제공자 연동 오류

## 8. 설정

### 8.1 환경 설정

- `environment`: `dev | test | prod`
- `config_path`: YAML 설정 파일 경로
- `minio.endpoint`
- `minio.access_key`
- `minio.secret_key`
- `minio.bucket_name`
- `minio.secure`

### 8.2 서비스 설정(YAML)

- `logging.level`
- `cors.origins`, `cors.credentials`
- `auth.verify_jwt`, `auth.allow_insecure_jwt_decode`, `auth.use_introspection`
- `keycloak.http_url`, `keycloak.manage_url`, `keycloak.realm`, `keycloak.client_id`, `keycloak.client_secret`

## 9. 비기능 요구사항 (NFR)

### 9.1 성능 (Performance)

- 일반 문서 업로드/다운로드 요청은 안정적으로 처리되어야 한다.
- 대용량 파일 처리 시 타임아웃/메모리 과사용을 방지해야 한다.
- 현재 구현:
	- 업로드: 파일 스트림을 사용해 MinIO에 저장한다.
	- 다운로드: 파일 스트림 방식으로 응답을 전달해 메모리 효율성을 확보한다.

### 9.2 가용성 (Availability)

- `/health/live`, `/health/ready` 엔드포인트를 통해 오케스트레이션 환경에서 헬스 상태를 확인할 수 있어야 한다.
- 애플리케이션 재기동 후에도 MinIO에 저장된 객체는 유지되어야 한다.

### 9.3 확장성 (Scalability)

- 애플리케이션은 상태 비저장(Stateless) 구조를 유지해 수평 확장이 가능해야 한다.
- 스토리지는 S3 호환 인터페이스를 사용해 MinIO scale-out 구조에 대응 가능해야 한다.

### 9.4 보안 (Security)

- 문서 API는 Bearer 토큰 인증을 필수로 적용해야 한다.
- 사용자별 object key 네임스페이스(`{username}/{file_path}`)를 사용해 기본 접근 경계를 분리해야 한다.
- 인증/인가 실패 시 표준화된 오류 포맷(`error`, `error_description`)을 반환해야 한다.
- MinIO 접근 자격증명은 환경설정으로 주입되고, 외부에 직접 노출되지 않아야 한다.

### 9.5 신뢰성/정합성 (Reliability)

- Soft Delete는 물리 삭제가 아닌 태그 기반 상태 전환으로 수행되어야 한다.
- Soft Delete된 객체는 조회 시 404로 처리되어야 한다.
- 미존재 객체 삭제 요청은 404를 반환해 API 의미론을 일관되게 유지해야 한다.

### 9.6 관측 가능성 (Observability)

- 서비스는 요청 처리 및 주요 이벤트(토큰 발급, 헬스체크 등)에 대해 구조화된 로깅이 가능해야 한다.
- 운영 환경에서 장애 분석이 가능하도록 로그 레벨(`logging.level`)을 설정 가능해야 한다.

### 9.7 운영성 (Operability)

- 환경별 설정(`dev/test/prod`)과 YAML 기반 서비스 설정을 통해 동일 코드의 운영 환경 전환이 가능해야 한다.
- 외부 의존성 상태 점검(Readiness 실제 의존성 체크)은 단계적으로 확장 가능해야 한다.

## 10. 테스트 기준

### 10.1 단위 테스트

- 문서 업로드 후 다운로드 성공
- Soft Delete 후 다운로드 404
- 미존재 문서 삭제 시 404
- Health live/ready 200 응답

### 10.2 Contract 테스트

구현 필요

### 10.3 통합 테스트

스테이징 환경

구현 필요

### 10.4 Contract 테슽 재검증

스테이징 환경

구현 필요

### 10.5 성능 테스트

스테이징 환경

구현 필요

## 11. 범위 외/추후 과제

- Metadata Service 연계 저장/조회
- Audit Service 연계 이벤트 적재
- Readiness의 외부 의존성 실체크(Keycloak/MinIO)
- 대용량 파일 스트리밍 최적화(현재는 다운로드 시 메모리 로드)

## 12. 한 줄 요약

DocMesh Document Service는 Keycloak 인증과 MinIO를 기반으로 사용자별 문서를 업로드/다운로드/소프트삭제하는 파일 전담 API 서비스다.