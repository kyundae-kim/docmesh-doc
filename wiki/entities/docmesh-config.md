---
title: docmesh-config
created: 2026-08-02
updated: 2026-08-04
type: entity
tags: [configuration, dependency, integration, security, testing]
sources: [raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md, raw/articles/docmesh-config-wiki-configuration-v0.1.0.md, raw/articles/docmesh-config-wiki-examples-v0.1.0.md, raw/articles/docmesh-config-env-example-v0.1.0.md, raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md, raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md, raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md, raw/articles/docmesh-py-core-env-example-v0.6.0.md]
confidence: medium
---

# docmesh-config

`docmesh-config` v0.1.0은 프로세스 환경변수에서 DocMesh 서비스 설정을 읽고, 외부 연결 없이 구성 상태와 runtime plan을 진단하는 Python 설정 패키지다. package root의 `__all__`을 안정 공개 표면으로 두며, `docmesh_config.config`는 설정 모델·로딩·진단을 위한 호환 facade다. 새 코드는 package-root import를 권장한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## Scope and public surface

공개 API는 `CommonConfig`와 Keycloak·PostgreSQL·SQLite·MinIO·Milvus·Ollama·Langfuse·NATS 설정 모델, `ServiceConfigs`, `load_service_configs(...)`, `load_available_service_configs(...)`, `diagnose_services(...)`, `RuntimePlan`, `RuntimePlanMetadata`, secret-safe 오류/직렬화 helper를 포함한다. 설정 로더는 client를 만들거나 DNS/socket/API에 연결하지 않는다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

`ServiceConfigs`는 선택적으로 로드된 서비스 설정 bundle이며 `require_*()`는 로드되지 않은 서비스를 요청할 때 구조화된 `ConfigError`를 낸다. `ConfigIssue`, `ServiceConfigurationDiagnosis`, `EnvironmentDiagnosis`는 canonical 환경변수 key와 remediation을 사용해 원문 secret을 노출하지 않는 진단 결과를 표현한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md]

## Configuration contract

설정 레퍼런스는 `CommonConfig`와 8개 서비스의 98개 환경변수를 추적한다. 모든 설정 모델은 인자 없이 생성되고 프로세스 환경만 읽으며, 환경변수 이름은 대소문자를 구분하지 않고 공백 값은 미설정으로 취급한다. `model_dump()`·`model_dump_json()`·validation 오류·진단 결과에는 secret과 endpoint credential이 마스킹된다. `.env`는 자동으로 읽지 않으므로 애플리케이션이나 배포기가 값을 process environment로 주입해야 한다. 세부 계약은 [[docmesh-config-configuration]]에 정리한다. ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

## Plan and diagnosis contract

`RuntimePlan`은 선택 서비스, required/optional 여부, 대안 그룹, startup healthcheck 정책과 MinIO bucket 요구를 하나의 immutable 값으로 묶는다. `diagnose_services(...)`는 `absent`·`complete`·`partial`·`invalid` 상태를 연결 없이 계산하며, `strict` 선택 모드에서는 대안 그룹의 중복 구성도 오류로 표시한다. `HealthcheckPolicy`는 실행기가 소비할 정책 metadata이지 실제 상태 확인 실행기가 아니다. 자세한 경계는 [[docmesh-config-runtime-plan]]에 정리한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md]

## Relationship to the DMS stack

이 source set은 `docmesh-config`가 설정·진단·plan metadata 계층이라는 사실을 보여 주지만, [[dms-core]]의 metadata backend/object-store factory나 [[fastapi-core]]의 `AppConfig`·router·lifespan 조립을 직접 구현한다고 말하지 않는다. 서비스 이름과 `POSTGRES_*`·`MINIO_*` 같은 환경변수가 겹치더라도 별도 패키지의 loader를 직접 통합했다고 추론하지 않는다. [[dms-core-configuration]]과 [[fastapi-core-configuration]]에서 각 소비 계층의 소유권을 따로 유지한다. ^[raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md] ^[raw/articles/docmesh-config-wiki-configuration-v0.1.0.md]

현재 소비 workspace의 `pyproject.toml`은 `docmesh-config` Git ref `v0.1.0`을 선언하고, interpreter에서 `docmesh_config` v0.1.0 import와 `load_service_configs`·`diagnose_services`·`RuntimePlan` exports를 확인했다. `docmesh_doc.dms_factory`는 이 package를 실제 설정 boundary로 사용하며, strict diagnosis와 selected-service loading을 regression test로 검증한다.

## v0.6 package consumer relationship

`docmesh-py-core` v0.6.0 API/Examples는 `docmesh_config`를 canonical settings/plan package로 import하고 `RuntimePlan`을 `docmesh_py_core` client/lifecycle API에 전달한다. 이 source set은 `docmesh-config`가 자체적으로 client factory, FastAPI `app.state`, readiness registry 또는 DMS storage assembly를 제공한다고 말하지 않지만, 현재 host adapter는 그 canonical settings를 py-core factory에 명시적으로 전달한다. ^[raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md] ^[raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md]

현재 interpreter에는 `docmesh-config` v0.1.0과 `docmesh-py-core` v0.6.0이 설치되어 있으며, wrapper factory signature와 SQLite/MinIO 조립을 확인했다. 소비 adapter는 version-aligned imports/signatures를 사용하고 `test_dms_factory.py`에서 client injection, strict configuration, legacy DSN rejection과 close를 검증한다.

## Usage boundary

예제는 SQLite 단독 로드, 환경에 존재하는 서비스만 선택 로드, 대안 서비스의 strict 진단, runtime metadata 생성, MinIO bucket 요구, 구조화 오류 처리, production transport 정책과 secret-safe 출력까지를 보여 준다. 예제는 외부 서비스에 연결하지 않으며, `.env.example`도 필요한 block을 복사한 뒤 배포기가 명시적으로 환경변수로 주입하는 template이다. ^[raw/articles/docmesh-config-wiki-examples-v0.1.0.md] ^[raw/articles/docmesh-config-env-example-v0.1.0.md]

`docmesh-py-core`의 settings/client assembly와 `fastapi-core`의 application lifecycle을 연결하려면 버전이 맞는 패키지의 실제 exports·signatures와 소비 adapter 테스트를 별도로 확인해야 한다. 현재 wiki의 관련 경계는 [[docmesh-py-core]], [[docmesh-py-core-usage-patterns]], [[fastapi-core-app-assembly]]를 함께 읽는다.

## Consumer source minimization

현재 consumer의 주요 반복은 설정 모델이 아니라 `RuntimePlan` 진단·`ServiceConfigs` loading·DMS client injection을 연결하는 adapter glue다. `docmesh-config`에 plan-aware resolved configuration과 structured diagnosis promotion을 additive API로 추가할 후보 및 DMS/FastAPI policy를 generic layer로 옮기지 않는 경계는 [[docmesh-config-consumer-source-minimization]]에 정리한다.

## Sources

- `raw/articles/docmesh-config-wiki-api-reference-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-configuration-v0.1.0.md`
- `raw/articles/docmesh-config-wiki-examples-v0.1.0.md`
- `raw/articles/docmesh-config-env-example-v0.1.0.md`
- `raw/articles/docmesh-py-core-wiki-api-reference-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-configuration-v0.6.0.md`
- `raw/articles/docmesh-py-core-wiki-examples-v0.6.0.md`
- `raw/articles/docmesh-py-core-env-example-v0.6.0.md`
