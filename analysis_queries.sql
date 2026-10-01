-- =============================================================================
-- Analisis de planilla - consultas para PostgreSQL 16+
--
-- Requiere: schema_planilla_pymes_postgres.sql + seed_planilla_postgres.sql
-- Uso:      psql -d planilla_pymes -f analysis_queries.sql
--
-- Cada consulta indica la pregunta de negocio, la tecnica SQL y como leer
-- el resultado. Definiciones usadas en todo el archivo:
--   bruto        = salario_bruto (salario del periodo + horas extra + bonos)
--   neto         = lo que recibe el empleado (bruto - INSS - IR - adelantos - prestamos)
--   costo empresa = bruto + aporte patronal (lo que realmente le cuesta a la empresa)
-- =============================================================================
SET search_path TO planilla;


-- -----------------------------------------------------------------------------
-- 1. Costo de planilla por quincena y variacion contra la quincena anterior
-- Pregunta: cuanto cuesta cada planilla y como cambia de un periodo a otro?
-- Tecnica:  JOIN + GROUP BY + funcion de ventana LAG
-- Lectura:  var_costo_pct muestra el crecimiento o caida contra la quincena previa.
-- -----------------------------------------------------------------------------
WITH costo AS (
    SELECT
        pp.fecha_inicio,
        pl.numero,
        COUNT(*)                                       AS empleados,
        SUM(d.salario_bruto)                           AS bruto,
        SUM(d.deducciones)                             AS deducciones,
        SUM(d.salario_neto)                            AS neto,
        SUM(d.aportes_patronales)                      AS aporte_patronal,
        SUM(d.salario_bruto + d.aportes_patronales)    AS costo_empresa
    FROM planillas pl
    JOIN periodos_pago pp    ON pp.id = pl.periodo_id
    JOIN planilla_detalle d  ON d.planilla_id = pl.id
    GROUP BY pp.fecha_inicio, pl.numero
)
SELECT
    numero,
    empleados,
    bruto,
    neto,
    costo_empresa,
    ROUND(100.0 * (costo_empresa - LAG(costo_empresa) OVER (ORDER BY fecha_inicio))
          / LAG(costo_empresa) OVER (ORDER BY fecha_inicio), 2) AS var_costo_pct
FROM costo
ORDER BY fecha_inicio;


-- -----------------------------------------------------------------------------
-- 2. Costo por departamento en el semestre y participacion en el total
-- Pregunta: que departamentos concentran el gasto de planilla?
-- Tecnica:  agregacion + SUM() OVER () para el porcentaje del total
-- Lectura:  pct_costo_total suma 100 %; costo_por_empleado normaliza por tamano.
-- -----------------------------------------------------------------------------
SELECT
    dep.nombre                                              AS departamento,
    COUNT(DISTINCT d.empleado_id)                           AS empleados_pagados,
    SUM(d.salario_bruto + d.aportes_patronales)             AS costo_empresa,
    ROUND(100.0 * SUM(d.salario_bruto + d.aportes_patronales)
          / SUM(SUM(d.salario_bruto + d.aportes_patronales)) OVER (), 2) AS pct_costo_total,
    ROUND(SUM(d.salario_bruto + d.aportes_patronales)
          / COUNT(DISTINCT d.empleado_id), 2)               AS costo_por_empleado
FROM planilla_detalle d
JOIN empleados e      ON e.id = d.empleado_id
JOIN departamentos dep ON dep.id = e.departamento_id
GROUP BY dep.nombre
ORDER BY costo_empresa DESC;


-- -----------------------------------------------------------------------------
-- 3. Evolucion mensual del costo por departamento (tabla pivote)
-- Pregunta: como evoluciona el costo de cada area mes a mes?
-- Tecnica:  DATE_TRUNC para pasar de quincenas a meses + SUM ... FILTER para pivotear
-- Lectura:  una fila por mes, una columna por departamento.
-- -----------------------------------------------------------------------------
SELECT
    TO_CHAR(DATE_TRUNC('month', pp.fecha_inicio), 'YYYY-MM')                          AS mes,
    SUM(d.salario_bruto + d.aportes_patronales) FILTER (WHERE dep.nombre = 'Finanzas')               AS finanzas,
    SUM(d.salario_bruto + d.aportes_patronales) FILTER (WHERE dep.nombre = 'HR')                     AS hr,
    SUM(d.salario_bruto + d.aportes_patronales) FILTER (WHERE dep.nombre = 'Implementacion')         AS implementacion,
    SUM(d.salario_bruto + d.aportes_patronales) FILTER (WHERE dep.nombre = 'IT')                     AS it,
    SUM(d.salario_bruto + d.aportes_patronales) FILTER (WHERE dep.nombre = 'Desarrollo de Software') AS desarrollo,
    SUM(d.salario_bruto + d.aportes_patronales)                                                      AS total
FROM planilla_detalle d
JOIN planillas pl      ON pl.id = d.planilla_id
JOIN periodos_pago pp  ON pp.id = pl.periodo_id
JOIN empleados e       ON e.id = d.empleado_id
JOIN departamentos dep ON dep.id = e.departamento_id
GROUP BY DATE_TRUNC('month', pp.fecha_inicio)
ORDER BY mes;


-- -----------------------------------------------------------------------------
-- 4. Composicion del costo por concepto de nomina
-- Pregunta: cuanto del gasto es salario, horas extra o bonos, y cuanto se retiene?
-- Tecnica:  JOIN con la tabla puente planilla_movimientos + porcentaje por tipo
-- Lectura:  pct_del_tipo compara conceptos dentro de ingresos, deducciones o aportes.
-- -----------------------------------------------------------------------------
SELECT
    c.tipo,
    c.codigo,
    c.nombre,
    COUNT(*)        AS movimientos,
    SUM(m.monto)    AS monto_total,
    ROUND(100.0 * SUM(m.monto) / SUM(SUM(m.monto)) OVER (PARTITION BY c.tipo), 2) AS pct_del_tipo
FROM planilla_movimientos m
JOIN conceptos_nomina c ON c.id = m.concepto_id
GROUP BY c.tipo, c.codigo, c.nombre, c.orden_impresion
ORDER BY c.tipo, c.orden_impresion;


-- -----------------------------------------------------------------------------
-- 5. Ranking salarial dentro de cada departamento
-- Pregunta: quien gana mas en cada area y que tan lejos esta del promedio?
-- Tecnica:  RANK() y AVG() OVER (PARTITION BY ...)
-- Lectura:  vs_promedio_pct > 0 = por encima del promedio de su departamento.
-- -----------------------------------------------------------------------------
SELECT
    dep.nombre                                                         AS departamento,
    RANK() OVER (PARTITION BY dep.id ORDER BY e.salario_base DESC)     AS ranking,
    e.codigo_empleado,
    e.cargo,
    e.salario_base,
    ROUND(AVG(e.salario_base) OVER (PARTITION BY dep.id), 2)           AS promedio_depto,
    ROUND(100.0 * (e.salario_base / AVG(e.salario_base) OVER (PARTITION BY dep.id) - 1), 1) AS vs_promedio_pct
FROM empleados e
JOIN departamentos dep ON dep.id = e.departamento_id
WHERE e.activo
ORDER BY dep.nombre, ranking;


-- -----------------------------------------------------------------------------
-- 6. Horas extra: costo por departamento y empleados que mas acumulan
-- Pregunta: donde se concentra el sobretiempo y cuanto cuesta?
-- Tecnica:  CTE + ROW_NUMBER() para el top 3 de cada departamento
-- Lectura:  pct_del_bruto_depto indica cuanto pesan las horas extra en el area.
-- -----------------------------------------------------------------------------
WITH horas AS (
    SELECT
        dep.nombre                 AS departamento,
        e.codigo_empleado,
        e.cargo,
        SUM(d.horas_extras)        AS horas_extra,
        SUM(m.monto)               AS costo_horas_extra
    FROM planilla_detalle d
    JOIN empleados e              ON e.id = d.empleado_id
    JOIN departamentos dep        ON dep.id = e.departamento_id
    JOIN planilla_movimientos m   ON m.detalle_id = d.id
    JOIN conceptos_nomina c       ON c.id = m.concepto_id AND c.codigo = 'HEXTRA'
    GROUP BY dep.nombre, e.codigo_empleado, e.cargo
),
bruto_depto AS (
    SELECT dep.nombre AS departamento, SUM(d.salario_bruto) AS bruto
    FROM planilla_detalle d
    JOIN empleados e       ON e.id = d.empleado_id
    JOIN departamentos dep ON dep.id = e.departamento_id
    GROUP BY dep.nombre
),
ranking AS (
    SELECT h.*, ROW_NUMBER() OVER (PARTITION BY h.departamento ORDER BY h.horas_extra DESC, h.codigo_empleado) AS puesto
    FROM horas h
)
SELECT
    r.departamento,
    r.puesto,
    r.codigo_empleado,
    r.cargo,
    r.horas_extra,
    r.costo_horas_extra,
    SUM(r.costo_horas_extra) OVER (PARTITION BY r.departamento)                         AS costo_he_depto,
    ROUND(100.0 * SUM(r.costo_horas_extra) OVER (PARTITION BY r.departamento) / b.bruto, 2) AS pct_del_bruto_depto
FROM ranking r
JOIN bruto_depto b ON b.departamento = r.departamento
WHERE r.puesto <= 3
ORDER BY costo_he_depto DESC, r.puesto;


-- -----------------------------------------------------------------------------
-- 7. Rotacion de personal: altas, bajas y headcount por mes
-- Pregunta: cuanta gente entra y sale, y cual es la tasa de rotacion?
-- Tecnica:  generate_series para crear el calendario + subconsultas correlacionadas
-- Lectura:  rotacion semestral = bajas / headcount promedio (ultima fila).
-- -----------------------------------------------------------------------------
WITH meses AS (
    SELECT generate_series(DATE '2026-01-01', DATE '2026-06-01', INTERVAL '1 month')::date AS inicio
),
movimiento AS (
    SELECT
        m.inicio,
        (SELECT COUNT(*) FROM empleados e
          WHERE e.fecha_ingreso <= (m.inicio + INTERVAL '1 month - 1 day')
            AND (e.fecha_salida IS NULL OR e.fecha_salida >= (m.inicio + INTERVAL '1 month - 1 day'))) AS headcount_fin_mes,
        (SELECT COUNT(*) FROM empleados e
          WHERE DATE_TRUNC('month', e.fecha_ingreso) = m.inicio) AS altas,
        (SELECT COUNT(*) FROM empleados e
          WHERE DATE_TRUNC('month', e.fecha_salida) = m.inicio)  AS bajas
    FROM meses m
)
SELECT TO_CHAR(inicio, 'YYYY-MM') AS mes, headcount_fin_mes, altas, bajas, NULL::numeric AS rotacion_pct
FROM movimiento
UNION ALL
SELECT 'Semestre', ROUND(AVG(headcount_fin_mes), 1), SUM(altas), SUM(bajas),
       ROUND(100.0 * SUM(bajas) / AVG(headcount_fin_mes), 2)
FROM movimiento
ORDER BY mes;


-- -----------------------------------------------------------------------------
-- 8. Ausentismo por departamento
-- Pregunta: que areas pierden mas dias de trabajo por ausencias?
-- Tecnica:  agregacion sobre asistencia_resumen + NULLIF para evitar division entre cero
-- Lectura:  tasa_ausentismo_pct = dias ausentes / dias programados.
-- -----------------------------------------------------------------------------
SELECT
    dep.nombre                                  AS departamento,
    SUM(a.dias_trabajados + a.dias_ausentes)    AS dias_programados,
    SUM(a.dias_ausentes)                        AS dias_ausentes,
    COUNT(*) FILTER (WHERE a.dias_ausentes > 0) AS quincenas_con_ausencia,
    ROUND(100.0 * SUM(a.dias_ausentes)
          / NULLIF(SUM(a.dias_trabajados + a.dias_ausentes), 0), 2) AS tasa_ausentismo_pct
FROM asistencia_resumen a
JOIN empleados e       ON e.id = a.empleado_id
JOIN departamentos dep ON dep.id = e.departamento_id
GROUP BY dep.nombre
ORDER BY tasa_ausentismo_pct DESC;


-- -----------------------------------------------------------------------------
-- 9. Salary advances: monto otorgado, recuperado y saldo pendiente
-- Pregunta: cuanto dinero adelantado sigue sin recuperarse?
-- Tecnica:  CASE para agrupar estados + porcentaje de recuperacion
-- Lectura:  solo los adelantos aprobados cuentan como dinero entregado;
--           'solicitado' y 'anulado' no salieron de caja.
-- -----------------------------------------------------------------------------
SELECT
    CASE
        WHEN sa.estado IN ('solicitado', 'anulado') THEN 'No desembolsado (' || sa.estado || ')'
        WHEN sa.saldo_pendiente = 0                 THEN 'Recuperado'
        ELSE 'En recuperacion'
    END                                                        AS situacion,
    COUNT(*)                                                   AS adelantos,
    SUM(sa.monto_aprobado)                                     AS monto,
    SUM(sa.monto_aprobado - sa.saldo_pendiente)
        FILTER (WHERE sa.estado NOT IN ('solicitado', 'anulado')) AS recuperado,
    SUM(sa.saldo_pendiente)
        FILTER (WHERE sa.estado NOT IN ('solicitado', 'anulado')) AS saldo_por_recuperar,
    ROUND(100.0 * SUM(sa.monto_aprobado - sa.saldo_pendiente)
                      FILTER (WHERE sa.estado NOT IN ('solicitado', 'anulado'))
          / NULLIF(SUM(sa.monto_aprobado)
                      FILTER (WHERE sa.estado NOT IN ('solicitado', 'anulado')), 0), 1) AS pct_recuperado
FROM salary_advances sa
GROUP BY 1
ORDER BY 1;


-- -----------------------------------------------------------------------------
-- 10. Prestamos: proyeccion de la fecha de cancelacion
-- Pregunta: cuando termina de pagar cada empleado su prestamo?
-- Tecnica:  CEIL para cuotas restantes + aritmetica de fechas (2 cuotas por mes)
-- Lectura:  fecha_estimada asume una cuota por quincena desde julio de 2026.
-- -----------------------------------------------------------------------------
SELECT
    pr.referencia,
    e.codigo_empleado,
    e.cargo,
    pr.monto_total,
    pr.cuota_periodica,
    pr.saldo_actual,
    ROUND(100.0 * (pr.monto_total - pr.saldo_actual) / pr.monto_total, 1) AS pct_pagado,
    CEIL(pr.saldo_actual / pr.cuota_periodica)::int                      AS cuotas_restantes,
    CASE
        WHEN pr.saldo_actual = 0 THEN 'Cancelado'
        ELSE TO_CHAR(DATE '2026-07-01'
                     + (CEIL(pr.saldo_actual / pr.cuota_periodica)::int / 2) * INTERVAL '1 month'
                     + CASE WHEN CEIL(pr.saldo_actual / pr.cuota_periodica)::int % 2 = 1
                            THEN INTERVAL '14 days' ELSE INTERVAL '-1 day' END,
                     'YYYY-MM-DD')
    END                                                                   AS fecha_estimada_cancelacion
FROM prestamos_empleado pr
JOIN empleados e ON e.id = pr.empleado_id
ORDER BY pr.saldo_actual DESC;


-- -----------------------------------------------------------------------------
-- Extra. Control de calidad: conciliacion del detalle contra los movimientos
-- Pregunta: los totales de cada empleado coinciden con el desglose por concepto?
-- Tecnica:  agregacion condicional + HAVING para mostrar solo las diferencias
-- Lectura:  el resultado esperado es CERO filas. Cualquier fila es un error de datos.
-- -----------------------------------------------------------------------------
SELECT
    pl.numero,
    e.codigo_empleado,
    d.ingresos,
    SUM(m.monto) FILTER (WHERE c.tipo = 'ingreso')                  AS ingresos_movimientos,
    d.deducciones,
    COALESCE(SUM(m.monto) FILTER (WHERE c.tipo = 'deduccion'), 0)   AS deducciones_movimientos
FROM planilla_detalle d
JOIN planillas pl            ON pl.id = d.planilla_id
JOIN empleados e             ON e.id = d.empleado_id
JOIN planilla_movimientos m  ON m.detalle_id = d.id
JOIN conceptos_nomina c      ON c.id = m.concepto_id
GROUP BY pl.numero, e.codigo_empleado, d.id
HAVING d.ingresos    <> SUM(m.monto) FILTER (WHERE c.tipo = 'ingreso')
    OR d.deducciones <> COALESCE(SUM(m.monto) FILTER (WHERE c.tipo = 'deduccion'), 0);
