"""
Genera seed_planilla_postgres.sql: datos de ejemplo para practicar analisis.

Escenario: empresa ficticia de software e implementacion de ERP en Managua.
Periodo: 12 quincenas, enero a junio de 2026.

Las tasas de INSS e IR son APROXIMADAS y solo sirven para practicar analisis;
no deben usarse para calcular una planilla legal.

Uso:
    python generate_seed.py > seed_planilla_postgres.sql
"""
import calendar
import random
from datetime import date
from decimal import ROUND_HALF_UP, Decimal

random.seed(2026)  # mismos datos en cada ejecucion

D = Decimal
CENT = D("0.01")


def money(value) -> Decimal:
    return D(value).quantize(CENT, rounding=ROUND_HALF_UP)


# --------------------------------------------------------------------------
# Parametros aproximados (Nicaragua, solo para practica)
# --------------------------------------------------------------------------
INSS_LABORAL = D("0.07")
INSS_PATRONAL = D("0.215")
# IR anual sobre renta neta (bruto - INSS): (desde, base fija, tasa)
IR_TRAMOS = [
    (D("0"), D("0"), D("0")),
    (D("100000"), D("0"), D("0.15")),
    (D("200000"), D("15000"), D("0.20")),
    (D("350000"), D("45000"), D("0.25")),
    (D("500000"), D("82500"), D("0.30")),
]

EMPRESA = ("TecnoServicios Nicaragua S.A.", "J0310000099999", "2250-1000", "rrhh@tecnoservicios.com.ni",
           "Managua, Nicaragua")

DEPARTAMENTOS = [
    ("Finanzas", "Contabilidad, tesoreria y reportes financieros"),
    ("HR", "Recursos humanos y planilla"),
    ("Implementacion", "Consultoria funcional e implementacion de ERP"),
    ("IT", "Infraestructura, redes y soporte interno"),
    ("Desarrollo de Software", "Desarrollo, QA y mantenimiento del producto"),
]

# (departamento, cargo, salario mensual de referencia)
PUESTOS = [
    ("Finanzas", "Gerente financiero", 62000),
    ("Finanzas", "Contador senior", 32000),
    ("Finanzas", "Contador", 23000),
    ("Finanzas", "Auxiliar contable", 14500),
    ("HR", "Gerente de recursos humanos", 52000),
    ("HR", "Especialista de planilla", 26000),
    ("HR", "Asistente de recursos humanos", 15000),
    ("Implementacion", "Gerente de implementacion", 58000),
    ("Implementacion", "Consultor funcional senior", 39000),
    ("Implementacion", "Consultor funcional senior", 38000),
    ("Implementacion", "Consultor funcional", 27000),
    ("Implementacion", "Consultor funcional", 26000),
    ("Implementacion", "Analista de soporte", 18500),
    ("IT", "Jefe de IT", 48000),
    ("IT", "Administrador de sistemas", 31000),
    ("IT", "Tecnico de soporte", 16500),
    ("IT", "Tecnico de soporte", 16000),
    ("Desarrollo de Software", "Lider tecnico", 72000),
    ("Desarrollo de Software", "Desarrollador senior", 54000),
    ("Desarrollo de Software", "Desarrollador senior", 52000),
    ("Desarrollo de Software", "Desarrollador", 36000),
    ("Desarrollo de Software", "Desarrollador", 35000),
    ("Desarrollo de Software", "Desarrollador", 34000),
    ("Desarrollo de Software", "QA tester", 25000),
    ("Desarrollo de Software", "QA tester", 24000),
]

NOMBRES = ["Ana Lucia", "Carlos Jose", "Martha Elena", "Jorge Luis", "Maria Fernanda", "Luis Alberto",
           "Karla Patricia", "Roberto Carlos", "Gabriela", "Oscar Daniel", "Silvia Maria", "Javier Antonio",
           "Daniela", "Erick Manuel", "Fatima", "Kevin Josue", "Ingrid Carolina", "Mario Jose", "Valeria",
           "Francisco Javier", "Andrea Sofia", "Hector Rene", "Paola Ivette", "Juan Pablo", "Rosa Amelia",
           "Diego Alejandro", "Lesbia Maria"]
APELLIDOS = ["Mendez", "Perez", "Lopez", "Garcia", "Martinez", "Rodriguez", "Gonzalez", "Hernandez",
             "Castillo", "Morales", "Ruiz", "Lacayo", "Chamorro", "Baltodano", "Somarriba", "Obando",
             "Rivas", "Espinoza", "Zeledon", "Arguello", "Solorzano", "Urbina", "Mairena", "Duarte",
             "Valle", "Cruz", "Torres"]

# Movimientos de personal en el semestre: codigo -> fecha de salida
BAJAS = {"EMP-011": date(2026, 2, 27), "EMP-016": date(2026, 4, 10), "EMP-023": date(2026, 5, 29)}
# Contrataciones del semestre: (departamento, cargo, salario, fecha de ingreso)
ALTAS = [
    ("Implementacion", "Consultor funcional", 27500, date(2026, 3, 2)),
    ("Desarrollo de Software", "QA tester", 24500, date(2026, 4, 16)),
]


def quincenas_2026():
    periodos = []
    for mes in range(1, 7):
        ultimo = calendar.monthrange(2026, mes)[1]
        nombre_mes = ["enero", "febrero", "marzo", "abril", "mayo", "junio"][mes - 1]
        periodos.append((f"Planilla quincena 1 {nombre_mes} 2026", date(2026, mes, 1), date(2026, mes, 15), mes, 1))
        periodos.append((f"Planilla quincena 2 {nombre_mes} 2026", date(2026, mes, 16), date(2026, mes, ultimo), mes, 2))
    return periodos


def ir_quincenal(bruto: Decimal, inss: Decimal) -> Decimal:
    """IR aproximado: anualiza la renta neta de la quincena (x24) y divide el impuesto entre 24."""
    anual = (bruto - inss) * 24
    impuesto = D("0")
    for desde, base, tasa in IR_TRAMOS:
        if anual > desde:
            impuesto = base + (anual - desde) * tasa
    return money(impuesto / 24)


def dias_habiles(inicio: date, fin: date) -> int:
    return sum(1 for n in range((fin - inicio).days + 1)
               if date.fromordinal(inicio.toordinal() + n).weekday() < 5)


def q(text) -> str:
    return "NULL" if text is None else "'" + str(text).replace("'", "''") + "'"


# --------------------------------------------------------------------------
# Empleados
# --------------------------------------------------------------------------
empleados = []
nombres = random.sample(NOMBRES, len(PUESTOS) + len(ALTAS))
apellidos = random.sample(APELLIDOS, len(PUESTOS) + len(ALTAS))

for i, (depto, cargo, salario) in enumerate(PUESTOS, start=1):
    codigo = f"EMP-{i:03d}"
    salario_real = (D(salario) * D(random.uniform(0.97, 1.03)) / 50).quantize(D("1")) * 50  # multiplo de 50
    ingreso = date(random.randint(2019, 2025), random.randint(1, 12), random.randint(1, 28))
    empleados.append({
        "codigo": codigo, "depto": depto, "cargo": cargo, "salario": money(salario_real),
        "nombres": nombres[i - 1], "apellidos": apellidos[i - 1], "ingreso": ingreso,
        "salida": BAJAS.get(codigo),
        "nacimiento": date(random.randint(1975, 2001), random.randint(1, 12), random.randint(1, 28)),
    })

for j, (depto, cargo, salario, ingreso) in enumerate(ALTAS, start=len(PUESTOS) + 1):
    empleados.append({
        "codigo": f"EMP-{j:03d}", "depto": depto, "cargo": cargo, "salario": money(salario),
        "nombres": nombres[j - 1], "apellidos": apellidos[j - 1], "ingreso": ingreso, "salida": None,
        "nacimiento": date(random.randint(1990, 2002), random.randint(1, 12), random.randint(1, 28)),
    })

for e in empleados:
    e["cedula"] = f"001-{e['nacimiento']:%d%m%y}-{random.randint(1000, 9999)}{random.choice('ABCDEFGHJKLMNP')}"

# --------------------------------------------------------------------------
# Adelantos y prestamos (se descuentan de planilla en planilla)
# --------------------------------------------------------------------------
periodos = quincenas_2026()
ULTIMO = len(periodos) - 1

# (codigo, monto, cuotas, indice del periodo del primer descuento, fecha solicitud)
ADELANTOS = [
    ("EMP-004", 3000, 2, 1, date(2026, 1, 12)),
    ("EMP-007", 2500, 1, 2, date(2026, 1, 28)),
    ("EMP-013", 4000, 2, 3, date(2026, 2, 9)),
    ("EMP-016", 3500, 2, 4, date(2026, 2, 25)),
    ("EMP-024", 5000, 2, 6, date(2026, 3, 27)),
    ("EMP-003", 2000, 1, 7, date(2026, 4, 8)),
    ("EMP-012", 6000, 3, 9, date(2026, 5, 11)),
    ("EMP-015", 3000, 2, 11, date(2026, 6, 19)),
]
PRESTAMOS = [  # (codigo, monto, cuota quincenal, fecha inicio, saldo al 1 de enero)
    ("EMP-002", 30000, 1250, date(2025, 7, 1), 18750),
    ("EMP-009", 12000, 1000, date(2025, 11, 1), 8000),
    ("EMP-021", 20000, 1000, date(2026, 2, 1), 20000),
]

adelantos = []
for n, (codigo, monto, cuotas, inicio, solicitud) in enumerate(ADELANTOS, start=1):
    adelantos.append({"ref": f"SA-2026-{n:03d}", "codigo": codigo, "monto": money(monto), "cuotas": cuotas,
                      "inicio": inicio, "solicitud": solicitud, "saldo": money(monto), "pagadas": 0})
prestamos = [{"ref": f"PREST-{n:03d}", "codigo": c, "monto": money(m), "cuota": money(cu), "inicio": f,
              "saldo": money(s)} for n, (c, m, cu, f, s) in enumerate(PRESTAMOS, start=1)]

# --------------------------------------------------------------------------
# Planillas
# --------------------------------------------------------------------------
detalles, movimientos, asistencias = [], [], []

for idx, (nombre_periodo, inicio, fin, mes, quincena) in enumerate(periodos):
    numero = f"PLN-2026-{mes:02d}-Q{quincena}"
    habiles = dias_habiles(inicio, fin)
    for e in empleados:
        if e["ingreso"] > fin or (e["salida"] and e["salida"] < inicio):
            continue
        desde = max(inicio, e["ingreso"])
        hasta = min(fin, e["salida"]) if e["salida"] else fin
        dias = dias_habiles(desde, hasta)
        proporcion = D(dias) / D(habiles)
        salario_q = money(e["salario"] / 2 * proporcion)

        ausencias = 0
        if dias == habiles and random.random() < 0.12:
            ausencias = random.choice([1, 1, 2])
        trabajados = dias - ausencias

        extra_horas = D(0)
        if e["depto"] in {"Implementacion", "IT", "Desarrollo de Software"} and random.random() < 0.45:
            extra_horas = D(random.choice([2, 3, 4, 4, 6, 8]))
        hora = e["salario"] / 30 / 8
        extra_monto = money(hora * 2 * extra_horas)

        bono = D(0)
        if e["depto"] == "Implementacion" and quincena == 2 and mes in {3, 6} and random.random() < 0.8:
            bono = money(random.choice([2000, 2500, 3000]))  # bono por go-live
        if e["depto"] == "Desarrollo de Software" and mes == 6 and quincena == 2:
            bono = money(1500)  # bono de cierre de release

        bruto = salario_q + extra_monto + bono
        inss = money(bruto * INSS_LABORAL)
        ir = ir_quincenal(bruto, inss)
        patronal = money(bruto * INSS_PATRONAL)

        movs = [("SALARIO", "Salario base del periodo", 1, salario_q)]
        if extra_horas:
            movs.append(("HEXTRA", f"{extra_horas} horas extra", extra_horas, extra_monto))
        if bono:
            movs.append(("BONO", "Bonificacion", 1, bono))
        movs.append(("INSS", "Seguro social laboral (aprox. 7%)", 1, inss))
        if ir:
            movs.append(("IR", "Retencion IR (aprox.)", 1, ir))

        disponible = bruto - inss - ir
        adelanto_total = D(0)
        for a in adelantos:
            if a["codigo"] == e["codigo"] and idx >= a["inicio"] and a["saldo"] > 0:
                cuota = money(a["monto"] / a["cuotas"]) if a["pagadas"] < a["cuotas"] - 1 else a["saldo"]
                cuota = min(cuota, a["saldo"], disponible)
                if cuota > 0:
                    a["saldo"] -= cuota
                    a["pagadas"] += 1
                    disponible -= cuota
                    adelanto_total += cuota
                    movs.append(("ADEL", f"Adelanto {a['ref']}", 1, cuota))
        for p in prestamos:
            if p["codigo"] == e["codigo"] and p["saldo"] > 0 and date(2026, mes, 1) >= p["inicio"].replace(day=1):
                cuota = min(p["cuota"], p["saldo"], disponible)
                if cuota > 0:
                    p["saldo"] -= cuota
                    disponible -= cuota
                    movs.append(("PREST", f"Cuota prestamo {p['ref']}", 1, cuota))
        movs.append(("INSS_PAT", "Aporte patronal INSS (aprox. 21.5%)", 1, patronal))

        deducciones = sum(m[3] for m in movs if m[0] in {"INSS", "IR", "ADEL", "PREST"})
        neto = bruto - deducciones
        assert neto >= 0
        observacion = "Ingreso en el periodo" if desde > inicio else ("Salida en el periodo" if hasta < fin else None)
        if ausencias:
            observacion = f"{ausencias} dia(s) de ausencia justificada"

        detalles.append((numero, e["codigo"], e["salario"], trabajados * 8, extra_horas, bruto, deducciones,
                         patronal, bruto, neto, observacion))
        movimientos.extend((numero, e["codigo"], *m) for m in movs)
        asistencias.append((e["codigo"], nombre_periodo, trabajados, ausencias, trabajados * 8, extra_horas))

# Adelantos adicionales sin descuento: uno solicitado y uno anulado
adelantos.append({"ref": "SA-2026-009", "codigo": "EMP-018", "monto": money(4500), "cuotas": 2, "inicio": None,
                  "solicitud": date(2026, 6, 26), "saldo": money(4500), "pagadas": 0, "estado": "solicitado"})
adelantos.append({"ref": "SA-2026-010", "codigo": "EMP-006", "monto": money(2000), "cuotas": 1, "inicio": None,
                  "solicitud": date(2026, 3, 3), "saldo": money(2000), "pagadas": 0, "estado": "anulado"})

# --------------------------------------------------------------------------
# Salida SQL
# --------------------------------------------------------------------------
out = []
w = out.append
w("-- =============================================================================")
w("-- Datos de ejemplo para analisis - generado por generate_seed.py (no editar a mano)")
w("-- Empresa ficticia de software e implementacion de ERP; 12 quincenas de 2026.")
w("-- INSS e IR son APROXIMADOS: sirven para practicar analisis, no para planilla legal.")
w("--")
w("-- REEMPLAZA los datos de ejemplo del esquema. Requiere schema_planilla_pymes_postgres.sql.")
w("-- Uso: psql -d planilla_pymes -f seed_planilla_postgres.sql")
w("-- =============================================================================")
w("SET search_path TO planilla;")
w("BEGIN;")
w("TRUNCATE planilla_movimientos, planilla_detalle, planillas, asistencia_resumen, salary_advances,")
w("         prestamos_empleado, periodos_pago, conceptos_nomina, empleados, departamentos, usuarios, empresas")
w("         RESTART IDENTITY CASCADE;")
w("")
w("INSERT INTO empresas (nombre, ruc, telefono, correo, direccion) VALUES (" + ", ".join(q(x) for x in EMPRESA) + ");")
w("")
w("INSERT INTO departamentos (empresa_id, nombre, descripcion) VALUES")
w(",\n".join(f"    (1, {q(n)}, {q(d)})" for n, d in DEPARTAMENTOS) + ";")
w("")
w("INSERT INTO usuarios (empresa_id, nombre, email, password_hash, rol) VALUES")
w("    (1, 'Usuario Admin', 'admin@tecnoservicios.com.ni', '$2y$12$demo.hash.seguro', 'admin'),")
w("    (1, 'Usuario RRHH', 'planilla@tecnoservicios.com.ni', '$2y$12$demo.hash.seguro', 'rrhh'),")
w("    (1, 'Usuario Finanzas', 'finanzas@tecnoservicios.com.ni', '$2y$12$demo.hash.seguro', 'contador');")
w("")
w("INSERT INTO empleados (empresa_id, departamento_id, codigo_empleado, nombres, apellidos, cedula, fecha_nacimiento,")
w("                       fecha_ingreso, fecha_salida, cargo, tipo_pago, salario_base, activo)")
w("SELECT 1, d.id, v.codigo, v.nombres, v.apellidos, v.cedula, v.nacimiento::date, v.ingreso::date, v.salida::date,")
w("       v.cargo, 'quincenal', v.salario, v.salida IS NULL")
w("FROM (VALUES")
w(",\n".join(
    f"    ({q(e['codigo'])}, {q(e['depto'])}, {q(e['nombres'])}, {q(e['apellidos'])}, {q(e['cedula'])}, "
    f"{q(e['nacimiento'])}, {q(e['ingreso'])}, {q(e['salida'])}, {q(e['cargo'])}, {e['salario']})"
    for e in empleados))
w(") AS v (codigo, depto, nombres, apellidos, cedula, nacimiento, ingreso, salida, cargo, salario)")
w("JOIN departamentos d ON d.nombre = v.depto;")
w("")
w("INSERT INTO periodos_pago (empresa_id, nombre, fecha_inicio, fecha_fin, fecha_pago, frecuencia, estado) VALUES")
w(",\n".join(f"    (1, {q(n)}, {q(i)}, {q(f)}, {q(f)}, 'quincenal', '{'calculado' if k == ULTIMO else 'cerrado'}')"
             for k, (n, i, f, _, _) in enumerate(periodos)) + ";")
w("")
w("INSERT INTO conceptos_nomina (empresa_id, codigo, nombre, tipo, naturaleza, afecta_bruto, es_obligatorio, orden_impresion) VALUES")
w("    (1, 'SALARIO',  'Salario base',              'ingreso',         'fijo',     true,  true,  1),")
w("    (1, 'HEXTRA',   'Horas extra',               'ingreso',         'variable', true,  false, 2),")
w("    (1, 'BONO',     'Bonificacion',              'ingreso',         'variable', true,  false, 3),")
w("    (1, 'INSS',     'Seguro social laboral',     'deduccion',       'formula',  false, true,  10),")
w("    (1, 'IR',       'Impuesto sobre la renta',   'deduccion',       'formula',  false, true,  11),")
w("    (1, 'ADEL',     'Adelanto de salario',       'deduccion',       'variable', false, false, 12),")
w("    (1, 'PREST',    'Cuota de prestamo',         'deduccion',       'variable', false, false, 13),")
w("    (1, 'INSS_PAT', 'Aporte patronal INSS',      'aporte_patronal', 'formula',  false, true,  20);")
w("")
w("INSERT INTO planillas (empresa_id, periodo_id, numero, observaciones, estado)")
w("SELECT 1, p.id, v.numero, NULL, v.estado::estado_planilla")
w("FROM (VALUES")
w(",\n".join(f"    ({q(n)}, 'PLN-2026-{m:02d}-Q{qq}', '{'aprobada' if k == ULTIMO else 'pagada'}')"
             for k, (n, _, _, m, qq) in enumerate(periodos)))
w(") AS v (periodo, numero, estado)")
w("JOIN periodos_pago p ON p.nombre = v.periodo;")
w("")
w("INSERT INTO planilla_detalle (planilla_id, empleado_id, salario_base, horas_trabajadas, horas_extras, ingresos,")
w("                              deducciones, aportes_patronales, salario_bruto, salario_neto, observaciones)")
w("SELECT pl.id, e.id, v.base, v.horas, v.extras, v.ingresos, v.deducciones, v.patronal, v.bruto, v.neto, v.obs")
w("FROM (VALUES")
w(",\n".join(f"    ({q(n)}, {q(c)}, {b}, {h}, {x}, {i}, {d}, {pa}, {br}, {ne}, {q(o)})"
             for n, c, b, h, x, i, d, pa, br, ne, o in detalles))
w(") AS v (numero, codigo, base, horas, extras, ingresos, deducciones, patronal, bruto, neto, obs)")
w("JOIN planillas pl ON pl.numero = v.numero")
w("JOIN empleados e ON e.codigo_empleado = v.codigo;")
w("")
w("INSERT INTO planilla_movimientos (detalle_id, concepto_id, descripcion, cantidad, monto)")
w("SELECT d.id, c.id, v.descripcion, v.cantidad, v.monto")
w("FROM (VALUES")
w(",\n".join(f"    ({q(n)}, {q(cod)}, {q(con)}, {q(desc)}, {cant}, {monto})"
             for n, cod, con, desc, cant, monto in movimientos))
w(") AS v (numero, codigo, concepto, descripcion, cantidad, monto)")
w("JOIN planillas pl ON pl.numero = v.numero")
w("JOIN empleados e ON e.codigo_empleado = v.codigo")
w("JOIN planilla_detalle d ON d.planilla_id = pl.id AND d.empleado_id = e.id")
w("JOIN conceptos_nomina c ON c.codigo = v.concepto;")
w("")
w("INSERT INTO asistencia_resumen (empresa_id, empleado_id, periodo_id, dias_trabajados, dias_ausentes, horas_normales, horas_extras)")
w("SELECT 1, e.id, p.id, v.trabajados, v.ausentes, v.horas, v.extras")
w("FROM (VALUES")
w(",\n".join(f"    ({q(c)}, {q(n)}, {t}, {a}, {h}, {x})" for c, n, t, a, h, x in asistencias))
w(") AS v (codigo, periodo, trabajados, ausentes, horas, extras)")
w("JOIN empleados e ON e.codigo_empleado = v.codigo")
w("JOIN periodos_pago p ON p.nombre = v.periodo;")
w("")
rows = []
for a in adelantos:
    estado = a.get("estado") or ("descontado" if a["saldo"] == 0 else "entregado")
    aprob = None if estado in {"solicitado", "anulado"} else a["solicitud"].replace(day=min(a["solicitud"].day + 1, 28))
    rows.append(f"    ({q(a['ref'])}, {q(a['codigo'])}, {q(a['solicitud'])}, {q(aprob)}, {q(aprob)}, {a['monto']}, "
                f"{a['saldo']}, {a['cuotas']}, {a['pagadas']}, '{estado}')")
w("INSERT INTO salary_advances (empresa_id, empleado_id, referencia, fecha_solicitud, fecha_aprobacion, fecha_entrega,")
w("                             monto_aprobado, saldo_pendiente, cuotas_pactadas, cuotas_pagadas, estado)")
w("SELECT 1, e.id, v.ref, v.solicitud::date, v.aprobacion::date, v.entrega::date, v.monto, v.saldo, v.cuotas, v.pagadas,")
w("       v.estado::estado_salary_advance")
w("FROM (VALUES")
w(",\n".join(rows))
w(") AS v (ref, codigo, solicitud, aprobacion, entrega, monto, saldo, cuotas, pagadas, estado)")
w("JOIN empleados e ON e.codigo_empleado = v.codigo;")
w("")
w("INSERT INTO prestamos_empleado (empresa_id, empleado_id, referencia, monto_total, saldo_actual, cuota_periodica, fecha_inicio, estado)")
w("SELECT 1, e.id, v.ref, v.monto, v.saldo, v.cuota, v.inicio::date, v.estado::estado_prestamo")
w("FROM (VALUES")
w(",\n".join(f"    ({q(p['ref'])}, {q(p['codigo'])}, {p['monto']}, {p['saldo']}, {p['cuota']}, {q(p['inicio'])}, "
             f"'{'cancelado' if p['saldo'] == 0 else 'activo'}')" for p in prestamos))
w(") AS v (ref, codigo, monto, saldo, cuota, inicio, estado)")
w("JOIN empleados e ON e.codigo_empleado = v.codigo;")
w("")
w("-- Totales del encabezado calculados desde el detalle")
w("UPDATE planillas p")
w("SET total_ingresos = d.ingresos, total_deducciones = d.deducciones, total_neto = d.neto")
w("FROM (SELECT planilla_id, SUM(ingresos) AS ingresos, SUM(deducciones) AS deducciones, SUM(salario_neto) AS neto")
w("      FROM planilla_detalle GROUP BY planilla_id) d")
w("WHERE d.planilla_id = p.id;")
w("")
w("COMMIT;")
print("\n".join(out))
