# Sistema de planilla para PYMES

## Objetivo

Construir un sistema de planilla claro, mantenible y listo para crecer desde una pequeña empresa hasta una mediana empresa sin rehacer la base de datos.

## Modulos iniciales

1. Empresas y usuarios
2. Empleados y departamentos
3. Periodos de pago
4. Planillas y detalle por empleado
5. Ingresos, deducciones y aportes
6. Prestamos y adelantos
7. Asistencia resumida
8. Reportes y cierres

## Flujo funcional recomendado

1. Registrar la empresa.
2. Crear usuarios con roles.
3. Registrar empleados y asignar departamento, cargo y tipo de pago.
4. Abrir un periodo de pago.
5. Cargar asistencia, horas extra, bonos, adelantos o prestamos.
6. Registrar salary advances aprobados antes del cierre si aplica.
7. Generar la planilla.
8. Revisar el detalle por empleado.
9. Aprobar, pagar y cerrar el periodo.

## Tablas clave

- `empresas`: datos generales de cada cliente o negocio.
- `usuarios`: acceso al sistema por empresa y por rol.
- `departamentos`: organizacion interna.
- `empleados`: expediente basico del colaborador.
- `periodos_pago`: controla el rango de fechas y el estado del proceso.
- `conceptos_nomina`: catalogo configurable para ingresos y deducciones.
- `planillas`: encabezado general de la corrida.
- `planilla_detalle`: resultado por empleado.
- `planilla_movimientos`: desglose de cada concepto aplicado.
- `salary_advances`: adelantos salariales solicitados o aprobados antes de la planilla.
- `prestamos_empleado`: control de saldo y cuota.
- `asistencia_resumen`: base para calculos de horas y ausencias.

## Por que esta estructura ayuda

- Evita meter todas las deducciones como columnas fijas.
- Permite agregar nuevos conceptos sin cambiar la tabla principal.
- Separa el encabezado de la planilla del detalle por trabajador.
- Permite controlar adelantos salariales por separado antes de descontarlos en planilla.
- Facilita reportes por empresa, periodo, empleado o concepto.
- Deja listo el camino para API, panel web o exportacion a Excel/PDF.

## Siguiente etapa recomendada

La mejor siguiente fase es construir estas 4 piezas en orden:

1. CRUD de empleados
2. CRUD de periodos de pago
3. Modulo de salary advance y otros movimientos variables
4. Generador de planilla con calculo automatico
5. Modulo de prestamos a empleados

## Regla importante

Las formulas legales y fiscales conviene dejarlas configurables por pais o empresa. Asi evitamos amarrar el sistema a una sola legislacion desde el inicio.
