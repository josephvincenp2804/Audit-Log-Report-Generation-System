from typing import List, Dict, Any, Optional
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

try:
    from ..database import get_db
    from ..schemas import (
        EmployeeCreate,
        EmployeeUpdate,
        EmployeeResponse,
        DepartmentResponse,
        UserResponse,
        SimulationResult,
        LoanCreate,
        LoanUpdate,
        LoanResponse
    )
    from ..models import Department
    from .. import crud
except (ImportError, ValueError):
    from app.database import get_db
    from app.schemas import (
        EmployeeCreate,
        EmployeeUpdate,
        EmployeeResponse,
        DepartmentResponse,
        UserResponse,
        SimulationResult,
        LoanCreate,
        LoanUpdate,
        LoanResponse
    )
    from app.models import Department
    import app.crud as crud

router = APIRouter(prefix="/api/simulation", tags=["Database Simulation"])

def get_client_ip(request: Request, fallback_ip: Optional[str] = None) -> str:
    """Extract client IP from request headers or socket."""
    if fallback_ip:
        return fallback_ip
    client_host = request.client.host if request.client else "127.0.0.1"
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return client_host

@router.post("/insert", response_model=SimulationResult, status_code=status.HTTP_201_CREATED)
def simulate_insert_employee(
    payload: EmployeeCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Simulate actual database employee insertion.
    Uses an atomic SQLAlchemy transaction to insert employee and record audit trail log.
    """
    # Validate department exists
    dept = db.query(Department).filter(Department.id == payload.department_id).first()
    if not dept:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Department with ID {payload.department_id} does not exist."
        )

    ip = get_client_ip(request, payload.acting_ip)
    emp_dict = payload.model_dump(exclude={"acting_username", "acting_ip"})

    try:
        new_emp, audit = crud.insert_employee(
            db=db,
            employee_dict=emp_dict,
            acting_username=payload.acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database transaction failed: {str(e)}"
        )

    return {
        "success": True,
        "message": f"Successfully inserted employee {new_emp.first_name} {new_emp.last_name} and recorded audit log.",
        "action_type": "INSERT",
        "audit_log": audit,
        "employee": new_emp.to_dict()
    }

@router.put("/update/{employee_id}", response_model=SimulationResult)
def simulate_update_employee(
    employee_id: int,
    payload: EmployeeUpdate,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Simulate actual database employee update.
    Captures previous value snapshot, applies changes, captures new value snapshot,
    and commits both operation and audit log atomically.
    """
    if payload.department_id:
        dept = db.query(Department).filter(Department.id == payload.department_id).first()
        if not dept:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Department with ID {payload.department_id} does not exist."
            )

    ip = get_client_ip(request, payload.acting_ip)
    update_data = payload.model_dump(exclude={"acting_username", "acting_ip"}, exclude_unset=True)

    try:
        updated_emp, audit = crud.update_employee(
            db=db,
            employee_id=employee_id,
            update_data=update_data,
            acting_username=payload.acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database update transaction failed: {str(e)}"
        )

    if not updated_emp:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Employee with ID {employee_id} not found."
        )

    return {
        "success": True,
        "message": f"Successfully updated employee #{employee_id} and generated UPDATE audit log.",
        "action_type": "UPDATE",
        "audit_log": audit,
        "employee": updated_emp.to_dict()
    }

@router.delete("/delete/{employee_id}", response_model=SimulationResult)
def simulate_delete_employee(
    employee_id: int,
    request: Request,
    acting_username: Optional[str] = "admin",
    acting_ip: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Simulate actual database employee deletion.
    Captures previous state in audit trail and removes employee record within atomic transaction.
    """
    ip = get_client_ip(request, acting_ip)

    try:
        deleted_emp_snapshot, audit = crud.delete_employee(
            db=db,
            employee_id=employee_id,
            acting_username=acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Database deletion transaction failed: {str(e)}"
        )

    if not deleted_emp_snapshot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Employee with ID {employee_id} not found."
        )

    return {
        "success": True,
        "message": f"Successfully deleted employee #{employee_id} and recorded DELETE audit log.",
        "action_type": "DELETE",
        "audit_log": audit,
        "employee": deleted_emp_snapshot
    }

@router.get("/employees", response_model=List[Dict[str, Any]])
def list_simulation_employees(db: Session = Depends(get_db)):
    """List current employees in the database for simulation testing."""
    employees = crud.get_employees(db)
    return [e.to_dict() for e in employees]

@router.get("/departments", response_model=List[Dict[str, Any]])
def list_simulation_departments(db: Session = Depends(get_db)):
    """List available departments for simulation assignment."""
    depts = crud.get_departments(db)
    return [d.to_dict() for d in depts]

@router.get("/users", response_model=List[Dict[str, Any]])
def list_simulation_users(db: Session = Depends(get_db)):
    """List users for audit attribution."""
    users = crud.get_users(db)
    return [u.to_dict() for u in users]

# --- Loan Simulation Endpoints (SI Capital & Financial Services) ---

@router.post("/loans/insert", response_model=SimulationResult, status_code=status.HTTP_201_CREATED)
def simulate_insert_loan(
    payload: LoanCreate,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Simulate actual loan disbursement & registration for SI Capital & Financial Services.
    Atomically creates loan record and logs an immutable INSERT audit entry.
    """
    ip = get_client_ip(request, payload.acting_ip)
    loan_dict = payload.model_dump(exclude={"acting_username", "acting_ip"})

    try:
        new_loan, audit = crud.insert_loan(
            db=db,
            loan_dict=loan_dict,
            acting_username=payload.acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Loan creation transaction failed: {str(e)}"
        )

    return {
        "success": True,
        "message": f"Successfully disbursed {new_loan.loan_type} #{new_loan.loan_number} for {new_loan.borrower_name} and recorded audit trail.",
        "action_type": "INSERT",
        "audit_log": audit,
        "loan": new_loan.to_dict()
    }

@router.put("/loans/update/{loan_id}", response_model=SimulationResult)
def simulate_update_loan(
    loan_id: int,
    payload: LoanUpdate,
    request: Request,
    db: Session = Depends(get_db)
):
    """
    Simulate loan record updates (e.g. status changes, repayments, interest rates).
    Captures previous and new states in the audit log atomically.
    """
    ip = get_client_ip(request, payload.acting_ip)
    update_data = payload.model_dump(exclude={"acting_username", "acting_ip"}, exclude_unset=True)

    try:
        updated_loan, audit = crud.update_loan(
            db=db,
            loan_id=loan_id,
            update_data=update_data,
            acting_username=payload.acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Loan update transaction failed: {str(e)}"
        )

    if not updated_loan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Loan with ID {loan_id} not found."
        )

    return {
        "success": True,
        "message": f"Successfully updated loan #{loan_id} and recorded UPDATE audit log.",
        "action_type": "UPDATE",
        "audit_log": audit,
        "loan": updated_loan.to_dict()
    }

@router.delete("/loans/delete/{loan_id}", response_model=SimulationResult)
def simulate_delete_loan(
    loan_id: int,
    request: Request,
    acting_username: Optional[str] = "admin",
    acting_ip: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """
    Simulate loan closure / write-off with prior state preservation in audit log.
    """
    ip = get_client_ip(request, acting_ip)

    try:
        deleted_snapshot, audit = crud.delete_loan(
            db=db,
            loan_id=loan_id,
            acting_username=acting_username or "admin",
            acting_ip=ip
        )
    except Exception as e:
        db.rollback()
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Loan deletion transaction failed: {str(e)}"
        )

    if not deleted_snapshot:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Loan with ID {loan_id} not found."
        )

    return {
        "success": True,
        "message": f"Successfully removed loan #{loan_id} and logged DELETE audit entry with prior state.",
        "action_type": "DELETE",
        "audit_log": audit,
        "loan": deleted_snapshot
    }

@router.get("/loans", response_model=List[Dict[str, Any]])
def list_simulation_loans(db: Session = Depends(get_db)):
    """List current loans for simulation."""
    loans = crud.get_loans(db)
    return [l.to_dict() for l in loans]


