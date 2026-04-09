# Publicacion en GitHub

## Recomendacion principal

No subas toda la carpeta `VillacodeR` completa, porque aqui hay archivos y carpetas que no pertenecen al sistema de planilla.

Lo correcto es publicar solo el proyecto de planilla.

## Que si debes subir

Sube estos archivos y carpetas en este orden:

1. [README.md](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\README.md)
2. [CONTRIBUTING.md](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\CONTRIBUTING.md)
3. [docs](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\docs)
4. [sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\sql)
5. [backend](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\backend)
6. [.gitignore](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\.gitignore)

## Que no debes subir

No subas estas carpetas o archivos al repositorio del sistema:

- [Página web](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\Página web)
- [sHOPIFY](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\sHOPIFY)
- [Día de mañana por la noche.docx](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\Día de mañana por la noche.docx)
- [Paper #2 - Perspectivas de los econ.md](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\Paper #2 - Perspectivas de los econ.md)
- [co.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\co.sql)
- [practicas de SQL.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\practicas de SQL.sql)
- [Prctica planilla.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\Prctica planilla.sql)
- [tablas planilla.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\tablas planilla.sql)
- [Valores de planilla.sql](C:\Users\Villa\OneDrive\Escritorio\VillacodeR\Valores de planilla.sql)

## Que carpetas locales deben quedar fuera

Estas deben mantenerse fuera del repositorio:

- `backend/data/`
- `.venv/`
- `__pycache__/`

## Estructura ideal a publicar

```text
/
|-- README.md
|-- CONTRIBUTING.md
|-- .gitignore
|-- docs/
|-- sql/
`-- backend/
```

## Orden sugerido si lo subes manualmente a GitHub web

1. Crea el repositorio vacio en GitHub.
2. Sube `README.md`.
3. Sube `CONTRIBUTING.md`.
4. Sube `.gitignore`.
5. Sube la carpeta `docs`.
6. Sube la carpeta `sql`.
7. Sube la carpeta `backend`.

## Orden sugerido si lo subes con Git

1. Inicializa Git en una carpeta limpia del proyecto.
2. Copia solo los archivos recomendados.
3. Revisa que `backend/data/` no este incluido.
4. Haz el primer commit.
5. Conecta el repositorio remoto.
6. Haz push.

## Consejo importante

Si quieres una publicacion mas profesional, crea una carpeta o repositorio nuevo llamado por ejemplo:

- `sistema-planilla-pymes`
- `payroll-pymes`
- `nomina-pymes`

Y mueve solo el proyecto de planilla ahi antes de publicarlo.
