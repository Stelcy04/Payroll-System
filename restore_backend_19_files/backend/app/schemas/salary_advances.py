from pydantic import BaseModel, ConfigDict, Field


class SalaryAdvanceCreate(BaseModel):
    company_id: int = Field(default=1, ge=1)
    employee_id: int = Field(ge=1)
    reference: str = Field(min_length=1, max_length=30)
    request_date: str
    approval_date: str | None = None
    delivery_date: str | None = None
    amount_approved: float = Field(gt=0)
    balance_pending: float = Field(gt=0)
    installments_planned: int = Field(default=1, ge=1)
    installments_paid: int = Field(default=0, ge=0)
    status: str = Field(default="requested", max_length=20)
    payment_cycle: str = Field(default="monthly", max_length=20)
    notes: str | None = Field(default=None, max_length=255)


class SalaryAdvanceResponse(SalaryAdvanceCreate):
    balance_pending: float = Field(ge=0)
    id: int
    model_config = ConfigDict(from_attributes=True)
