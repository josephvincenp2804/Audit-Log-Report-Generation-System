from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from sqlalchemy.orm import Session

try:
    from ..database import get_db
    from ..schemas import ReportGenerateResponse
    from ..services.report_service import ReportService
    from .. import crud
except (ImportError, ValueError):
    from app.database import get_db
    from app.schemas import ReportGenerateResponse
    from app.services.report_service import ReportService
    import app.crud as crud

router = APIRouter(prefix="/api/reports", tags=["Reports"])

def validate_dates(start_date: Optional[str], end_date: Optional[str]):
    if start_date and end_date:
        s_dt = crud.parse_date(start_date)
        e_dt = crud.parse_date(end_date)
        if s_dt and e_dt and s_dt > e_dt:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Invalid date range: start_date cannot be later than end_date."
            )

@router.get("/generate", response_model=ReportGenerateResponse)
def generate_report(
    start_date: Optional[str] = Query(None, description="Start date filter (YYYY-MM-DD or ISO)"),
    end_date: Optional[str] = Query(None, description="End date filter (YYYY-MM-DD or ISO)"),
    action_type: Optional[str] = Query(None, description="Operation type filter (INSERT, UPDATE, DELETE)"),
    operation_type: Optional[str] = Query(None, description="Alias for action_type"),
    username: Optional[str] = Query(None, description="Username filter"),
    table_name: Optional[str] = Query(None, description="Table name filter"),
    db: Session = Depends(get_db)
):
    """
    Generate filtered audit log report data with summary metrics.
    """
    effective_action = action_type or operation_type
    validate_dates(start_date, end_date)

    records = crud.get_all_filtered_audit_logs(
        db=db,
        username=username,
        action_type=effective_action,
        table_name=table_name,
        start_date=start_date,
        end_date=end_date
    )

    insert_count = sum(1 for r in records if r.action_type == "INSERT")
    update_count = sum(1 for r in records if r.action_type == "UPDATE")
    delete_count = sum(1 for r in records if r.action_type == "DELETE")

    applied_filters = {
        "start_date": start_date or "All Time",
        "end_date": end_date or "Latest",
        "action_type": effective_action or "ALL",
        "username": username or "ALL",
        "table_name": table_name or "ALL"
    }

    return {
        "total_records": len(records),
        "insert_count": insert_count,
        "update_count": update_count,
        "delete_count": delete_count,
        "applied_filters": applied_filters,
        "generated_at": datetime.now(timezone.utc),
        "records": records
    }

@router.get("/download/pdf")
def download_pdf_report(
    start_date: Optional[str] = Query(None, description="Start date filter"),
    end_date: Optional[str] = Query(None, description="End date filter"),
    action_type: Optional[str] = Query(None, description="Operation type filter"),
    operation_type: Optional[str] = Query(None, description="Alias for action_type"),
    username: Optional[str] = Query(None, description="Username filter"),
    table_name: Optional[str] = Query(None, description="Table name filter"),
    db: Session = Depends(get_db)
):
    """
    Generate and stream an enterprise PDF report of filtered audit logs.
    """
    effective_action = action_type or operation_type
    validate_dates(start_date, end_date)

    records = crud.get_all_filtered_audit_logs(
        db=db,
        username=username,
        action_type=effective_action,
        table_name=table_name,
        start_date=start_date,
        end_date=end_date
    )

    filters = {
        "start_date": start_date,
        "end_date": end_date,
        "action_type": effective_action,
        "username": username,
        "table_name": table_name
    }

    pdf_bytes = ReportService.generate_pdf(records, filters)
    timestamp_str = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    filename = f"audit_report_{timestamp_str}.pdf"

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Access-Control-Expose-Headers": "Content-Disposition"
        }
    )

@router.get("/download/csv")
def download_csv_report(
    start_date: Optional[str] = Query(None, description="Start date filter"),
    end_date: Optional[str] = Query(None, description="End date filter"),
    action_type: Optional[str] = Query(None, description="Operation type filter"),
    operation_type: Optional[str] = Query(None, description="Alias for action_type"),
    username: Optional[str] = Query(None, description="Username filter"),
    table_name: Optional[str] = Query(None, description="Table name filter"),
    db: Session = Depends(get_db)
):
    """
    Generate and stream a CSV file containing all filtered audit log records.
    """
    effective_action = action_type or operation_type
    validate_dates(start_date, end_date)

    records = crud.get_all_filtered_audit_logs(
        db=db,
        username=username,
        action_type=effective_action,
        table_name=table_name,
        start_date=start_date,
        end_date=end_date
    )

    filters = {
        "start_date": start_date,
        "end_date": end_date,
        "action_type": effective_action,
        "username": username,
        "table_name": table_name
    }

    csv_content = ReportService.generate_csv(records, filters)
    timestamp_str = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    filename = f"audit_report_{timestamp_str}.csv"

    return Response(
        content=csv_content,
        media_type="text/csv",
        headers={
            "Content-Disposition": f'attachment; filename="{filename}"',
            "Access-Control-Expose-Headers": "Content-Disposition"
        }
    )

