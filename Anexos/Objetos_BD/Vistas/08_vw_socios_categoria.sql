-- Vista Tabla 8
--8. Socios y sus categorías
CREATE OR REPLACE VIEW fongal.vw_socios_categoria AS
SELECT
    s.id_socio,
    s.codigo_socio,
    pn.nombres,
    pn.apellido_paterno,
    pn.apellido_materno,
    cs.nombre AS categoria_socio,
    cs.cuota_base,
    s.fecha_afiliacion,
    s.estado_afiliacion
FROM fongal.socio s
INNER JOIN fongal.persona p
    ON s.id_persona = p.id_persona
INNER JOIN fongal.persona_natural pn
    ON p.id_persona = pn.id_persona
INNER JOIN fongal.categoria_socio cs
    ON s.id_categoria_socio = cs.id_categoria_socio;

SELECT *
FROM fongal.vw_socios_categoria;
