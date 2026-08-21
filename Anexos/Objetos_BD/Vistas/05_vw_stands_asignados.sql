-- Vista Tabla 5
--5. Stands y sus asignaciones
CREATE OR REPLACE VIEW fongal.vw_stands_asignados AS
SELECT
    s.id_stand,
    e.nombre AS evento,
    s.codigo AS codigo_stand,
    s.zona,
    s.area_m2,
    s.tarifa_base,
    a.id_asignacion,
    a.id_persona,
    a.fecha_inicio,
    a.fecha_fin,
    a.monto_pactado,
    a.estado
FROM fongal.stand s
INNER JOIN fongal.evento e
    ON s.id_evento = e.id_evento
LEFT JOIN fongal.asignacion_stand a
    ON s.id_stand = a.id_stand;

SELECT *
FROM fongal.vw_stands_asignados;
