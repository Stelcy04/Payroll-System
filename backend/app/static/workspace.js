const api={employees:"/employees",employeeBulkExcel:"/employees/bulk-excel",employeeReport:"/employees/reports/hiring",periods:"/periods",periodRepo:"/periods/repository",advances:"/salary-advances",advanceReport:"/salary-advances/reports/created",payrolls:"/payroll-runs",generatePayroll:"/payrolls/generate"};
const state={employees:[],periodRepo:{open:[],closed:[],future:[],summary:{open:0,closed:0,future:0}},advances:[],payrolls:[]};
const titles={employees:["Repositorio de empleados","Consulta el repositorio, crea nuevos registros o importa empleados desde Excel."],periods:["Repositorio de periodos","Gestiona periodos abiertos, cerrados y futuros desde una pantalla propia."],advances:["Repositorio de salary advances","Registra y consulta salary advances con su reporte por ciclo."],payrolls:["Repositorio de planillas","Genera planillas y revisa el detalle por empleado."]};
const toast=document.getElementById("toast");
const qs=id=>document.getElementById(id);
const fmt=v=>new Intl.NumberFormat("es-NI",{style:"currency",currency:"NIO",minimumFractionDigits:2}).format(Number(v||0));
const badge=v=>`<span class="badge ${["discounted","calculated","closed"].includes(v)?"warn":v==="future"?"neutral":""}">${v||"-"}</span>`;

function showToast(message){toast.textContent=message;toast.classList.add("show");clearTimeout(showToast.t);showToast.t=setTimeout(()=>toast.classList.remove("show"),2400)}

async function request(url,opt={}){
  const headers=opt.body instanceof FormData?{}:{"Content-Type":"application/json"};
  const response=await fetch(url,{headers,...opt});
  if(!response.ok){
    const type=response.headers.get("content-type")||"";
    if(type.includes("application/json")){
      const payload=await response.json();
      throw new Error(payload.detail||"Error");
    }
    throw new Error(await response.text()||"Error");
  }
  const type=response.headers.get("content-type")||"";
  return type.includes("application/json")?response.json():response.text();
}

function createInput(label,name,type="text",value=""){return `<div><label for="${name}">${label}</label><input id="${name}" name="${name}" type="${type}" value="${value}"></div>`}
function createSelect(label,name,options){return `<div><label for="${name}">${label}</label><select id="${name}" name="${name}">${options.map(o=>`<option value="${o.value}">${o.label}</option>`).join("")}</select></div>`}
function renderTable(node,cols,rows,empty){if(!rows.length){node.innerHTML=`<div class="empty">${empty}</div>`;return}node.innerHTML=`<div class="table-wrap"><table><thead><tr>${cols.map(c=>`<th>${c.label}</th>`).join("")}</tr></thead><tbody>${rows.map(r=>`<tr>${cols.map(c=>`<td>${c.render?c.render(r[c.key],r):(r[c.key]??"")}</td>`).join("")}</tr>`).join("")}</tbody></table></div>`}

function setActiveScreen(screen){
  document.querySelectorAll(".menu-item").forEach(btn=>btn.classList.toggle("active",btn.dataset.screen===screen));
  document.querySelectorAll(".screen").forEach(view=>view.classList.toggle("active",view.id===`screen-${screen}`));
  qs("screen-title").textContent=titles[screen][0];
  qs("screen-description").textContent=titles[screen][1];
}

function showEmployeeRepository(){qs("employees-repository-panel").classList.remove("hidden");qs("employees-create-panel").classList.add("hidden")}
function showEmployeeCreate(){qs("employees-repository-panel").classList.add("hidden");qs("employees-create-panel").classList.remove("hidden")}
function showAdvanceRepository(){qs("advances-repository-panel").classList.remove("hidden");qs("advances-create-panel").classList.add("hidden")}
function showAdvanceCreate(){qs("advances-repository-panel").classList.add("hidden");qs("advances-create-panel").classList.remove("hidden")}
function nextAdvanceReference(){return `SA-${Date.now().toString().slice(-6)}`}

function buildForms(){
  qs("employee-form").innerHTML=`${createInput("Codigo","code","text","EMP-201")}${createInput("Documento","identity_document")}<div class="form-row">${createInput("Nombres","first_name","text","Maria")}${createInput("Apellidos","last_name","text","Lopez")}</div><div class="form-row">${createInput("Fecha ingreso","hire_date","date","2026-04-07")}${createInput("Fecha nacimiento","birth_date","date","")}</div><div class="form-row">${createInput("Correo","email","email","")}${createInput("Telefono","phone","text","")}</div>${createInput("Direccion","address")}<div class="form-row">${createInput("Departamento","department","text","Contabilidad")}${createInput("Cargo","position","text","Auxiliar contable")}</div><div class="form-row">${createSelect("Contrato","contract_type",[{value:"permanent",label:"Permanente"},{value:"temporary",label:"Temporal"},{value:"services",label:"Servicios"}])}${createSelect("Ciclo","payment_type",[{value:"monthly",label:"Mensual"},{value:"biweekly",label:"Quincenal"},{value:"weekly",label:"Semanal"}])}</div>${createInput("Salario base","base_salary","number","13000")}<button class="btn primary" type="submit">Guardar empleado</button>`;
  qs("employees-report-toolbar").innerHTML=`<div class="toolbar"><select id="employee-report-group"><option value="monthly">Mensual</option><option value="biweekly">Quincenal</option><option value="annual">Anual</option></select><button class="btn ghost small" id="employee-report-refresh" type="button">Actualizar</button><a class="btn ghost small" id="employees-report-excel" href="/employees/reports/hiring/export.xlsx?group_by=monthly">Excel</a><a class="btn ghost small" id="employees-report-pdf" href="/employees/reports/hiring/export.pdf?group_by=monthly">PDF</a></div>`;
  qs("period-form").innerHTML=`${createInput("Nombre","period-name","text","Abril 2026 - Quincena 2")}<div class="form-row">${createInput("Inicio","start_date","date","2026-04-16")}${createInput("Fin","end_date","date","2026-04-30")}</div><div class="form-row">${createInput("Pago","payment_date","date","2026-04-30")}${createSelect("Frecuencia","frequency",[{value:"biweekly",label:"Quincenal"},{value:"monthly",label:"Mensual"},{value:"weekly",label:"Semanal"}])}</div>${createSelect("Estado","status",[{value:"open",label:"Abierto"},{value:"future",label:"Futuro"},{value:"closed",label:"Cerrado"}])}${createInput("Notas","notes")}<button class="btn primary" type="submit">Guardar periodo</button>`;
  qs("advance-form").innerHTML=`<div><label for="advance-employee">Empleado</label><select id="advance-employee" name="employee_id"></select></div><div class="form-row">${createInput("Referencia","reference","text",nextAdvanceReference())}${createSelect("Ciclo de pago","payment_cycle",[{value:"monthly",label:"Mensual"},{value:"biweekly",label:"Quincenal"}])}</div><div class="form-row">${createInput("Monto aprobado","amount_approved","number","800")}${createInput("Fecha solicitud","request_date","date","2026-04-07")}</div>${createInput("Notas","notes","text","Creado desde workspace")}<button class="btn primary" type="submit">Guardar salary advance</button>`;
  qs("advances-report-toolbar").innerHTML=`<div class="toolbar"><select id="advance-report-group"><option value="monthly">Mensual</option><option value="biweekly">Quincenal</option></select><button class="btn ghost small" id="advance-report-refresh" type="button">Actualizar</button><a class="btn ghost small" id="advances-report-excel" href="/salary-advances/reports/created/export.xlsx?group_by=monthly">Excel</a><a class="btn ghost small" id="advances-report-pdf" href="/salary-advances/reports/created/export.pdf?group_by=monthly">PDF</a></div>`;
  qs("payroll-form").innerHTML=`<div><label for="payroll-period">Periodo</label><select id="payroll-period" name="period_id"></select></div><button class="btn secondary" type="submit">Generar planilla</button>`;
}

function fillSelectors(){
  qs("advance-employee").innerHTML=state.employees.map(e=>`<option value="${e.id}">${e.code} - ${e.first_name} ${e.last_name}</option>`).join("");
  qs("payroll-period").innerHTML=state.periodRepo.open.map(p=>`<option value="${p.id}">${p.name}</option>`).join("");
}

function renderEmployees(){
  renderTable(qs("employees-repository"),[
    {key:"code",label:"Codigo"},
    {key:"first_name",label:"Empleado",render:(_,r)=>`${r.first_name} ${r.last_name}`},
    {key:"identity_document",label:"Documento"},
    {key:"hire_date",label:"Ingreso"},
    {key:"department",label:"Departamento"},
    {key:"position",label:"Cargo"},
    {key:"employment_status",label:"Estado",render:v=>badge(v||"active")},
    {key:"payment_type",label:"Ciclo"},
    {key:"base_salary",label:"Salario",render:v=>fmt(v)},
    {key:"id",label:"Acciones",render:(v,r)=>{
      if(r.can_delete){
        return `<button class="btn danger small" data-delete-employee="${v}" data-name="${r.first_name} ${r.last_name}">Eliminar</button>`;
      }
      return `<div class="actions"><button class="btn ghost small" data-deactivate-employee="${v}" data-name="${r.first_name} ${r.last_name}">Deactivate</button><button class="btn ghost small" data-archive-employee="${v}" data-name="${r.first_name} ${r.last_name}">Archive</button></div>`;
    }}
  ],state.employees,"No hay empleados registrados.");
  document.querySelectorAll("[data-delete-employee]").forEach(btn=>btn.onclick=async()=>{try{if(!confirm(`Eliminar a ${btn.dataset.name}?`))return;await request(`/employees/${btn.dataset.deleteEmployee}`,{method:"DELETE"});showToast("Empleado eliminado");await loadData()}catch{showToast("No se pudo eliminar el empleado")}});
  document.querySelectorAll("[data-deactivate-employee]").forEach(btn=>btn.onclick=async()=>{try{if(!confirm(`Desactivar a ${btn.dataset.name}?`))return;await request(`/employees/${btn.dataset.deactivateEmployee}/deactivate`,{method:"PATCH"});showToast("Empleado desactivado");await loadData()}catch(error){showToast(error.message||"No se pudo desactivar")}});
  document.querySelectorAll("[data-archive-employee]").forEach(btn=>btn.onclick=async()=>{try{if(!confirm(`Archivar a ${btn.dataset.name}?`))return;await request(`/employees/${btn.dataset.archiveEmployee}/archive`,{method:"PATCH"});showToast("Empleado archivado");await loadData()}catch(error){showToast(error.message||"No se pudo archivar")}});
}

async function renderEmployeeReport(){
  const data=await request(`${api.employeeReport}?group_by=${qs("employee-report-group").value}`);
  renderTable(qs("employees-report"),[{key:"period",label:"Periodo"},{key:"count",label:"Contratados"}],data.rows,"Sin datos para este reporte.");
  qs("employees-report-excel").href=`/employees/reports/hiring/export.xlsx?group_by=${qs("employee-report-group").value}`;
  qs("employees-report-pdf").href=`/employees/reports/hiring/export.pdf?group_by=${qs("employee-report-group").value}`;
}

function renderPeriods(){
  qs("periods-open-count").textContent=state.periodRepo.summary.open;
  qs("periods-closed-count").textContent=state.periodRepo.summary.closed;
  qs("periods-future-count").textContent=state.periodRepo.summary.future;
  const cols=[{key:"name",label:"Periodo"},{key:"start_date",label:"Inicio"},{key:"end_date",label:"Fin"},{key:"payment_date",label:"Pago"},{key:"frequency",label:"Frecuencia"},{key:"status",label:"Estado",render:v=>badge(v)}];
  renderTable(qs("periods-open-table"),cols,state.periodRepo.open,"No hay periodos abiertos.");
  renderTable(qs("periods-closed-table"),cols,state.periodRepo.closed,"No hay periodos cerrados.");
  renderTable(qs("periods-future-table"),cols,state.periodRepo.future,"No hay periodos futuros.");
}

function renderAdvances(){
  renderTable(qs("advances-repository"),[
    {key:"reference",label:"Referencia"},
    {key:"employee_id",label:"Empleado",render:v=>{const e=state.employees.find(x=>x.id===v);return e?`${e.code} - ${e.first_name} ${e.last_name}`:`Empleado ${v}`}},
    {key:"request_date",label:"Solicitud"},
    {key:"payment_cycle",label:"Ciclo"},
    {key:"amount_approved",label:"Monto",render:v=>fmt(v)},
    {key:"balance_pending",label:"Saldo",render:v=>fmt(v)},
    {key:"status",label:"Estado",render:v=>badge(v)},
    {key:"id",label:"Acciones",render:(v,r)=>r.status==="discounted"?`<span class="badge neutral">Aplicado</span>`:`<button class="btn danger small" data-delete-advance="${v}" data-ref="${r.reference}">Eliminar</button>`}
  ],state.advances,"No hay salary advances registrados.");
  document.querySelectorAll("[data-delete-advance]").forEach(btn=>btn.onclick=async()=>{try{if(!confirm(`Eliminar ${btn.dataset.ref}?`))return;await request(`/salary-advances/${btn.dataset.deleteAdvance}`,{method:"DELETE"});showToast("Salary advance eliminado");await loadData()}catch{showToast("No se pudo eliminar el salary advance")}});
}

async function renderAdvanceReport(){
  const data=await request(`${api.advanceReport}?group_by=${qs("advance-report-group").value}`);
  renderTable(qs("advances-report"),[{key:"period",label:"Periodo"},{key:"count",label:"Cantidad"},{key:"amount_total",label:"Monto total",render:v=>fmt(v)}],data.rows,"Sin datos para este reporte.");
  qs("advances-report-excel").href=`/salary-advances/reports/created/export.xlsx?group_by=${qs("advance-report-group").value}`;
  qs("advances-report-pdf").href=`/salary-advances/reports/created/export.pdf?group_by=${qs("advance-report-group").value}`;
}

async function renderPayrolls(){
  const items=await Promise.all(state.payrolls.map(p=>request(`${api.payrolls}/${p.id}`)));
  qs("payrolls-repository").innerHTML=!items.length?`<div class="empty">No hay planillas generadas.</div>`:items.map(p=>`<article class="payroll-card"><div class="payroll-head"><strong>Planilla #${p.id}</strong><div>${p.period_name} | Pago ${p.payment_date||"-"}</div></div><div style="padding:16px"><div class="meta"><div><span>Estado</span><strong>${p.period_status||"-"}</strong></div><div><span>Rango</span><strong>${p.period_start_date||"-"} al ${p.period_end_date||"-"}</strong></div><div><span>Empleados</span><strong>${p.employees_count}</strong></div><div><span>Total neto</span><strong>${fmt(p.net_total)}</strong></div></div><div class="table-wrap"><table><thead><tr><th>Empleado</th><th>Codigo</th><th>Salario</th><th>Advance</th><th>Deducciones</th><th>Neto</th></tr></thead><tbody>${p.details.map(d=>`<tr><td>${d.employee_name||`Empleado ${d.employee_id}`}</td><td>${d.employee_code}</td><td>${fmt(d.base_salary)}</td><td>${fmt(d.salary_advance_discount)}</td><td>${fmt(d.total_deductions)}</td><td>${fmt(d.net_salary)}</td></tr>`).join("")}</tbody></table></div></div></article>`).join("");
}

async function uploadEmployeeExcel(file){
  if(!file) return;
  const body=new FormData();
  body.append("file",file);
  try{
    const result=await request(`${api.employeeBulkExcel}?company_id=1`,{method:"POST",body});
    qs("employee-excel-status").textContent=`${result.created_count} creados, ${result.skipped_count} omitidos`;
    showToast("Carga desde Excel completada");
    await loadData();
  }catch{
    showToast("No se pudo cargar el Excel");
  }
}

async function loadData(){
  const [employees,periodRepo,advances,payrolls]=await Promise.all([request(api.employees),request(api.periodRepo),request(api.advances),request(api.payrolls)]);
  state.employees=employees;
  state.periodRepo=periodRepo;
  state.advances=advances;
  state.payrolls=payrolls;
  fillSelectors();
  renderEmployees();
  renderPeriods();
  renderAdvances();
  await renderEmployeeReport();
  await renderAdvanceReport();
  await renderPayrolls();
}

function bindUI(){
  document.querySelectorAll(".menu-item").forEach(btn=>btn.onclick=()=>setActiveScreen(btn.dataset.screen));
  qs("employees-create-new").onclick=showEmployeeCreate;
  qs("employees-back-to-repository").onclick=showEmployeeRepository;
  qs("advances-create-new").onclick=showAdvanceCreate;
  qs("advances-back-to-repository").onclick=showAdvanceRepository;
  qs("employees-excel-file").addEventListener("change",e=>uploadEmployeeExcel(e.target.files[0]));
  document.addEventListener("click",e=>{if(e.target.id==="employee-report-refresh")renderEmployeeReport();if(e.target.id==="advance-report-refresh")renderAdvanceReport()});
}

function bindForms(){
  qs("employee-form").addEventListener("submit",async e=>{
    e.preventDefault();
    const d=Object.fromEntries(new FormData(e.currentTarget).entries());
    d.company_id=1;
    d.base_salary=Number(d.base_salary);
    d.active=true;
    try{
      await request(api.employees,{method:"POST",body:JSON.stringify(d)});
      e.currentTarget.reset();
      qs("code").value=`EMP-${Math.floor(Math.random()*900+100)}`;
      showToast("Empleado creado");
      showEmployeeRepository();
      await loadData();
    }catch(error){showToast(error.message||"No se pudo crear el empleado")}
  });

  qs("period-form").addEventListener("submit",async e=>{
    e.preventDefault();
    const f=new FormData(e.currentTarget);
    const d={company_id:1,name:f.get("period-name"),start_date:f.get("start_date"),end_date:f.get("end_date"),payment_date:f.get("payment_date"),frequency:f.get("frequency"),status:f.get("status"),notes:f.get("notes")};
    try{await request(api.periods,{method:"POST",body:JSON.stringify(d)});showToast("Periodo guardado");await loadData()}catch(error){showToast(error.message||"No se pudo guardar el periodo")}
  });

  qs("advance-form").addEventListener("submit",async e=>{
    e.preventDefault();
    const d=Object.fromEntries(new FormData(e.currentTarget).entries());
    d.company_id=1;
    d.employee_id=Number(d.employee_id);
    d.amount_approved=Number(d.amount_approved);
    d.balance_pending=d.amount_approved;
    d.installments_planned=1;
    d.installments_paid=0;
    d.status="approved";
    d.approval_date=d.request_date;
    d.delivery_date=d.request_date;
    try{
      await request(api.advances,{method:"POST",body:JSON.stringify(d)});
      showToast("Salary advance guardado");
      e.currentTarget.reset();
      qs("reference").value=nextAdvanceReference();
      qs("request_date").value="2026-04-07";
      showAdvanceRepository();
      await loadData();
    }catch(error){showToast(error.message||"No se pudo guardar el salary advance")}
  });

  qs("payroll-form").addEventListener("submit",async e=>{
    e.preventDefault();
    const d={company_id:1,period_id:Number(new FormData(e.currentTarget).get("period_id"))};
    try{await request(api.generatePayroll,{method:"POST",body:JSON.stringify(d)});showToast("Planilla generada");await loadData()}catch(error){showToast(error.message||"No se pudo generar la planilla")}
  });
}

buildForms();
bindUI();
bindForms();
showEmployeeRepository();
showAdvanceRepository();
loadData().catch(()=>showToast("No se pudo cargar el workspace"));
