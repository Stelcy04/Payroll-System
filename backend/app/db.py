import json
from copy import deepcopy

from app.config import DATA_DIR, DB_PATH


DEFAULT_DATA = {
    "employees": [],
    "payroll_periods": [],
    "salary_advances": [],
    "payroll_runs": [],
    "payroll_run_details": [],
}


def initialize_database() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    if not DB_PATH.exists():
        DB_PATH.write_text(json.dumps(DEFAULT_DATA, indent=2), encoding="utf-8")


def load_data() -> dict:
    initialize_database()
    raw = DB_PATH.read_text(encoding="utf-8").strip()
    if not raw:
        return deepcopy(DEFAULT_DATA)
    data = json.loads(raw)
    for key, value in DEFAULT_DATA.items():
        data.setdefault(key, deepcopy(value))
    return data


def save_data(data: dict) -> None:
    DB_PATH.write_text(json.dumps(data, indent=2), encoding="utf-8")


def next_id(items: list[dict]) -> int:
    if not items:
        return 1
    return max(int(item["id"]) for item in items) + 1
