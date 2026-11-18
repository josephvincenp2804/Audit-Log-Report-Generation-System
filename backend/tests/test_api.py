import pytest
from datetime import datetime, timezone, timedelta

def test_health_endpoint(client):
    """Test GET /api/health endpoint returns 200 and healthy status."""
    response = client.get("/api/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["database"] == "connected"
    assert "timestamp" in data

def test_dashboard_summary(client):
    """Test GET /api/dashboard/summary aggregates audit activity counts."""
    response = client.get("/api/dashboard/summary")
    assert response.status_code == 200
    data = response.json()
    assert data["total_activities"] >= 30
    assert data["insert_count"] > 0
    assert data["update_count"] > 0
    assert data["delete_count"] > 0
    assert len(data["recent_activities"]) <= 10
    assert "INSERT" in data["activity_by_action"]
    assert "UPDATE" in data["activity_by_action"]
    assert "DELETE" in data["activity_by_action"]
    assert len(data["daily_trends"]) == 14
    assert len(data["audit_activity_summary"]) > 10

def test_audit_log_retrieval(client):
    """Test GET /api/audit-logs pagination and filtering."""
    # Default paginated list
    response = client.get("/api/audit-logs?page=1&page_size=10")
    assert response.status_code == 200
    data = response.json()
    assert len(data["items"]) == 10
    assert data["total"] >= 30
    assert data["page"] == 1
    assert data["total_pages"] >= 3

    # Filter by action_type=INSERT
    resp_insert = client.get("/api/audit-logs?action_type=INSERT")
    assert resp_insert.status_code == 200
    data_insert = resp_insert.json()
    assert all(item["action_type"] == "INSERT" for item in data_insert["items"])

    # Filter by username
    resp_user = client.get("/api/audit-logs?username=admin")
    assert resp_user.status_code == 200
    data_user = resp_user.json()
    assert all("admin" in item["username"].lower() for item in data_user["items"])

def test_audit_log_detail(client):
    """Test GET /api/audit-logs/{audit_id} retrieves individual record details."""
    # First get an existing audit_id
    list_resp = client.get("/api/audit-logs?page=1&page_size=1")
    first_id = list_resp.json()["items"][0]["audit_id"]

    detail_resp = client.get(f"/api/audit-logs/{first_id}")
    assert detail_resp.status_code == 200
    detail = detail_resp.json()
    assert detail["audit_id"] == first_id
    assert "action_type" in detail
    assert "table_name" in detail
    assert "record_id" in detail

    # 404 for nonexistent id
    not_found = client.get("/api/audit-logs/99999999")
    assert not_found.status_code == 404

def test_date_filtering(client):
    """Test date filtering logic and validation."""
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    yesterday = (datetime.now(timezone.utc) - timedelta(days=1)).strftime("%Y-%m-%d")

    # Valid date range
    resp = client.get(f"/api/audit-logs?start_date={yesterday}&end_date={today}")
    assert resp.status_code == 200

    # Invalid date range (start > end) should return 400 Bad Request
    invalid_resp = client.get(f"/api/audit-logs?start_date={today}&end_date={yesterday}")
    assert invalid_resp.status_code == 400
    assert "Invalid date range" in invalid_resp.json()["detail"]

def test_reports_generate(client):
    """Test GET /api/reports/generate produces structured preview."""
    resp = client.get("/api/reports/generate?action_type=INSERT")
    assert resp.status_code == 200
    data = resp.json()
    assert data["insert_count"] > 0
    assert data["update_count"] == 0
    assert data["delete_count"] == 0
    assert data["total_records"] == data["insert_count"]
    assert len(data["records"]) == data["total_records"]

def test_simulation_insert(client):
    """Test POST /api/simulation/insert creates employee and audit log in one transaction."""
    payload = {
        "first_name": "TestUnit",
        "last_name": "Developer",
        "email": "testunit.developer@example.com",
        "phone": "+1-555-9988",
        "department_id": 1,
        "job_title": "Automated Test Engineer",
        "salary": 110000.0,
        "status": "Active",
        "acting_username": "sarah.connor",
        "acting_ip": "10.0.0.50"
    }
    response = client.post("/api/simulation/insert", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["action_type"] == "INSERT"
    assert data["audit_log"]["action_type"] == "INSERT"
    assert data["audit_log"]["table_name"] == "employees"
    assert data["audit_log"]["username"] == "sarah.connor"
    assert data["employee"]["email"] == "testunit.developer@example.com"

def test_simulation_update(client):
    """Test PUT /api/simulation/update/{id} modifies employee and generates UPDATE audit log."""
    # First insert an employee to update
    ins_payload = {
        "first_name": "Updatable",
        "last_name": "Target",
        "email": "updatable.target@example.com",
        "department_id": 1,
        "job_title": "Junior Staff",
        "salary": 60000.0,
        "status": "Active"
    }
    ins_resp = client.post("/api/simulation/insert", json=ins_payload)
    assert ins_resp.status_code == 201
    emp_id = ins_resp.json()["employee"]["id"]

    # Now update
    upd_payload = {
        "job_title": "Senior Staff",
        "salary": 95000.0,
        "acting_username": "alex.smith"
    }
    upd_resp = client.put(f"/api/simulation/update/{emp_id}", json=upd_payload)
    assert upd_resp.status_code == 200
    data = upd_resp.json()
    assert data["success"] is True
    assert data["action_type"] == "UPDATE"
    assert data["audit_log"]["action_type"] == "UPDATE"
    assert data["audit_log"]["username"] == "alex.smith"
    assert "Junior Staff" in data["audit_log"]["previous_value"]
    assert "Senior Staff" in data["audit_log"]["new_value"]

def test_simulation_delete(client):
    """Test DELETE /api/simulation/delete/{id} removes employee and records DELETE audit log."""
    # Insert employee to delete
    ins_payload = {
        "first_name": "Deletable",
        "last_name": "Candidate",
        "email": "deletable.candidate@example.com",
        "department_id": 1,
        "job_title": "Temp Associate",
        "salary": 50000.0,
        "status": "Active"
    }
    ins_resp = client.post("/api/simulation/insert", json=ins_payload)
    assert ins_resp.status_code == 201
    emp_id = ins_resp.json()["employee"]["id"]

    # Delete employee
    del_resp = client.delete(f"/api/simulation/delete/{emp_id}?acting_username=admin")
    assert del_resp.status_code == 200
    data = del_resp.json()
    assert data["success"] is True
    assert data["action_type"] == "DELETE"
    assert data["audit_log"]["action_type"] == "DELETE"
    assert "Deletable" in data["audit_log"]["previous_value"]

    # Updating the deleted employee now returns 404
    upd_deleted = client.put(f"/api/simulation/update/{emp_id}", json={"salary": 55000.0})
    assert upd_deleted.status_code == 404

def test_pdf_report_download(client):
    """Test GET /api/reports/download/pdf returns valid PDF file."""
    response = client.get("/api/reports/download/pdf")
    assert response.status_code == 200
    assert response.headers["content-type"] == "application/pdf"
    assert "attachment; filename=" in response.headers["content-disposition"]
    # PDF files start with %PDF- header magic bytes
    assert response.content.startswith(b"%PDF-")
    assert len(response.content) > 500

def test_csv_report_download(client):
    """Test GET /api/reports/download/csv returns valid CSV file with expected headers."""
    response = client.get("/api/reports/download/csv")
    assert response.status_code == 200
    assert "text/csv" in response.headers["content-type"]
    assert "attachment; filename=" in response.headers["content-disposition"]
    text = response.text
    assert "Audit ID,Timestamp (UTC),Username" in text
    assert "INSERT" in text or "UPDATE" in text or "DELETE" in text
