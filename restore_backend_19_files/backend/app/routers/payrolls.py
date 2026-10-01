from fastapi import APIRouter

from app.schemas.payroll import PayrollGenerateRequest, PayrollGenerateResponse
from app.services.payroll import generate_payroll


router = APIRouter(prefix="/payrolls", tags=["payrolls"])


@router.post("/generate", response_model=PayrollGenerateResponse, status_code=201)
def generate_payroll_endpoint(payload: PayrollGenerateRequest) -> dict:
    return generate_payroll(company_id=payload.company_id, period_id=payload.period_id)
