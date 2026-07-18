# Wiki Schema

## Domain
`dms-core`를 도메인/로직 코어로, `fastapi-core`를 FastAPI 컴포넌트 계층으로 사용해 DMS(Document Management System)를 FastAPI로 배포하는 아키텍처, 구현, 운영 지식.

## Conventions
- 파일명은 소문자와 하이픈만 사용한다(예: `dms-core.md`).
- `raw/`는 원문 보관 영역이며 생성 후 수정하지 않는다.
- `entities/`, `concepts/`, `comparisons/`, `queries/`의 모든 위키 페이지는 아래 YAML frontmatter로 시작한다.
- 위키 페이지 간에는 `[[wikilinks]]`를 사용한다. 새 페이지는 가능하면 최소 2개의 기존 페이지로 연결한다. 초기 핵심 페이지가 아직 없으면 첫 관련 페이지가 생성된 뒤 상호 연결을 보완한다.
- 페이지를 갱신할 때 `updated` 날짜를 변경한다.
- 새 위키 페이지는 `index.md`의 적절한 섹션에 추가하고, 모든 작업은 `log.md`에 기록한다.
- 3개 이상 소스를 종합한 페이지의 문단에는 해당 근거를 `^[raw/.../source.md]` 형식으로 표시한다.
- 태그는 아래 taxonomy의 항목만 사용한다. 새로운 태그가 필요하면 먼저 이 문서에 추가한다.

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

`confidence`, `contested`, `contradictions`는 해당할 때만 넣는다. 단일 출처 또는 빠르게 변하는 주장에는 보통 `confidence: medium` 또는 `low`를 쓴다.

## Raw-source Frontmatter
```yaml
---
source_url: https://example.com/source
ingested: YYYY-MM-DD
sha256: <body-only SHA-256>
---
```

해시는 frontmatter 뒤의 본문에 대해서만 계산한다. 동일 URL을 재수집하면 해시를 비교해 동일하면 건너뛰고, 변경되었으면 source drift로 기록한다.

## Tag Taxonomy
- **System/domain:** `dms`, `document`, `metadata`, `storage`, `workflow`
- **Application/API:** `fastapi`, `api`, `fastapi-core`, `dms-core`, `integration`, `messaging`
- **Platform/operations:** `deployment`, `container`, `configuration`, `security`, `observability`
- **Engineering:** `architecture`, `testing`, `migration`, `performance`, `dependency`

## Page Thresholds
- 엔티티나 개념이 2개 이상의 소스에 등장하거나 한 소스의 중심 주제이면 페이지를 만든다.
- 기존에 다룬 대상이면 새 페이지 대신 기존 페이지를 갱신한다.
- 단순 언급, 주변적 세부 사항, 도메인 밖의 정보는 페이지를 만들지 않는다.
- 페이지가 약 200줄을 넘으면 하위 주제로 분리한다.
- 완전히 대체된 페이지는 `_archive/`로 옮기고 index에서 제거한다.

## Entity Pages
주요 컴포넌트, 패키지, 서비스별로 한 페이지를 둔다. 목적, 핵심 API/설정, 관계, 근거 소스를 포함한다.

## Concept Pages
배포 구조, 의존성 경계, 문서 수명주기, 인증/권한, 저장소 연동 같은 설계 주제별로 한 페이지를 둔다. 정의, 현재 결정, 미해결 질문, 관련 페이지를 포함한다.

## Comparison Pages
대안이나 구현 방식을 비교한다. 비교 목적, 표 형식의 기준, 결론/권고, 근거를 포함한다.

## Update Policy
새 정보가 기존 정보와 충돌하면:
1. 출처와 날짜를 비교한다.
2. 실제로 상충하면 양쪽 견해와 날짜/출처를 기록한다.
3. frontmatter에 `contradictions`와 필요 시 `contested: true`를 넣는다.
4. lint 보고서에서 사용자 검토 항목으로 표시한다.
