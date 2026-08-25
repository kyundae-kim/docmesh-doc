from __future__ import annotations

import pytest
from starlette.requests import ClientDisconnect

from docmesh_doc.router import (
    _stream_async_document,
    _stream_document,
    _stream_document_chunks,
)
from test_docmesh_doc.support import FakeSDK, public_metadata


@pytest.mark.anyio
async def test_stream_closes_dms_resource_on_client_disconnect():
    sdk = FakeSDK()
    item = sdk.get_document_content_stream("doc-1")
    response = _stream_document(item, disposition="attachment")

    async def receive():
        return {"type": "http.disconnect"}

    async def send(message):
        if message["type"] == "http.response.body":
            raise OSError("client disconnected")

    with pytest.raises(ClientDisconnect):
        await response(
            {
                "type": "http",
                "method": "GET",
                "path": "/documents/doc-1/download",
                "headers": [],
                "asgi": {"spec_version": "2.4"},
            },
            receive,
            send,
        )

    assert sdk.stream_closed is True


@pytest.mark.anyio
async def test_async_stream_closes_dms_resource_on_client_disconnect():
    class AsyncStream:
        document_id = "doc-1"
        content_type = "application/pdf"
        filename = "contract.pdf"
        size = 3
        checksum = "checksum"
        closed = False

        async def aiter_chunks_closing(self):
            try:
                yield b"pdf"
            finally:
                await self.aclose()

        async def aclose(self):
            self.closed = True

    item = AsyncStream()
    response = _stream_async_document(item, disposition="inline")

    async def receive():
        return {"type": "http.disconnect"}

    async def send(message):
        if message["type"] == "http.response.body":
            raise OSError("client disconnected")

    with pytest.raises(ClientDisconnect):
        await response(
            {
                "type": "http",
                "method": "GET",
                "path": "/documents/doc-1/content/async",
                "headers": [],
                "asgi": {"spec_version": "2.4"},
            },
            receive,
            send,
        )

    assert item.closed is True


@pytest.mark.anyio
async def test_chunk_iterator_closes_on_client_disconnect():
    closed = False

    def chunks():
        nonlocal closed
        try:
            yield b"pdf"
        finally:
            closed = True

    response = _stream_document_chunks(
        chunks(),
        metadata=public_metadata(),
    )

    async def receive():
        return {"type": "http.disconnect"}

    async def send(message):
        if message["type"] == "http.response.body":
            raise OSError("client disconnected")

    with pytest.raises(ClientDisconnect):
        await response(
            {
                "type": "http",
                "method": "GET",
                "path": "/documents/doc-1/chunks",
                "headers": [],
                "asgi": {"spec_version": "2.4"},
            },
            receive,
            send,
        )

    assert closed is True
