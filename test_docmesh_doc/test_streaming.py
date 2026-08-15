from __future__ import annotations

import pytest
from starlette.requests import ClientDisconnect

from docmesh_doc.router import _stream_document
from test_docmesh_doc.support import FakeSDK


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
