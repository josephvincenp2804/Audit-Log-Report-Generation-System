from datetime import datetime, timezone, timedelta
from typing import Optional, List, Tuple, Dict, Any
from sqlalchemy.orm import Session  # type: ignore
from sqlalchemy import func, desc, asc, cast, Date  # type: ignore

try:
    from .models import AuditLog, Employee, Department, User, Loan
    from .services.audit_service import AuditService
except (ImportError, ValueError):
    from app.models import AuditLog, Employee, Department, User, Loan
    from app.services.audit_service import AuditService


def parse_date(date_str: Optional[str]) -> Optional[datetime]:
    """Helper to parse ISO or YYYY-MM-DD date string."""
    if not date_str:
        return None
    try:
        # Check standard date YYYY-MM-DD
        if len(date_str) == 10:
            return datetime.strptime(date_str, "%Y-%m-%d")
        # Check ISO format
        return datetime.fromisoformat(date_str.replace("Z", "+00:00"))
    except Exception:
        return None


def get_audit_logs(
    db: Session,
    username: Optional[str] = None,
    action_type: Optional[str] = None,
    table_name: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    sort_by: str = "timestamp",
    sort_order: str = "desc",
    skip: int = 0,
    limit: int = 15
) -> Tuple[int, List[AuditLog]]:
    """
    Retrieves filtered and paginated audit logs.
    """
    query = db.query(AuditLog)

    if username and username.strip():
        query = query.filter(AuditLog.username.ilike(f"%{username.strip()}%"))

    if action_type and action_type.strip().upper() != "ALL":
        query = query.filter(AuditLog.action_type == action_type.strip().upper())

    if table_name and table_name.strip().upper() != "ALL":
        query = query.filter(AuditLog.table_name == table_name.strip())

    start_dt = parse_date(start_date)
    if start_dt:
        start_dt = start_dt.replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(AuditLog.timestamp >= start_dt)

    end_dt = parse_date(end_date)
    if end_dt:
        end_dt = end_dt.replace(hour=23, minute=59, second=59, microsecond=999999)
        query = query.filter(AuditLog.timestamp <= end_dt)

    total_count = query.count()

    # Sorting
    sort_column = getattr(AuditLog, sort_by, AuditLog.timestamp)
    if sort_order.lower() == "asc":
        query = query.order_by(asc(sort_column))
    else:
        query = query.order_by(desc(sort_column))

    items = query.offset(skip).limit(limit).all()
    return total_count, items


def get_all_filtered_audit_logs(
    db: Session,
    username: Optional[str] = None,
    action_type: Optional[str] = None,
    table_name: Optional[str] = None,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None
) -> List[AuditLog]:
    """
    Returns all audit logs matching filter parameters (used for report generation).
    """
    query = db.query(AuditLog)

    if username and username.strip():
        query = query.filter(AuditLog.username.ilike(f"%{username.strip()}%"))

    if action_type and action_type.strip().upper() != "ALL":
        query = query.filter(AuditLog.action_type == action_type.strip().upper())

    if table_name and table_name.strip().upper() != "ALL":
        query = query.filter(AuditLog.table_name == table_name.strip())

    start_dt = parse_date(start_date)
    if start_dt:
        start_dt = start_dt.replace(hour=0, minute=0, second=0, microsecond=0)
        query = query.filter(AuditLog.timestamp >= start_dt)

    end_dt = parse_date(end_date)
    if end_dt:
        end_dt = end_dt.replace(hour=23, minute=59, second=59, microsecond=999999)
        query = query.filter(AuditLog.timestamp <= end_dt)

    return query.order_by(desc(AuditLog.timestamp)).all()


def get_audit_log_by_id(db: Session, audit_id: int) -> Optional[AuditLog]:
    return db.query(AuditLog).filter(AuditLog.audit_id == audit_id).first()


def get_dashboard_summary(db: Session) -> Dict[str, Any]:
    """
    Aggregates dashboard statistics from audit log records.
    """
    total_activities = db.query(AuditLog).count()
    insert_count = db.query(AuditLog).filter(AuditLog.action_type == "INSERT").count()
    update_count = db.query(AuditLog).filter(AuditLog.action_type == "UPDATE").count()
    delete_count = db.query(AuditLog).filter(AuditLog.action_type == "DELETE").count()

    recent_activities = db.query(AuditLog).order_by(desc(AuditLog.timestamp)).limit(10).all()

    # Breakdown by Action
    activity_by_action = {
        "INSERT": insert_count,
        "UPDATE": update_count,
        "DELETE": delete_count
    }

    # Breakdown by Table
    table_rows = db.query(AuditLog.table_name, func.count(AuditLog.audit_id)).group_by(AuditLog.table_name).all()
    activity_by_table = {table: count for table, count in table_rows}

    # Breakdown by User (Top 5)
    user_rows = db.query(AuditLog.username, func.count(AuditLog.audit_id)).group_by(AuditLog.username).order_by(desc(func.count(AuditLog.audit_id))).limit(5).all()
    activity_by_user = {user: count for user, count in user_rows}

    # Daily Trends for the past 14 days
    today = datetime.now(timezone.utc).date()
    start_period = today - timedelta(days=13)
    
    # Query logs from the last 14 days
    logs_period = db.query(AuditLog).filter(AuditLog.timestamp >= datetime(start_period.year, start_period.month, start_period.day)).all()
    
    # Bucket by date
    daily_buckets: Dict[str, Dict[str, int]] = {}
    for i in range(14):
        d_str = (start_period + timedelta(days=i)).isoformat()
        daily_buckets[d_str] = {"INSERT": 0, "UPDATE": 0, "DELETE": 0, "TOTAL": 0}

    for log in logs_period:
        if log.timestamp:
            d_str = log.timestamp.date().isoformat()
            if d_str in daily_buckets:
                action = log.action_type.upper()
                if action in daily_buckets[d_str]:
                    daily_buckets[d_str][action] += 1
                daily_buckets[d_str]["TOTAL"] += 1

    daily_trends = [
        {
            "date": d,
            "insert_count": counts["INSERT"],
            "update_count": counts["UPDATE"],
            "delete_count": counts["DELETE"],
            "total_count": counts["TOTAL"]
        }
        for d, counts in sorted(daily_buckets.items())
    ]

    summary_text = (
        f"Audit repository contains {total_activities} logged events. "
        f"Operations distribution: {insert_count} inserts, {update_count} updates, and {delete_count} deletions across "
        f"{len(activity_by_table)} monitored tables by {len(activity_by_user)} active system users."
    )

    return {
        "total_activities": total_activities,
        "insert_count": insert_count,
        "update_count": update_count,
        "delete_count": delete_count,
        "recent_activities": recent_activities,
        "activity_by_action": activity_by_action,
        "activity_by_table": activity_by_table,
        "activity_by_user": activity_by_user,
        "daily_trends": daily_trends,
        "audit_activity_summary": summary_text
    }


# --- Simulation / Atomic DB Operations with Audit Trail ---

def insert_employee(
    db: Session,
    employee_dict: Dict[str, Any],
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Employee, AuditLog]:
    """
    Executes actual Employee INSERT and records an audit log atomically in one transaction.
    """
    # 1. Create employee model
    new_employee = Employee(
        first_name=employee_dict["first_name"],
        last_name=employee_dict["last_name"],
        email=employee_dict["email"],
        phone=employee_dict.get("phone"),
        department_id=employee_dict["department_id"],
        job_title=employee_dict["job_title"],
        salary=employee_dict["salary"],
        status=employee_dict.get("status", "Active")
    )
    db.add(new_employee)
    db.flush()  # Populate employee id

    # 2. Record audit log
    emp_snapshot = new_employee.to_dict()
    audit_entry = AuditService.log_activity(
        db=db,
        action_type="INSERT",
        table_name="employees",
        record_id=str(new_employee.id),
        username=acting_username,
        previous_value=None,
        new_value=emp_snapshot,
        ip_address=acting_ip
    )

    # 3. Commit transaction
    db.commit()
    db.refresh(new_employee)
    db.refresh(audit_entry)
    return new_employee, audit_entry


def update_employee(
    db: Session,
    employee_id: int,
    update_data: Dict[str, Any],
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Optional[Employee], Optional[AuditLog]]:
    """
    Executes actual Employee UPDATE and records previous and new values in audit log atomically.
    """
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        return None, None

    # 1. Capture snapshot before update
    prev_snapshot = employee.to_dict()

    # 2. Update fields
    for field, value in update_data.items():
        if value is not None and hasattr(employee, field) and field not in ["id", "created_at", "updated_at"]:
            setattr(employee, field, value)

    employee.updated_at = datetime.now(timezone.utc)
    db.flush()

    # 3. Capture snapshot after update
    new_snapshot = employee.to_dict()

    # 4. Record audit log
    audit_entry = AuditService.log_activity(
        db=db,
        action_type="UPDATE",
        table_name="employees",
        record_id=str(employee.id),
        username=acting_username,
        previous_value=prev_snapshot,
        new_value=new_snapshot,
        ip_address=acting_ip
    )

    # 5. Commit transaction
    db.commit()
    db.refresh(employee)
    db.refresh(audit_entry)
    return employee, audit_entry


def delete_employee(
    db: Session,
    employee_id: int,
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Optional[Dict[str, Any]], Optional[AuditLog]]:
    """
    Executes actual Employee DELETE and records the deleted record in audit log atomically.
    """
    employee = db.query(Employee).filter(Employee.id == employee_id).first()
    if not employee:
        return None, None

    # 1. Capture snapshot before deletion
    prev_snapshot = employee.to_dict()

    # 2. Delete employee record
    db.delete(employee)
    db.flush()

    # 3. Record audit log
    audit_entry = AuditService.log_activity(
        db=db,
        action_type="DELETE",
        table_name="employees",
        record_id=str(employee_id),
        username=acting_username,
        previous_value=prev_snapshot,
        new_value=None,
        ip_address=acting_ip
    )

    # 4. Commit transaction
    db.commit()
    db.refresh(audit_entry)
    return prev_snapshot, audit_entry


# --- Helper retrieval functions ---
def get_employees(db: Session) -> List[Employee]:
    return db.query(Employee).order_by(Employee.id.desc()).all()

def get_departments(db: Session) -> List[Department]:
    return db.query(Department).order_by(Department.name.asc()).all()

def get_users(db: Session) -> List[User]:
    return db.query(User).order_by(User.username.asc()).all()

# --- Loan Simulation / Atomic DB Operations (SI Capital & Financial Services) ---

def insert_loan(
    db: Session,
    loan_dict: Dict[str, Any],
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Loan, AuditLog]:
    """
    Executes actual Loan INSERT and records an audit log atomically in one transaction.
    """
    new_loan = Loan(
        loan_number=loan_dict["loan_number"],
        loan_type=loan_dict["loan_type"],
        borrower_name=loan_dict["borrower_name"],
        principal_amount=loan_dict["principal_amount"],
        interest_rate=loan_dict["interest_rate"],
        tenure_period=loan_dict["tenure_period"],
        doc_fee=loan_dict.get("doc_fee", 0.0),
        status=loan_dict.get("status", "Active")
    )
    db.add(new_loan)
    db.flush()

    loan_snapshot = new_loan.to_dict()
    audit_entry = AuditService.log_activity(
        db=db,
        action_type="INSERT",
        table_name="loans",
        record_id=str(new_loan.id),
        username=acting_username,
        previous_value=None,
        new_value=loan_snapshot,
        ip_address=acting_ip
    )

    db.commit()
    db.refresh(new_loan)
    db.refresh(audit_entry)
    return new_loan, audit_entry


def update_loan(
    db: Session,
    loan_id: int,
    update_data: Dict[str, Any],
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Optional[Loan], Optional[AuditLog]]:
    """
    Executes actual Loan UPDATE and records previous and new values in audit log atomically.
    """
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        return None, None

    prev_snapshot = loan.to_dict()

    for field, value in update_data.items():
        if value is not None and hasattr(loan, field) and field not in ["id", "created_at", "updated_at"]:
            setattr(loan, field, value)

    loan.updated_at = datetime.now(timezone.utc)
    db.flush()

    new_snapshot = loan.to_dict()

    audit_entry = AuditService.log_activity(
        db=db,
        action_type="UPDATE",
        table_name="loans",
        record_id=str(loan.id),
        username=acting_username,
        previous_value=prev_snapshot,
        new_value=new_snapshot,
        ip_address=acting_ip
    )

    db.commit()
    db.refresh(loan)
    db.refresh(audit_entry)
    return loan, audit_entry


def delete_loan(
    db: Session,
    loan_id: int,
    acting_username: str = "admin",
    acting_ip: str = "127.0.0.1"
) -> Tuple[Optional[Dict[str, Any]], Optional[AuditLog]]:
    """
    Executes actual Loan DELETE and records the deleted record in audit log atomically.
    """
    loan = db.query(Loan).filter(Loan.id == loan_id).first()
    if not loan:
        return None, None

    prev_snapshot = loan.to_dict()
    db.delete(loan)
    db.flush()

    audit_entry = AuditService.log_activity(
        db=db,
        action_type="DELETE",
        table_name="loans",
        record_id=str(loan_id),
        username=acting_username,
        previous_value=prev_snapshot,
        new_value=None,
        ip_address=acting_ip
    )

    db.commit()
    db.refresh(audit_entry)
    return prev_snapshot, audit_entry


def get_loans(db: Session) -> List[Loan]:
    return db.query(Loan).order_by(Loan.id.desc()).all()


