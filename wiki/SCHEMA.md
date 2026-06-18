# Wiki Schema

## Domain
FastAPI 기반의 RESTful API 서버에서 문서(document)와 문서 관련 메타데이터를 관리하는 시스템 지식 베이스.

이 위키는 다음을 다룬다:
- 문서 업로드/다운로드/조회/삭제 API
- 문서 메타데이터 모델, 저장 방식, 검증 규칙
- 인증/인가, 감사(audit), 검색, 버전 관리, 비동기 처리
- 스토리지 계층(MinIO/S3, 로컬 파일시스템 등)과 애플리케이션 계층의 연계
- FastAPI 애플리케이션 구조, 운영/관측, 외부 연동

## Conventions
- File names: lowercase, hyphens, no spaces (e.g., `document-metadata-model.md`)
- Every wiki page starts with YAML frontmatter
- Use `[[wikilinks]]` to link between pages (minimum 2 outbound links per page)
- When updating a page, always bump the `updated` date
- Every new page must be added to `index.md` under the correct section
- Every action must be appended to `log.md`
- On pages that synthesize 3+ sources, append provenance markers like `^[raw/articles/source-file.md]` to paragraphs whose claims trace to a specific source
- Raw sources in `raw/` are immutable; corrections and interpretations belong in wiki pages only

## Frontmatter
```yaml
---
title: Page Title
created: YYYY-MM-DD
updated: YYYY-MM-DD
type: entity | concept | comparison | query | summary
tags: [from taxonomy below]
sources: [raw/articles/source-name.md]
confidence: high | medium | low
contested: true
contradictions: [other-page-slug]
---
```

Notes:
- `confidence`, `contested`, and `contradictions` are optional but recommended for evolving design decisions or single-source claims.
- `sources` must always list the raw source files that support the page.

## raw/ Frontmatter
```yaml
---
source_url: https://example.com/article
ingested: YYYY-MM-DD
sha256: <hex digest of the raw content below the frontmatter>
---
```

The `sha256` is computed over the raw body only, excluding the frontmatter.

## Tag Taxonomy
Every tag used on a page must appear here first.

### API / Architecture
- api
- rest
- endpoint
- router
- service
- repository
- architecture
- async
- background-task

### Document Domain
- document
- metadata
- schema
- validation
- versioning
- search
- indexing
- classification

### Storage / Data
- database
- orm
- sqlalchemy
- postgres
- minio
- s3
- filesystem
- migration

### Security / Governance
- auth
- authorization
- audit
- compliance
- privacy

### Operations / Quality
- testing
- observability
- logging
- deployment
- performance
- reliability

### Meta
- comparison
- decision
- convention
- issue
- roadmap

Rule: if a new tag is needed, add it here before using it on any page.

## Page Thresholds
- **Create a page** when an entity/concept appears in 2+ sources OR is central to one source
- **Add to existing page** when a source mentions something already covered
- **DON'T create a page** for passing mentions, minor details, or out-of-scope topics
- **Split a page** when it exceeds ~200 lines — break into sub-topics with cross-links
- **Archive a page** when its content is fully superseded — move to `_archive/`, remove from index

## Entity Pages
One page per notable entity such as:
- API resources (`document`, `document-metadata`, `upload-session`)
- External systems (`minio`, `postgres`, `nats`)
- Major internal components (`document-service`, `metadata-repository`)

Each entity page should include:
- Overview / responsibility
- Key fields, behaviors, and lifecycle
- Relationships to other entities via `[[wikilinks]]`
- Relevant source references

## Concept Pages
One page per core topic such as:
- document lifecycle
- metadata validation strategy
- storage abstraction
- search and indexing
- authentication and authorization flows

Each concept page should include:
- Definition / explanation
- Current implementation or intended design
- Open questions or trade-offs
- Related concepts via `[[wikilinks]]`

## Comparison Pages
Use comparison pages for side-by-side analyses such as:
- MinIO vs filesystem storage
- synchronous vs background processing
- inline metadata vs normalized metadata tables

Include:
- What is being compared and why
- Dimensions of comparison (table preferred)
- Decision / synthesis
- Sources

## Update Policy
When new information conflicts with existing content:
1. Check dates — newer sources generally supersede older ones
2. If genuinely contradictory, note both positions with dates and sources
3. Mark the contradiction in frontmatter with `contradictions: [page-name]`
4. Set `contested: true` when unresolved
5. Flag the issue in a lint report for review

## Suggested Top-Level Themes
The initial wiki should expect content around:
- Document CRUD API design
- Metadata schema and storage strategy
- File/object storage integration
- Search, filtering, and pagination
- Access control and auditability
- Operational concerns for FastAPI services
