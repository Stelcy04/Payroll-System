DROP DATABASE IF EXISTS sistema_planilla_pymes;
CREATE DATABASE sistema_planilla_pymes CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sistema_planilla_pymes;

CREATE TABLE empresas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL,
    ruc VARCHAR(50) NULL,
    telefono VARCHAR(30) NULL,
    correo VARCHAR(150) NULL,
    direccion TEXT NULL,
    moneda CHAR(3) NOT NULL DEFAULT 'NIO',
    estado ENUM('activa', 'inactiva') NOT NULL DEFAULT 'activa',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE usuarios (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    rol ENUM('admin', 'rrhh', 'contador', 'consulta') NOT NULL DEFAULT 'rrhh',
    estado ENUM('activo', 'bloqueado') NOT NULL DEFAULT 'activo',
    ultimo_acceso TIMESTAMP NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_usuarios_email_empresa (empresa_id, email),
    CONSTRAINT fk_usuarios_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB;

CREATE TABLE departamentos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    descripcion VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_departamento_empresa_nombre (empresa_id, nombre),
    CONSTRAINT fk_departamentos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB;

CREATE TABLE empleados (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    departamento_id BIGINT UNSIGNED NULL,
    codigo_empleado VARCHAR(30) NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    cedula VARCHAR(25) NULL,
    fecha_nacimiento DATE NULL,
    fecha_ingreso DATE NOT NULL,
    fecha_salida DATE NULL,
    telefono VARCHAR(30) NULL,
    correo VARCHAR(150) NULL,
    direccion TEXT NULL,
    cargo VARCHAR(100) NOT NULL,
    tipo_pago ENUM('mensual', 'quincenal', 'semanal', 'por_hora') NOT NULL DEFAULT 'mensual',
    salario_base DECIMAL(12,2) NOT NULL,
    activo TINYINT(1) NOT NULL DEFAULT 1,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_empleado_empresa_codigo (empresa_id, codigo_empleado),
    UNIQUE KEY uk_empleado_empresa_cedula (empresa_id, cedula),
    CONSTRAINT fk_empleados_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_empleados_departamento
        FOREIGN KEY (departamento_id) REFERENCES departamentos(id)
) ENGINE=InnoDB;

CREATE TABLE periodos_pago (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,
    fecha_pago DATE NOT NULL,
    frecuencia ENUM('semanal', 'quincenal', 'mensual', 'extraordinaria') NOT NULL,
    estado ENUM('abierto', 'calculado', 'cerrado', 'anulado') NOT NULL DEFAULT 'abierto',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_periodo_empresa_fechas (empresa_id, fecha_inicio, fecha_fin),
    CONSTRAINT fk_periodos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB;

CREATE TABLE conceptos_nomina (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    codigo VARCHAR(30) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    tipo ENUM('ingreso', 'deduccion', 'aporte_patronal', 'informativo') NOT NULL,
    naturaleza ENUM('fijo', 'variable', 'formula') NOT NULL DEFAULT 'variable',
    afecta_bruto TINYINT(1) NOT NULL DEFAULT 1,
    es_obligatorio TINYINT(1) NOT NULL DEFAULT 0,
    orden_impresion INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_concepto_empresa_codigo (empresa_id, codigo),
    CONSTRAINT fk_conceptos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id)
) ENGINE=InnoDB;

CREATE TABLE planillas (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    periodo_id BIGINT UNSIGNED NOT NULL,
    numero VARCHAR(30) NOT NULL,
    observaciones TEXT NULL,
    estado ENUM('borrador', 'calculada', 'aprobada', 'pagada', 'anulada') NOT NULL DEFAULT 'borrador',
    total_ingresos DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_deducciones DECIMAL(14,2) NOT NULL DEFAULT 0,
    total_neto DECIMAL(14,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_planilla_empresa_numero (empresa_id, numero),
    UNIQUE KEY uk_planilla_periodo (periodo_id),
    CONSTRAINT fk_planillas_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_planillas_periodo
        FOREIGN KEY (periodo_id) REFERENCES periodos_pago(id)
) ENGINE=InnoDB;

CREATE TABLE planilla_detalle (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    planilla_id BIGINT UNSIGNED NOT NULL,
    empleado_id BIGINT UNSIGNED NOT NULL,
    salario_base DECIMAL(12,2) NOT NULL DEFAULT 0,
    horas_trabajadas DECIMAL(10,2) NOT NULL DEFAULT 0,
    horas_extras DECIMAL(10,2) NOT NULL DEFAULT 0,
    ingresos DECIMAL(12,2) NOT NULL DEFAULT 0,
    deducciones DECIMAL(12,2) NOT NULL DEFAULT 0,
    aportes_patronales DECIMAL(12,2) NOT NULL DEFAULT 0,
    salario_bruto DECIMAL(12,2) NOT NULL DEFAULT 0,
    salario_neto DECIMAL(12,2) NOT NULL DEFAULT 0,
    observaciones VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_planilla_empleado (planilla_id, empleado_id),
    CONSTRAINT fk_detalle_planilla
        FOREIGN KEY (planilla_id) REFERENCES planillas(id),
    CONSTRAINT fk_detalle_empleado
        FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE planilla_movimientos (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    detalle_id BIGINT UNSIGNED NOT NULL,
    concepto_id BIGINT UNSIGNED NOT NULL,
    descripcion VARCHAR(255) NULL,
    cantidad DECIMAL(10,2) NOT NULL DEFAULT 1,
    monto DECIMAL(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_movimientos_detalle
        FOREIGN KEY (detalle_id) REFERENCES planilla_detalle(id),
    CONSTRAINT fk_movimientos_concepto
        FOREIGN KEY (concepto_id) REFERENCES conceptos_nomina(id)
) ENGINE=InnoDB;

CREATE TABLE salary_advances (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    empleado_id BIGINT UNSIGNED NOT NULL,
    referencia VARCHAR(30) NOT NULL,
    fecha_solicitud DATE NOT NULL,
    fecha_aprobacion DATE NULL,
    fecha_entrega DATE NULL,
    monto_aprobado DECIMAL(12,2) NOT NULL,
    saldo_pendiente DECIMAL(12,2) NOT NULL,
    cuotas_pactadas INT NOT NULL DEFAULT 1,
    cuotas_pagadas INT NOT NULL DEFAULT 0,
    estado ENUM('solicitado', 'aprobado', 'entregado', 'descontado', 'anulado') NOT NULL DEFAULT 'solicitado',
    observaciones VARCHAR(255) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_salary_advance_empresa_referencia (empresa_id, referencia),
    CONSTRAINT fk_salary_advance_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_salary_advance_empleado
        FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE prestamos_empleado (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    empleado_id BIGINT UNSIGNED NOT NULL,
    referencia VARCHAR(30) NOT NULL,
    monto_total DECIMAL(12,2) NOT NULL,
    saldo_actual DECIMAL(12,2) NOT NULL,
    cuota_periodica DECIMAL(12,2) NOT NULL,
    fecha_inicio DATE NOT NULL,
    estado ENUM('activo', 'cancelado') NOT NULL DEFAULT 'activo',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_prestamo_empresa_referencia (empresa_id, referencia),
    CONSTRAINT fk_prestamos_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_prestamos_empleado
        FOREIGN KEY (empleado_id) REFERENCES empleados(id)
) ENGINE=InnoDB;

CREATE TABLE asistencia_resumen (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    empresa_id BIGINT UNSIGNED NOT NULL,
    empleado_id BIGINT UNSIGNED NOT NULL,
    periodo_id BIGINT UNSIGNED NOT NULL,
    dias_trabajados DECIMAL(8,2) NOT NULL DEFAULT 0,
    dias_ausentes DECIMAL(8,2) NOT NULL DEFAULT 0,
    horas_normales DECIMAL(10,2) NOT NULL DEFAULT 0,
    horas_extras DECIMAL(10,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_asistencia_periodo_empleado (periodo_id, empleado_id),
    CONSTRAINT fk_asistencia_empresa
        FOREIGN KEY (empresa_id) REFERENCES empresas(id),
    CONSTRAINT fk_asistencia_empleado
        FOREIGN KEY (empleado_id) REFERENCES empleados(id),
    CONSTRAINT fk_asistencia_periodo
        FOREIGN KEY (periodo_id) REFERENCES periodos_pago(id)
) ENGINE=InnoDB;

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

INSERT INTO empleados (
    empresa_id,
    departamento_id,
    codigo_empleado,
    nombres,
    apellidos,
    cedula,
    fecha_ingreso,
    telefono,
    cargo,
    tipo_pago,
    salario_base
)
VALUES
    (1, 1, 'EMP-001', 'Ana Lucia', 'Mendez', '001-010190-0001A', '2025-01-10', '8888-1111', 'Contadora', 'mensual', 18000.00),
    (1, 2, 'EMP-002', 'Carlos Jose', 'Perez', '001-020292-0002B', '2025-02-01', '8888-2222', 'Ejecutivo de ventas', 'quincenal', 12000.00),
    (1, 3, 'EMP-003', 'Martha Elena', 'Lopez', '001-030395-0003C', '2025-03-15', '8888-3333', 'Operaria', 'semanal', 9500.00);

INSERT INTO periodos_pago (empresa_id, nombre, fecha_inicio, fecha_fin, fecha_pago, frecuencia)
VALUES (1, 'Planilla quincena 1 abril 2026', '2026-04-01', '2026-04-15', '2026-04-15', 'quincenal');

INSERT INTO conceptos_nomina (empresa_id, codigo, nombre, tipo, naturaleza, afecta_bruto, es_obligatorio, orden_impresion)
VALUES
    (1, 'SALARIO', 'Salario base', 'ingreso', 'fijo', 1, 1, 1),
    (1, 'HEXTRA', 'Horas extra', 'ingreso', 'variable', 1, 0, 2),
    (1, 'BONO', 'Bonificacion', 'ingreso', 'variable', 1, 0, 3),
    (1, 'INSS', 'Seguro social laboral', 'deduccion', 'formula', 0, 1, 10),
    (1, 'IR', 'Impuesto sobre la renta', 'deduccion', 'formula', 0, 1, 11),
    (1, 'ADEL', 'Adelanto de salario', 'deduccion', 'variable', 0, 0, 12),
    (1, 'PREST', 'Cuota de prestamo', 'deduccion', 'variable', 0, 0, 13);

INSERT INTO planillas (empresa_id, periodo_id, numero, observaciones, estado)
VALUES (1, 1, 'PLN-2026-04-001', 'Planilla inicial de ejemplo', 'calculada');

INSERT INTO planilla_detalle (
    planilla_id,
    empleado_id,
    salario_base,
    horas_trabajadas,
    horas_extras,
    ingresos,
    deducciones,
    aportes_patronales,
    salario_bruto,
    salario_neto,
    observaciones
)
VALUES
    (1, 1, 18000.00, 80.00, 4.00, 18450.00, 1250.00, 1850.00, 18450.00, 17200.00, 'Sin incidencias'),
    (1, 2, 12000.00, 80.00, 6.00, 12650.00, 920.00, 1265.00, 12650.00, 11730.00, 'Incluye comision'),
    (1, 3, 9500.00, 80.00, 2.00, 9700.00, 630.00, 970.00, 9700.00, 9070.00, 'Turno normal');

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

INSERT INTO salary_advances (
    empresa_id,
    empleado_id,
    referencia,
    fecha_solicitud,
    fecha_aprobacion,
    fecha_entrega,
    monto_aprobado,
    saldo_pendiente,
    cuotas_pactadas,
    cuotas_pagadas,
    estado,
    observaciones
)
VALUES
    (1, 2, 'SA-001', '2026-04-03', '2026-04-04', '2026-04-04', 500.00, 500.00, 1, 0, 'entregado', 'Adelanto salarial de emergencia');
    
INSERT INTO prestamos_empleado (
    empresa_id,
    empleado_id,
    referencia,
    monto_total,
    saldo_actual,
    cuota_periodica,
    fecha_inicio
)
VALUES (1, 3, 'PREST-001', 3000.00, 2400.00, 300.00, '2026-02-01');

INSERT INTO asistencia_resumen (
    empresa_id,
    empleado_id,
    periodo_id,
    dias_trabajados,
    dias_ausentes,
    horas_normales,
    horas_extras
)
VALUES
    (1, 1, 1, 10, 0, 80, 4),
    (1, 2, 1, 10, 0, 80, 6),
    (1, 3, 1, 10, 0, 80, 2);

UPDATE planillas
SET
    total_ingresos = (SELECT COALESCE(SUM(ingresos), 0) FROM planilla_detalle WHERE planilla_id = 1),
    total_deducciones = (SELECT COALESCE(SUM(deducciones), 0) FROM planilla_detalle WHERE planilla_id = 1),
    total_neto = (SELECT COALESCE(SUM(salario_neto), 0) FROM planilla_detalle WHERE planilla_id = 1)
WHERE id = 1;

CREATE VIEW vw_resumen_planilla AS
SELECT
    p.id AS planilla_id,
    p.numero,
    e.nombre AS empresa,
    pp.nombre AS periodo,
    p.estado,
    p.total_ingresos,
    p.total_deducciones,
    p.total_neto
FROM planillas p
INNER JOIN empresas e ON e.id = p.empresa_id
INNER JOIN periodos_pago pp ON pp.id = p.periodo_id;

CREATE VIEW vw_colaboradores_activos AS
SELECT
    em.id,
    em.codigo_empleado,
    CONCAT(em.nombres, ' ', em.apellidos) AS empleado,
    em.cargo,
    d.nombre AS departamento,
    em.tipo_pago,
    em.salario_base
FROM empleados em
LEFT JOIN departamentos d ON d.id = em.departamento_id
WHERE em.activo = 1;
