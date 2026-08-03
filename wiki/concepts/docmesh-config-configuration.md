---
title: docmesh-config configuration model
created: 2026-08-02
updated: 2026-08-02
type: concept
tags: [configuration, security, deployment, integration, dependency]
sources: [raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-config configuration model

`docmesh-config` v0.1.0의 configuration layer는 `CommonConfig`와 8개 서비스 모델의 98개 canonical 환경변수를 process environment에서만 읽는다. 설정 모델은 생성자 keyword를 받지 않고, 환경변수 key는 대소문자를 구분하지 않으며, 앞뒤 공백과 공백-only 값은 정규화된다. `.env` 자동 로딩은 지원하지 않는다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

## Loading and selection

`load_service_configs(services=...)`는 명시한 서비스가 완전하고 유효한지 검사한다. `services`를 생략하면 환경변수가 존재하는 서비스를 optional 후보로 감지한다. `load_available_service_configs(...)`는 선택 후보 중 관련 환경변수가 있는 서비스만 로드하지만, prefix가 일부만 존재하는 서비스는 조용히 건너뛰지 않고 `ConfigError`로 처리한다. 로더는 client 생성이나 외부 연결을 하지 않는다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

결과 bundle인 `ServiceConfigs`는 `common`, `keycloak`, `postgres`, `sqlite`, `minio`, `milvus`, `ollama`, `langfuse`, `nats` 필드를 가지며, `require_*()`는 누락된 서비스에 `service_not_loaded` 오류를 낸다. `docmesh_env`는 `common.env` 편의 property다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## Service-specific rules

- PostgreSQL은 `POSTGRES_HOST`, `POSTGRES_DB`, `POSTGRES_USER`, `POSTGRES_PASSWORD`를 필수 입력으로 두고 port·pool·timeout metadata를 제공한다. 문서에는 DSN 입력이 정의되어 있지 않다.
- SQLite는 `SQLITE_PATH`가 필수이며 `:memory:`, WAL, read-only, busy timeout을 설정한다.
- MinIO는 endpoint/access/secret이 필수이고 `RuntimePlan.minio_bucket_required=True`인 소비자에서만 `MINIO_BUCKET`이 조건부 필수가 된다.
- Milvus는 `MILVUS_ENDPOINT`만 지원하며 이전 `MILVUS_URI`/`uri` compatibility alias는 없다.
- Keycloak provisioning은 admin client secret 방식과 username/password 방식 중 정확히 하나를 요구한다.
- Langfuse는 `LANGFUSE_ENABLED=false`이면 host와 key를 생략할 수 있다.
- NATS 인증은 user/password, token, credentials file 중 최대 하나를 선택한다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

이 규칙은 generic service configuration의 계약이다. [[dms-core-configuration]]의 DMS metadata-backend 선택·MinIO object-store 조립과 동일한 factory 계약으로 합치지 않는다.

## Secret safety and production

`repr`, 문자열/JSON 직렬화, validation 오류, 진단 결과는 secret과 endpoint credential을 마스킹한다. `mask_sensitive_value(...)`는 URL userinfo, 민감 query/fragment, bearer/JWT, password/token/secret assignment를 보호하며 일반 email과 비민감 parameter는 보존한다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

`DOCMESH_SECURITY_MODE=production` 또는 production alias 환경에서는 Keycloak SSL 검증, MinIO secure/cert check, Milvus secure, Ollama SSL 검증을 끌 수 없다. `replace-me`, `changeme`, `placeholder` secret과 localhost/example endpoint도 production placeholder 문제로 진단된다. 이 검증은 네트워크 연결을 대신하지 않는다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## Deployment template

`.env.example`은 모든 canonical 변수를 추적하는 개발용 template이며 자동으로 로드되지 않는다. 필요한 서비스 block만 활성화하고 placeholder를 실제 secret으로 교체한 뒤, Secret manager·container secret·orchestrator를 통해 process environment로 주입한다. 실제 `.env`와 credential은 저장소에 커밋하지 않는다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md] ^[raw/articles/docmesh-config-env-example-v0.1.0.md]

## Integration boundary

`docmesh-config`와 [[docmesh-py-core]]가 같은 서비스 이름을 다룬다는 사실만으로 두 loader나 settings type이 호환된다고 가정하지 않는다. 또한 `docmesh-config` 문서에는 [[fastapi-core]]의 `AppConfig`, CORS, router, lifespan 또는 readiness registry를 직접 조립한다는 계약이 없다. 소비 애플리케이션은 `docmesh-config` bundle을 `docmesh-py-core`/FastAPI runtime에 전달하기 전에 version-aligned imports, signatures와 contract tests를 확인해야 한다.

현재 workspace는 `pyproject.toml`에 `docmesh-config` v0.1.0을 선언하지만 이 세션에서 package import와 application source 사용처가 확인되지 않았다. 그러므로 이 페이지는 upstream configuration contract와 소비 계층 간의 integration boundary를 기록하며, 실행 배포가 이미 이 loader를 사용한다고 단정하지 않는다.

## v0.6 consumer package boundary

`docmesh-py-core` v0.6.0 문서는 `docmesh_config`를 canonical settings/`RuntimePlan` package로 사용하고, `docmesh_py_core`가 그 plan을 client/lifecycle assembly에 소비한다고 명시한다. compatibility facade가 있더라도 새 코드는 두 package root를 사용해야 한다. 이 package-level bridge는 `fastapi-core`의 `AppConfig`·router·lifespan이나 DMS storage factory를 `docmesh-config`가 직접 조립한다는 뜻이 아니다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Related pages

- [[docmesh-config]] — package 범위와 workspace reconciliation.
- [[docmesh-config-runtime-plan]] — 선택 서비스·대안·startup policy metadata.
- [[fastapi-core-configuration]] — FastAPI `AppConfig`/service hosting 설정 소유권.
- [[dms-core-configuration]] — DMS metadata store·MinIO SDK 설정 소유권.

## Sources

- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
