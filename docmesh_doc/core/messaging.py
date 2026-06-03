import json
from typing import Any


async def publish_json_event(nats_client: Any, subject: str, payload: dict[str, Any]) -> None:
    event_payload = {
        "event": subject,
        "schema_version": 1,
        **payload,
    }
    await nats_client.publish(subject, json.dumps(event_payload).encode("utf-8"))
