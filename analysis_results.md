# Resultados del analisis de planilla

Resultados de [analysis_queries.sql](analysis_queries.sql) sobre los datos de [seed_planilla_postgres.sql](seed_planilla_postgres.sql): empresa ficticia de software e implementacion de ERP, 27 empleados en 5 departamentos, 12 quincenas de enero a junio de 2026. Montos en cordobas (C$). INSS e IR son aproximados.

**Hallazgo principal:** en el semestre la empresa pago 4,199,259 C$ netos a sus empleados, pero su costo real fue de 6,603,945 C$ (bruto + aporte patronal), un 57.3 % mas que lo que llega al bolsillo de los empleados.

Para reproducirlo:

```bash
createdb planilla_pymes
psql -d planilla_pymes -f schema_planilla_pymes_postgres.sql
psql -d planilla_pymes -f seed_planilla_postgres.sql
psql -d planilla_pymes -f analysis_queries.sql
```

## 1. Costo de planilla por quincena y variacion contra la quincena anterior

El costo para la empresa por quincena se movió entre 526,666 y 563,813 C$. La caída de la primera quincena de junio (−4.88 %) coincide con la salida de un empleado de Desarrollo, y el salto de la segunda (+5.39 %) con los bonos de *go-live* y de *release*.

| numero | empleados | bruto | neto | costo_empresa | var_costo_pct |
| --- | --- | --- | --- | --- | --- |
| PLN-2026-01-Q1 | 25 | 446,566.66 | 348,731.72 | 542,578.53 |  |
| PLN-2026-01-Q2 | 25 | 452,869.16 | 351,329.42 | 550,236.08 | 1.41 |
| PLN-2026-02-Q1 | 25 | 448,203.75 | 344,770.83 | 544,567.61 | -1.03 |
| PLN-2026-02-Q2 | 25 | 453,097.92 | 349,871.11 | 550,514.01 | 1.09 |
| PLN-2026-03-Q1 | 25 | 464,043.32 | 355,616.04 | 563,812.67 | 2.42 |
| PLN-2026-03-Q2 | 25 | 457,022.91 | 353,103.32 | 555,282.89 | -1.51 |
| PLN-2026-04-Q1 | 25 | 449,804.84 | 346,966.40 | 546,512.92 | -1.58 |
| PLN-2026-04-Q2 | 25 | 463,479.16 | 355,016.39 | 563,127.23 | 3.04 |
| PLN-2026-05-Q1 | 25 | 454,225.84 | 354,134.38 | 551,884.44 | -2.00 |
| PLN-2026-05-Q2 | 25 | 455,713.75 | 353,208.73 | 553,692.24 | 0.33 |
| PLN-2026-06-Q1 | 24 | 433,470.00 | 335,744.03 | 526,666.10 | -4.88 |
| PLN-2026-06-Q2 | 24 | 456,847.91 | 350,766.77 | 555,070.26 | 5.39 |

## 2. Costo por departamento en el semestre y participacion en el total

Desarrollo de Software concentra el 39 % del costo con 9 personas y tiene el mayor costo por empleado. Implementación es el segundo bloque, con el 24 %.

| departamento | empleados_pagados | costo_empresa | pct_costo_total | costo_por_empleado |
| --- | --- | --- | --- | --- |
| Desarrollo de Software | 9 | 2,574,323.37 | 38.98 | 286,035.93 |
| Implementacion | 7 | 1,589,908.63 | 24.08 | 227,129.80 |
| Finanzas | 4 | 959,728.56 | 14.53 | 239,932.14 |
| IT | 4 | 788,163.30 | 11.93 | 197,040.83 |
| HR | 3 | 691,821.12 | 10.48 | 230,607.04 |

## 3. Evolucion mensual del costo por departamento (tabla pivote)

Finanzas y HR tienen un costo mensual constante porque no registran horas extra ni bonos. La variación viene de Implementación, IT y Desarrollo. IT baja de unos 141,600 a 117,100 C$ mensuales tras la salida de abril.

| mes | finanzas | hr | implementacion | it | desarrollo | total |
| --- | --- | --- | --- | --- | --- | --- |
| 2026-01 | 159,954.76 | 115,303.52 | 256,511.84 | 141,615.36 | 419,429.13 | 1,092,814.61 |
| 2026-02 | 159,954.76 | 115,303.52 | 264,063.06 | 139,330.14 | 416,430.14 | 1,095,081.62 |
| 2026-03 | 159,954.76 | 115,303.52 | 278,540.79 | 141,883.66 | 423,412.83 | 1,119,095.56 |
| 2026-04 | 159,954.76 | 115,303.52 | 265,224.90 | 131,098.32 | 438,058.65 | 1,109,640.15 |
| 2026-05 | 159,954.76 | 115,303.52 | 261,060.49 | 117,098.17 | 452,159.74 | 1,105,576.68 |
| 2026-06 | 159,954.76 | 115,303.52 | 264,507.55 | 117,137.65 | 424,832.88 | 1,081,736.36 |

## 4. Composicion del costo por concepto de nomina

El salario base es el 96.7 % de los ingresos; horas extra y bonos suman solo 3.3 %. El IR representa el 64 % de lo retenido al empleado, más que el INSS laboral.

| tipo | codigo | nombre | movimientos | monto_total | pct_del_tipo |
| --- | --- | --- | --- | --- | --- |
| ingreso | SALARIO | Salario base | 298 | 5,257,418.18 | 96.73 |
| ingreso | HEXTRA | Horas extra | 102 | 149,927.04 | 2.76 |
| ingreso | BONO | Bonificacion | 15 | 28,000.00 | 0.52 |
| deduccion | INSS | Seguro social laboral | 298 | 380,474.24 | 30.78 |
| deduccion | IR | Impuesto sobre la renta | 298 | 795,111.84 | 64.32 |
| deduccion | ADEL | Adelanto de salario | 14 | 27,500.00 | 2.22 |
| deduccion | PREST | Cuota de prestamo | 30 | 33,000.00 | 2.67 |
| aporte_patronal | INSS_PAT | Aporte patronal INSS | 298 | 1,168,599.76 | 100.00 |

## 5. Ranking salarial dentro de cada departamento

Las mayores brechas internas están en Finanzas, donde la gerencia gana 87.5 % más que el promedio del área y el auxiliar 55.3 % menos.

| departamento | ranking | codigo_empleado | cargo | salario_base | promedio_depto | vs_promedio_pct |
| --- | --- | --- | --- | --- | --- | --- |
| Desarrollo de Software | 1 | EMP-018 | Lider tecnico | 70,500.00 | 40,381.25 | 74.60 |
| Desarrollo de Software | 2 | EMP-019 | Desarrollador senior | 54,700.00 | 40,381.25 | 35.50 |
| Desarrollo de Software | 3 | EMP-020 | Desarrollador senior | 53,450.00 | 40,381.25 | 32.40 |
| Desarrollo de Software | 4 | EMP-022 | Desarrollador | 35,650.00 | 40,381.25 | -11.70 |
| Desarrollo de Software | 5 | EMP-021 | Desarrollador | 35,250.00 | 40,381.25 | -12.70 |
| Desarrollo de Software | 6 | EMP-024 | QA tester | 25,000.00 | 40,381.25 | -38.10 |
| Desarrollo de Software | 7 | EMP-027 | QA tester | 24,500.00 | 40,381.25 | -39.30 |
| Desarrollo de Software | 8 | EMP-025 | QA tester | 24,000.00 | 40,381.25 | -40.60 |
| Finanzas | 1 | EMP-001 | Gerente financiero | 61,700.00 | 32,912.50 | 87.50 |
| Finanzas | 2 | EMP-002 | Contador senior | 32,650.00 | 32,912.50 | -0.80 |
| Finanzas | 3 | EMP-003 | Contador | 22,600.00 | 32,912.50 | -31.30 |
| Finanzas | 4 | EMP-004 | Auxiliar contable | 14,700.00 | 32,912.50 | -55.30 |
| HR | 1 | EMP-005 | Gerente de recursos humanos | 53,200.00 | 31,633.33 | 68.20 |
| HR | 2 | EMP-006 | Especialista de planilla | 26,650.00 | 31,633.33 | -15.80 |
| HR | 3 | EMP-007 | Asistente de recursos humanos | 15,050.00 | 31,633.33 | -52.40 |
| IT | 1 | EMP-014 | Jefe de IT | 48,450.00 | 31,650.00 | 53.10 |
| IT | 2 | EMP-015 | Administrador de sistemas | 30,850.00 | 31,650.00 | -2.50 |
| IT | 3 | EMP-017 | Tecnico de soporte | 15,650.00 | 31,650.00 | -50.60 |
| Implementacion | 1 | EMP-008 | Gerente de implementacion | 56,950.00 | 34,650.00 | 64.40 |
| Implementacion | 2 | EMP-009 | Consultor funcional senior | 39,900.00 | 34,650.00 | 15.20 |
| Implementacion | 3 | EMP-010 | Consultor funcional senior | 38,450.00 | 34,650.00 | 11.00 |
| Implementacion | 4 | EMP-026 | Consultor funcional | 27,500.00 | 34,650.00 | -20.60 |
| Implementacion | 5 | EMP-012 | Consultor funcional | 26,650.00 | 34,650.00 | -23.10 |
| Implementacion | 6 | EMP-013 | Analista de soporte | 18,450.00 | 34,650.00 | -46.80 |

## 6. Horas extra: costo por departamento y empleados que mas acumulan

IT es el área donde las horas extra pesan más sobre el bruto (3.49 %), aunque su costo total es menor. Un técnico de soporte acumula 50 horas en el semestre, la cifra individual más alta.

| departamento | puesto | codigo_empleado | cargo | horas_extra | costo_horas_extra | costo_he_depto | pct_del_bruto_depto |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Desarrollo de Software | 1 | EMP-020 | Desarrollador senior | 43.00 | 19,152.91 | 43,139.58 | 2.04 |
| Desarrollo de Software | 2 | EMP-019 | Desarrollador senior | 32.00 | 14,586.67 | 43,139.58 | 2.04 |
| Desarrollo de Software | 3 | EMP-021 | Desarrollador | 32.00 | 9,400.00 | 43,139.58 | 2.04 |
| Implementacion | 1 | EMP-008 | Gerente de implementacion | 35.00 | 16,610.41 | 33,906.66 | 2.59 |
| Implementacion | 2 | EMP-010 | Consultor funcional senior | 27.00 | 8,651.25 | 33,906.66 | 2.59 |
| Implementacion | 3 | EMP-009 | Consultor funcional senior | 26.00 | 8,645.00 | 33,906.66 | 2.59 |
| IT | 1 | EMP-017 | Tecnico de soporte | 50.00 | 6,520.83 | 22,636.24 | 3.49 |
| IT | 2 | EMP-014 | Jefe de IT | 31.00 | 12,516.25 | 22,636.24 | 3.49 |
| IT | 3 | EMP-015 | Administrador de sistemas | 14.00 | 3,599.16 | 22,636.24 | 3.49 |

## 7. Rotacion de personal: altas, bajas y headcount por mes

Hubo 2 altas y 3 bajas con un headcount promedio de 24.5 personas: una rotación semestral de 12.24 %.

| mes | headcount_fin_mes | altas | bajas | rotacion_pct |
| --- | --- | --- | --- | --- |
| 2026-01 | 25 | 0 | 0 |  |
| 2026-02 | 24 | 0 | 1 |  |
| 2026-03 | 25 | 1 | 0 |  |
| 2026-04 | 25 | 1 | 1 |  |
| 2026-05 | 24 | 0 | 1 |  |
| 2026-06 | 24 | 0 | 0 |  |
| Semestre | 24.50 | 2 | 3 | 12.24 |

## 8. Ausentismo por departamento

HR tiene el ausentismo más alto (2.33 % de los días programados) y Desarrollo el más bajo (0.66 %).

| departamento | dias_programados | dias_ausentes | quincenas_con_ausencia | tasa_ausentismo_pct |
| --- | --- | --- | --- | --- |
| HR | 387.00 | 9.00 | 8 | 2.33 |
| Finanzas | 516.00 | 6.00 | 4 | 1.16 |
| Implementacion | 774.00 | 9.00 | 7 | 1.16 |
| IT | 459.00 | 5.00 | 4 | 1.09 |
| Desarrollo de Software | 1,064.00 | 7.00 | 6 | 0.66 |

## 9. Salary advances: monto otorgado, recuperado y saldo pendiente

De los 8 adelantos desembolsados, 7 están recuperados al 100 % y queda 1,500 C$ por recuperar. Hay una solicitud de 4,500 C$ pendiente de aprobación.

| situacion | adelantos | monto | recuperado | saldo_por_recuperar | pct_recuperado |
| --- | --- | --- | --- | --- | --- |
| En recuperacion | 1 | 3,000.00 | 1,500.00 | 1,500.00 | 50.00 |
| No desembolsado (anulado) | 1 | 2,000.00 |  |  |  |
| No desembolsado (solicitado) | 1 | 4,500.00 |  |  |  |
| Recuperado | 7 | 26,000.00 | 26,000.00 | 0.00 | 100.00 |

## 10. Prestamos: proyeccion de la fecha de cancelacion

El préstamo PREST-003 termina de pagarse hacia el 30 de noviembre de 2026 y PREST-001 hacia el 15 de agosto; PREST-002 ya está cancelado.

| referencia | codigo_empleado | cargo | monto_total | cuota_periodica | saldo_actual | pct_pagado | cuotas_restantes | fecha_estimada_cancelacion |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PREST-003 | EMP-021 | Desarrollador | 20,000.00 | 1,000.00 | 10,000.00 | 50.00 | 10 | 2026-11-30 |
| PREST-001 | EMP-002 | Contador senior | 30,000.00 | 1,250.00 | 3,750.00 | 87.50 | 3 | 2026-08-15 |
| PREST-002 | EMP-009 | Consultor funcional senior | 12,000.00 | 1,000.00 | 0.00 | 100.00 | 0 | Cancelado |

## Extra. Control de calidad: conciliacion del detalle contra los movimientos

La conciliación devuelve 0 filas: el detalle de cada empleado coincide con su desglose por concepto en las 298 líneas de planilla.

*Sin filas: no hay diferencias.*
