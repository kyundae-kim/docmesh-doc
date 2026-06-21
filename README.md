# DocMesh Document Service

DocMesh Document Service는 사용자 문서를 MinIO에 저장/조회/삭제(Soft Delete)하고,
문서 연관 metadata를 Postgres에 저장/관리하는 FastAPI 서비스입니다.

이 저장소의 문서는 목적별로 분리되어 있습니다.
