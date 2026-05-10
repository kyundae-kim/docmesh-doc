from dataclasses import dataclass

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse


@dataclass(slots=True)
class AuthError(Exception):
    status_code: int
    error: str
    error_description: str
    headers: dict[str, str] | None = None


def auth_error_payload(error: str, error_description: str) -> dict[str, str]:
    return {
        "error": error,
        "error_description": error_description,
    }


async def auth_error_handler(_: Request, exc: AuthError) -> JSONResponse:
    return JSONResponse(
        status_code=exc.status_code,
        content=auth_error_payload(exc.error, exc.error_description),
        headers=exc.headers,
    )


def register_exception_handlers(app: FastAPI) -> None:
    app.add_exception_handler(AuthError, auth_error_handler)
