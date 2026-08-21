-- Vista Tabla 9
--9. Participantes y resultados de evaluaciones
CREATE OR REPLACE VIEW fongal.vw_resultados_concursos AS
SELECT
    p.id_participacion,
    c.nombre AS concurso,
    a.codigo_arete,
    a.nombre AS animal,
    e.id_evaluacion,
    SUM(de.puntaje) AS puntaje_total,
    e.observaciones
FROM fongal.participacion p
INNER JOIN fongal.concurso c
    ON p.id_concurso = c.id_concurso
LEFT JOIN fongal.animal a
    ON p.id_animal = a.id_animal
INNER JOIN fongal.evaluacion e
    ON p.id_participacion = e.id_participacion
INNER JOIN fongal.detalle_evaluacion de
    ON e.id_evaluacion = de.id_evaluacion
GROUP BY
    p.id_participacion,
    c.nombre,
    a.codigo_arete,
    a.nombre,
    e.id_evaluacion,
    e.observaciones;

SELECT *
FROM fongal.vw_resultados_concursos
ORDER BY puntaje_total DESC;
