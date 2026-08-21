-- Vista Tabla 4
--4. Animales y su peso más reciente
CREATE OR REPLACE VIEW fongal.vw_animales_ultimo_peso AS
SELECT
    a.id_animal,
    a.codigo_arete,
    a.nombre AS animal,
    a.sexo,
    cp.fecha,
    cp.peso_kg
FROM fongal.animal a
INNER JOIN fongal.control_peso cp
    ON a.id_animal = cp.id_animal
WHERE cp.fecha = (
    SELECT MAX(cp2.fecha)
    FROM fongal.control_peso cp2
    WHERE cp2.id_animal = cp.id_animal
);

SELECT *
FROM fongal.vw_animales_ultimo_peso;
