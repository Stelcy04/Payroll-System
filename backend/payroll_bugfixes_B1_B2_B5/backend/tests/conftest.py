import pytest
from fastapi.testclient import TestClient

from app import db
from app.main import app


@pytest.fixture
def client(tmp_path, monkeypatch):
    """Cliente de prueba con una base JSON temporal y vacia para cada test."""
    monkeypatch.setattr(db, "DATA_DIR", tmp_path)
    monkeypatch.setattr(db, "DB_PATH", tmp_path / "payroll_test.json")
    with TestClient(app) as test_client:
        yield test_client


def create_employee(client, code="E1", base_salary=10000, **extra):
    payload = {
        "code": code,
        "first_name": "Ana",
        "last_name": "Mendez",
        "position": "Analista",
        "base_salary": base_salary,
        **extra,
    }
    response = client.post("/employees", json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def create_period(client, status="open", name="Abril Q1"):
    payload = {
        "name": name,
        "start_date": "2026-04-01",
        "end_date": "2026-04-15",
        "payment_date": "2026-04-15",
        "status": status,
    }
    response = client.post("/periods", json=payload)
    assert response.status_code == 201, response.text
    return response.json()


def create_advance(client, employee_id, amount, reference, request_date="2026-04-03", installments=1):
    payload = {
        "employee_id": employee_id,
        "reference": reference,
        "request_date": request_date,
        "amount_approved": amount,
        "balance_pending": amount,
        "installments_planned": installments,
        "status": "approved",
    }
    response = client.post("/salary-advances", json=payload)
    assert response.status_code == 201, response.text
    return response.json()
