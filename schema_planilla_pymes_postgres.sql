-- =============================================================================
-- Sistema de planilla para PYMES - esquema PostgreSQL (16+)
-- Migrado desde schema_planilla_pymes.sql (MySQL/InnoDB).
--
-- Cambios principales respecto a la version MySQL:
--   * AUTO_INCREMENT          -> GENERATED ALWAYS AS IDENTITY
--   * ENUM en linea           -> tipos ENUM propios (CREATE TYPE)
--   * TINYINT(1)              -> BOOLEAN
--   * DECIMAL                 -> NUMERIC
--   * ON UPDATE TIMESTAMP     -> trigger set_updated_at()
--   * Indices explicitos en claves foraneas (PostgreSQL no los crea solo)
--   * Reglas nuevas de integridad: CHECK, FK compuestas por empresa y
--     EXCLUDE para impedir periodos de pago solapados.
--
-- Uso:
--   createdb planilla_pymes
--   psql -d planilla_pymes -f schema_planilla_pymes_postgres.sql
--
-- El script falla si el esquema ya existe, para no borrar datos por error.
-- Para empezar de cero de forma intencional:
--   DROP SCHEMA planilla CASCADE;
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS btree_gist;  -- necesario para el EXCLUDE de periodos

CREATE SCHEMA planilla;
SET search_path TO planilla;

-- -----------------------------------------------------------------------------
-- Tipos ENUM
-- -----------------------------------------------------------------------------
CREATE TYPE estado_empresa        AS ENUM ('activa', 'inactiva');
CREATE TYPE rol_usuario           AS ENUM ('admin', 'rrhh', 'contador', 'consulta');
CREATE TYPE estado_usuario        AS ENUM ('activo', 'bloqueado');
CREATE TYPE tipo_pago             AS ENUM ('mensual', 'quincenal', 'semanal', 'por_hora');
CREATE TYPE frecuencia_periodo    AS ENUM ('semanal', 'quincenal', 'mensual', 'extraordinaria');
CREATE TYPE estado_periodo        AS ENUM ('abierto', 'calculado', 'cerrado', 'anulado');
CREATE TYPE tipo_concepto         AS ENUM ('ingreso', 'deduccion', 'aporte_patronal', 'informativo');
CREATE TYPE naturaleza_concepto   AS ENUM ('fijo', 'variable', 'formula');
CREATE TYPE estado_planilla       AS ENUM ('borrador', 'calculada', 'aprobada', 'pagada', 'anulada');
CREATE TYPE estado_salary_advance AS ENUM ('solicitado', 'aprobado', 'entregado', 'descontado', 'anulado');
CREATE TYPE estado_prestamo       AS ENUM ('activo', 'cancelado');

-- -----------------------------------------------------------------------------
-- updated_at automatico (reemplaza ON UPDATE CURRENT_TIMESTAMP de MySQL)
-- -----------------------------------------------------------------------------
CREATE FUNCTION set_updated_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- -----------------------------------------------------------------------------
-- Empresas y usuarios
-- -----------------------------------------------------------------------------
CREATE TABLE empresas (
    id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre      VARCHAR(150) NOT NULL,
    ruc         VARCHAR(50),
    telefono    VARCHAR(30),
    correo      VARCHAR(150),
    direccion   TEXT,
    moneda      CHAR(3) NOT NULL DEFAULT 'NIO',
    estado      estado_empresa NOT NULL DEFAULT 'activa',
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE usuarios (
    id             BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id     BIGINT NOT NULL REFERENCES empresas (id),
    nombre         VARCHAR(100) NOT NULL,
    email          VARCHAR(150) NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    rol            rol_usuario NOT NULL DEFAULT 'rrhh',
    estado         estado_usuario NOT NULL DEFAULT 'activo',
    ultimo_acceso  TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_usuarios_email_empresa UNIQUE (empresa_id, email)
);

-- -----------------------------------------------------------------------------
-- Organizacion y empleados
-- -----------------------------------------------------------------------------
CREATE TABLE departamentos (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id   BIGINT NOT NULL REFERENCES empresas (id),
    nombre       VARCHAR(100) NOT NULL,
    descripcion  VARCHAR(255),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_departamento_empresa_nombre UNIQUE (empresa_id, nombre),
    -- Permite que otras tablas exijan "departamento de la MISMA empresa"
    CONSTRAINT uk_departamento_empresa_id UNIQUE (empresa_id, id)
);

CREATE TABLE empleados (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id        BIGINT NOT NULL REFERENCES empresas (id),
    departamento_id   BIGINT,
    codigo_empleado   VARCHAR(30) NOT NULL,
    nombres           VARCHAR(100) NOT NULL,
    apellidos         VARCHAR(100) NOT NULL,
    cedula            VARCHAR(25),
    fecha_nacimiento  DATE,
    fecha_ingreso     DATE NOT NULL,
    fecha_salida      DATE,
    telefono          VARCHAR(30),
    correo            VARCHAR(150),
    direccion         TEXT,
    cargo             VARCHAR(100) NOT NULL,
    tipo_pago         tipo_pago NOT NULL DEFAULT 'mensual',
    salario_base      NUMERIC(12,2) NOT NULL,
    activo            BOOLEAN NOT NULL DEFAULT true,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_empleado_empresa_codigo UNIQUE (empresa_id, codigo_empleado),
    CONSTRAINT uk_empleado_empresa_cedula UNIQUE (empresa_id, cedula),
    CONSTRAINT uk_empleado_empresa_id     UNIQUE (empresa_id, id),
    -- FK compuesta: el departamento debe pertenecer a la misma empresa (antes S1)
    CONSTRAINT fk_empleados_departamento
        FOREIGN KEY (empresa_id, departamento_id) REFERENCES departamentos (empresa_id, id),
    CONSTRAINT ck_empleado_salario_positivo CHECK (salario_base > 0),          -- antes S2
    CONSTRAINT ck_empleado_fecha_salida     CHECK (fecha_salida IS NULL OR fecha_salida >= fecha_ingreso)
);

-- -----------------------------------------------------------------------------
-- Periodos de pago
-- -----------------------------------------------------------------------------
CREATE TABLE periodos_pago (
    id            BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id    BIGINT NOT NULL REFERENCES empresas (id),
    nombre        VARCHAR(100) NOT NULL,
    fecha_inicio  DATE NOT NULL,
    fecha_fin     DATE NOT NULL,
    fecha_pago    DATE NOT NULL,
    frecuencia    frecuencia_periodo NOT NULL,
    estado        estado_periodo NOT NULL DEFAULT 'abierto',
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    -- Incluye la frecuencia: una planilla extraordinaria puede compartir fechas con la quincena
    CONSTRAINT uk_periodo_empresa_fechas UNIQUE (empresa_id, frecuencia, fecha_inicio, fecha_fin),
    CONSTRAINT uk_periodo_empresa_id     UNIQUE (empresa_id, id),
    CONSTRAINT ck_periodo_fechas         CHECK (fecha_fin >= fecha_inicio),     -- antes S3
    CONSTRAINT ck_periodo_fecha_pago     CHECK (fecha_pago >= fecha_inicio),
    -- Dos periodos de la misma empresa y frecuencia no pueden solaparse (antes S4).
    -- Se compara por frecuencia porque una semana puede caer dentro de una quincena,
    -- y se ignoran periodos anulados y planillas extraordinarias (aguinaldo, bonos).
    CONSTRAINT ex_periodo_sin_solapamiento EXCLUDE USING gist (
        empresa_id WITH =,
        frecuencia WITH =,
        daterange(fecha_inicio, fecha_fin, '[]') WITH &&
    ) WHERE (estado <> 'anulado' AND frecuencia <> 'extraordinaria')
);

-- -----------------------------------------------------------------------------
-- Catalogo de conceptos
-- -----------------------------------------------------------------------------
CREATE TABLE conceptos_nomina (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id       BIGINT NOT NULL REFERENCES empresas (id),
    codigo           VARCHAR(30) NOT NULL,
    nombre           VARCHAR(100) NOT NULL,
    tipo             tipo_concepto NOT NULL,
    naturaleza       naturaleza_concepto NOT NULL DEFAULT 'variable',
    afecta_bruto     BOOLEAN NOT NULL DEFAULT true,
    es_obligatorio   BOOLEAN NOT NULL DEFAULT false,
    orden_impresion  INTEGER NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_concepto_empresa_codigo UNIQUE (empresa_id, codigo),
    CONSTRAINT ck_concepto_orden CHECK (orden_impresion >= 0)
);

-- -----------------------------------------------------------------------------
-- Planillas: encabezado, detalle por empleado y movimientos por concepto
-- -----------------------------------------------------------------------------
CREATE TABLE planillas (
    id                 BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id         BIGINT NOT NULL REFERENCES empresas (id),
    periodo_id         BIGINT NOT NULL,
    numero             VARCHAR(30) NOT NULL,
    observaciones      TEXT,
    estado             estado_planilla NOT NULL DEFAULT 'borrador',
    total_ingresos     NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_deducciones  NUMERIC(14,2) NOT NULL DEFAULT 0,
    total_neto         NUMERIC(14,2) NOT NULL DEFAULT 0,
    created_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_planilla_empresa_numero UNIQUE (empresa_id, numero),
    CONSTRAINT uk_planilla_periodo        UNIQUE (periodo_id),  -- una planilla por periodo
    CONSTRAINT fk_planillas_periodo
        FOREIGN KEY (empresa_id, periodo_id) REFERENCES periodos_pago (empresa_id, id),
    CONSTRAINT ck_planilla_totales CHECK (total_ingresos >= 0 AND total_deducciones >= 0 AND total_neto >= 0)
);

CREATE TABLE planilla_detalle (
    id                  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    planilla_id         BIGINT NOT NULL REFERENCES planillas (id),
    empleado_id         BIGINT NOT NULL REFERENCES empleados (id),
    salario_base        NUMERIC(12,2) NOT NULL DEFAULT 0,
    horas_trabajadas    NUMERIC(10,2) NOT NULL DEFAULT 0,
    horas_extras        NUMERIC(10,2) NOT NULL DEFAULT 0,
    ingresos            NUMERIC(12,2) NOT NULL DEFAULT 0,
    deducciones         NUMERIC(12,2) NOT NULL DEFAULT 0,
    aportes_patronales  NUMERIC(12,2) NOT NULL DEFAULT 0,
    salario_bruto       NUMERIC(12,2) NOT NULL DEFAULT 0,
    salario_neto        NUMERIC(12,2) NOT NULL DEFAULT 0,
    observaciones       VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_planilla_empleado UNIQUE (planilla_id, empleado_id),
    CONSTRAINT ck_detalle_montos CHECK (
        salario_base >= 0 AND horas_trabajadas >= 0 AND horas_extras >= 0
        AND ingresos >= 0 AND deducciones >= 0 AND aportes_patronales >= 0
        AND salario_bruto >= 0
    ),
    CONSTRAINT ck_detalle_neto_no_negativo CHECK (salario_neto >= 0)  -- misma regla que el fix B1
);

CREATE TABLE planilla_movimientos (
    id           BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    detalle_id   BIGINT NOT NULL REFERENCES planilla_detalle (id),
    concepto_id  BIGINT NOT NULL REFERENCES conceptos_nomina (id),
    descripcion  VARCHAR(255),
    cantidad     NUMERIC(10,2) NOT NULL DEFAULT 1,
    monto        NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT ck_movimiento_valores CHECK (cantidad > 0 AND monto >= 0)
);

-- -----------------------------------------------------------------------------
-- Adelantos, prestamos y asistencia
-- -----------------------------------------------------------------------------
CREATE TABLE salary_advances (
    id                BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id        BIGINT NOT NULL REFERENCES empresas (id),
    empleado_id       BIGINT NOT NULL,
    referencia        VARCHAR(30) NOT NULL,
    fecha_solicitud   DATE NOT NULL,
    fecha_aprobacion  DATE,
    fecha_entrega     DATE,
    monto_aprobado    NUMERIC(12,2) NOT NULL,
    saldo_pendiente   NUMERIC(12,2) NOT NULL,
    cuotas_pactadas   INTEGER NOT NULL DEFAULT 1,
    cuotas_pagadas    INTEGER NOT NULL DEFAULT 0,
    estado            estado_salary_advance NOT NULL DEFAULT 'solicitado',
    observaciones     VARCHAR(255),
    created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_salary_advance_empresa_referencia UNIQUE (empresa_id, referencia),
    -- El empleado debe ser de la misma empresa que el adelanto
    CONSTRAINT fk_salary_advance_empleado
        FOREIGN KEY (empresa_id, empleado_id) REFERENCES empleados (empresa_id, id),
    CONSTRAINT ck_advance_monto  CHECK (monto_aprobado > 0),
    CONSTRAINT ck_advance_saldo  CHECK (saldo_pendiente BETWEEN 0 AND monto_aprobado),   -- antes S5
    CONSTRAINT ck_advance_cuotas CHECK (cuotas_pactadas >= 1 AND cuotas_pagadas BETWEEN 0 AND cuotas_pactadas),
    CONSTRAINT ck_advance_fechas CHECK (
        (fecha_aprobacion IS NULL OR fecha_aprobacion >= fecha_solicitud)
        AND (fecha_entrega IS NULL OR fecha_aprobacion IS NULL OR fecha_entrega >= fecha_aprobacion)
    )
);

CREATE TABLE prestamos_empleado (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id       BIGINT NOT NULL REFERENCES empresas (id),
    empleado_id      BIGINT NOT NULL,
    referencia       VARCHAR(30) NOT NULL,
    monto_total      NUMERIC(12,2) NOT NULL,
    saldo_actual     NUMERIC(12,2) NOT NULL,
    cuota_periodica  NUMERIC(12,2) NOT NULL,
    fecha_inicio     DATE NOT NULL,
    estado           estado_prestamo NOT NULL DEFAULT 'activo',
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_prestamo_empresa_referencia UNIQUE (empresa_id, referencia),
    CONSTRAINT fk_prestamos_empleado
        FOREIGN KEY (empresa_id, empleado_id) REFERENCES empleados (empresa_id, id),
    CONSTRAINT ck_prestamo_montos CHECK (
        monto_total > 0
        AND saldo_actual BETWEEN 0 AND monto_total
        AND cuota_periodica > 0 AND cuota_periodica <= monto_total
    )
);

CREATE TABLE asistencia_resumen (
    id               BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    empresa_id       BIGINT NOT NULL REFERENCES empresas (id),
    empleado_id      BIGINT NOT NULL,
    periodo_id       BIGINT NOT NULL,
    dias_trabajados  NUMERIC(8,2) NOT NULL DEFAULT 0,
    dias_ausentes    NUMERIC(8,2) NOT NULL DEFAULT 0,
    horas_normales   NUMERIC(10,2) NOT NULL DEFAULT 0,
    horas_extras     NUMERIC(10,2) NOT NULL DEFAULT 0,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uk_asistencia_periodo_empleado UNIQUE (periodo_id, empleado_id),
    CONSTRAINT fk_asistencia_empleado
        FOREIGN KEY (empresa_id, empleado_id) REFERENCES empleados (empresa_id, id),
    CONSTRAINT fk_asistencia_periodo
        FOREIGN KEY (empresa_id, periodo_id) REFERENCES periodos_pago (empresa_id, id),
    CONSTRAINT ck_asistencia_valores CHECK (
        dias_trabajados >= 0 AND dias_ausentes >= 0 AND horas_normales >= 0 AND horas_extras >= 0
    )
);

-- -----------------------------------------------------------------------------
-- Triggers de updated_at
-- -----------------------------------------------------------------------------
CREATE TRIGGER trg_empresas_updated_at        BEFORE UPDATE ON empresas        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_usuarios_updated_at        BEFORE UPDATE ON usuarios        FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_empleados_updated_at       BEFORE UPDATE ON empleados       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_periodos_updated_at        BEFORE UPDATE ON periodos_pago   FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_planillas_updated_at       BEFORE UPDATE ON planillas       FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_salary_advances_updated_at BEFORE UPDATE ON salary_advances FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- -----------------------------------------------------------------------------
-- Indices para claves foraneas
-- PostgreSQL no indexa las FK automaticamente (MySQL/InnoDB si). Solo se crean
-- los que no estan cubiertos ya por un UNIQUE que empieza por esa columna.
-- -----------------------------------------------------------------------------
CREATE INDEX ix_empleados_departamento         ON empleados (empresa_id, departamento_id);
CREATE INDEX ix_planillas_empresa_periodo      ON planillas (empresa_id, periodo_id);
CREATE INDEX ix_planilla_detalle_empleado      ON planilla_detalle (empleado_id);
CREATE INDEX ix_planilla_movimientos_detalle   ON planilla_movimientos (detalle_id);
CREATE INDEX ix_planilla_movimientos_concepto  ON planilla_movimientos (concepto_id);
CREATE INDEX ix_salary_advances_empleado       ON salary_advances (empresa_id, empleado_id);
CREATE INDEX ix_prestamos_empleado             ON prestamos_empleado (empresa_id, empleado_id);
CREATE INDEX ix_asistencia_empleado            ON asistencia_resumen (empresa_id, empleado_id);
CREATE INDEX ix_asistencia_periodo             ON asistencia_resumen (empresa_id, periodo_id);

-- -----------------------------------------------------------------------------
-- Datos de ejemplo (identicos a la version MySQL)
-- -----------------------------------------------------------------------------
INSERT INTO empresas (nombre, ruc, telefono, correo, direccion)
VALUES ('Comercial Las Flores', 'J0310000000001', '2222-0000', 'info@lasflores.com', 'Managua, Nicaragua');

INSERT INTO departamentos (empresa_id, nombre, descripcion)
VALUES
    (1, 'Administracion', 'Gestion general y soporte'),
    (1, 'Ventas', 'Equipo comercial'),
    (1, 'Operaciones', 'Produccion y servicio');

INSERT INTO usuarios (empresa_id, nombre, email, password_hash, rol)
VALUES
    (1, 'Mariela Gomez', 'admin@lasflores.com', '$2y$12$demo.hash.seguro', 'admin'),
    (1, 'Luis Chavez', 'rrhh@lasflores.com', '$2y$12$demo.hash.seguro', 'rrhh');

INSERT INTO empleados (empresa_id, departamento_id, codigo_empleado, nombres, apellidos, cedula,
                       fecha_ingreso, telefono, cargo, tipo_pago, salario_base)
VALUES
    (1, 1, 'EMP-001', 'Ana Lucia', 'Mendez', '001-010190-0001A', '2025-01-10', '8888-1111', 'Contadora', 'mensual', 18000.00),
    (1, 2, 'EMP-002', 'Carlos Jose', 'Perez', '001-020292-0002B', '2025-02-01', '8888-2222', 'Ejecutivo de ventas', 'quincenal', 12000.00),
    (1, 3, 'EMP-003', 'Martha Elena', 'Lopez', '001-030395-0003C', '2025-03-15', '8888-3333', 'Operaria', 'semanal', 9500.00);

INSERT INTO periodos_pago (empresa_id, nombre, fecha_inicio, fecha_fin, fecha_pago, frecuencia)
VALUES (1, 'Planilla quincena 1 abril 2026', '2026-04-01', '2026-04-15', '2026-04-15', 'quincenal');

INSERT INTO conceptos_nomina (empresa_id, codigo, nombre, tipo, naturaleza, afecta_bruto, es_obligatorio, orden_impresion)
VALUES
    (1, 'SALARIO', 'Salario base',            'ingreso',   'fijo',     true,  true,  1),
    (1, 'HEXTRA',  'Horas extra',             'ingreso',   'variable', true,  false, 2),
    (1, 'BONO',    'Bonificacion',            'ingreso',   'variable', true,  false, 3),
    (1, 'INSS',    'Seguro social laboral',   'deduccion', 'formula',  false, true,  10),
    (1, 'IR',      'Impuesto sobre la renta', 'deduccion', 'formula',  false, true,  11),
    (1, 'ADEL',    'Adelanto de salario',     'deduccion', 'variable', false, false, 12),
    (1, 'PREST',   'Cuota de prestamo',       'deduccion', 'variable', false, false, 13);

INSERT INTO planillas (empresa_id, periodo_id, numero, observaciones, estado)
VALUES (1, 1, 'PLN-2026-04-001', 'Planilla inicial de ejemplo', 'calculada');

INSERT INTO planilla_detalle (planilla_id, empleado_id, salario_base, horas_trabajadas, horas_extras, ingresos,
                              deducciones, aportes_patronales, salario_bruto, salario_neto, observaciones)
VALUES
    (1, 1, 18000.00, 80.00, 4.00, 18450.00, 1250.00, 1850.00, 18450.00, 17200.00, 'Sin incidencias'),
    (1, 2, 12000.00, 80.00, 6.00, 12650.00,  920.00, 1265.00, 12650.00, 11730.00, 'Incluye comision'),
    (1, 3,  9500.00, 80.00, 2.00,  9700.00,  630.00,  970.00,  9700.00,  9070.00, 'Turno normal');

INSERT INTO planilla_movimientos (detalle_id, concepto_id, descripcion, cantidad, monto)
VALUES
    (1, 1, 'Salario base del periodo', 1, 18000.00),
    (1, 2, '4 horas extra', 4, 450.00),
    (1, 4, 'Deduccion de seguro social', 1, 650.00),
    (1, 5, 'Retencion de impuesto', 1, 600.00),
    (2, 1, 'Salario base del periodo', 1, 12000.00),
    (2, 2, '6 horas extra', 6, 650.00),
    (2, 4, 'Deduccion de seguro social', 1, 420.00),
    (2, 6, 'Adelanto aplicado', 1, 500.00),
    (3, 1, 'Salario base del periodo', 1, 9500.00),
    (3, 2, '2 horas extra', 2, 200.00),
    (3, 4, 'Deduccion de seguro social', 1, 330.00),
    (3, 7, 'Cuota de prestamo', 1, 300.00);

INSERT INTO salary_advances (empresa_id, empleado_id, referencia, fecha_solicitud, fecha_aprobacion, fecha_entrega,
                             monto_aprobado, saldo_pendiente, cuotas_pactadas, cuotas_pagadas, estado, observaciones)
VALUES (1, 2, 'SA-001', '2026-04-03', '2026-04-04', '2026-04-04', 500.00, 500.00, 1, 0, 'entregado',
        'Adelanto salarial de emergencia');

INSERT INTO prestamos_empleado (empresa_id, empleado_id, referencia, monto_total, saldo_actual, cuota_periodica, fecha_inicio)
VALUES (1, 3, 'PREST-001', 3000.00, 2400.00, 300.00, '2026-02-01');

INSERT INTO asistencia_resumen (empresa_id, empleado_id, periodo_id, dias_trabajados, dias_ausentes, horas_normales, horas_extras)
VALUES
    (1, 1, 1, 10, 0, 80, 4),
    (1, 2, 1, 10, 0, 80, 6),
    (1, 3, 1, 10, 0, 80, 2);

-- Totales del encabezado calculados desde el detalle
UPDATE planillas p
SET total_ingresos    = d.ingresos,
    total_deducciones = d.deducciones,
    total_neto        = d.neto
FROM (
    SELECT planilla_id,
           COALESCE(SUM(ingresos), 0)     AS ingresos,
           COALESCE(SUM(deducciones), 0)  AS deducciones,
           COALESCE(SUM(salario_neto), 0) AS neto
    FROM planilla_detalle
    GROUP BY planilla_id
) d
WHERE d.planilla_id = p.id;

-- -----------------------------------------------------------------------------
-- Vistas
-- -----------------------------------------------------------------------------
CREATE VIEW vw_resumen_planilla AS
SELECT
    p.id      AS planilla_id,
    p.numero,
    e.nombre  AS empresa,
    pp.nombre AS periodo,
    p.estado,
    p.total_ingresos,
    p.total_deducciones,
    p.total_neto
FROM planillas p
JOIN empresas e       ON e.id = p.empresa_id
JOIN periodos_pago pp ON pp.id = p.periodo_id;

CREATE VIEW vw_colaboradores_activos AS
SELECT
    em.id,
    em.codigo_empleado,
    em.nombres || ' ' || em.apellidos AS empleado,
    em.cargo,
    d.nombre AS departamento,
    em.tipo_pago,
    em.salario_base
FROM empleados em
LEFT JOIN departamentos d ON d.id = em.departamento_id
WHERE em.activo;
