from pydantic import BaseModel, EmailStr, Field, ConfigDict
from typing import Optional, List, Dict, Any
from datetime import datetime

# --- User Schemas ---
class UserBase(BaseModel):
    username: str
    email: EmailStr
    full_name: str
    role: str = "Analyst"

class UserCreate(UserBase):
    pass

class UserResponse(UserBase):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --- Department Schemas ---
class DepartmentBase(BaseModel):
    name: str
    code: str
    description: Optional[str] = None

class DepartmentResponse(DepartmentBase):
    id: int
    created_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --- Employee Schemas ---
class EmployeeBase(BaseModel):
    first_name: str = Field(..., min_length=1, max_length=60)
    last_name: str = Field(..., min_length=1, max_length=60)
    email: EmailStr
    phone: Optional[str] = None
    department_id: int
    job_title: str = Field(..., min_length=1, max_length=100)
    salary: float = Field(..., gt=0)
    status: str = Field("Active", pattern="^(Active|On Leave|Terminated)$")

class EmployeeCreate(EmployeeBase):
    acting_username: Optional[str] = "admin"
    acting_ip: Optional[str] = "192.168.1.100"

class EmployeeUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone: Optional[str] = None
    department_id: Optional[int] = None
    job_title: Optional[str] = None
    salary: Optional[float] = None
    status: Optional[str] = None
    acting_username: Optional[str] = "admin"
    acting_ip: Optional[str] = "192.168.1.100"

class EmployeeResponse(EmployeeBase):
    id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

# --- Audit Log Schemas ---
class AuditLogResponse(BaseModel):
    audit_id: int
    user_id: Optional[int] = None
    username: str
    action_type: str
    table_name: str
    record_id: str
    previous_value: Optional[str] = None
    new_value: Optional[str] = None
    ip_address: Optional[str] = None
    timestamp: datetime
    model_config = ConfigDict(from_attributes=True)

class AuditLogDetailResponse(AuditLogResponse):
    previous_value_parsed: Optional[Any] = None
    new_value_parsed: Optional[Any] = None

class PaginatedAuditLogsResponse(BaseModel):
    items: List[AuditLogResponse]
    total: int
    page: int
    page_size: int
    total_pages: int

# --- Dashboard Schemas ---
class DailyTrendItem(BaseModel):
    date: str
    insert_count: int
    update_count: int
    delete_count: int
    total_count: int

class DashboardSummaryResponse(BaseModel):
    total_activities: int
    insert_count: int
    update_count: int
    delete_count: int
    recent_activities: List[AuditLogResponse]
    activity_by_action: Dict[str, int]
    activity_by_table: Dict[str, int]
    activity_by_user: Dict[str, int]
    daily_trends: List[DailyTrendItem]
    audit_activity_summary: str

# --- Report Schemas ---
class ReportFilterParams(BaseModel):
    start_date: Optional[str] = None
    end_date: Optional[str] = None
    action_type: Optional[str] = None
    username: Optional[str] = None

class ReportGenerateResponse(BaseModel):
    total_records: int
    insert_count: int
    update_count: int
    delete_count: int
    applied_filters: Dict[str, Any]
    generated_at: datetime
    records: List[AuditLogResponse]

# --- Simulation Result Schemas ---
class SimulationResult(BaseModel):
    success: bool
    message: str
    action_type: str
    audit_log: AuditLogResponse
    employee: Optional[Dict[str, Any]] = None
    loan: Optional[Dict[str, Any]] = None

# --- Loan Schemas (SI Capital & Financial Services) ---
class LoanBase(BaseModel):
    loan_number: str
    loan_type: str = Field(..., pattern="^(Daily Loan|Weekly Loan|Personal Loan|Vehicle Loan|Gold Loan)$")
    borrower_name: str
    principal_amount: float = Field(..., gt=0)
    interest_rate: float = Field(..., ge=0)
    tenure_period: str
    doc_fee: float = Field(0.0, ge=0)
    status: str = Field("Active", pattern="^(Active|Disbursed|Closed|Overdue)$")

class LoanCreate(LoanBase):
    acting_username: Optional[str] = "admin"
    acting_ip: Optional[str] = "192.168.1.100"

class LoanUpdate(BaseModel):
    borrower_name: Optional[str] = None
    principal_amount: Optional[float] = None
    interest_rate: Optional[float] = None
    tenure_period: Optional[str] = None
    doc_fee: Optional[float] = None
    status: Optional[str] = None
    acting_username: Optional[str] = "admin"
    acting_ip: Optional[str] = "192.168.1.100"

class LoanResponse(LoanBase):
    id: int
    created_at: datetime
    updated_at: datetime
    model_config = ConfigDict(from_attributes=True)

