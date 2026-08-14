# DocMesh Document Service

DocMesh Document Service는 문서 본문과 metadata를 일관된 HTTP API로 관리하는 FastAPI 서비스입니다. 문서 본문은 DMS SDK가 구성한 MinIO object store에 저장하고, 문서 ID·원본 파일명·작성자·checksum·상태·사용자 metadata는 metadata store에서 관리합니다.
