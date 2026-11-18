from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
try:
    from ..database import get_db
    from ..schemas import DashboardSummaryResponse
    from .. import crud
except (ImportError, ValueError):
    from app.database import get_db
    from app.schemas import DashboardSummaryResponse
    import app.crud as crud

router = APIRouter(prefix="/api/dashboard", tags=["Dashboard"])

@router.get("/summary", response_model=DashboardSummaryResponse)
def get_dashboard_summary(db: Session = Depends(get_db)):
    """
    Get aggregated dashboard summary metrics including:
    - Total audit activity count
    - INSERT, UPDATE, DELETE breakdowns
    - Recent activities
    - Activity distribution by table and action
    - Daily 14-day activity trends
    - High-level audit activity summary description
    """
    summary_data = crud.get_dashboard_summary(db)
    return summary_data

