from tests.conftest import create_advance, create_employee, create_period


def generate(client, period_id):
    return client.post("/payrolls/generate", json={"period_id": period_id})


def test_basic_payroll_discounts_advance(client):
    employee = create_employee(client, base_salary=18000)
    create_advance(client, employee["id"], 500, "SA-1")
    period = create_period(client)

    response = generate(client, period["id"])

    assert response.status_code == 201
    result = response.json()["employees"][0]
    assert result["gross_salary"] == 18000
    assert result["salary_advance_discount"] == 500
    assert result["net_salary"] == 17500
    assert client.get(f"/periods/{period['id']}").json()["status"] == "calculated"


# B1 ---------------------------------------------------------------------------

def test_net_salary_is_never_negative(client):
    employee = create_employee(client, base_salary=5000)
    advance = create_advance(client, employee["id"], 9000, "SA-1", installments=3)
    period = create_period(client)

    result = generate(client, period["id"]).json()["employees"][0]

    assert result["salary_advance_discount"] == 5000
    assert result["net_salary"] == 0

    pending = client.get(f"/salary-advances/{advance['id']}").json()
    assert pending["balance_pending"] == 4000
    assert pending["status"] == "approved"
    assert pending["installments_paid"] == 1


def test_remaining_balance_is_discounted_in_next_payroll(client):
    employee = create_employee(client, base_salary=5000)
    advance = create_advance(client, employee["id"], 9000, "SA-1", installments=2)
    first = create_period(client, name="Abril Q1")
    generate(client, first["id"])

    second = client.post(
        "/periods",
        json={"name": "Abril Q2", "start_date": "2026-04-16", "end_date": "2026-04-30", "payment_date": "2026-04-30"},
    ).json()
    result = generate(client, second["id"]).json()["employees"][0]

    assert result["salary_advance_discount"] == 4000
    assert result["net_salary"] == 1000
    final = client.get(f"/salary-advances/{advance['id']}").json()
    assert final["balance_pending"] == 0
    assert final["status"] == "discounted"
    assert final["installments_paid"] == 2


def test_oldest_advance_is_applied_first(client):
    employee = create_employee(client, base_salary=1000)
    newer = create_advance(client, employee["id"], 800, "SA-NEW", request_date="2026-04-10")
    older = create_advance(client, employee["id"], 700, "SA-OLD", request_date="2026-04-01")
    period = create_period(client)

    generate(client, period["id"])

    assert client.get(f"/salary-advances/{older['id']}").json()["status"] == "discounted"
    assert client.get(f"/salary-advances/{newer['id']}").json()["balance_pending"] == 500


def test_partially_applied_advance_cannot_be_deleted(client):
    employee = create_employee(client, base_salary=5000)
    advance = create_advance(client, employee["id"], 9000, "SA-1", installments=3)
    generate(client, create_period(client)["id"])

    response = client.delete(f"/salary-advances/{advance['id']}")

    assert response.status_code == 409


# B2 ---------------------------------------------------------------------------

def test_cannot_generate_payroll_for_closed_period(client):
    create_employee(client)
    period = create_period(client, status="closed")

    response = generate(client, period["id"])

    assert response.status_code == 409
    assert "abierto" in response.json()["detail"]
    assert client.get("/payroll-runs").json() == []


def test_cannot_generate_payroll_for_future_period(client):
    create_employee(client)
    period = create_period(client, status="future")

    assert generate(client, period["id"]).status_code == 409


def test_second_generation_reports_duplicate(client):
    create_employee(client)
    period = create_period(client)
    assert generate(client, period["id"]).status_code == 201

    response = generate(client, period["id"])

    assert response.status_code == 409
    assert "ya fue generada" in response.json()["detail"]
