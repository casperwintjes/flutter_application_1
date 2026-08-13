import json
import os
from pathlib import Path

from .const import DATA_FILE


def ensure_storage_file(path: str = DATA_FILE) -> Path:
    storage_path = Path(path)
    if not storage_path.exists():
        storage_path.write_text(json.dumps({"version": 1, "recipes": [], "shoppingLists": []}), encoding="utf-8")
    return storage_path


def read_storage(path: str = DATA_FILE) -> dict:
    storage_path = ensure_storage_file(path)
    with storage_path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def write_storage(payload: dict, path: str = DATA_FILE) -> dict:
    storage_path = ensure_storage_file(path)
    with storage_path.open("w", encoding="utf-8") as handle:
        json.dump(payload, handle, indent=2)
    return payload
