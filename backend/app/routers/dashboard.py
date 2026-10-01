from pathlib import Path

from fastapi import APIRouter
from fastapi.responses import FileResponse


router = APIRouter(tags=["dashboard"])
STATIC_DIR = Path(__file__).resolve().parents[1] / "static"


@router.get("/", include_in_schema=False)
def dashboard() -> FileResponse:
    return FileResponse(STATIC_DIR / "index.html")


@router.get("/workspace", include_in_schema=False)
def modular_dashboard() -> FileResponse:
    return FileResponse(STATIC_DIR / "workspace.html")
