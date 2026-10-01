from collections import Counter
from datetime import datetime

from fastapi import APIRouter, HTTPException

from app.db import load_data, next_id, save_data
from app.schemas.salary_advances import SalaryAdvanceCreate, SalaryAdvanceResponse
from app.services.exports import excel_response, pdf_response


router = APIRouter(prefix="/salary-advances", tags=["salary-advances"])


@router.get("", response_model=list[SalaryAdvanceResponse])
def list_salary_advances() -> list[dict]:
    data = load_data()
    return sorted(data["salary_advances"], key=lambda item: item["id"], reverse=True)


@router.get("/export.xlsx")
def export_salary_advances_excel():
    data = load_data()
    employee_map = {employee["id"]: employee for employee in data["employees"]}
    rows = []
    for item in data["salary_advances"]:
        employee = employee_map.get(item["employee_id"], {})
        rows.append(
            [
                item.get("reference"),
                f"{employee.get('first_name', '')} {employee.get('last_name', '')}".strip(),
                item.get("request_date"),
                item.get("payment_cycle"),
                item.get("amount_approved"),
                item.get("balance_pending"),
                item.get("status"),
            ]
        )
    return excel_response("salary_advances_repository.xlsx", "salary-advances", ["Referencia", "Empleado", "Solicitud", "Ciclo", "Monto", "Saldo", "Estado"], rows)


@router.get("/export.pdf")
def export_salary_advances_pdf():
    data = load_data()
    employee_map = {employee["id"]: employee for employee in data["employees"]}
    rows = []
    for item in data["salary_advances"]:
        employee = employee_map.get(item["employee_id"], {})
        rows.append(
            [
                item.get("reference"),
                f"{employee.get('first_name', '')} {employee.get('last_name', '')}".strip(),
                item.get("request_date"),
                item.get("payment_cycle"),
                item.get("amount_approved"),
                item.get("balance_pending"),
                item.get("status"),
            ]
        )
    return pdf_response("salary_advances_repository.pdf", "Repositorio de Salary Advances", ["Referencia", "Empleado", "Solicitud", "Ciclo", "Monto", "Saldo", "Estado"], rows)


@router.post("", response_model=SalaryAdvanceResponse, status_code=201)
def create_salary_advance(payload: SalaryAdvanceCreate) -> dict:
    data = load_data()
    employee = next((item for item in data["employees"] if item["id"] == payload.employee_id), None)
    if employee is None:
        raise HTTPException(status_code=404, detail="Empleado no encontrado")

    exists = next(
        (
            item
            for item in data["salary_advances"]
            if item["company_id"] == payload.company_id and item["reference"] == payload.reference
        ),
        None,
    )
    if exists is not None:
        raise HTTPException(status_code=409, detail="Ya existe un salary advance con esa referencia")

    advance = payload.model_dump()
    advance["id"] = next_id(data["salary_advances"])
    data["salary_advances"].append(advance)
    save_data(data)
    return advance


@router.get("/reports/created")
def salary_advance_report(group_by: str = "monthly") -> dict:
    data = load_data()
    if group_by not in {"monthly", "biweekly"}:
        raise HTTPException(status_code=400, detail="El reporte solo soporta monthly o biweekly")

    buckets = Counter()
    amount_buckets = Counter()
    cycle_buckets = Counter()

    for advance in data["salary_advances"]:
        request_date = advance.get("request_date")
        if not request_date:
            continue
        dt = datetime.strptime(request_date, "%Y-%m-%d")
        if group_by == "monthly":
            bucket = dt.strftime("%Y-%m")
        else:
            half = "Q1" if dt.day <= 15 else "Q2"
            bucket = f"{dt.strftime('%Y-%m')}-{half}"
        buckets[bucket] += 1
        amount_buckets[bucket] += float(advance.get("amount_approved", 0))
        cycle_buckets[advance.get("payment_cycle", "monthly")] += 1

    rows = [
        {
            "period": key,
            "count": buckets[key],
            "amount_total": round(amount_buckets[key], 2),
        }
        for key in sorted(buckets.keys())
    ]
    return {
        "group_by": group_by,
        "rows": rows,
        "by_payment_cycle": dict(cycle_buckets),
    }


@router.get("/reports/created/export.xlsx")
def export_salary_advance_report_excel(group_by: str = "monthly"):
    report = salary_advance_report(group_by)
    rows = [[item["period"], item["count"], item["amount_total"]] for item in report["rows"]]
    return excel_response("salary_advances_report.xlsx", "advances-report", ["Periodo", "Cantidad", "Monto total"], rows)


@router.get("/reports/created/export.pdf")
def export_salary_advance_report_pdf(group_by: str = "monthly"):
    report = salary_advance_report(group_by)
    rows = [[item["period"], item["count"], item["amount_total"]] for item in report["rows"]]
    return pdf_response("salary_advances_report.pdf", "Reporte de Salary Advances", ["Periodo", "Cantidad", "Monto total"], rows)


@router.get("/{advance_id}", response_model=SalaryAdvanceResponse)
def get_salary_advance(advance_id: int) -> dict:
    data = load_data()
    row = next((item for item in data["salary_advances"] if item["id"] == advance_id), None)
    if row is None:
        raise HTTPException(status_code=404, detail="Salary advance no encontrado")
    return row


@router.delete("/{advance_id}")
def delete_salary_advance(advance_id: int) -> dict:
    data = load_data()
    advance = next((item for item in data["salary_advances"] if item["id"] == advance_id), None)
    if advance is None:
        raise HTTPException(status_code=404, detail="Salary advance no encontrado")

    # Un adelanto descontado total o parcialmente ya forma parte del historial de planilla
    if advance["status"] == "discounted" or advance.get("installments_paid", 0) > 0:
        raise HTTPException(
            status_code=409,
            detail="No se puede eliminar un salary advance ya aplicado en planilla",
        )

    data["salary_advances"] = [item for item in data["salary_advances"] if item["id"] != advance_id]
    save_data(data)
    return {"message": "Salary advance eliminado"}
