-- Vista Tabla 6
--6. Empleados, cargos y áreas
CREATE OR REPLACE VIEW fongal.vw_empleados_cargos AS
SELECT
    e.id_empleado,
    e.codigo_empleado,
    pn.nombres,
    pn.apellido_paterno,
    pn.apellido_materno,
    c.id_contrato,
    ca.nombre AS cargo,
    ar.nombre AS area,
    c.tipo_contrato,
    c.fecha_inicio,
    c.fecha_fin,
    e.estado
FROM fongal.empleado e
INNER JOIN fongal.persona_natural pn
    ON e.id_persona = pn.id_persona
INNER JOIN fongal.contrato c
    ON e.id_empleado = c.id_empleado
INNER JOIN fongal.cargo ca
    ON c.id_cargo = ca.id_cargo
INNER JOIN fongal.area ar
    ON c.id_area = ar.id_area;

SELECT *
FROM fongal.vw_empleados_cargos;
