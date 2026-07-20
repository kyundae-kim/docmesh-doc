# 제품 요구사항 정의서 (PRD)

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 대상 릴리스 | MVP |
| 최종 코드 대조일 | 2026-07-18 |
| 제품 정의 | `dms-core` 문서 관리 기능을 `fastapi-core`로 조립해 제공하는 HTTP Document Management Service |

## 1. 목적

DocMesh Document Service의 목적은 업무 시스템이 파일 저장소와 메타데이터 저장소의 구현 세부사항을 직접 다루지 않고, 일관되고 보호된 HTTP API로 문서를 관리하도록 하는 것이다.

서비스는 문서 본문과 메타데이터의 정합성, 대용량 다운로드의 자원 관리, 삭제 정책, 의존 저장소 장애 식별을 공통 기능으로 제공한다. 이를 통해 각 소비 시스템이 동일한 문서 lifecycle과 운영 상태 신호를 사용하게 한다.

### 1.1 제품 경계

- **`dms-core`**는 문서 업로드·조회·다운로드·삭제·저장소 health를 수행한다.
- **`fastapi-core`**는 애플리케이션 factory, 공통 health, 인증, 설정, readiness, lifecycle을 제공한다.
- **DocMesh Document Service**는 두 컴포넌트를 조립하여 배포 가능한 HTTP 서비스로 제공한다.

기본 배포 구성은 문서 본문에 MinIO, 문서 메타데이터에 PostgreSQL을 사용한다. 애플리케이션은 DMS backend 구현을 직접 선택하거나 생성하지 않고 DMS 환경 factory에 위임한다.

## 2. 제품 목표

| ID | 목표 | 성공 기준 |
| --- | --- | --- |
| G-001 | 하나의 document ID로 본문과 메타데이터를 관리한다. | 업로드 성공 문서는 조회 가능한 metadata와 접근 가능한 본문을 가진다. |
| G-002 | 문서 lifecycle의 필수 HTTP 작업을 제공한다. | 업로드, 목록·metadata·콘텐츠 조회, streaming download, soft/hard delete의 수용 기준을 통과한다. |
| G-003 | 인증과 권한 정책으로 문서 작업을 보호한다. | 인증되지 않은 요청은 차단되고 hard delete는 별도 권한 검사를 통과해야 한다. |
| G-004 | 저장소 장애와 구성 오류를 운영자가 식별할 수 있게 한다. | liveness/readiness와 표준 오류 응답이 의존성 상태와 오류 유형을 구분한다. |
| G-005 | 대용량 전송과 서비스 종료에서 자원을 정리한다. | streaming 및 SDK lifecycle의 close 동작이 자동화 테스트로 검증된다. |

## 3. 범위

### 3.1 포함 범위

- HTTP 기반 파일 업로드와 document ID 생성 또는 호출자 지정 ID 지원
- 문서 목록, 공개 metadata, 전체 콘텐츠, streaming download 조회
- soft delete 및 권한 기반 hard delete
- filename, 작성자, checksum, 사용자 정의 metadata 관리
- PostgreSQL metadata store와 MinIO object store를 사용하는 배포 구성
- liveness/readiness, 인증·권한, CORS, secret 주입, correlation ID 기반 오류 추적

### 3.2 제외 범위

- 웹 UI와 최종 사용자 문서 탐색
- 전문·벡터 검색, OCR, 미리보기와 변환
- 문서 버전 관리, 복구, 동시 편집
- 대용량 비동기 업로드 큐
- 문서 이벤트 broker의 publish/subscribe 계약
- 테넌트별 저장소 분리, 보존 기간 자동화, 법적 보존 정책

> NATS는 `fastapi-core`의 선택적 서비스 클라이언트일 수 있으나, 문서 이벤트 API는 MVP 제품 범위에 포함하지 않는다.

## 4. 제품 요구사항

### 4.1 애플리케이션 및 보안

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-APP-001 | 서비스는 `fastapi-core.create_app(...)`으로 FastAPI 애플리케이션을 생성해야 한다. | Must | 공통 health, 설정, resource state를 포함해 기동한다. |
| FR-APP-002 | DMS SDK는 `ManagedResource` lifecycle에서 한 번 생성하고 종료 시 close해야 한다. | Must | 정상 종료와 close 실패 동작이 검증된다. |
| FR-APP-003 | DMS route는 SDK 구현체를 직접 생성하지 않고 전용 dependency로 SDK를 획득해야 한다. | Must | route 테스트에서 dependency override가 가능하다. |
| FR-APP-004 | 서비스는 liveness와 readiness endpoint를 제공해야 한다. | Must | liveness는 프로세스 생존을, readiness는 필수 의존성 준비 상태를 반환한다. |
| FR-SEC-001 | 모든 문서 작업 route는 인증된 사용자만 접근할 수 있어야 한다. | Must | 인증되지 않은 요청은 문서 작업을 수행하지 못한다. |
| FR-SEC-002 | hard delete에는 일반 문서 작업보다 강화된 권한 검사를 적용해야 한다. | Must | 권한 없는 인증 사용자는 hard delete를 수행하지 못한다. |

### 4.2 문서 lifecycle

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-DOC-001 | 서비스는 파일 본문, filename, content type, 선택 metadata를 받아 문서를 생성해야 한다. | Must | 유효한 요청은 문서 ID와 생성 정보를 반환하고 이후 조회할 수 있다. |
| FR-DOC-002 | 호출자가 ID를 지정하지 않으면 서비스 또는 SDK가 충돌 없는 document ID를 생성해야 한다. | Must | ID 생략 업로드가 새 document ID를 반환한다. |
| FR-DOC-003 | 서비스는 ID로 활성 문서의 공개 metadata를 조회해야 한다. | Must | metadata와 상태를 반환하며 내부 저장소 식별자는 노출하지 않는다. |
| FR-DOC-004 | 서비스는 문서 목록을 offset/limit과 선택 status filter로 조회해야 한다. | Must | pagination과 filter가 SDK에 전달되고 공개 metadata 배열을 반환한다. |
| FR-DOC-005 | 서비스는 문서 콘텐츠 전체 조회를 제공해야 한다. | Should | 작은 문서에서 저장된 content type과 안전한 filename disposition을 보존한다. |
| FR-DOC-006 | 대용량 문서 다운로드는 streaming으로 제공해야 한다. | Must | 전체 본문을 애플리케이션 메모리에 적재하지 않고 chunk 단위로 전송한다. |
| FR-DOC-007 | 서비스는 soft delete를 제공해야 한다. | Must | 본문을 삭제하고 metadata를 `deleted` 상태로 보존하며 일반 조회·다운로드를 차단한다. |
| FR-DOC-008 | 권한 있는 사용자에게 hard delete를 제공해야 한다. | Must | object와 metadata가 제거되거나 식별 가능한 오류가 반환된다. |
| FR-DOC-009 | filename, 작성자, 사용자 정의 metadata, checksum은 document metadata로 관리해야 한다. | Must | 업로드 시 제공·파생된 정보가 metadata 조회에서 확인된다. |
| FR-DOC-010 | 원본 filename과 작성자 정보는 MinIO object metadata가 아닌 document metadata에 저장해야 한다. | Must | object metadata에 업무 metadata가 기록되지 않는다. |

### 4.3 오류, 정합성 및 운영

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-ERR-001 | validation, not found, duplicate, configuration, storage, consistency 오류를 표준 오류 응답으로 구분해야 한다. | Must | 오류 유형별 HTTP status, 오류 코드, 안전한 메시지가 API 계약에 정의된다. |
| FR-ERR-002 | 잘못된 입력은 저장소 작업 전에 거부해야 한다. | Must | 예: 0 이하 chunk size 또는 빈 파일 정보 요청이 validation 오류를 반환하고 문서를 생성하지 않는다. |
| FR-ERR-003 | object 저장 후 metadata 저장에 실패하면 본문 정리를 시도해야 한다. | Must | 실패 주입 테스트가 cleanup 시도를 검증한다. |
| FR-ERR-004 | cleanup 실패 또는 metadata·본문 불일치는 consistency 오류로 기록·응답해야 한다. | Must | 상관 ID로 오류를 추적할 수 있다. |
| FR-ERR-005 | 존재하지 않거나 soft-deleted 문서는 동일한 외부 not-found 정책으로 처리해야 한다. | Must | 존재 여부를 불필요하게 노출하지 않는 일관된 응답이 검증된다. |
| FR-OPS-001 | 배포 template은 PostgreSQL metadata store와 MinIO object store를 구성해야 한다. | Must | 필요한 `POSTGRES_*`, `MINIO_*`, `DMS_METADATA_BACKEND=postgresql` 설정이 제공된다. |
| FR-OPS-002 | 필수 저장소 설정 누락 또는 장애는 기동 실패 또는 readiness 실패로 드러나야 한다. | Must | 필수 의존성 장애 시 readiness가 503을 반환한다. |
| FR-OPS-003 | CORS, 인증 URL, root path, readiness 정책은 환경 설정으로 명시해야 한다. | Must | 배포 환경별 정책을 코드 변경 없이 적용할 수 있다. |
| FR-OPS-004 | secret과 연결 정보는 외부 secret 주입 또는 환경변수로 제공하고 로그·응답에 원문을 노출해서는 안 된다. | Must | credential, DSN, storage key, stack trace가 외부에 노출되지 않는다. |

## 5. 품질 및 릴리스 기준

| 영역 | 릴리스 기준 |
| --- | --- |
| 데이터 정합성 | 업로드·삭제의 성공 및 부분 실패 경로가 검증되고, 미처리 object 또는 metadata 상태를 consistency 오류로 식별한다. |
| 자원 관리 | streaming 완료·예외·연결 종료와 application shutdown에서 stream 및 SDK close를 검증한다. |
| 가용성 | liveness와 readiness를 분리하고 PostgreSQL·MinIO 장애가 readiness에 반영됨을 검증한다. |
| 보안 | 인증, hard delete 권한, 안전한 오류 응답, 운영 CORS 정책을 API 계약 테스트로 검증한다. |
| 호환성 | Python 3.11 이상 및 저장소에 고정된 `dms`, `fastapi-core`, `docmesh-py-core` 조합에서 테스트를 통과한다. |

## 6. 추적성

세부 기술 요구사항은 [소프트웨어 요구사항 정의서](srs.md)에서 정의한다.

| PRD 영역 | SRS 요구사항 |
| --- | --- |
| 애플리케이션 및 보안 | SRS-ARC, SRS-SEC |
| 문서 lifecycle | SRS-DOM, SRS-API |
| 오류 및 정합성 | SRS-ERR |
| 저장소·설정·운영 | SRS-STO, SRS-OPS, SRS-CFG |
| 품질 및 검증 | SRS-NFR |