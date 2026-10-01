# Contributing

Gracias por querer aportar a este proyecto.

## Objetivo del proyecto

Este sistema busca construir una solucion de planilla para pequenas y medianas empresas, con procesos claros, interfaz modular y capacidad de automatizar calculos de nomina con la menor intervencion manual posible.

## Antes de contribuir

Se recomienda leer primero:

1. [README.md](README.md)
2. [funcional.md](funcional.md)
3. [tecnico.md](tecnico.md)
4. [roadmap.md](roadmap.md)

## Tipos de contribucion utiles

- correccion de errores
- mejoras de interfaz
- mejoras del motor de planilla
- reportes
- documentacion
- validaciones de negocio
- soporte para importacion o exportacion

## Reglas para contribuir

- no romper el flujo ya existente de empleados, periodos, salary advances o planillas
- preferir cambios pequenos y claros
- documentar cualquier cambio importante en `avance.md`
- mantener consistencia entre frontend, backend y documentacion
- si agregas una regla de negocio, explica por que existe

## Estructura basica del proyecto

- [backend](backend): API y frontend
- Documentacion: archivos `.md` en la raiz del repositorio
- [schema_planilla_pymes.sql](schema_planilla_pymes.sql): modelo SQL base

## Como proponer cambios

1. Identifica el modulo que vas a tocar.
2. Revisa si ya existe documentacion sobre ese modulo.
3. Realiza el cambio.
4. Verifica que no rompa el flujo actual.
5. Actualiza documentacion si aplica.

## Buenas practicas

- usar nombres claros
- evitar logica duplicada
- mantener los reportes consistentes
- preferir soluciones simples antes que complejas
- pensar siempre en el usuario final y en el area administrativa

## Ideas pendientes donde se puede colaborar

- prestamos a empleados
- asistencia
- vacaciones
- deducciones configurables
- autenticacion
- multiempresa
- aprobacion formal de planilla
- dashboard ejecutivo

## Nota final

La mejor contribucion no siempre es la mas grande. Una mejora pequena, bien hecha y bien documentada, vale mucho para el crecimiento del proyecto.
