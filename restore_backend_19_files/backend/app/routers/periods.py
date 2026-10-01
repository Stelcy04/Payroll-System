from fastapi import APIRouter, HTTPException

from app.db import load_data, next_id, save_data
from app.schemas.periods import PayrollPeriodCreate, PayrollPeriodResponse
from app.services.exports import excel_response, pdf_response


router = APIRouter(prefix="/periods", tags=["periods"])


@router.get("", response_model=list[PayrollPeriodResponse])
def list_periods() -> list[dict]:
    data = load_data()
    return sorted(data["payroll_periods"], key=lambda item: item["id"], reverse=True)


@router.get("/export.xlsx")
def export_periods_excel():
    data = load_data()
    rows = [[item.get("name"), item.get("start_date"), item.get("end_date"), item.get("payment_date"), item.get("frequency"), item.get("status")] for item in data["payroll_periods"]]
    return excel_response("periods_repository.xlsx", "periods", ["Periodo", "Inicio", "Fin", "Pago", "Frecuencia", "Estado"], rows)


@router.get("/export.pdf")
def export_periods_pdf():
    data = load_data()
    rows = [[item.get("name"), item.get("start_date"), item.get("end_date"), item.get("payment_date"), item.get("frequency"), item.get("status")] for item in data["payroll_periods"]]
    return pdf_response("periods_repository.pdf", "Repositorio de Periodos", ["Periodo", "Inicio", "Fin", "Pago", "Frecuencia", "Estado"], rows)


@router.post("", response_model=PayrollPeriodResponse, status_code=201)
def create_period(payload: PayrollPeriodCreate) -> dict:
    data = load_data()
    period = payload.model_dump()
    period["id"] = next_id(data["payroll_periods"])
    data["payroll_periods"].append(period)
    save_data(data)
    return period


@router.get("/repository")
def periods_repository() -> dict:
    data = load_data()
    open_periods = []
    closed_periods = []
    future_periods = []

    for period in sorted(data["payroll_periods"], key=lambda item: item["id"], reverse=True):
        if period["status"] in {"closed", "calculated"}:
            closed_periods.append(period)
        elif period["status"] == "future":
            future_periods.append(period)
        else:
            open_periods.append(period)

    return {
        "summary": {
            "open": len(open_periods),
            "closed": len(closed_periods),
            "future": len(future_periods),
        },
        "open": open_periods,
        "closed": closed_periods,
        "future": future_periods,
    }


@router.get("/{period_id}", response_model=PayrollPeriodResponse)
def get_period(period_id: int) -> dict:
    data = load_data()
    row = next((item for item in data["payroll_periods"] if item["id"] == period_id), None)
    if row is None:
        raise HTTPException(status_code=404, detail="Periodo no encontrado")
    return row
