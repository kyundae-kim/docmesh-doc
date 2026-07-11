# 제품 요구사항 정의서 (PRD)

| 항목 | 내용 |
| --- | --- |
| 제품명 | DocMesh Document Service |
| 문서 상태 | Draft |
| 버전 | 0.1 |
| 작성일 | 2026-07-11 |
| 대상 릴리스 | MVP |
| 제품 한 줄 정의 | `dms-core`의 문서 관리 기능을 `fastapi-core` 기반 FastAPI 컴포넌트로 제공하는 HTTP Document Management Service |

## 1. 배경과 문제 정의

서비스 및 업무 시스템은 파일 본문 저장, 문서 메타데이터 관리, 다운로드 스트리밍, 삭제 및 저장소 상태 확인을 각각 구현하는 대신 일관된 API로 사용해야 한다. 이를 개별 서비스가 구현하면 문서 본문과 메타데이터의 정합성, 대용량 전송, 삭제 정책, 외부 저장소 장애 처리 방식이 달라진다.

DocMesh Document Service는 다음의 역할 분리를 제품화한다.

- **`dms-core`**: 문서 업로드·조회·스트리밍 다운로드·soft/hard delete·storage health를 수행하는 문서 도메인 SDK
- **`fastapi-core`**: 앱 factory, 공통 health, 인증 router, 설정, readiness, lifecycle을 제공하는 FastAPI 컴포넌트 계층
- **DocMesh Document Service**: 위 두 컴포넌트를 조립해 소비 시스템에 안정적인 HTTP API를 제공하는 배포 가능 제품

문서 본문은 MinIO object store에, 문서 메타데이터는 모든 환경에서 PostgreSQL에 보관한다.

## 2. 제품 비전 및 목표

### 2.1 비전

애플리케이션 개발자가 저장소 구현 세부사항 없이 HTTP API를 통해 문서를 안전하게 생성·조회·다운로드·삭제할 수 있고, 운영자는 공통 health/readiness 신호로 서비스와 의존 저장소의 상태를 판단할 수 있게 한다.

### 2.2 MVP 목표

1. 문서 본문과 메타데이터를 하나의 문서 ID로 관리한다.
2. 파일 업로드, 메타데이터 조회, 전체 콘텐츠 조회, 스트리밍 다운로드, soft delete, hard delete를 HTTP API로 제공한다.
3. `fastapi-core.create_app(...)`를 공통 앱 진입점으로 사용하여 health, 설정, 인증, lifecycle을 일관되게 구성한다.
4. SDK 생성과 종료를 FastAPI lifespan에 연결하여 서비스 종료 시 SDK와 stream 자원을 정리한다.
5. MinIO와 metadata store의 실패를 readiness 및 표준 오류 응답으로 식별 가능하게 한다.
6. 운영 환경에서 인증·권한·CORS·secret 주입을 명시적으로 설정한다.

### 2.3 성공 지표

| 지표 | MVP 목표 | 측정 방식 |
| --- | --- | --- |
| 핵심 기능 검증률 | 정의된 MVP 수용 기준 100% 통과 | 자동화 API/통합 테스트 |
| 문서 lifecycle 정합성 | 업로드 실패 후 metadata만 또는 object만 남는 미처리 상태 0건 | 실패 주입 통합 테스트 및 운영 점검 |
| readiness 정확성 | 필수 의존성 장애 시 readiness가 503 반환 | 의존성 장애 통합 테스트 |
| 다운로드 처리 | 대용량 다운로드가 streaming response로 전달 | 스트리밍 API 테스트 |
| 자원 정리 | 요청 stream 및 shutdown 시 SDK close 누락 0건 | lifecycle/자원 정리 테스트 |

## 3. 사용자 및 이해관계자

| 역할 | 주요 목적 | 대표 작업 |
| --- | --- | --- |
| API 소비 애플리케이션 | 업무 문서를 서비스에 연계 | 문서 업로드, metadata 조회, 다운로드, 삭제 |
| 서비스 운영자 | 서비스 가용성 및 저장소 상태 관리 | liveness/readiness 확인, 설정·secret 주입, 장애 대응 |
| 플랫폼/보안 담당자 | 안전한 노출과 접근 제어 | 인증 방식, 권한 정책, CORS, reverse proxy 경로 관리 |
| 개발·QA 담당자 | API 품질 및 정합성 검증 | API 계약 테스트, 저장소 장애/정리 시나리오 검증 |

## 4. 제품 범위

### 4.1 포함 범위

- HTTP 기반 문서 업로드
- 문서 메타데이터와 콘텐츠 조회
- streaming 방식의 다운로드
- soft delete 및 hard delete
- 문서 ID의 생성 또는 호출자 지정 ID 사용
- 문서 메타데이터, 작성자, checksum 등 부가 정보 관리
- liveness 및 readiness endpoint
- 인증/권한 dependency를 적용할 수 있는 API 보호 구조
- PostgreSQL + MinIO 기반 문서 저장 구성
- SDK storage health와 앱 readiness를 함께 고려한 운영 상태 판단

### 4.2 제외 범위 (MVP)

- 웹 UI 및 최종 사용자 문서 탐색 화면
- 문서 내용 전문 검색, 벡터 검색, OCR, 미리보기/변환
- 문서 버전 관리와 동시 편집
- 대용량 비동기 업로드 작업 큐
- 문서 이벤트 broker publish/subscribe의 표준 계약
- 테넌트별 저장소 분리, 보존 기간 자동화, 법적 보존 정책

> NATS는 `fastapi-core`에서 선택 가능한 서비스 클라이언트일 수 있으나, `dms-core` 자체의 메시지 publish/subscribe 기능은 MVP 범위에 포함하지 않는다.

## 5. 핵심 사용자 흐름

### 5.1 문서 업로드

1. 소비 애플리케이션이 인증된 요청으로 파일 본문, filename, content type 및 선택 메타데이터를 전송한다.
2. 서비스는 요청을 검증하고 `dms-core` 업로드 요청으로 변환한다.
3. SDK는 object store에 본문을 저장한 뒤 metadata store에 문서 메타데이터를 저장한다.
4. 저장에 성공하면 서비스는 문서 ID와 생성된 문서 정보를 반환한다.
5. metadata 저장 실패 시 SDK는 저장한 본문 정리를 시도한다. 정리까지 실패하면 서비스는 정합성 오류로 기록·응답한다.

### 5.2 메타데이터 조회 및 다운로드

1. 소비 애플리케이션이 문서 ID로 metadata 또는 콘텐츠를 요청한다.
2. 서비스는 삭제 상태와 존재 여부를 확인한다.
3. metadata 조회는 문서 속성 및 상태를 반환한다.
4. 다운로드는 콘텐츠를 streaming response로 전달하며, 응답 종료 또는 오류 시 stream을 정리한다.
5. metadata는 존재하지만 본문이 없으면 서비스는 데이터 정합성 오류로 처리하고 운영자가 식별할 수 있게 기록한다.

### 5.3 문서 삭제

1. 소비 애플리케이션이 문서 ID와 삭제 방식(soft 또는 hard)을 지정한다.
2. 서비스는 호출 권한 및 문서 상태를 검증한다.
3. soft delete는 metadata를 `deleted` 상태로 남기고, hard delete는 object와 metadata를 제거한다.
4. 삭제 진행 중 상태는 `deleting`으로 관리하며, 저장소 작업 실패는 표준 오류 응답과 운영 로그로 남긴다.

### 5.4 서비스 시작 및 상태 점검

1. 애플리케이션은 `fastapi-core.create_app(...)`으로 조립된다.
2. custom lifespan에서 DMS SDK를 생성하고 필요 시 startup health check를 수행한다.
3. SDK 인스턴스는 route dependency가 접근할 수 있는 application state 경계에 보관한다.
4. 종료 시 SDK와 열린 외부 자원을 close한다.
5. 운영 플랫폼은 liveness와 readiness endpoint로 프로세스 및 필수 의존성 상태를 판정한다.

## 6. 기능 요구사항

### 6.1 애플리케이션 조립 및 공통 API

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-APP-001 | 서비스는 `fastapi-core.create_app(...)`을 기반으로 FastAPI 앱을 생성해야 한다. | Must | 앱이 공통 health router 및 설정/state를 포함해 기동된다. |
| FR-APP-002 | DMS SDK는 custom lifespan에서 한 번 생성하고 종료 시 close해야 한다. | Must | 정상 종료 및 기동 실패 경로에서 SDK close가 테스트로 검증된다. |
| FR-APP-003 | DMS route는 SDK 구현체를 직접 생성하지 않고 전용 FastAPI dependency를 통해 SDK를 획득해야 한다. | Must | route 단위 테스트에서 dependency override가 가능하다. |
| FR-APP-004 | 서비스는 `GET /health/liveness`와 `GET /health/readiness`를 제공해야 한다. | Must | liveness는 프로세스 생존, readiness는 필수 의존성 상태를 반환한다. |
| FR-APP-005 | 모든 문서 작업 route에 인증 dependency를 적용하고 hard delete에는 강화된 권한 dependency를 적용해야 한다. | Must | 인증되지 않거나 권한 없는 요청은 문서 작업을 수행할 수 없다. |

### 6.2 문서 API

세부 URI, request/response 스키마는 소프트웨어 요구사항 정의서 및 API Reference에서 확정한다. MVP는 아래 행위를 반드시 제공한다.

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-DOC-001 | 파일 본문, filename, content type 및 선택 metadata를 받아 문서를 생성해야 한다. | Must | 유효한 요청은 문서 ID, 상태, 생성 정보를 반환하고 이후 조회 가능하다. |
| FR-DOC-002 | 호출자가 document ID를 지정하지 않으면 서비스 또는 SDK가 식별자를 생성해야 한다. | Must | ID 생략 업로드가 충돌 없는 문서 ID를 반환한다. |
| FR-DOC-003 | 문서 metadata를 ID로 조회해야 한다. | Must | 존재하는 활성 문서는 metadata와 상태를 반환한다. |
| FR-DOC-004 | 문서 콘텐츠 전체 조회를 제공해야 한다. | Should | 작은 문서에 대해 content type을 보존해 콘텐츠를 반환한다. |
| FR-DOC-005 | 대용량 문서 다운로드는 streaming 방식으로 제공해야 한다. | Must | 전체 콘텐츠를 메모리에 적재하지 않고 chunk 단위로 전송한다. |
| FR-DOC-006 | soft delete를 제공해야 한다. | Must | 삭제 문서는 `deleted` 상태가 되며 일반 조회/다운로드 정책에 따라 차단된다. |
| FR-DOC-007 | 권한 있는 호출자에게 hard delete를 제공해야 한다. | Must | object와 metadata 삭제가 완료되거나 실패가 식별 가능한 오류로 반환된다. |
| FR-DOC-008 | filename, uploader/created_by, 사용자 정의 metadata, checksum을 문서 metadata로 관리해야 한다. | Must | 업로드 시 제공한 정보가 metadata 조회 결과에서 확인된다. |
| FR-DOC-009 | 업로드된 원본 filename과 uploader 정보는 MinIO object metadata가 아니라 document metadata에 저장해야 한다. | Must | object metadata에 해당 업무 정보가 기록되지 않고 document metadata에서 조회된다. |

### 6.3 오류 및 정합성

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-ERR-001 | validation, not found, duplicate, configuration, storage, consistency 오류를 구분된 표준 오류 응답으로 반환해야 한다. | Must | 오류 유형별 HTTP status, 오류 코드, 안전한 메시지가 API 계약에 정의된다. |
| FR-ERR-002 | 요청 검증 실패(예: 잘못된 chunk size)는 저장소 작업 전에 거부해야 한다. | Must | 잘못된 요청이 validation 오류를 반환하고 문서를 생성하지 않는다. |
| FR-ERR-003 | object 저장 후 metadata 저장 실패 시 본문 정리를 시도해야 한다. | Must | 실패 주입 테스트에서 cleanup 시도가 검증된다. |
| FR-ERR-004 | cleanup도 실패하거나 metadata와 본문 상태가 불일치하면 consistency 오류로 기록해야 한다. | Must | 오류 응답·구조화 로그·운영 알림의 상관 ID로 장애를 추적할 수 있다. |
| FR-ERR-005 | 존재하지 않는 문서와 삭제된 문서의 외부 노출 정책을 API 계약에 명시해야 한다. | Must | 비인가 정보 노출 없이 일관된 응답이 테스트된다. |

### 6.4 운영 및 설정

| ID | 요구사항 | 우선순위 | 수용 기준 |
| --- | --- | --- | --- |
| FR-OPS-001 | 서비스는 모든 환경에서 PostgreSQL을 metadata store, MinIO를 object store로 사용해야 한다. | Must | 두 의존성이 설정·연결되고 startup/readiness 검증 대상에 포함된다. |
| FR-OPS-003 | MinIO bucket 또는 metadata store 설정이 누락되면 서비스는 정상 준비 상태가 되면 안 된다. | Must | 구성 오류가 기동 실패 또는 readiness 실패로 드러난다. |
| FR-OPS-004 | `ROOT_PATH`, `TOKEN_URL`, CORS, 활성 서비스, 필수 readiness 서비스를 환경 설정으로 명시할 수 있어야 한다. | Must | reverse proxy 및 배포별 URL/health 정책이 코드 변경 없이 적용된다. |
| FR-OPS-005 | 운영 secret과 DSN은 외부 secret 주입 또는 명시적 환경변수로 제공해야 하며 로그에 원문을 남기면 안 된다. | Must | 설정/로그 점검에서 credential 노출이 없다. |
| FR-OPS-006 | 필수 서비스 장애는 readiness 503, 선택 서비스 장애는 degraded 상태로 구분해야 한다. | Must | required service와 optional service 장애 테스트가 각각 기대 상태를 반환한다. |

## 7. 비기능 요구사항

| 영역 | 요구사항 |
| --- | --- |
| 보안 | 모든 문서 작업은 인증 검사를 거쳐야 하며 hard delete에는 강화된 권한 검사를 적용한다. 운영 CORS는 허용 origin을 명시하며 wildcard origin과 credential 조합을 사용하지 않는다. |
| 데이터 정합성 | 업로드는 본문 저장 후 metadata 저장 순서를 따르며, 실패 보상과 consistency 오류 추적을 제공한다. |
| 성능/자원 | 대용량 다운로드는 streaming으로 제공하고, stream과 SDK는 예외·종료 경로를 포함해 반드시 close한다. |
| 가용성 | liveness와 readiness를 분리한다. readiness는 DMS 필수 의존성 상태를 반영한다. |
| 관측성 | 요청 ID 또는 상관 ID, 문서 ID, 작업 종류, 결과, 오류 유형을 구조화 로그로 남긴다. 파일 본문·access token·secret은 로그에 남기지 않는다. |
| 호환성 | Python 3.11 이상 및 저장소에 고정된 `dms`, `fastapi-core`, `docmesh-py-core` 의존성 버전과 호환되어야 한다. |
| 테스트 | unit test는 request 변환·오류 매핑·dependency를, integration test는 PostgreSQL·MinIO·lifecycle·health를 검증한다. |

## 8. API 및 데이터 정책

### 8.1 API 설계 원칙

- API는 HTTP resource 중심으로 문서 생성, metadata 조회, 콘텐츠 다운로드, 삭제를 제공한다.
- upload는 multipart/form-data 또는 확정된 바이너리 전송 계약을 사용하며, filename과 content type은 명시적으로 받는다.
- 다운로드는 저장된 content type과 안전한 `Content-Disposition` 정책을 적용한다.
- metadata response에는 최소한 document ID, filename, content type, 크기, 상태, 생성/수정 시각, created_by, checksum, 사용자 metadata를 포함한다.
- API 오류 응답에는 기계 판독 가능한 오류 코드와 요청 상관 ID를 포함한다. 내부 stack trace, credential, 저장소 endpoint 상세는 외부 응답에 노출하지 않는다.

### 8.2 데이터 수명주기 정책

| 상태 | 의미 | 허용 작업 |
| --- | --- | --- |
| `available` | 본문과 metadata가 정상적으로 사용 가능한 문서 | metadata 조회, 다운로드, 삭제 |
| `deleting` | 삭제 작업이 진행 중인 문서 | 재시도/조회 정책은 API 계약에서 제한적으로 정의 |
| `deleted` | soft delete된 문서 | 일반 다운로드·조회 차단, 복구는 MVP 범위 밖 |
| hard deleted | object와 metadata가 제거된 문서 | 일반 API로 조회 불가 |

## 9. 배포 아키텍처 및 의존성 경계

```text
API Consumer
    │ HTTPS
    ▼
DocMesh Document Service (FastAPI)
    ├─ fastapi-core: create_app, health, auth, config, readiness, lifespan
    └─ dms-core: upload, metadata/content lookup, stream, delete, health, close
          ├─ PostgreSQL (metadata store)
          └─ MinIO (required object store)
```

- HTTP request/response 변환, 인증·권한, SDK 오류의 HTTP 매핑은 서비스 route 계층의 책임이다.
- 문서 lifecycle, storage 접근, metadata/object 정합성은 `dms-core`의 책임이다.
- app factory, 공통 health, app state, CORS, 공통 설정과 readiness 정책은 `fastapi-core`의 책임이다.
- 메시지 broker 연결이 필요해도 DMS SDK의 기능으로 간주하지 않으며, 서비스의 별도 lifecycle 확장으로 설계한다.

## 10. 출시 수용 기준

MVP는 다음 모두를 만족할 때 출시 가능하다.

1. `fastapi-core` 기반 앱이 기동하고 liveness/readiness endpoint가 동작한다.
2. PostgreSQL + MinIO 환경에서 파일 업로드 후 metadata 조회와 streaming 다운로드가 가능하다.
3. soft delete와 권한이 제한된 hard delete가 API 계약대로 동작한다.
4. 미존재 문서, 삭제 문서, 중복 문서, validation, storage, configuration, consistency 오류의 응답 계약이 테스트된다.
5. object 저장 후 metadata 저장 실패 및 cleanup 실패 시나리오가 테스트되며, 정합성 오류가 운영 로그에서 식별된다.
6. 필수 의존성 장애 시 readiness가 503을, 선택 의존성 장애 시 degraded 상태를 반환한다.
7. 인증·권한·CORS·secret 주입이 운영 환경에서 명시적으로 설정되고, secret/파일 본문이 로그에 노출되지 않는다.
8. SDK 및 response stream의 정상·오류·shutdown 정리 경로가 테스트된다.
9. API Reference, 설정 정의서, 메시지 정의서, 테스트 정의서가 본 PRD의 범위 및 정책과 모순 없이 작성된다.

## 11. 가정, 제약 및 미결 사항

| 구분 | 내용 | 결정 필요 시점 |
| --- | --- | --- |
| 가정 | PostgreSQL은 모든 환경의 metadata store이며, MinIO는 모든 환경에서 필수다. | MVP 구현 전 |
| 제약 | 현재 수집된 `dms-core`/`fastapi-core` 문서는 직접적인 FastAPI adapter의 확정 구현을 제공하지 않는다. 서비스 route·dependency·오류 매핑은 본 제품에서 정의·검증해야 한다. | SRS/API 설계 |
| 제약 | 참조 문서 간 내부 버전 표기와 Git tag가 일치하지 않을 수 있다. 실제 배포 전 잠금된 패키지의 public API를 테스트로 검증한다. | 의존성 업그레이드 및 release 전 |
| 미결 | 문서 API의 최종 URI, upload payload 형식, pagination/목록 조회 필요 여부 | API Reference 작성 전 |
| 미결 | soft-deleted 문서의 관리자 조회·복구 정책 | MVP 이후 또는 보안 정책 확정 시 |
| 미결 | 인증 provider와 문서별 권한 모델(소유자, 역할, 테넌트)의 세부 정책 | 보안 설계 전 |
| 미결 | hard delete의 승인·감사·보존 정책 | 운영 출시 전 |
| 미결 | NATS 등 이벤트 발행 필요성과 이벤트 스키마 | 이벤트 연동 요구 발생 시 |
