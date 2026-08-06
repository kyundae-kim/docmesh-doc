---
title: fastapi-core configuration model
created: 2026-07-11
updated: 2026-08-02
type: concept
tags: [fastapi, fastapi-core, configuration, deployment, security, observability]
sources: [raw/articles/fastapi-core-api-v0.1.6.md, raw/articles/fastapi-core-api-v0.3.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md, raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md, raw/articles/fastapi-core-config-v0.1.6.md, raw/articles/fastapi-core-config-v0.2.0.md, raw/articles/fastapi-core-config-v0.3.0.md, raw/articles/fastapi-core-wiki-configuration.md, raw/articles/fastapi-core-wiki-configuration-v0.5.0.md, raw/articles/fastapi-core-wiki-configuration-v0.6.0.md, raw/articles/fastapi-core-wiki-configuration-v0.7.0.md, raw/articles/fastapi-core-env-example-v0.3.0.md, raw/articles/fastapi-core-env-example-v0.4.0.md, raw/articles/fastapi-core-env-example-v0.5.0.md, raw/articles/fastapi-core-env-example-v0.6.0.md, raw/articles/fastapi-core-env-example-v0.7.0.md, raw/articles/fastapi-core-examples-v0.1.6.md, raw/articles/fastapi-core-wiki-examples.md, raw/articles/fastapi-core-wiki-examples-v0.7.0.md, raw/articles/dms-core-config-v0.2.0.md, raw/articles/dms-core-wiki-api-reference-v0.7.0.md, raw/articles/dms-core-wiki-configuration-v0.7.0.md, raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
contested: true
---

# fastapi-core configuration model

`fastapi-core`의 설정은 앱 조립용 `AppConfig`와 외부 의존성용 `docmesh_py_core.ServiceConfigs`의 두 계층으로 나뉜다. 전자는 root path, token URL, CORS, logging, readiness와 서비스 선택을 제어하고, 후자는 Keycloak·PostgreSQL·SQLite·MinIO·Milvus·Ollama·Langfuse·NATS 연결 설정을 제공한다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

GitHub Wiki Configuration snapshot도 같은 두 계층과 `ServiceRuntime` 조립 경계를 확인한다. 다만 이 source는 기준 버전을 `fastapi-core 0.3.0`, `docmesh-py-core v0.3.0`으로 표기하면서도 tagged v0.3.0 config snapshot과 body가 다르다. 특히 `build_docmesh_env_overlay()`가 개발 fallback을 추가하지 않고 `os.environ`의 복사본만 반환한다고 명시한다. installed runtime 검증 전에는 이 차이를 문서 간 불일치로 보존한다. ^[raw/articles/fastapi-core-wiki-configuration.md] ^[raw/articles/fastapi-core-config-v0.3.0.md]

2026-07-19 v0.5.0 Wiki Configuration reference는 이 두 계층을 `fastapi-core 0.5.0`과 `docmesh-py-core 0.4.0`의 current implementation으로 제시하고, `.env.example`은 자동 로드되지 않으며 loader cache는 테스트에서 명시적으로 clear해야 한다고 기록한다. 설치된 `fastapi-core 0.5.0`은 `AppConfig`/loader 경계와 startup failure mode·retry fields를 제공하고 프로젝트는 `docmesh-py-core 0.4.0`을 선언한다. 배포 값은 runtime policy와 함께 검증한다. ^[raw/articles/fastapi-core-wiki-configuration-v0.5.0.md]

v0.6.0 API reference도 `AppConfig`와 `load_app_config()`를 intended configuration entrypoint로 두고 loader 결과가 1개로 cache되며 환경 변경 test 뒤 `cache_clear()`가 필요하다고 기록한다. 설치된 v0.6.0 loader와 expanded access-log field를 runtime에서 확인했다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md]

요청된 v0.6.0 Configuration endpoint는 수집 시 v0.6.0 API Reference와 body-only SHA-256 및 바이트가 동일했다. 따라서 immutable raw capture는 보존하되 configuration-specific 사실을 중복 추가하지 않았으며, mutable Wiki endpoint가 이후 변할 수 있으므로 다음 수집에서 다시 비교한다. ^[raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/fastapi-core-wiki-configuration-v0.6.0.md]

## Deployment contract

DMS FastAPI 배포는 `ROOT_PATH`, `TOKEN_URL`, CORS 설정, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`를 환경에서 명시해 [[fastapi-core-app-assembly]]의 공개 경로와 readiness 정책을 결정한다. [[fastapi-core]]는 이 값을 소비해 app state와 middleware를 구성하며, 외부 시스템 설정은 [[docmesh-py-core]]를 통해 service client에 전달한다.

## Operating guardrails

tagged v0.3.0 config snapshot은 `build_docmesh_env_overlay()`가 Keycloak, MinIO, NATS 등의 개발·테스트 fallback을 추가한다고 설명하지만, GitHub Wiki snapshot은 원본 process environment를 변경하지 않는 복사만 반환하며 fallback을 추가하지 않는다고 설명한다. 어느 쪽이 설치된 package에 적용되는지 검증되기 전에는 fallback에 의존하지 않는다. 운영 환경에서는 secret/token/비밀번호를 명시적 환경변수나 외부 secret 주입으로 제공하고, wildcard CORS와 credential 조합을 피하며, required service 집합을 배포 정책으로 선언해야 한다. ^[raw/articles/fastapi-core-config-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-configuration.md]

`v0.3.0`의 `.env.example`은 자동으로 읽히는 파일이 아니라 배포 시 주입할 값을 설명하는 template이다. 활성 기본 surface는 `DOCMESH_SERVICES=keycloak`, `READINESS_REQUIRED_SERVICES=keycloak`, localhost CORS origins, startup healthcheck 비활성화이며, 실제 service credential과 연결 정보는 주석 처리되고 `[REDACTED]`로 표기된다. CSV 목록을 빈 값으로 설정하면 빈 목록이 되고 기본값을 쓰려면 변수를 제거해야 한다. ^[raw/articles/fastapi-core-env-example-v0.3.0.md]

Git tag `v0.4.0`의 `.env.example`은 자동 loading을 하지 않고, dotenv를 쓰더라도 애플리케이션이 명시적으로 선택해야 한다고 다시 명시한다. 이 template은 서비스 없는 최소 실행을 기본으로 `DOCMESH_SERVICES=`와 `READINESS_REQUIRED_SERVICES=`를 비운다. 즉, v0.3.0 template의 keycloak default surface와 달리 필요한 서비스와 그 credential을 모두 명시적으로 활성화해야 한다. `DOCMESH_SERVICE_ALTERNATIVES`는 세미콜론 group/쉼표 service 형식을 사용하며, production security validation은 `DOCMESH_ENV` 또는 `DOCMESH_SECURITY_MODE`로 켠다. ^[raw/articles/fastapi-core-env-example-v0.4.0.md]

Git tag `v0.5.0` `.env.example`은 같은 명시적 dotenv loading과 서비스 없는 baseline을 유지하면서 readiness timeout, CORS, logging, 서비스별 secret placeholder를 한 template에 정리한다. PostgreSQL에는 DSN이 아닌 개별 접속 필드만 제시하고, 필요한 credential-dependent service를 활성화할 때 credential도 함께 주입하라고 명시한다. 설치된 v0.5.0 `AppConfig`에는 `DOCMESH_STARTUP_FAILURE_MODE`, attempts, retry-delay가 있지만 template의 설정을 deployment에 채택하기 전에는 DocMesh runtime과 함께 검증한다. ^[raw/articles/fastapi-core-env-example-v0.5.0.md]

Git tag `v0.6.0` `.env.example`도 process environment만 읽고 파일을 자동 로드하지 않는다고 명시한다. active line은 empty enabled/required service, `CORS_ORIGINS=*`와 `CORS_CREDENTIALS=false`, startup fail/retry defaults를 service-free baseline으로 둔다. 서비스 block은 선택 목록을 먼저 채운 뒤에만 완성해 주입해야 하며 real secret은 version control 밖에 둔다. 설치된 v0.6.0은 startup 및 access-log field를 제공하므로 template의 application surface와 일치한다. ^[raw/articles/fastapi-core-env-example-v0.6.0.md]

## v0.7.0 configuration contract

v0.7.0 Configuration reference는 `AppConfig`와 `docmesh_config.ServiceConfigs`를 분리하고, `load_app_config()`의 cache, `.env` 비자동 로딩, process 환경의 빈 CSV를 빈 목록으로 해석하는 규칙, `required_services ⊆ enabled_services` 검증을 명시한다. 현재 interpreter에서 `fastapi_core` v0.7.0과 `docmesh_config` v0.1.0을 import하고 `create_app`/loader signature를 확인했다. `build_runtime_plan`은 AppConfig의 readiness/startup policy를 `docmesh_config.RuntimePlan`/`HealthcheckPolicy`로 변환하는 framework 경계이고, DMS storage selection은 별도 host adapter가 담당한다. ^[raw/articles/fastapi-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md]

v0.7.0 template은 `DOCMESH_SERVICES=`와 `READINESS_REQUIRED_SERVICES=`를 active service-free baseline으로 두고, 선택 service를 활성화할 때 완전한 설정 block과 secret을 함께 주입하도록 한다. `DOCMESH_STARTUP_FAILURE_MODE`, startup attempts/retry delay, access-log keys, 개별 PostgreSQL 필드, `MILVUS_ENDPOINT`, NATS auth mode가 application/service 설정 inventory에 포함된다. ^[raw/articles/fastapi-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-env-example-v0.7.0.md]

v0.7.0 Configuration 문서 내부에는 `NATS_NAME` 기본값이 `CFG-SVC-NATS` 표에서는 `docmesh-config`로, 전체 environment inventory와 `.env.example`에서는 `docmesh-py-core`로 나타나는 불일치가 있다. 설치본이 없어 어느 값이 runtime default인지 결정하지 않고, 패키지 source와 tests에서 확인할 unresolved documentation discrepancy로 남긴다. ^[raw/articles/fastapi-core-wiki-configuration-v0.7.0.md] ^[raw/articles/fastapi-core-env-example-v0.7.0.md]

`v0.2.0` 설정 문서는 PostgreSQL을 `ServiceConfigs`가 다루는 외부 시스템, development/test fallback, 그리고 전용 dependency 범위에 포함한다. 이는 PostgreSQL 지원이 `fastapi-core` 자체의 문서 저장 API를 뜻하는 것은 아니며, [[docmesh-py-core]]가 제공하는 설정·client wrapper를 [[fastapi-core-app-assembly]]가 선택 서비스와 readiness에 연결하는 application-layer 통합이다. ^[raw/articles/fastapi-core-config-v0.2.0.md]

`v0.2.0` config 문서는 `CORS_ORIGINS`, `DOCMESH_SERVICES`, `READINESS_REQUIRED_SERVICES`의 빈 문자열이 validation error라고 기록하지만, `v0.3.0` API는 환경변수 빈 문자열을 빈 목록으로 해석하고 미설정일 때만 기본값을 사용한다고 문서화한다. 새 ref를 채택할 때는 빈 `DOCMESH_SERVICES`가 keycloak 기본값이 아니라 빈 enabled set이 되는지 설치된 패키지와 테스트에서 확인해야 한다. ^[raw/articles/fastapi-core-api-v0.3.0.md]

`v0.4.0` environment template은 그 빈-CSV 해석을 deployable configuration으로 채택한다: template에 기록된 빈 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`는 서비스 없는 앱을 뜻하며, AppConfig default를 의도하면 변수를 제거한다. 당시 v0.5.0 runtime probe에서는 `AppConfig`의 서비스 선택·readiness·logging, startup failure/retry fields와 `.env` 비자동 로딩을 확인했다. 현재 manifest와 interpreter는 `fastapi-core` v0.7.0이며, v0.7 package surface를 직접 확인했다. ^[raw/articles/fastapi-core-env-example-v0.4.0.md] ^[raw/articles/fastapi-core-wiki-configuration-v0.5.0.md]

`v0.3.0` config와 GitHub Wiki snapshot은 `DOCMESH_SERVICE_ALTERNATIVES`의 세미콜론 그룹·쉼표 서비스 목록 parsing, readiness per-service/overall timeout, `DOCMESH_HEALTHCHECK_ENABLED`의 `startup_healthcheck` alias, 그리고 `required_services ⊆ enabled_services` 검증을 함께 기록한다. Wiki snapshot은 `load_docmesh_settings(...)`/`build_docmesh_env_overlay()`가 process environment를 변경하지 않으며, runtime injection 시 서비스 설정·client 조립만 우회되고 AppConfig CORS/logging/readiness 정책은 계속 적용된다고 설명한다. ^[raw/articles/fastapi-core-config-v0.3.0.md] ^[raw/articles/fastapi-core-wiki-configuration.md]

GitHub Wiki Examples는 `load_docmesh_settings(("sqlite", "nats"))`가 선택된 설정만 로드하고, 빈 tuple이 서비스 설정을 로드하지 않는 예시를 제공한다. 이 loader와 `load_app_config()`는 cache되므로, 동일 process에서 환경을 바꾸는 테스트만 각각 `cache_clear()`를 호출한다. ^[raw/articles/fastapi-core-wiki-examples.md]

같은 이름의 `DOCMESH_HEALTHCHECK_ENABLED`는 `docmesh-py-core.CommonConfig.healthcheck_enabled`와 FastAPI `AppConfig.startup_healthcheck`에 각각 관여할 수 있다. Py Core의 기본값은 `true`지만 FastAPI startup policy 기본값은 `false`이므로, DMS 배포는 startup network check 여부를 별도로 결정해야 한다. production 보안 제약은 FastAPI가 재구현하지 않고 Py Core loader/assembly의 `validate_runtime_security()` 결과에 의존한다. ^[raw/articles/fastapi-core-config-v0.3.0.md]

업스트림 `docmesh-py-core`는 공백 문자열을 미설정으로 보고 selected service만 validation하도록 `load_service_configs(services=...)`를 제공한다. 반대로 `load_available_service_configs(...)`는 관련 prefix가 하나라도 있으면 부분 설정을 오류로 처리한다. 따라서 FastAPI의 enabled-service 선택, deployment secret 주입, DMS SDK가 실제로 소비하는 저장소 설정을 같은 목록으로 취급하지 말고 각각의 loader 경계를 확인해야 한다. 또한 startup 상태 확인은 `RuntimePlan.healthcheck`가 제어하므로 FastAPI 앱의 readiness 정책과 별도로 명시해야 한다. ^[raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md]

`AppConfig` 직접 주입, 환경변수 설정, SQLite만 선택 로딩하는 실행 예제는 [[fastapi-core-usage-patterns]]를 참고한다. 이 예제들은 [[fastapi-core-app-assembly]]의 readiness 상태와 service selection이 함께 바뀐다는 점을 보여 준다. ^[raw/articles/fastapi-core-examples-v0.1.6.md]

`SQLITE_PATH`와 MinIO 같은 이름이 두 계층에 걸쳐 보이지만, DMS SDK의 storage 선택·startup health 정책은 [[dms-core-configuration]]의 책임이고, `fastapi-core`는 application assembly와 service readiness 정책을 담당한다. 같은 환경을 배포하더라도 설정 소유 경계를 명시해야 한다. ^[raw/articles/dms-core-config-v0.2.0.md]


v0.7.0 Configuration은 DMS가 환경변수·`.env`·connection을 직접 읽거나 만들지 않고 host-created Engine/MinIO client 또는 component를 받는다고 명시한다. 따라서 FastAPI `AppConfig`/secret layer와 DMS storage assembly는 같은 deployment에서 함께 구성하더라도 ownership을 합치지 않으며, DMS `DmsServiceConfigs`와 plan은 host-side policy/input으로 검증한다. 현재 consumer는 `dms_factory.py`에서 이 경계를 실행하고, `dms` v0.7.0 package와 close semantics를 테스트했다. ^[raw/articles/dms-core-wiki-configuration-v0.7.0.md] ^[raw/articles/dms-core-wiki-api-reference-v0.7.0.md]

## docmesh-config boundary

`docmesh-config` v0.1.0은 process-environment-only common/service settings, `ServiceConfigs`, `RuntimePlan`과 network-free diagnosis를 제공한다. 이것은 `fastapi-core`의 `AppConfig`·CORS·token URL·enabled/required service policy·readiness/lifespan assembly와 다른 configuration layer다. 두 문서가 같은 environment prefix를 언급해도 direct loader integration이나 shared model을 가정하지 않는다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

`docmesh-config`의 `HealthcheckPolicy`는 runtime이 소비할 metadata이고, FastAPI readiness registry나 managed resource healthcheck를 실행하지 않는다. 현재 `pyproject.toml`과 interpreter는 v0.1.0 dependency를 사용하며, application은 `docmesh-config` loader/diagnosis를 DMS host assembly에 명시적으로 연결한다. 이 plan이 FastAPI resource에 자동 주입된다고 기록하지 않고, [[docmesh-config-runtime-plan]], [[fastapi-core-app-assembly]]와 version-aligned contract test로 bridge를 검증한다.

## v0.6 docmesh-py-core package bridge

`docmesh-py-core` v0.6.0 API/Examples는 `docmesh_config.RuntimePlan`을 자체 `service_lifespan`/assembly가 소비하는 package bridge를 명시한다. generic FastAPI 예제는 FastAPI를 별도 dependency로 설치하고 `app.state.services`에 runtime을 두지만, `fastapi-core`의 `create_app`·AppConfig·readiness registry contract를 직접 증명하지 않는다. 현재 adapter는 generic runtime을 DMS에 자동 연결하지 않고, 필요한 sync client factory만 명시적으로 호출한 뒤 FastAPI resource lifecycle에 DMS SDK를 등록한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

## Open questions

- DMS 프로덕션에서 `DOCMESH_SERVICES`와 `READINESS_REQUIRED_SERVICES`에 포함할 서비스는 무엇인가?
- secret 주입은 배포 플랫폼의 어떤 메커니즘으로 표준화할 것인가?
- reverse proxy 경로와 `ROOT_PATH`/`TOKEN_URL` 조합은 어떤 URL 계약을 따라야 하는가?
- PostgreSQL을 DMS 배포의 enabled/required service 집합에 포함할지, 그리고 DMS SDK의 metadata-store 선택과 어떻게 정렬할 것인가?

## Sources

- `raw/articles/fastapi-core-api-v0.1.6.md`
- `raw/articles/fastapi-core-api-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/fastapi-core-config-v0.1.6.md`
- `raw/articles/fastapi-core-config-v0.2.0.md`
- `raw/articles/fastapi-core-config-v0.3.0.md`
- `raw/articles/fastapi-core-wiki-configuration.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.5.0.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.6.0.md`
- `raw/articles/fastapi-core-wiki-configuration-v0.7.0.md`
- `raw/articles/fastapi-core-env-example-v0.3.0.md`
- `raw/articles/fastapi-core-env-example-v0.4.0.md`
- `raw/articles/fastapi-core-env-example-v0.5.0.md`
- `raw/articles/fastapi-core-env-example-v0.6.0.md`
- `raw/articles/fastapi-core-env-example-v0.7.0.md`
- `raw/articles/fastapi-core-examples-v0.1.6.md`
- `raw/articles/fastapi-core-wiki-examples.md`
- `raw/articles/fastapi-core-wiki-examples-v0.7.0.md`
- `raw/articles/dms-core-config-v0.2.0.md`
- `raw/articles/dms-core-wiki-api-reference-v0.7.0.md`
- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
