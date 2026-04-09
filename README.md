# Sistema de Planilla para PYMES

Proyecto en construccion para administrar planilla de pequenas y medianas empresas.

## Estado actual

Hoy el proyecto ya cuenta con:

- base de datos modelo en SQL para una version mas completa
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

1. [diseno funcional](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\sistema-planilla-diseno.md)
2. [guia funcional](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\funcional.md)
3. [guia tecnica](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\tecnico.md)
4. [bitacora de avance](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\avance.md)
5. [roadmap](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\roadmap.md)
6. [como contribuir](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\CONTRIBUTING.md)
7. [como publicarlo en GitHub](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs\publicacion-github.md)

## Como ejecutar el backend

Desde [backend](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend):

```bash
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

## Pantallas principales

- `http://127.0.0.1:8000/docs`
- `http://127.0.0.1:8000/workspace`

## Estructura principal

- [backend](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend): API, persistencia local y frontend web
- [docs](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs): documentacion funcional y tecnica
- [sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\sql): esquema SQL base

## Community

Si quieres colaborar en el proyecto, revisa primero [CONTRIBUTING.md](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\CONTRIBUTING.md).

Ese archivo explica:

- como entender el proyecto antes de aportar
- en que areas se puede colaborar
- reglas basicas para mantener consistencia
- buenas practicas para proponer cambios

## Objetivo del sistema

Construir un sistema capaz de generar planilla con la menor intervencion manual posible, dejando al usuario la validacion de casos especiales y excepciones del negocio.
