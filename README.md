# Sistema de Planilla para PYMES

Proyecto en construccion para administrar planilla de pequenas y medianas empresas.

## Estado actual

Hoy el proyecto ya cuenta con:

- base de datos modelo en SQL (MySQL) para una version mas completa
- backend en Python con FastAPI
- persistencia local en JSON para desarrollo
- modulo de empleados
- modulo de periodos
- modulo de salary advances
- generacion basica de planilla
- reportes en PDF y Excel
- importacion masiva de empleados desde Excel
- interfaz web modular en `/workspace`

## Ruta recomendada para leer la documentacion

1. [diseno funcional](sistema-planilla-diseno.md)
2. [guia funcional](funcional.md)
3. [guia tecnica](tecnico.md)
4. [bitacora de avance](avance.md)
5. [roadmap](roadmap.md)
6. [como contribuir](CONTRIBUTING.md)

## Como ejecutar el backend

Desde la carpeta [backend](backend):

```bash
python -m venv .venv
.venv\Scripts\activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

El servidor debe iniciarse desde `backend/`, porque la app busca la carpeta `app/static` de forma relativa.

## Pantallas principales

- `http://127.0.0.1:8000/docs`: documentacion interactiva de la API (Swagger)
- `http://127.0.0.1:8000/workspace`: interfaz modular

## Estructura principal

- [backend](backend): API FastAPI, persistencia local y frontend web
  - [app/routers](backend/app/routers): endpoints por modulo
  - [app/services](backend/app/services): calculo de planilla y exportaciones
  - [app/schemas](backend/app/schemas): validacion con Pydantic
  - [app/static](backend/app/static): interfaz web
- [schema_planilla_pymes.sql](schema_planilla_pymes.sql): esquema SQL base
- Documentacion funcional y tecnica: archivos `.md` en la raiz

La persistencia local se crea automaticamente en `backend/data/payroll_dev.json` y no se publica en el repositorio.

## Community

Si quieres colaborar en el proyecto, revisa primero [CONTRIBUTING.md](CONTRIBUTING.md).

Ese archivo explica:

- como entender el proyecto antes de aportar
- en que areas se puede colaborar
- reglas basicas para mantener consistencia
- buenas practicas para proponer cambios

## Objetivo del sistema

Construir un sistema capaz de generar planilla con la menor intervencion manual posible, dejando al usuario la validacion de casos especiales y excepciones del negocio.
