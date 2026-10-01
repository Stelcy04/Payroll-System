from fastapi import HTTPException

from app.db import load_data, next_id, save_data


def generate_payroll(company_id: int, period_id: int) -> dict:
    data = load_data()
    period = next(
        (
            item
            for item in data["payroll_periods"]
            if item["id"] == period_id and item["company_id"] == company_id
        ),
        None,
    )
    if period is None:
        raise HTTPException(status_code=404, detail="Periodo no encontrado para la empresa")

    employees = [
        item
        for item in data["employees"]
        if item["company_id"] == company_id and item["active"]
    ]
    if not employees:
        raise HTTPException(status_code=400, detail="No hay empleados activos para generar la planilla")

    existing_run = next(
        (item for item in data["payroll_runs"] if item["period_id"] == period_id),
        None,
    )
    if existing_run is not None:
        raise HTTPException(status_code=409, detail="La planilla de este periodo ya fue generada")

    # B2: solo se genera planilla sobre periodos abiertos
    if period.get("status") != "open":
        raise HTTPException(
            status_code=409,
            detail=f"Solo se puede generar planilla para un periodo abierto (estado actual: {period.get('status')})",
        )

    employee_results = []
    gross_total = 0.0
    deductions_total = 0.0
    net_total = 0.0

    for employee in employees:
        employee_advances = sorted(
            (
                item
                for item in data["salary_advances"]
                if item["company_id"] == company_id
                and item["employee_id"] == employee["id"]
                and item["status"] in {"approved", "delivered"}
            ),
            key=lambda item: (item.get("request_date") or "", item["id"]),
        )
        base_salary = float(employee["base_salary"])
        gross_salary = base_salary

        # B1: el descuento nunca supera el bruto, asi el neto no puede ser negativo.
        # Los adelantos se aplican del mas antiguo al mas reciente; lo que no alcanza
        # a descontarse queda como saldo pendiente para la siguiente planilla.
        available = gross_salary
        advance_applications = []
        for advance in employee_advances:
            pending = float(advance["balance_pending"])
            applied = min(pending, available)
            if applied <= 0:
                break
            advance_applications.append((advance, applied))
            available -= applied

        salary_advance_discount = sum(applied for _, applied in advance_applications)
        total_deductions = salary_advance_discount
        net_salary = gross_salary - total_deductions

        employee_results.append(
            {
                "employee_id": employee["id"],
                "employee_name": f"{employee['first_name']} {employee['last_name']}",
                "base_salary": round(base_salary, 2),
                "salary_advance_discount": round(salary_advance_discount, 2),
                "gross_salary": round(gross_salary, 2),
                "total_deductions": round(total_deductions, 2),
                "net_salary": round(net_salary, 2),
            }
        )
        gross_total += gross_salary
        deductions_total += total_deductions
        net_total += net_salary

        for advance, applied in advance_applications:
            remaining = round(float(advance["balance_pending"]) - applied, 2)
            advance["balance_pending"] = remaining
            if remaining <= 0:
                advance["balance_pending"] = 0
                advance["installments_paid"] = advance["installments_planned"]
                advance["status"] = "discounted"
            else:
                advance["installments_paid"] = min(
                    advance.get("installments_paid", 0) + 1,
                    advance["installments_planned"],
                )

    payroll_run_id = next_id(data["payroll_runs"])
    data["payroll_runs"].append(
        {
            "id": payroll_run_id,
            "company_id": company_id,
            "period_id": period_id,
            "gross_total": round(gross_total, 2),
            "deductions_total": round(deductions_total, 2),
            "net_total": round(net_total, 2),
            "status": "generated",
        }
    )

    for result in employee_results:
        data["payroll_run_details"].append(
            {
                "id": next_id(data["payroll_run_details"]),
                "payroll_run_id": payroll_run_id,
                "employee_id": result["employee_id"],
                "base_salary": result["base_salary"],
                "salary_advance_discount": result["salary_advance_discount"],
                "other_income": 0,
                "gross_salary": result["gross_salary"],
                "total_deductions": result["total_deductions"],
                "net_salary": result["net_salary"],
            }
        )

    period["status"] = "calculated"
    save_data(data)

    return {
        "payroll_run_id": payroll_run_id,
        "period_id": period_id,
        "gross_total": round(gross_total, 2),
        "deductions_total": round(deductions_total, 2),
        "net_total": round(net_total, 2),
        "employees": employee_results,
    }
