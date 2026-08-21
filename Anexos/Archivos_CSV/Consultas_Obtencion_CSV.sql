SELECT
    nombre,
    descripcion,
    salario_base AS sueldo_base_referencial
FROM ADJG.cargo
ORDER BY id_cargo;



SELECT
    r.nombreregion AS nombre
FROM ADJG.region r
JOIN ADJG.pais p ON r.id_pais = p.id_pais
WHERE p.codigo_iso = 'PER' -- ajustar si el codigo ISO cargado es distinto
ORDER BY r.id_region;






SELECT
    s.nombresubregion AS nombre,
    r.nombreregion AS nombre_departamento
FROM ADJG.subregion s
JOIN ADJG.region r ON s.id_region = r.id_region
ORDER BY s.id_subregion;




SELECT
    c.nombreciudad AS nombre,
    c.codigo_ubigeo,
    s.nombresubregion AS nombre_provincia,
    r.nombreregion AS nombre_departamento
FROM ADJG.ciudad c
JOIN ADJG.subregion s ON c.id_subregion = s.id_subregion
JOIN ADJG.region r ON s.id_region = r.id_region
ORDER BY c.id_ciudad;




SELECT
    p.tipo_persona,
    td.nombredoc AS tipo_documento,
    p.numero_documento,
    p.email AS correo,
    p.telefono,
    UPPER(p.estado) AS estado, -- ADJG usa 'Activo'/'Inactivo'; fongal usa 'ACTIVO'/'INACTIVO'
    p.fecha_registro,
    p.nombres,
    p.apaterno AS apellido_paterno,
    p.amaterno AS apellido_materno,
    c.fecha_nacimiento,
    p.razon_social,
    p.nombre_comercial
FROM ADJG.persona p
JOIN ADJG.tipo_documento td ON p.id_tipo_documento = td.id_tipo_documento
LEFT JOIN ADJG.cliente c ON c.id_persona = p.id_persona
ORDER BY p.id_persona;



SELECT
    td.nombredoc AS tipo_documento,
    per.numero_documento,
    CONCAT(d.calle, ' ', d.numero) AS direccion_linea,
    d.referencia,
    c.nombreciudad AS nombre_distrito,
    s.nombresubregion AS nombre_provincia,
    r.nombreregion AS nombre_departamento,
    CAST(dc.es_principal AS INT) AS es_principal
FROM (
    SELECT id_persona, id_direccion, es_principal FROM ADJG.direccion_cliente
    UNION ALL
    SELECT id_persona, id_direccion, es_principal FROM ADJG.direccion_empleado
    UNION ALL
    SELECT id_persona, id_direccion, es_principal FROM ADJG.direccion_proveedor
) dc
JOIN ADJG.persona per ON per.id_persona = dc.id_persona
JOIN ADJG.tipo_documento td ON td.id_tipo_documento = per.id_tipo_documento
JOIN ADJG.direccion d ON d.id_direccion = dc.id_direccion
JOIN ADJG.ciudad c ON c.id_ciudad = d.id_ciudad
JOIN ADJG.subregion s ON s.id_subregion = c.id_subregion
JOIN ADJG.region r ON r.id_region = s.id_region
ORDER BY per.id_persona;