import math
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy.orm import Session
try:
    from ..database import get_db
    from ..schemas import PaginatedAuditLogsResponse, AuditLogDetailResponse
    from .. import crud
except (ImportError, ValueError):
    from app.database import get_db
    from app.schemas import PaginatedAuditLogsResponse, AuditLogDetailResponse
    import app.crud as crud

router = APIRouter(prefix="/api/audit-logs", tags=["Audit Logs"])

@router.get("", response_model=PaginatedAuditLogsResponse)
def get_audit_logs(
    username: Optional[str] = Query(None, description="Filter by username substring"),
    action_type: Optional[str] = Query(None, description="Filter by action type (INSERT, UPDATE, DELETE)"),
    table_name: Optional[str] = Query(None, description="Filter by table name"),
    start_date: Optional[str] = Query(None, description="Start date (YYYY-MM-DD or ISO)"),
    end_date: Optional[str] = Query(None, description="End date (YYYY-MM-DD or ISO)"),
    sort_by: str = Query("timestamp", description="Field to sort by (timestamp, audit_id, username)"),
    sort_order: str = Query("desc", pattern="^(asc|desc)$", description="Sort order"),
    page: int = Query(1, ge=1, description="Page number starting at 1"),
    page_size: int = Query(15, ge=1, le=100, description="Items per page"),
    db: Session = Depends(get_db)
):
    """
    Search, filter, sort and paginate audit log trail records.
    """
    # Validate date range logic if both dates provided
    if start_date and end_date:
        s_dt = crud.parse_date(start_date)
        e_dt = crud.parse_date(end_date)
        if s_dt and e_dt and s_dt > e_dt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid date range: start_date cannot be later than end_date."
            )

    skip = (page - 1) * page_size
    total, items = crud.get_audit_logs(
        db=db,
        username=username,
        action_type=action_type,
        table_name=table_name,
        start_date=start_date,
        end_date=end_date,
        sort_by=sort_by,
        sort_order=sort_order,
        skip=skip,
        limit=page_size
    )

    total_pages = math.ceil(total / page_size) if total > 0 else 1

    return {
        "items": items,
        "total": total,
        "page": page,
        "page_size": page_size,
        "total_pages": total_pages
    }

@router.get("/{audit_id}", response_model=AuditLogDetailResponse)
def get_audit_log_detail(audit_id: int, db: Session = Depends(get_db)):
    """
    Retrieve single audit record details with structured JSON parsing of previous and new values.
    """
    log = crud.get_audit_log_by_id(db, audit_id=audit_id)
    if not log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Audit log record with ID {audit_id} not found."
        )
    return log.to_dict()

