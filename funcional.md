# Guia funcional

## Vision general

El sistema busca cubrir los procesos principales de una planilla para PYMES:

- registrar empleados
- administrar periodos de pago
- registrar salary advances
- generar planilla
- exportar reportes

## Modulo de empleados

Actualmente permite:

- crear empleados manualmente
- cargar empleados masivamente desde Excel
- consultar el repositorio de empleados
- ver reporte de contrataciones
- exportar repositorio y reporte en PDF o Excel
- desactivar o archivar empleados con historial
- eliminar empleados sin movimientos

### Regla funcional importante

Un empleado con salary advances o historial de planilla no debe eliminarse. En esos casos se recomienda desactivarlo o archivarlo.

## Modulo de periodos

Actualmente permite:

- crear periodos
- consultar periodos abiertos
- consultar periodos cerrados
- consultar periodos futuros
- exportar el repositorio en PDF o Excel

## Modulo de salary advances

Actualmente permite:

- registrar salary advances
- consultar su repositorio
- consultar reporte mensual o quincenal
- exportar repositorio y reporte en PDF o Excel
- eliminar salary advances no aplicados

### Regla funcional importante

Si un salary advance ya fue aplicado en planilla, no debe eliminarse.

## Modulo de planillas

Actualmente permite:

- generar una planilla desde un periodo abierto
- consultar el repositorio de planillas generadas
- revisar el detalle por empleado
- exportar el repositorio en PDF o Excel

## Flujo funcional actual

1. Crear empleados.
2. Crear un periodo de pago.
3. Registrar salary advances si existen.
4. Generar la planilla.
5. Revisar el detalle.
6. Exportar reportes si es necesario.

## Casos que todavia no estan completos

- vacaciones
- incapacidades
- liquidaciones
- bonos y deducciones configurables
- prestamos a empleados
- aprobacion formal de planilla
- autenticacion y multiempresa
