# 테스트 정의서

## 실행 명령

```bash
# 전체 테스트
uv run pytest -q

# 외부 저장소가 필요 없는 테스트
uv run pytest -m 'not integration'

# 실제 PostgreSQL/MinIO가 준비된 경우
uv run pytest -m integration
```

`pytest` 실행은 application assembly, HTTP contract, DMS error mapping, stream lifecycle, config/client factory 회귀를 함께 검증합니다. integration marker가 있는 테스트는 외부 저장소나 인증 fixture가 없으면 skip될 수 있습니다.

## 주요 release gate

| 영역 | 검증 내용 |
| --- | --- |
| Host assembly | `docmesh-config` selected loader → `docmesh-py-core` client wrapper → `dms.create_sdk_from_clients(...)` 순서, SQLite 대안, strict ambiguity, legacy `POSTGRES_DSN` 거부 |
| FastAPI assembly | `DomainModule`, required DMS managed resource, auth opt-in, OpenAPI/error contract, startup failure와 shutdown cleanup |
| Upload | multipart file/metadata validation, authenticated `created_by`, stream request, `Location`, DMS-derived checksum metadata |
| Read/list | public metadata allowlist, cursor/limit/status 전달, `storage_key` 비노출 |
| Download | inline/attachment headers, chunk-size bounds, producer/disconnect/cancellation cleanup |
| Delete | soft delete 기본값, hard-delete permission, public status response |
| Errors | validation, not-found, conflict, payload-size, dependency/storage/consistency 오류의 stable envelope와 correlation ID |

## 외부 의존성 경계

단위/API 테스트는 실제 PostgreSQL·MinIO 연결 없이 fake SDK 또는 SQLite/구성된 client factory를 사용합니다. 실제 `check_health()` network probe는 dummy endpoint로 실행하지 않습니다. 통합 테스트에서만 실제 endpoint와 secret provider를 주입합니다.

## 관련 기준

- [소프트웨어 요구사항 정의서](srs.md)
- [설정 정의서](config.md)
- [API Reference](api.md)
- [FastAPI core application assembly wiki](../wiki/concepts/fastapi-core-app-assembly.md)
- [DMS core configuration wiki](../wiki/concepts/dms-core-configuration.md)
