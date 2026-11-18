from datetime import datetime, timezone
import json
from sqlalchemy import Column, Integer, String, Text, DateTime, Float, ForeignKey  # type: ignore
from sqlalchemy.orm import relationship  # type: ignore
from .database import Base

def utc_now():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    email = Column(String(120), unique=True, index=True, nullable=False)
    full_name = Column(String(120), nullable=False)
    role = Column(String(50), default="Analyst", nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "username": self.username,
            "email": self.email,
            "full_name": self.full_name,
            "role": self.role,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class Department(Base):
    __tablename__ = "departments"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    name = Column(String(100), unique=True, nullable=False)
    code = Column(String(20), unique=True, nullable=False)
    description = Column(String(255), nullable=True)
    created_at = Column(DateTime, default=utc_now, nullable=False)

    employees = relationship("Employee", back_populates="department")

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "code": self.code,
            "description": self.description,
            "created_at": self.created_at.isoformat() if self.created_at else None
        }

class Employee(Base):
    __tablename__ = "employees"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    first_name = Column(String(60), nullable=False)
    last_name = Column(String(60), nullable=False)
    email = Column(String(120), unique=True, nullable=False)
    phone = Column(String(30), nullable=True)
    department_id = Column(Integer, ForeignKey("departments.id"), nullable=False)
    job_title = Column(String(100), nullable=False)
    salary = Column(Float, nullable=False)
    status = Column(String(20), default="Active", nullable=False)
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    department = relationship("Department", back_populates="employees")

    def to_dict(self):
        return {
            "id": self.id,
            "first_name": self.first_name,
            "last_name": self.last_name,
            "email": self.email,
            "phone": self.phone,
            "department_id": self.department_id,
            "department_name": self.department.name if self.department else None,
            "job_title": self.job_title,
            "salary": self.salary,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }

class AuditLog(Base):
    __tablename__ = "audit_logs"

    audit_id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    username = Column(String(100), index=True, nullable=False)
    action_type = Column(String(20), index=True, nullable=False)  # INSERT, UPDATE, DELETE
    table_name = Column(String(50), index=True, nullable=False)
    record_id = Column(String(50), nullable=False)
    previous_value = Column(Text, nullable=True)  # JSON string
    new_value = Column(Text, nullable=True)       # JSON string
    ip_address = Column(String(50), nullable=True)
    timestamp = Column(DateTime, default=utc_now, index=True, nullable=False)

    def to_dict(self):
        # Helper to parse JSON if string
        prev_parsed = None
        new_parsed = None
        if self.previous_value:
            try:
                prev_parsed = json.loads(self.previous_value)
            except Exception:
                prev_parsed = self.previous_value
        if self.new_value:
            try:
                new_parsed = json.loads(self.new_value)
            except Exception:
                new_parsed = self.new_value

        return {
            "audit_id": self.audit_id,
            "user_id": self.user_id,
            "username": self.username,
            "action_type": self.action_type,
            "table_name": self.table_name,
            "record_id": self.record_id,
            "previous_value": self.previous_value,
            "new_value": self.new_value,
            "previous_value_parsed": prev_parsed,
            "new_value_parsed": new_parsed,
            "ip_address": self.ip_address,
            "timestamp": self.timestamp.isoformat() if self.timestamp else None
        }

class Loan(Base):
    __tablename__ = "loans"

    id = Column(Integer, primary_key=True, index=True, autoincrement=True)
    loan_number = Column(String(50), unique=True, index=True, nullable=False)
    loan_type = Column(String(50), nullable=False)  # Daily Loan, Weekly Loan, Personal Loan, Vehicle Loan, Gold Loan
    borrower_name = Column(String(100), nullable=False)
    principal_amount = Column(Float, nullable=False)
    interest_rate = Column(Float, nullable=False)
    tenure_period = Column(String(50), nullable=False)
    doc_fee = Column(Float, default=0.0)
    status = Column(String(20), default="Active", nullable=False)  # Active, Disbursed, Closed, Overdue
    created_at = Column(DateTime, default=utc_now, nullable=False)
    updated_at = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    def to_dict(self):
        return {
            "id": self.id,
            "loan_number": self.loan_number,
            "loan_type": self.loan_type,
            "borrower_name": self.borrower_name,
            "principal_amount": self.principal_amount,
            "interest_rate": self.interest_rate,
            "tenure_period": self.tenure_period,
            "doc_fee": self.doc_fee,
            "status": self.status,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None
        }


