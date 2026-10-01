from fastapi import APIRouter, HTTPException

from app.db import load_data
from app.services.exports import excel_response, pdf_response


router = APIRouter(prefix="/payroll-runs", tags=["payroll-runs"])


@router.get("")
def list_payroll_runs() -> list[dict]:
    data = load_data()
    period_map = {period["id"]: period for period in data["payroll_periods"]}
    payroll_runs = []
    for item in data["payroll_runs"]:
        period = period_map.get(item["period_id"], {})
        details_count = sum(1 for detail in data["payroll_run_details"] if detail["payroll_run_id"] == item["id"])
        payroll_runs.append(
            {
                **item,
                "period_name": period.get("name", f"Periodo {item['period_id']}"),
                "period_status": period.get("status"),
                "payment_date": period.get("payment_date"),
                "employees_count": details_count,
            }
        )
    return sorted(payroll_runs, key=lambda item: item["id"], reverse=True)


@router.get("/export.xlsx")
def export_payroll_runs_excel():
    rows = [[item["id"], item["period_name"], item["payment_date"], item["employees_count"], item["gross_total"], item["deductions_total"], item["net_total"], item["status"]] for item in list_payroll_runs()]
    return excel_response("payroll_runs_repository.xlsx", "payroll-runs", ["Planilla", "Periodo", "Pago", "Empleados", "Bruto", "Deducciones", "Neto", "Estado"], rows)


@router.get("/export.pdf")
def export_payroll_runs_pdf():
    rows = [[item["id"], item["period_name"], item["payment_date"], item["employees_count"], item["gross_total"], item["deductions_total"], item["net_total"], item["status"]] for item in list_payroll_runs()]
    return pdf_response("payroll_runs_repository.pdf", "Repositorio de Planillas", ["Planilla", "Periodo", "Pago", "Empleados", "Bruto", "Deducciones", "Neto", "Estado"], rows)


@router.get("/{payroll_run_id}")
def get_payroll_run(payroll_run_id: int) -> dict:
    data = load_data()
    payroll_run = next((item for item in data["payroll_runs"] if item["id"] == payroll_run_id), None)
    if payroll_run is None:
        raise HTTPException(status_code=404, detail="Planilla no encontrada")

    period = next((item for item in data["payroll_periods"] if item["id"] == payroll_run["period_id"]), {})
    employee_map = {employee["id"]: employee for employee in data["employees"]}
    details = []
    for item in data["payroll_run_details"]:
        if item["payroll_run_id"] != payroll_run_id:
            continue

        employee = employee_map.get(item["employee_id"], {})
        details.append(
            {
                **item,
                "employee_code": employee.get("code", f"EMP-{item['employee_id']}"),
                "employee_name": f"{employee.get('first_name', '')} {employee.get('last_name', '')}".strip(),
            }
        )

    return {
        **payroll_run,
        "period_name": period.get("name", f"Periodo {payroll_run['period_id']}"),
        "period_status": period.get("status"),
        "period_start_date": period.get("start_date"),
        "period_end_date": period.get("end_date"),
        "payment_date": period.get("payment_date"),
        "employees_count": len(details),
        "details": details,
    }
