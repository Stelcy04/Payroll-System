# Bitacora de avance

## Fase inicial completada

Durante las primeras sesiones se avanzo en:

- definicion del esquema base de planilla para PYMES
- diseno funcional inicial
- creacion de backend con FastAPI
- creacion de persistencia local en JSON
- creacion de rutas para empleados, periodos, salary advances y planillas
- generacion basica de planilla
- repositorio de planillas con detalle por empleado
- importacion masiva de empleados desde Excel
- exportacion de reportes en PDF y Excel
- creacion de interfaz modular en `/workspace`

## Ajustes realizados

- correccion de errores en salary advances
- mejora de referencias automaticas para salary advances
- proteccion para no eliminar salary advances aplicados
- proteccion para no eliminar empleados con historial
- incorporacion de acciones de desactivar y archivar empleados
- separacion de pantallas por modulo

## Estado del proyecto hoy

El proyecto ya funciona como prototipo navegable y permite demostrar un flujo real de planilla.

## Pendientes inmediatos

- mejorar estados visuales en empleados
- aplicar la misma experiencia de subpantallas a todos los modulos
- fortalecer el motor de calculo automatico
- documentar formulas y reglas del negocio
