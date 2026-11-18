# Audit Log Report Generation System - Backend

Enterprise-grade Audit Trail & Report Generation API built with Python, FastAPI, SQLAlchemy, SQLite, Pydantic, and ReportLab.

## Architecture

- **Framework**: FastAPI (Asynchronous REST API, OpenAPI / Swagger documentation)
- **ORM / Database**: SQLAlchemy with SQLite (`audit_system.db`)
- **Transaction Safety**: Atomic database updates with automatic audit logging within the same transaction.
- **Reporting Engine**: ReportLab (Vector-quality PDF generation with dynamic page numbering) and CSV streaming.
- **Data Validation**: Pydantic v2 schemas with type safety.

## Project Structure

```
backend/
├── app/
│   ├── main.py             # FastAPI entrypoint, CORS & Lifespan seeding
│   ├── database.py         # SQLAlchemy engine & session dependency
│   ├── models.py           # User, Department, Employee, AuditLog models
│   ├── schemas.py          # Pydantic request/response validation
│   ├── crud.py             # Database queries, filtering, aggregation, transactions
│   ├── seed.py             # 35+ realistic audit trail records across 14 days
│   ├── routers/
│   │   ├── dashboard.py    # GET /api/dashboard/summary
│   │   ├── audit_logs.py   # GET /api/audit-logs, GET /api/audit-logs/{id}
│   │   ├── reports.py      # GET /api/reports/generate, /download/pdf, /download/csv
│   │   └── simulation.py   # POST /insert, PUT /update/{id}, DELETE /delete/{id}
│   └── services/
│       ├── audit_service.py   # Audit transaction logger
│       └── report_service.py  # ReportLab PDF & CSV builder
├── tests/
│   ├── conftest.py         # TestClient fixtures & isolated DB
│   └── test_api.py         # 11 unit & integration test scenarios
├── requirements.txt
└── README.md
```

## Setup & Running

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run development server:
   ```bash
   uvicorn app.main:app --reload --port 8000
   ```

3. Interactive API Documentation:
   - Swagger UI: `http://localhost:8000/docs`
   - ReDoc: `http://localhost:8000/redoc`

4. Run tests:
   ```bash
   python -m pytest backend/tests -v
   ```

