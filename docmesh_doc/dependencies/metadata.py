from fastapi import Request

from docmesh_doc.services.metadata import MetadataService


def get_metadata_service(request: Request) -> MetadataService:
    return request.app.state.metadata_service
