from datetime import datetime
from io import BytesIO

from openpyxl import Workbook

from app.routers.employees import EMPLOYEE_TEMPLATE_COLUMNS

VALID_ROW = ["E10", "Luis", "Chavez", "001", "1990-01-01", "2026-04-07", "l@x.com", "8888", "Managua",
             "Finanzas", "Analista", "permanent", "monthly", 14500]


def excel_file(rows):
    workbook = Workbook()
    sheet = workbook.active
    sheet.append(EMPLOYEE_TEMPLATE_COLUMNS)
    for row in rows:
        sheet.append(row)
    stream = BytesIO()
    workbook.save(stream)
    return {"file": ("employees.xlsx", stream.getvalue())}


def row(**changes):
    values = dict(zip(EMPLOYEE_TEMPLATE_COLUMNS, VALID_ROW))
    values.update(changes)
    return [values[column] for column in EMPLOYEE_TEMPLATE_COLUMNS]


def test_valid_file_creates_employees(client):
    response = client.post("/employees/bulk-excel", files=excel_file([row(), row(code="E11")]))

    assert response.status_code == 201
    assert response.json()["created_count"] == 2


# B5 ---------------------------------------------------------------------------

def test_invalid_row_does_not_block_valid_rows(client):
    rows = [row(code="E1"), row(code="E2", base_salary=None), row(code="E3", base_salary="catorce mil")]

    response = client.post("/employees/bulk-excel", files=excel_file(rows))

    assert response.status_code == 201
    body = response.json()
    assert body["created_count"] == 1
    assert body["invalid_count"] == 2
    assert [item["row"] for item in body["skipped"]] == [3, 4]
    assert all("base_salary" in item["errors"][0] for item in body["skipped"])


def test_duplicates_and_invalid_rows_are_both_reported(client):
    rows = [row(code="E1"), row(code="E1"), row(code="E2", position="")]

    body = client.post("/employees/bulk-excel", files=excel_file(rows)).json()

    assert body["created_count"] == 1
    assert body["skipped_count"] == 2
    assert body["invalid_count"] == 1


# B6 ---------------------------------------------------------------------------

def test_corrupt_file_returns_400(client):
    response = client.post("/employees/bulk-excel", files={"file": ("employees.xlsx", b"esto no es un excel")})

    assert response.status_code == 400


# B7 ---------------------------------------------------------------------------

def test_non_iso_date_is_rejected_and_report_keeps_working(client):
    rows = [row(code="E1"), row(code="E2", hire_date="07/04/2026")]

    body = client.post("/employees/bulk-excel", files=excel_file(rows)).json()

    assert body["created_count"] == 1
    assert "AAAA-MM-DD" in body["skipped"][0]["errors"][0]
    assert client.get("/employees/reports/hiring").status_code == 200


def test_real_excel_date_cells_are_accepted(client):
    rows = [row(code="E1", hire_date=datetime(2026, 4, 7), birth_date=datetime(1990, 1, 1))]

    body = client.post("/employees/bulk-excel", files=excel_file(rows)).json()

    assert body["created_count"] == 1
    assert body["created"][0]["hire_date"] == "2026-04-07"
