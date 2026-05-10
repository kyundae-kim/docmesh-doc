from fastapi import FastAPI


from docmesh_doc.routes.auth import router as auth_router
from docmesh_doc.routes.health import router as healthcheck_router


def include_routes(app: FastAPI):
    app.include_router(healthcheck_router)
    app.include_router(auth_router)
