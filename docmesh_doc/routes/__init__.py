from fastapi import FastAPI

from docmesh_doc.routes.documents import router as documents_router
from docmesh_doc.routes.metadata import router as metadata_router


def include_routes(app: FastAPI) -> None:
    app.include_router(documents_router)
    app.include_router(metadata_router)
