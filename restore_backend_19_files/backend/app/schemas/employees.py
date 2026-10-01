from pydantic import BaseModel, ConfigDict, Field


class EmployeeCreate(BaseModel):
    company_id: int = Field(default=1, ge=1)
    code: str = Field(min_length=1, max_length=30)
    first_name: str = Field(min_length=1, max_length=100)
    last_name: str = Field(min_length=1, max_length=100)
    identity_document: str | None = Field(default=None, max_length=30)
    birth_date: str | None = None
    hire_date: str | None = None
    email: str | None = Field(default=None, max_length=150)
    phone: str | None = Field(default=None, max_length=30)
    address: str | None = Field(default=None, max_length=255)
    department: str | None = Field(default=None, max_length=100)
    position: str = Field(min_length=1, max_length=100)
    contract_type: str = Field(default="permanent", max_length=30)
    payment_type: str = Field(default="monthly", max_length=20)
    base_salary: float = Field(gt=0)
    active: bool = True
    employment_status: str = Field(default="active", max_length=20)


class EmployeeResponse(EmployeeCreate):
    id: int
    can_delete: bool = False
    has_salary_advances: bool = False
    has_payroll_history: bool = False
    model_config = ConfigDict(from_attributes=True)


class EmployeeBulkCreate(BaseModel):
    company_id: int = Field(default=1, ge=1)
    employees: list[EmployeeCreate] = Field(default_factory=list)
