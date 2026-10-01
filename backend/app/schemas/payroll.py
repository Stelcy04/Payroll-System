from pydantic import BaseModel, Field


class PayrollGenerateRequest(BaseModel):
    company_id: int = Field(default=1, ge=1)
    period_id: int = Field(ge=1)


class PayrollEmployeeResult(BaseModel):
    employee_id: int
    employee_name: str
    base_salary: float
    salary_advance_discount: float
    gross_salary: float
    total_deductions: float
    net_salary: float


class PayrollGenerateResponse(BaseModel):
    payroll_run_id: int
    period_id: int
    gross_total: float
    deductions_total: float
    net_total: float
    employees: list[PayrollEmployeeResult]
