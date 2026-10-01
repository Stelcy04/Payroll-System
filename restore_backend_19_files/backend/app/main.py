from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles

from app.db import initialize_database
from app.routers import dashboard, employees, payroll_runs, payrolls, periods, salary_advances


app = FastAPI(
    title="Payroll API",
    version="0.1.0",
    description="Backend inicial para sistema de planilla de PYMES",
)


@app.on_event("startup")
def on_startup() -> None:
    initialize_database()


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


app.mount("/static", StaticFiles(directory="app/static"), name="static")
app.include_router(dashboard.router)
app.include_router(employees.router)
app.include_router(periods.router)
app.include_router(salary_advances.router)
app.include_router(payrolls.router)
app.include_router(payroll_runs.router)
