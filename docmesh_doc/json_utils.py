from __future__ import annotations

import json


def ensure_json_serializable(value: object) -> object:
    """Validate that a value can be encoded as standard JSON."""
    json.dumps(value, allow_nan=False)
    return value
