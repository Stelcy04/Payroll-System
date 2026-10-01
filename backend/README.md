# Backend de planilla

Backend inicial para un sistema de planilla de pequenas y medianas empresas.

## Stack

- Python 3.11+
- FastAPI
- Pydantic para validacion
- Persistencia JSON para desarrollo local
- OpenPyXL para Excel y ReportLab para PDF

## Modulos incluidos

- Empleados
- Periodos de pago
- Salary advances
- Generacion basica de planilla
- Reportes y exportaciones PDF/Excel

## Ejecutar

Desde esta carpeta (`backend/`):

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Luego abre `http://127.0.0.1:8000/docs` para la API o `http://127.0.0.1:8000/workspace` para la interfaz.

## Pruebas

```bash
pip install -r requirements-dev.txt
python -m pytest
```

Las pruebas usan una base JSON temporal, asi que no modifican `data/payroll_dev.json`.

## Endpoints

### General

- `GET /health`

### Empleados

- `GET /employees`
- `POST /employees`
- `POST /employees/bulk`
- `POST /employees/bulk-excel`
- `GET /employees/template`
- `GET /employees/{employee_id}`
- `PATCH /employees/{employee_id}/deactivate`
- `PATCH /employees/{employee_id}/archive`
- `DELETE /employees/{employee_id}`
- `GET /employees/reports/hiring`
- `GET /employees/reports/hiring/export.xlsx`
- `GET /employees/reports/hiring/export.pdf`
- `GET /employees/export.xlsx`
- `GET /employees/export.pdf`

### Periodos

- `GET /periods`
- `POST /periods`
- `GET /periods/repository`
- `GET /periods/{period_id}`
- `GET /periods/export.xlsx`
- `GET /periods/export.pdf`

### Salary advances

- `GET /salary-advances`
- `POST /salary-advances`
- `GET /salary-advances/{advance_id}`
- `DELETE /salary-advances/{advance_id}`
- `GET /salary-advances/reports/created`
- `GET /salary-advances/reports/created/export.xlsx`
- `GET /salary-advances/reports/created/export.pdf`
- `GET /salary-advances/export.xlsx`
- `GET /salary-advances/export.pdf`

### Planillas

- `POST /payrolls/generate`
- `GET /payroll-runs`
- `GET /payroll-runs/{payroll_run_id}`
- `GET /payroll-runs/export.xlsx`
- `GET /payroll-runs/export.pdf`

## Nota

La persistencia local se crea automaticamente en `backend/data/payroll_dev.json`. El esquema SQL de MySQL esta en [schema_planilla_pymes.sql](../schema_planilla_pymes.sql) como modelo objetivo para produccion; la aplicacion todavia no se conecta a esa base.
