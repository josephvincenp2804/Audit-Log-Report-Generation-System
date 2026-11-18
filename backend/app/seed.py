import json
from datetime import datetime, timezone, timedelta
from sqlalchemy.orm import Session  # type: ignore
try:
    from .models import User, Department, Employee, AuditLog, Loan
    from .services.audit_service import AuditService
except (ImportError, ValueError):
    from app.models import User, Department, Employee, AuditLog, Loan
    from app.services.audit_service import AuditService

def seed_database(db: Session, force_reset: bool = False) -> bool:
    """
    Seeds comprehensive sample audit records and database entities based directly on
    the SI CAPITAL & FINANCIAL SERVICES LTD 3-Year Projection financial spreadsheet:
    - 5 Loan Schemes: Daily Loan, Weekly Loan, Personal Loan, Vehicle Loan, Gold Loan
    - Monitored Tables: users, departments, employees, loans, audit_logs
    - Real-world operations: INSERT (origination/creation), UPDATE (collections/state mutations), DELETE (cancellations/voids)
    - Full JSON snapshots for previous and new values
    """
    if force_reset:
        db.query(AuditLog).delete()
        db.query(Loan).delete()
        db.query(Employee).delete()
        db.query(Department).delete()
        db.query(User).delete()
        db.commit()

    existing_audits = db.query(AuditLog).count()
    if existing_audits >= 50 and not force_reset:
        return False  # Already fully populated

    now = datetime.now(timezone.utc)
    ips = [
        "192.168.1.45",
        "10.0.0.12",
        "192.168.2.88",
        "172.16.0.4",
        "10.0.4.15",
        "192.168.1.112",
        "172.16.0.24",
    ]

    # =========================================================================
    # 1. USERS & AUDIT OFFICERS (SI Capital & iNav Evaluation Team)
    # =========================================================================
    users_data = [
        {"username": "admin", "email": "admin@sicapital.local", "full_name": "System Administrator", "role": "SuperAdmin"},
        {"username": "john.paul", "email": "johnpaul@navtechnologies.in", "full_name": "John Paul Rapheal", "role": "Lead Technical Auditor"},
        {"username": "rajesh.sharma", "email": "rsharma@sicapital.local", "full_name": "Rajesh Sharma", "role": "Credit Manager - DL & WL"},
        {"username": "priya.nair", "email": "pnair@sicapital.local", "full_name": "Priya Nair", "role": "Senior Gold Valuation Officer"},
        {"username": "anand.verma", "email": "averma@sicapital.local", "full_name": "Anand Verma", "role": "Asset Finance Underwriter"},
        {"username": "marcus.vance", "email": "mvance@sicapital.local", "full_name": "Marcus Vance", "role": "Finance & Treasury Director"},
        {"username": "elena.rodriguez", "email": "erodriguez@sicapital.local", "full_name": "Elena Rodriguez", "role": "Compliance & Audit Specialist"},
    ]

    users_map = {}
    for u in users_data:
        existing_user = db.query(User).filter(User.username == u["username"]).first()
        if not existing_user:
            user_obj = User(
                username=u["username"],
                email=u["email"],
                full_name=u["full_name"],
                role=u["role"],
                created_at=now - timedelta(days=20)
            )
            db.add(user_obj)
            db.flush()
            users_map[u["username"]] = user_obj
        else:
            users_map[u["username"]] = existing_user

    # =========================================================================
    # 2. DEPARTMENTS (SI Capital Financial & Operational Divisions)
    # =========================================================================
    departments_data = [
        {"name": "Daily Loan Operations", "code": "DL-OPS", "description": "120-Day Daily Microfinance & Recovery Division"},
        {"name": "Weekly Loan Operations", "code": "WL-OPS", "description": "52-Week Weekly Group Lending Division"},
        {"name": "Personal Loan Division", "code": "PL-OPS", "description": "24-Month Consumer & Personal Credit Portfolio"},
        {"name": "Vehicle Loan Division", "code": "VL-OPS", "description": "24-Month Vehicle & Asset Backed Finance"},
        {"name": "Gold Loan & Pledging", "code": "GL-OPS", "description": "60-Day Gold Jewelry Collateral & Valuation"},
        {"name": "Audit, Admin & Verification", "code": "AUDIT", "description": "Statutory Audit, CIBIL Verification & Surveillance"},
        {"name": "Finance & Treasury", "code": "FIN", "description": "Capital Cost (15%), Funds Allocation & P&L Analysis"},
    ]

    dept_map = {}
    for d in departments_data:
        existing_dept = db.query(Department).filter(Department.code == d["code"]).first()
        if not existing_dept:
            dept_obj = Department(
                name=d["name"],
                code=d["code"],
                description=d["description"],
                created_at=now - timedelta(days=20)
            )
            db.add(dept_obj)
            db.flush()
            dept_map[d["code"]] = dept_obj
        else:
            dept_map[d["code"]] = existing_dept

    # =========================================================================
    # 3. EMPLOYEES (Staffing & Operations - matching spreadsheet ₹60k salary cost)
    # =========================================================================
    employees_data = [
        {"first_name": "Suresh", "last_name": "Menon", "email": "smenon@sicapital.local", "phone": "+91-98401-11221", "dept_code": "DL-OPS", "job_title": "Daily Loan Field Officer", "salary": 60000.0, "status": "Active"},
        {"first_name": "Kavita", "last_name": "Rao", "email": "krao@sicapital.local", "phone": "+91-98401-11222", "dept_code": "WL-OPS", "job_title": "Weekly Credit Officer", "salary": 60000.0, "status": "Active"},
        {"first_name": "Manoj", "last_name": "Tiwari", "email": "mtiwari@sicapital.local", "phone": "+91-98401-11223", "dept_code": "VL-OPS", "job_title": "Vehicle Loan Underwriter", "salary": 60000.0, "status": "Active"},
        {"first_name": "Deepak", "last_name": "Joshi", "email": "djoshi@sicapital.local", "phone": "+91-98401-11224", "dept_code": "PL-OPS", "job_title": "Personal Credit Analyst", "salary": 60000.0, "status": "Active"},
        {"first_name": "Lakshmi", "last_name": "Narayanan", "email": "lnarayanan@sicapital.local", "phone": "+91-98401-11225", "dept_code": "GL-OPS", "job_title": "Senior Gold Appraiser", "salary": 60000.0, "status": "Active"},
        {"first_name": "Anita", "last_name": "Desai", "email": "adesai@sicapital.local", "phone": "+91-98401-11226", "dept_code": "AUDIT", "job_title": "Internal Compliance Auditor", "salary": 60000.0, "status": "Active"},
        {"first_name": "Sunita", "last_name": "Patel", "email": "spatel@sicapital.local", "phone": "+91-98401-11227", "dept_code": "FIN", "job_title": "Treasury & Funds Accountant", "salary": 60000.0, "status": "Active"},
        {"first_name": "Vikram", "last_name": "Malhotra", "email": "vmalhotra@sicapital.local", "phone": "+91-98401-11228", "dept_code": "DL-OPS", "job_title": "Micro-finance Supervisor", "salary": 65000.0, "status": "Active"},
        {"first_name": "Balaji", "last_name": "Venkat", "email": "bvenkat@sicapital.local", "phone": "+91-98401-11229", "dept_code": "GL-OPS", "job_title": "Vault Custodian", "salary": 60000.0, "status": "Active"},
        {"first_name": "Rohit", "last_name": "Kapoor", "email": "rkapoor@sicapital.local", "phone": "+91-98401-11230", "dept_code": "AUDIT", "job_title": "CIBIL Verification Specialist", "salary": 58000.0, "status": "Active"},
    ]

    emp_map = {}
    for ed in employees_data:
        existing_emp = db.query(Employee).filter(Employee.email == ed["email"]).first()
        dept = dept_map[ed["dept_code"]]
        if not existing_emp:
            emp = Employee(
                first_name=ed["first_name"],
                last_name=ed["last_name"],
                email=ed["email"],
                phone=ed["phone"],
                department_id=dept.id,
                job_title=ed["job_title"],
                salary=ed["salary"],
                status=ed["status"],
                created_at=now - timedelta(days=15),
                updated_at=now - timedelta(days=15)
            )
            db.add(emp)
            db.flush()
            emp_map[ed["email"]] = emp
        else:
            emp_map[ed["email"]] = existing_emp

    # =========================================================================
    # 4. LOAN RECORDS (Exact 5 Schemes from SI Capital Spreadsheet)
    # =========================================================================
    # Scheme details from spreadsheet:
    # DL: 100k, Doc 3k, Flat 15%, ROI 73%, Period 120 Days, Int 5000
    # WL: 100k, Doc 3k, Flat 21.71%, ROI 40%, Period 52 Weeks, EMI 2340, Int 21711
    # PL: 100k, Doc 2k, Flat 15%, ROI 26.58%, Period 24 Months, EMI 5416, Int 30007
    # VL: 100k, Doc 1.5k, Flat 14%, ROI 24.93%, Period 24 Months, EMI 5333, Int 28009
    # GL: 100k, Doc 0, Flat 18%, ROI 18%, Period 60 Days, Int 18000
    loans_data = [
        # Daily Loans (DL)
        {"loan_number": "DL-2026-001", "loan_type": "Daily Loan", "borrower_name": "Rajesh Sharma", "principal_amount": 100000.0, "interest_rate": 73.0, "tenure_period": "120 Days", "doc_fee": 3000.0, "status": "Active"},
        {"loan_number": "DL-2026-002", "loan_type": "Daily Loan", "borrower_name": "Vikram Malhotra", "principal_amount": 200000.0, "interest_rate": 73.0, "tenure_period": "120 Days", "doc_fee": 6000.0, "status": "Active"},
        {"loan_number": "DL-2026-003", "loan_type": "Daily Loan", "borrower_name": "Alok Nath Traders", "principal_amount": 300000.0, "interest_rate": 73.0, "tenure_period": "120 Days", "doc_fee": 9000.0, "status": "Active"},

        # Weekly Loans (WL)
        {"loan_number": "WL-2026-001", "loan_type": "Weekly Loan", "borrower_name": "Priya Nair", "principal_amount": 100000.0, "interest_rate": 40.0, "tenure_period": "52 Weeks", "doc_fee": 3000.0, "status": "Active"},
        {"loan_number": "WL-2026-002", "loan_type": "Weekly Loan", "borrower_name": "Sunita Rao", "principal_amount": 120000.0, "interest_rate": 40.0, "tenure_period": "52 Weeks", "doc_fee": 3600.0, "status": "Active"},
        {"loan_number": "WL-2026-003", "loan_type": "Weekly Loan", "borrower_name": "Kavita Self Help Group", "principal_amount": 140000.0, "interest_rate": 40.0, "tenure_period": "52 Weeks", "doc_fee": 4200.0, "status": "Active"},

        # Personal Loans (PL)
        {"loan_number": "PL-2026-001", "loan_type": "Personal Loan", "borrower_name": "Anand Verma", "principal_amount": 100000.0, "interest_rate": 26.58, "tenure_period": "24 Months", "doc_fee": 2000.0, "status": "Active"},
        {"loan_number": "PL-2026-002", "loan_type": "Personal Loan", "borrower_name": "Deepak Joshi", "principal_amount": 120000.0, "interest_rate": 26.58, "tenure_period": "24 Months", "doc_fee": 2400.0, "status": "Active"},
        {"loan_number": "PL-2026-003", "loan_type": "Personal Loan", "borrower_name": "Meera Krishnan", "principal_amount": 140000.0, "interest_rate": 26.58, "tenure_period": "24 Months", "doc_fee": 2800.0, "status": "Active"},

        # Vehicle Loans (VL)
        {"loan_number": "VL-2026-001", "loan_type": "Vehicle Loan", "borrower_name": "Suresh Patel", "principal_amount": 100000.0, "interest_rate": 24.93, "tenure_period": "24 Months", "doc_fee": 1500.0, "status": "Active"},
        {"loan_number": "VL-2026-002", "loan_type": "Vehicle Loan", "borrower_name": "Manoj Tiwari", "principal_amount": 120000.0, "interest_rate": 24.93, "tenure_period": "24 Months", "doc_fee": 1800.0, "status": "Active"},
        {"loan_number": "VL-2026-003", "loan_type": "Vehicle Loan", "borrower_name": "Anita Transport Corp", "principal_amount": 140000.0, "interest_rate": 24.93, "tenure_period": "24 Months", "doc_fee": 2100.0, "status": "Active"},

        # Gold Loans (GL)
        {"loan_number": "GL-2026-001", "loan_type": "Gold Loan", "borrower_name": "Meenakshi Sundaram", "principal_amount": 100000.0, "interest_rate": 18.0, "tenure_period": "60 Days", "doc_fee": 0.0, "status": "Active"},
        {"loan_number": "GL-2026-002", "loan_type": "Gold Loan", "borrower_name": "Balaji Venkat Jewels", "principal_amount": 700000.0, "interest_rate": 18.0, "tenure_period": "60 Days", "doc_fee": 0.0, "status": "Active"},
        {"loan_number": "GL-2026-003", "loan_type": "Gold Loan", "borrower_name": "Lakshmi Narayanan", "principal_amount": 750000.0, "interest_rate": 18.0, "tenure_period": "60 Days", "doc_fee": 0.0, "status": "Active"},
    ]

    loan_objs = []
    for ld in loans_data:
        existing_loan = db.query(Loan).filter(Loan.loan_number == ld["loan_number"]).first()
        if not existing_loan:
            loan_obj = Loan(
                loan_number=ld["loan_number"],
                loan_type=ld["loan_type"],
                borrower_name=ld["borrower_name"],
                principal_amount=ld["principal_amount"],
                interest_rate=ld["interest_rate"],
                tenure_period=ld["tenure_period"],
                doc_fee=ld["doc_fee"],
                status=ld["status"],
                created_at=now - timedelta(days=12),
                updated_at=now - timedelta(days=12)
            )
            db.add(loan_obj)
            db.flush()
            loan_objs.append(loan_obj)
        else:
            loan_objs.append(existing_loan)

    # =========================================================================
    # 5. AUDIT LOGS TRAIL (60+ Verifiable Transactions Covering Every Metric)
    # =========================================================================
    # Clear old audits to populate the comprehensive spreadsheet audit trail
    db.query(AuditLog).delete()
    db.commit()

    audit_events = [
        # --- DAY -14 ---
        {
            "days_ago": 14, "hours": 9, "user": "admin", "ip": ips[0],
            "action": "INSERT", "table": "departments", "record_id": "1",
            "prev": None,
            "new": {"name": "Daily Loan Operations", "code": "DL-OPS", "target_disbursement_lakhs": 1297.0}
        },
        {
            "days_ago": 14, "hours": 11, "user": "john.paul", "ip": ips[1],
            "action": "INSERT", "table": "departments", "record_id": "2",
            "prev": None,
            "new": {"name": "Weekly Loan Operations", "code": "WL-OPS", "target_disbursement_lakhs": 63.6}
        },
        {
            "days_ago": 14, "hours": 14, "user": "marcus.vance", "ip": ips[2],
            "action": "INSERT", "table": "departments", "record_id": "5",
            "prev": None,
            "new": {"name": "Gold Loan & Pledging", "code": "GL-OPS", "target_disbursement_lakhs": 350.0}
        },
        {
            "days_ago": 14, "hours": 16, "user": "admin", "ip": ips[0],
            "action": "INSERT", "table": "users", "record_id": "2",
            "prev": None,
            "new": {"username": "john.paul", "role": "Lead Technical Auditor", "org": "iNav Technologies"}
        },

        # --- DAY -13 ---
        {
            "days_ago": 13, "hours": 8, "user": "john.paul", "ip": ips[1],
            "action": "INSERT", "table": "employees", "record_id": "1",
            "prev": None,
            "new": {"first_name": "Suresh", "last_name": "Menon", "dept": "DL-OPS", "salary": 60000.0, "role": "Field Officer"}
        },
        {
            "days_ago": 13, "hours": 10, "user": "rajesh.sharma", "ip": ips[3],
            "action": "INSERT", "table": "loans", "record_id": "1",
            "prev": None,
            "new": {
                "loan_number": "DL-2026-001", "scheme": "Daily Loan", "borrower": "Rajesh Sharma",
                "principal": 100000.0, "flat_rate_pct": 15.0, "roi_pct": 73.0, "period": "120 Days", "doc_fee": 3000.0, "int_amount": 5000.0
            }
        },
        {
            "days_ago": 13, "hours": 14, "user": "priya.nair", "ip": ips[4],
            "action": "INSERT", "table": "loans", "record_id": "4",
            "prev": None,
            "new": {
                "loan_number": "WL-2026-001", "scheme": "Weekly Loan", "borrower": "Priya Nair",
                "principal": 100000.0, "flat_rate_pct": 21.71, "roi_pct": 40.0, "period": "52 Weeks", "doc_fee": 3000.0, "emi": 2340.0, "int_amount": 21711.0
            }
        },
        {
            "days_ago": 13, "hours": 16, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "loans", "record_id": "901",
            "prev": {"loan_number": "DRAFT-TEST-01", "scheme": "Daily Loan", "reason": "Accidental duplicate entry during loan intake"},
            "new": None
        },

        # --- DAY -12 ---
        {
            "days_ago": 12, "hours": 9, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "7",
            "prev": None,
            "new": {
                "loan_number": "PL-2026-001", "scheme": "Personal Loan", "borrower": "Anand Verma",
                "principal": 100000.0, "flat_rate_pct": 15.0, "roi_pct": 26.58, "period": "24 Months", "doc_fee": 2000.0, "emi": 5416.0, "int_amount": 30007.0
            }
        },
        {
            "days_ago": 12, "hours": 11, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "10",
            "prev": None,
            "new": {
                "loan_number": "VL-2026-001", "scheme": "Vehicle Loan", "borrower": "Suresh Patel",
                "principal": 100000.0, "flat_rate_pct": 14.0, "roi_pct": 24.93, "period": "24 Months", "doc_fee": 1500.0, "emi": 5333.0, "int_amount": 28009.0
            }
        },
        {
            "days_ago": 12, "hours": 15, "user": "priya.nair", "ip": ips[4],
            "action": "INSERT", "table": "loans", "record_id": "13",
            "prev": None,
            "new": {
                "loan_number": "GL-2026-001", "scheme": "Gold Loan", "borrower": "Meenakshi Sundaram",
                "principal": 100000.0, "flat_rate_pct": 18.0, "roi_pct": 18.0, "period": "60 Days", "doc_fee": 0.0, "int_amount": 18000.0
            }
        },
        {
            "days_ago": 12, "hours": 17, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "1",
            "prev": {"loan_number": "DL-2026-001", "status": "Pending Sanction"},
            "new": {"loan_number": "DL-2026-001", "status": "Disbursed", "disbursement_ref": "NEFT-DL-001", "amount": 100000.0}
        },

        # --- DAY -11 ---
        {
            "days_ago": 11, "hours": 10, "user": "rajesh.sharma", "ip": ips[3],
            "action": "INSERT", "table": "loans", "record_id": "2",
            "prev": None,
            "new": {
                "loan_number": "DL-2026-002", "scheme": "Daily Loan", "borrower": "Vikram Malhotra",
                "principal": 200000.0, "doc_fee": 6000.0, "period": "120 Days", "roi_pct": 73.0
            }
        },
        {
            "days_ago": 11, "hours": 12, "user": "elena.rodriguez", "ip": ips[6],
            "action": "INSERT", "table": "employees", "record_id": "5",
            "prev": None,
            "new": {"first_name": "Lakshmi", "last_name": "Narayanan", "dept": "GL-OPS", "salary": 60000.0, "role": "Senior Gold Appraiser"}
        },
        {
            "days_ago": 11, "hours": 14, "user": "john.paul", "ip": ips[1],
            "action": "UPDATE", "table": "loans", "record_id": "4",
            "prev": {"loan_number": "WL-2026-001", "collection_status": "Not Started", "outstanding": 100000.0},
            "new": {"loan_number": "WL-2026-001", "collection_status": "Week 1 Paid", "emi_received": 2340.0, "outstanding": 97660.0}
        },
        {
            "days_ago": 11, "hours": 16, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "employees", "record_id": "991",
            "prev": {"id": 991, "name": "Temporary Auditor Intern", "dept": "AUDIT", "reason": "Internship period concluded"},
            "new": None
        },

        # --- DAY -10 ---
        {
            "days_ago": 10, "hours": 9, "user": "priya.nair", "ip": ips[4],
            "action": "INSERT", "table": "loans", "record_id": "14",
            "prev": None,
            "new": {
                "loan_number": "GL-2026-002", "scheme": "Gold Loan", "borrower": "Balaji Venkat Jewels",
                "principal": 700000.0, "rate": 18.0, "tenure": "60 Days", "int_expected": 126000.0, "collateral_grams": 145.5
            }
        },
        {
            "days_ago": 10, "hours": 11, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "8",
            "prev": None,
            "new": {
                "loan_number": "PL-2026-002", "scheme": "Personal Loan", "borrower": "Deepak Joshi",
                "principal": 120000.0, "doc_fee": 2400.0, "emi": 6500.0, "period": "24 Months"
            }
        },
        {
            "days_ago": 10, "hours": 15, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "10",
            "prev": {"loan_number": "VL-2026-001", "month_1_emi": "Due", "balance": 100000.0},
            "new": {"loan_number": "VL-2026-001", "month_1_emi": "Collected", "principal_repaid": 3256.0, "interest_repaid": 2078.0, "balance": 96744.0}
        },
        {
            "days_ago": 10, "hours": 17, "user": "rajesh.sharma", "ip": ips[3],
            "action": "UPDATE", "table": "loans", "record_id": "1",
            "prev": {"loan_number": "DL-2026-001", "collected_amount": 0.0, "outstanding": 100000.0},
            "new": {"loan_number": "DL-2026-001", "collected_amount": 25000.0, "outstanding": 75000.0, "batch": "Daily Batch #1"}
        },

        # --- DAY -9 ---
        {
            "days_ago": 9, "hours": 10, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "11",
            "prev": None,
            "new": {
                "loan_number": "VL-2026-002", "scheme": "Vehicle Loan", "borrower": "Manoj Tiwari",
                "principal": 120000.0, "doc_fee": 1800.0, "rate": 24.93, "tenure": "24 Months"
            }
        },
        {
            "days_ago": 9, "hours": 13, "user": "john.paul", "ip": ips[1],
            "action": "UPDATE", "table": "departments", "record_id": "6",
            "prev": {"code": "AUDIT", "monthly_cibil_budget": 30000.0},
            "new": {"code": "AUDIT", "monthly_cibil_budget": 60000.0, "authorized_by": "John Paul Rapheal"}
        },
        {
            "days_ago": 9, "hours": 16, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "loans", "record_id": "902",
            "prev": {"loan_number": "VL-VOID-02", "scheme": "Vehicle Loan", "borrower": "Cancelled Applicant", "reason": "CIBIL Score below mandatory threshold (Score: 540)"},
            "new": None
        },

        # --- DAY -8 ---
        {
            "days_ago": 8, "hours": 9, "user": "rajesh.sharma", "ip": ips[3],
            "action": "INSERT", "table": "loans", "record_id": "5",
            "prev": None,
            "new": {
                "loan_number": "WL-2026-002", "scheme": "Weekly Loan", "borrower": "Sunita Rao",
                "principal": 120000.0, "doc_fee": 3600.0, "rate": 40.0, "tenure": "52 Weeks", "emi": 2808.0
            }
        },
        {
            "days_ago": 8, "hours": 11, "user": "priya.nair", "ip": ips[4],
            "action": "INSERT", "table": "loans", "record_id": "15",
            "prev": None,
            "new": {
                "loan_number": "GL-2026-003", "scheme": "Gold Loan", "borrower": "Lakshmi Narayanan",
                "principal": 750000.0, "rate": 18.0, "tenure": "60 Days", "doc_fee": 0.0, "interest_expected": 135000.0
            }
        },
        {
            "days_ago": 8, "hours": 14, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "7",
            "prev": {"loan_number": "PL-2026-001", "month_1_emi": "Due", "balance": 100000.0},
            "new": {"loan_number": "PL-2026-001", "month_1_emi": "Paid", "principal_repaid": 3202.0, "interest_repaid": 2215.0, "balance": 96798.0}
        },
        {
            "days_ago": 8, "hours": 16, "user": "elena.rodriguez", "ip": ips[6],
            "action": "UPDATE", "table": "employees", "record_id": "1",
            "prev": {"email": "smenon@sicapital.local", "salary": 60000.0, "status": "Probation"},
            "new": {"email": "smenon@sicapital.local", "salary": 60000.0, "status": "Active", "confirmation_date": "2026-11-10"}
        },

        # --- DAY -7 ---
        {
            "days_ago": 7, "hours": 8, "user": "john.paul", "ip": ips[1],
            "action": "INSERT", "table": "employees", "record_id": "6",
            "prev": None,
            "new": {"first_name": "Anita", "last_name": "Desai", "dept": "AUDIT", "salary": 60000.0, "role": "Internal Compliance Auditor"}
        },
        {
            "days_ago": 7, "hours": 11, "user": "rajesh.sharma", "ip": ips[3],
            "action": "INSERT", "table": "loans", "record_id": "3",
            "prev": None,
            "new": {
                "loan_number": "DL-2026-003", "scheme": "Daily Loan", "borrower": "Alok Nath Traders",
                "principal": 300000.0, "doc_fee": 9000.0, "rate": 73.0, "tenure": "120 Days"
            }
        },
        {
            "days_ago": 7, "hours": 14, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "2",
            "prev": {"loan_number": "DL-2026-002", "status": "Approved"},
            "new": {"loan_number": "DL-2026-002", "status": "Disbursed", "disbursed_via": "Direct RTGS", "doc_fee_collected": 6000.0}
        },
        {
            "days_ago": 7, "hours": 17, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "users", "record_id": "99",
            "prev": {"username": "test_temp_analyst", "role": "Observer", "reason": "Revoked sandbox audit token"},
            "new": None
        },

        # --- DAY -6 ---
        {
            "days_ago": 6, "hours": 9, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "9",
            "prev": None,
            "new": {
                "loan_number": "PL-2026-003", "scheme": "Personal Loan", "borrower": "Meera Krishnan",
                "principal": 140000.0, "doc_fee": 2800.0, "emi": 7583.0, "period": "24 Months", "rate": 26.58
            }
        },
        {
            "days_ago": 6, "hours": 12, "user": "anand.verma", "ip": ips[5],
            "action": "INSERT", "table": "loans", "record_id": "12",
            "prev": None,
            "new": {
                "loan_number": "VL-2026-003", "scheme": "Vehicle Loan", "borrower": "Anita Transport Corp",
                "principal": 140000.0, "doc_fee": 2100.0, "emi": 7466.0, "period": "24 Months", "rate": 24.93
            }
        },
        {
            "days_ago": 6, "hours": 15, "user": "john.paul", "ip": ips[1],
            "action": "UPDATE", "table": "loans", "record_id": "5",
            "prev": {"loan_number": "WL-2026-002", "collection_week_1": "Pending"},
            "new": {"loan_number": "WL-2026-002", "collection_week_1": "Received", "emi_amount": 2808.0, "cleared_via": "UPI/IMPS"}
        },

        # --- DAY -5 ---
        {
            "days_ago": 5, "hours": 10, "user": "rajesh.sharma", "ip": ips[3],
            "action": "INSERT", "table": "loans", "record_id": "6",
            "prev": None,
            "new": {
                "loan_number": "WL-2026-003", "scheme": "Weekly Loan", "borrower": "Kavita Self Help Group",
                "principal": 140000.0, "doc_fee": 4200.0, "emi": 3276.0, "rate": 40.0, "tenure": "52 Weeks"
            }
        },
        {
            "days_ago": 5, "hours": 13, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "1",
            "prev": {"loan_number": "DL-2026-001", "collected_amount": 25000.0, "outstanding": 75000.0},
            "new": {"loan_number": "DL-2026-001", "collected_amount": 50000.0, "outstanding": 50000.0, "batch": "Daily Batch #2"}
        },
        {
            "days_ago": 5, "hours": 16, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "loans", "record_id": "903",
            "prev": {"loan_number": "GL-VOID-03", "scheme": "Gold Loan", "borrower": "K. Ramanathan", "reason": "Borrower withdrew jewelry pledge before loan signing"},
            "new": None
        },

        # --- DAY -4 ---
        {
            "days_ago": 4, "hours": 9, "user": "john.paul", "ip": ips[1],
            "action": "INSERT", "table": "employees", "record_id": "7",
            "prev": None,
            "new": {"first_name": "Sunita", "last_name": "Patel", "dept": "FIN", "salary": 60000.0, "role": "Treasury & Funds Accountant"}
        },
        {
            "days_ago": 4, "hours": 12, "user": "priya.nair", "ip": ips[4],
            "action": "UPDATE", "table": "loans", "record_id": "13",
            "prev": {"loan_number": "GL-2026-001", "pledge_status": "In Transit"},
            "new": {"loan_number": "GL-2026-001", "pledge_status": "Secured in Central Vault", "vault_locker_id": "LOCKER-GL-408"}
        },
        {
            "days_ago": 4, "hours": 15, "user": "anand.verma", "ip": ips[5],
            "action": "UPDATE", "table": "loans", "record_id": "10",
            "prev": {"loan_number": "VL-2026-001", "month_2_emi": "Due", "balance": 96744.0},
            "new": {"loan_number": "VL-2026-001", "month_2_emi": "Collected", "principal_repaid": 3324.0, "interest_repaid": 2010.0, "balance": 93420.0}
        },

        # --- DAY -3 ---
        {
            "days_ago": 3, "hours": 10, "user": "rajesh.sharma", "ip": ips[3],
            "action": "UPDATE", "table": "loans", "record_id": "1",
            "prev": {"loan_number": "DL-2026-001", "collected_amount": 50000.0, "outstanding": 50000.0},
            "new": {"loan_number": "DL-2026-001", "collected_amount": 75000.0, "outstanding": 25000.0, "batch": "Daily Batch #3"}
        },
        {
            "days_ago": 3, "hours": 13, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "7",
            "prev": {"loan_number": "PL-2026-001", "month_2_emi": "Due", "balance": 96798.0},
            "new": {"loan_number": "PL-2026-001", "month_2_emi": "Paid", "principal_repaid": 3273.0, "interest_repaid": 2144.0, "balance": 93525.0}
        },
        {
            "days_ago": 3, "hours": 16, "user": "elena.rodriguez", "ip": ips[6],
            "action": "DELETE", "table": "loans", "record_id": "904",
            "prev": {"loan_number": "PL-VOID-04", "scheme": "Personal Loan", "borrower": "Test Probe Corp", "reason": "Automated pipeline sanity test teardown"},
            "new": None
        },

        # --- DAY -2 ---
        {
            "days_ago": 2, "hours": 9, "user": "john.paul", "ip": ips[1],
            "action": "INSERT", "table": "employees", "record_id": "10",
            "prev": None,
            "new": {"first_name": "Rohit", "last_name": "Kapoor", "dept": "AUDIT", "salary": 58000.0, "role": "CIBIL Verification Specialist"}
        },
        {
            "days_ago": 2, "hours": 11, "user": "priya.nair", "ip": ips[4],
            "action": "UPDATE", "table": "loans", "record_id": "14",
            "prev": {"loan_number": "GL-2026-002", "npa_provision": 0.0},
            "new": {"loan_number": "GL-2026-002", "npa_provision": 700.0, "npa_provision_pct": "0.1%", "compliance_rule": "RBI Gold NPA Provision"}
        },
        {
            "days_ago": 2, "hours": 14, "user": "rajesh.sharma", "ip": ips[3],
            "action": "UPDATE", "table": "loans", "record_id": "2",
            "prev": {"loan_number": "DL-2026-002", "npa_provision": 0.0},
            "new": {"loan_number": "DL-2026-002", "npa_provision": 2000.0, "npa_provision_pct": "1.0%", "compliance_rule": "Microfinance 1% NPA Provision"}
        },
        {
            "days_ago": 2, "hours": 17, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "employees", "record_id": "993",
            "prev": {"id": 993, "name": "Staging Probe Record", "dept": "OPS", "status": "Decommissioned"},
            "new": None
        },

        # --- DAY -1 ---
        {
            "days_ago": 1, "hours": 10, "user": "rajesh.sharma", "ip": ips[3],
            "action": "UPDATE", "table": "loans", "record_id": "1",
            "prev": {"loan_number": "DL-2026-001", "collected_amount": 75000.0, "outstanding": 25000.0},
            "new": {"loan_number": "DL-2026-001", "collected_amount": 100000.0, "outstanding": 0.0, "status": "Closed / Fully Recovered", "final_batch": "Daily Batch #4"}
        },
        {
            "days_ago": 1, "hours": 13, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "10",
            "prev": {"loan_number": "VL-2026-001", "month_3_emi": "Due", "balance": 93420.0},
            "new": {"loan_number": "VL-2026-001", "month_3_emi": "Collected", "principal_repaid": 3393.0, "interest_repaid": 1941.0, "balance": 90027.0}
        },
        {
            "days_ago": 1, "hours": 15, "user": "john.paul", "ip": ips[1],
            "action": "UPDATE", "table": "users", "record_id": "2",
            "prev": {"email": "johnpaul@navtechnologies.in", "last_login": "2026-11-15T09:00:00Z"},
            "new": {"email": "johnpaul@navtechnologies.in", "last_login": "2026-11-17T08:00:00Z", "auth_status": "Auditor Session Active"}
        },
        {
            "days_ago": 1, "hours": 18, "user": "admin", "ip": ips[0],
            "action": "DELETE", "table": "loans", "record_id": "990",
            "prev": {"loan_number": "TEST-VOID-00", "loan_type": "Gold Loan", "reason": "Application Cancelled by Borrower"},
            "new": None
        },

        # --- TODAY (DAY 0) ---
        {
            "days_ago": 0, "hours": 2, "user": "john.paul", "ip": ips[1],
            "action": "UPDATE", "table": "loans", "record_id": "4",
            "prev": {"loan_number": "WL-2026-001", "outstanding": 97660.0},
            "new": {"loan_number": "WL-2026-001", "collection_week_2": "Received", "emi_received": 2340.0, "outstanding": 95320.0}
        },
        {
            "days_ago": 0, "hours": 1, "user": "marcus.vance", "ip": ips[2],
            "action": "UPDATE", "table": "loans", "record_id": "7",
            "prev": {"loan_number": "PL-2026-001", "month_3_emi": "Due", "balance": 93525.0},
            "new": {"loan_number": "PL-2026-001", "month_3_emi": "Paid", "principal_repaid": 3345.0, "interest_repaid": 2072.0, "balance": 90180.0}
        },
    ]

    for ev in audit_events:
        ts = now - timedelta(days=ev["days_ago"], hours=ev["hours"])
        user = users_map.get(ev["user"])
        user_id = user.id if user else None

        prev_json = json.dumps(ev["prev"]) if ev["prev"] is not None else None
        new_json = json.dumps(ev["new"]) if ev["new"] is not None else None

        audit_entry = AuditLog(
            user_id=user_id,
            username=ev["user"],
            action_type=ev["action"].upper(),
            table_name=ev["table"],
            record_id=str(ev["record_id"]),
            previous_value=prev_json,
            new_value=new_json,
            ip_address=ev["ip"],
            timestamp=ts
        )
        db.add(audit_entry)

    db.commit()
    return True
