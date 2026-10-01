# Backend de planilla

Backend inicial para un sistema de planilla de pequenas y medianas empresas.

## Stack

- Python 3.11+
- FastAPI
- Persistencia JSON para desarrollo local

## Modulos incluidos

- Empleados
- Periodos de pago
- Salary advances
- Generacion basica de planilla

## Ejecutar

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

## Endpoints principales

- `GET /health`
- `GET /employees`
- `POST /employees`
- `GET /periods`
- `POST /periods`
- `GET /salary-advances`
- `POST /salary-advances`
- `POST /payrolls/generate`

## Nota

La persistencia local se crea automaticamente en `backend/data/payroll_dev.json`. El esquema SQL de MySQL sigue en `sql/schema_planilla_pymes.sql` como modelo principal para produccion.
