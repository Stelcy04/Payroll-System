# Guia tecnica

## Stack actual

- Python 3.11
- FastAPI
- persistencia JSON local
- OpenPyXL para Excel
- ReportLab para PDF
- frontend estatico servido desde FastAPI

## Ubicaciones clave

- [main.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\main.py): punto de entrada
- [db.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\db.py): persistencia JSON
- [employees.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\routers\employees.py): empleados y reportes
- [periods.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\routers\periods.py): periodos
- [salary_advances.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\routers\salary_advances.py): salary advances
- [payroll.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\services\payroll.py): generacion basica de planilla
- [exports.py](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\services\exports.py): exportacion PDF y Excel
- [workspace.html](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\static\workspace.html): interfaz modular
- [workspace.css](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\static\workspace.css): estilos
- [workspace.js](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\app\static\workspace.js): logica frontend

## Persistencia actual

La persistencia de desarrollo vive en:

- [payroll_dev.json](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend\data\payroll_dev.json)

Colecciones actuales:

- `employees`
- `payroll_periods`
- `salary_advances`
- `payroll_runs`
- `payroll_run_details`

## Endpoints importantes

### Empleados

- `GET /employees`
- `POST /employees`
- `POST /employees/bulk-excel`
- `PATCH /employees/{employee_id}/deactivate`
- `PATCH /employees/{employee_id}/archive`
- `DELETE /employees/{employee_id}`
- `GET /employees/reports/hiring`
- `GET /employees/export.xlsx`
- `GET /employees/export.pdf`

### Periodos

- `GET /periods`
- `POST /periods`
- `GET /periods/repository`
- `GET /periods/export.xlsx`
- `GET /periods/export.pdf`

### Salary advances

- `GET /salary-advances`
- `POST /salary-advances`
- `DELETE /salary-advances/{advance_id}`
- `GET /salary-advances/reports/created`
- `GET /salary-advances/export.xlsx`
- `GET /salary-advances/export.pdf`

### Planillas

- `POST /payrolls/generate`
- `GET /payroll-runs`
- `GET /payroll-runs/{payroll_run_id}`
- `GET /payroll-runs/export.xlsx`
- `GET /payroll-runs/export.pdf`

## Decision tecnica importante

El proyecto tiene dos niveles de modelo:

- un modelo SQL mas completo y escalable en [schema_planilla_pymes.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\sql\schema_planilla_pymes.sql)
- una persistencia JSON simple para desarrollo y prototipado rapido

## Riesgos tecnicos actuales

- no hay autenticacion
- no hay control multiempresa real en la UI
- la persistencia JSON no es ideal para produccion
- el motor de calculo de planilla aun es basico
- faltan reglas legales avanzadas
