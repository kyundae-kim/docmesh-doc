from __future__ import annotations

import os
from contextlib import asynccontextmanager
from dataclasses import replace
from typing import Callable
from uuid import uuid4

import dms
from fastapi import FastAPI, HTTPException, Request
from fastapi.exceptions import RequestValidationError
from fastapi.middleware.cors import CORSMiddleware
from fastapi.openapi.utils import get_openapi
from fastapi.responses import JSONResponse

from docmesh_doc.dms_factory import DmsRuntime, DmsSettings, create_dms_runtime
from docmesh_doc.errors import (
    dms_error_handler,
    http_error_handler,
    unhandled_error_handler,
    validation_error_handler,
)
from docmesh_doc.router import router


ReadinessCheck = Callable[[], bool | dict[str, object]]


def _effective_settings(
    settings: DmsSettings | None,
    *,
    root_path: str | None,
) -> DmsSettings:
    selected = settings or DmsSettings.from_env(dict(os.environ))
    if root_path is not None:
        selected = replace(selected, root_path=root_path)
    return selected


def _correlation_id(request: Request) -> str:
    supplied = request.headers.get("X-Correlation-ID", "").strip()
    if supplied and len(supplied) <= 128 and all(
        32 <= ord(character) < 127 for character in supplied
    ):
        return supplied
    return str(uuid4())


def _readiness_payload(
    app: FastAPI,
    readiness_check: ReadinessCheck | None,
) -> tuple[int, dict[str, object]]:
    if readiness_check is not None:
        try:
            result = readiness_check()
        except Exception:
            result = False
        if isinstance(result, bool):
            payload = {
                "status": "ok" if result else "error",
                "ok": result,
                "details": {"dms": {"ok": result, "required": True}},
            }
        else:
            ok = bool(result.get("ok", False))
            payload = dict(result)
            payload.setdefault("status", "ok" if ok else "error")
            payload.setdefault("details", {})
        return (200 if bool(payload.get("ok")) else 503), payload

    runtime: DmsRuntime | None = getattr(app.state, "dms_runtime", None)
    if runtime is not None:
        payload = runtime.check_readiness()
        return (200 if bool(payload["ok"]) else 503), payload

    if getattr(app.state, "dms_sdk", None) is None:
        payload = {
            "status": "error",
            "ok": False,
            "details": {"dms": {"ok": False, "required": True}},
        }
        return 503, payload

    return 200, {
        "status": "ok",
        "ok": True,
        "details": {"dms": {"ok": True, "required": True}},
    }


def create_application(
    sdk: dms.DefaultDocumentManagementSDK | None = None,
    *,
    settings: DmsSettings | None = None,
    runtime: DmsRuntime | None = None,
    root_path: str | None = None,
    readiness_check: ReadinessCheck | None = None,
) -> FastAPI:
    """Create the HTTP API around a host-injected dms-core facade.

    An injected SDK or runtime remains owned by the caller and is not closed
    by the application lifespan. When neither is supplied, the application
    assembles and owns a runtime for its own lifespan.
    """

    if sdk is not None and runtime is not None:
        raise ValueError("provide sdk or runtime, not both")

    selected = _effective_settings(
        settings,
        root_path=root_path,
    )
    if runtime is not None:
        sdk = runtime.sdk

    @asynccontextmanager
    async def lifespan(application: FastAPI):
        owned_runtime: DmsRuntime | None = None
        if application.state.dms_runtime is None and sdk is None:
            owned_runtime = create_dms_runtime(selected)
            application.state.dms_runtime = owned_runtime
            application.state.dms_sdk = owned_runtime.sdk
        try:
            yield
        finally:
            if owned_runtime is not None:
                owned_runtime.close()

    app = FastAPI(
        title="DocMesh Document Service",
        version="0.4.0",
        root_path=selected.root_path,
        lifespan=lifespan,
    )
    app.state.settings = selected
    app.state.dms_sdk = sdk
    app.state.dms_runtime = runtime
    app.state.readiness_check = readiness_check

    if selected.cors_origins:
        app.add_middleware(
            CORSMiddleware,
            allow_origins=list(selected.cors_origins),
            allow_credentials="*" not in selected.cors_origins,
            allow_methods=["*"],
            allow_headers=["*"],
        )

    @app.middleware("http")
    async def correlation_middleware(request: Request, call_next):
        correlation_id = _correlation_id(request)
        request.state.correlation_id = correlation_id
        response = await call_next(request)
        response.headers["X-Correlation-ID"] = correlation_id
        return response

    @app.get("/health/liveness", tags=["health"])
    async def liveness() -> dict[str, str]:
        return {"status": "ok"}

    @app.get("/health/readiness", tags=["health"])
    async def readiness() -> JSONResponse:
        status_code, payload = _readiness_payload(app, readiness_check)
        return JSONResponse(status_code=status_code, content=payload)

    app.include_router(router)

    def openapi() -> dict[str, object]:
        if app.openapi_schema:
            return app.openapi_schema
        schema = get_openapi(
            title=app.title,
            version=app.version,
            routes=app.routes,
        )
        for path, path_item in schema["paths"].items():
            if not path.startswith("/documents"):
                continue
            for operation in path_item.values():
                if isinstance(operation, dict):
                    operation.get("responses", {}).pop("422", None)
        app.openapi_schema = schema
        return schema

    app.openapi = openapi
    app.add_exception_handler(dms.DmsError, dms_error_handler)
    app.add_exception_handler(RequestValidationError, validation_error_handler)
    app.add_exception_handler(HTTPException, http_error_handler)
    app.add_exception_handler(Exception, unhandled_error_handler)
    return app
