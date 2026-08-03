# 메시징 정의서

## 현재 범위

DocMesh Document Service의 현재 HTTP 구현은 문서 metadata/object storage와 FastAPI lifecycle만 제공합니다. 문서 upload·list·read·delete를 위해 NATS, Kafka 또는 다른 broker 연결을 생성하지 않습니다.

`dms-core` v0.7.0도 broker integration, publisher/subscriber API, event transport 또는 auth integration을 public storage SDK 계약으로 제공하지 않습니다. 따라서 `DOCMESH_SERVICES`에 NATS를 추가하는 것만으로 document event가 발행된다고 가정하지 않습니다.

## 설정 ownership

- NATS 같은 외부 client가 필요하면 `docmesh-py-core` 설정·client 계층을 별도 선택합니다.
- FastAPI service runtime의 enabled/required service와 readiness는 `fastapi-core`가 관리합니다.
- DMS document SDK의 metadata/object lifecycle은 `dms`가 관리합니다.
- 세 계층을 연결하는 adapter는 application host가 명시적으로 작성해야 하며, 동일한 환경변수 이름만으로 direct integration을 추론하지 않습니다.

## 향후 event integration 경계

향후 업로드·삭제 이벤트를 추가할 때는 다음을 별도 설계해야 합니다.

1. event schema와 versioning
2. publish 실패 시 document operation과의 정합성/재시도 정책
3. outbox 또는 idempotent consumer 저장소
4. NATS connection lifecycle과 readiness 기준
5. tenant, actor, correlation ID를 포함한 secret-safe 관측성

이 기능은 현재 API 성공 계약이나 DMS SDK factory에 포함되지 않습니다.
