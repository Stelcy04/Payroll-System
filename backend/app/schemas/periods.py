from pydantic import BaseModel, ConfigDict, Field


class PayrollPeriodCreate(BaseModel):
    company_id: int = Field(default=1, ge=1)
    name: str = Field(min_length=1, max_length=100)
    start_date: str
    end_date: str
    payment_date: str
    frequency: str = Field(default="biweekly", max_length=20)
    status: str = Field(default="open", max_length=20)
    notes: str | None = Field(default=None, max_length=255)


class PayrollPeriodResponse(PayrollPeriodCreate):
    id: int
    model_config = ConfigDict(from_attributes=True)
