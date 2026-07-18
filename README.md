# DocMesh Document Service

DocMesh Document Service는 사용자 문서를 MinIO에 저장/조회/삭제(Soft Delete)하고,
문서 연관 metadata를 Postgres에 저장/관리하는 FastAPI 서비스입니다.

이 저장소의 문서는 목적별로 분리되어 있습니다.

- [API Reference](docs/api.md) — 공개 HTTP/hosting API ID, schema, 구현·요구사항·테스트 추적성
- [API 사용 예시](docs/examples.md) — API ID별 `curl`/hosting 예시와 역방향 추적표
- [설정 정의서](docs/config.md) — 설정 그룹·환경변수와 공개 API 영향도
- [제품 요구사항 정의서](docs/prd.md), [소프트웨어 요구사항 정의서](docs/srs.md), [테스트 정의서](docs/test.md)
