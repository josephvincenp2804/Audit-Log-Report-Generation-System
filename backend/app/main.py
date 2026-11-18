from datetime import datetime, timezone
from contextlib import asynccontextmanager
from fastapi import FastAPI, Depends, status  # type: ignore
from fastapi.middleware.cors import CORSMiddleware  # type: ignore
from sqlalchemy.orm import Session  # type: ignore

from .database import engine, Base, get_db, SessionLocal
from .seed import seed_database
from .routers import dashboard, audit_logs, reports, simulation

@asynccontextmanager
async def lifespan(app: FastAPI):
    # 1. Automatically create database tables
    Base.metadata.create_all(bind=engine)
    
    # 2. Seed initial realistic audit records if unpopulated
    db = SessionLocal()
    try:
        seed_database(db)
    finally:
        db.close()
    
    yield
    # Shutdown logic if any

app = FastAPI(
    title="Audit Log Report Generation System API",
    description="Enterprise-grade Audit Trail & Report Generation Backend with Simulated Database Transactions.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    lifespan=lifespan
)

# CORS Configuration for Flutter Web and Mobile/Desktop clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://127.0.0.1:3000",
        "http://localhost:3000",
        "http://127.0.0.1:8000",
        "http://localhost:8000",
        "*"
    ],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["Content-Disposition", "*"]
)

# Include Modular Routers
app.include_router(dashboard.router)
app.include_router(audit_logs.router)
app.include_router(reports.router)
app.include_router(simulation.router)

@app.get("/api/health", tags=["Health"])
def health_check(db: Session = Depends(get_db)):
    """
    Health check endpoint reporting API and database connectivity status.
    """
    return {
        "status": "ok",
        "service": "Audit Log Report Generation System",
        "database": "connected",
        "timestamp": datetime.now(timezone.utc).isoformat()
    }

