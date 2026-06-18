# Wiki Log

> Chronological record of all wiki actions. Append-only.
> Format: `## [YYYY-MM-DD] action | subject`
> Actions: ingest, update, query, lint, create, archive, delete
> When this file exceeds 500 entries, rotate: rename to log-YYYY.md, start fresh.

## [2026-06-18] create | Wiki initialized
- Domain: FastAPI 기반의 RESTful API 서버에서 문서와 문서 관련 메타데이터를 관리하는 시스템
- Structure created: `SCHEMA.md`, `index.md`, `log.md`
- Directories created: `raw/articles`, `raw/papers`, `raw/transcripts`, `raw/assets`, `entities`, `concepts`, `comparisons`, `queries`

## [2026-06-18] ingest | docmesh-py-core SDK usage guide
- Source added: `raw/articles/docmesh-py-core-sdk-2026-06-18.md`
- Pages created: `entities/service-factory-registry.md`, `concepts/sdk-consumption-pattern.md`, `concepts/fastapi-sdk-lifespan-integration.md`, `concepts/service-selection-and-health-checks.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | docmesh-py-core API guide
- Source added: `raw/articles/docmesh-py-core-api-2026-06-18.md`
- Pages created: `entities/keycloak-auth-service.md`, `entities/nats-connection-builder.md`, `entities/service-client-wrapper.md`, `concepts/sensitive-data-masking.md`
- Pages updated: `entities/service-factory-registry.md`, `concepts/service-selection-and-health-checks.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | docmesh-py-core configuration guide
- Source added: `raw/articles/docmesh-py-core-config-2026-06-18.md`
- Pages created: `entities/settings.md`, `concepts/environment-variable-configuration.md`, `concepts/keycloak-provisioning-configuration.md`
- Pages updated: `entities/keycloak-auth-service.md`, `concepts/sdk-consumption-pattern.md`, `concepts/sensitive-data-masking.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | fastapi-core API specification
- Source added: `raw/articles/fastapi-core-api-2026-06-18.md`
- Pages created: `entities/keycloak-auth-provider.md`, `entities/env-config.md`, `entities/service-settings.md`, `concepts/fastapi-core-dependency-policy.md`, `concepts/application-lifecycle-and-readiness.md`, `concepts/nats-event-subjects.md`
- Pages updated: `concepts/fastapi-sdk-lifespan-integration.md`, `concepts/service-selection-and-health-checks.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | fastapi-core configuration guide
- Source added: `raw/articles/fastapi-core-config-2026-06-18.md`
- Pages created: `concepts/fastapi-core-layered-configuration.md`
- Pages updated: `entities/env-config.md`, `entities/service-settings.md`, `concepts/application-lifecycle-and-readiness.md`, `concepts/fastapi-core-dependency-policy.md`, `concepts/environment-variable-configuration.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | fastapi-core messaging guide
- Source added: `raw/articles/fastapi-core-messaging-2026-06-18.md`
- Pages created: `concepts/fastapi-core-messaging-integration.md`, `concepts/domain-event-payload-conventions.md`
- Pages updated: `concepts/nats-event-subjects.md`
- Navigation updated: `index.md`

## [2026-06-18] ingest | dms-core SDK public interface
- Source added: `raw/articles/dms-core-sdk-interface-2026-06-18.md`
- Pages created: `entities/document-management-sdk.md`, `entities/document-metadata.md`, `concepts/document-storage-key-policy.md`, `concepts/document-operation-consistency.md`
- Pages updated: `concepts/sdk-consumption-pattern.md`, `concepts/sensitive-data-masking.md`
- Navigation updated: `index.md`
