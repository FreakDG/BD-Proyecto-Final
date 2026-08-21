-- Vista Tabla 7
--7. Historial salarial de empleados
CREATE OR REPLACE VIEW fongal.vw_historial_salarial AS
SELECT
    e.id_empleado,
    pn.nombres,
    pn.apellido_paterno,
    pn.apellido_materno,
    ca.nombre AS cargo,
    hs.monto_remuneracion,
    hs.fecha_inicio_vigencia,
    hs.motivo
FROM fongal.historial_salarial hs
INNER JOIN fongal.contrato c
    ON hs.id_contrato = c.id_contrato
INNER JOIN fongal.empleado e
    ON c.id_empleado = e.id_empleado
INNER JOIN fongal.persona_natural pn
    ON e.id_persona = pn.id_persona
INNER JOIN fongal.cargo ca
    ON c.id_cargo = ca.id_cargo;

SELECT *
FROM fongal.vw_historial_salarial;
