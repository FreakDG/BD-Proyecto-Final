-- Vista Tabla 3
--3. Árbol genealógico básico de animales
CREATE OR REPLACE VIEW fongal.vw_arbol_genealogico_animales AS
SELECT
    a.id_animal,
    a.codigo_arete,
    a.nombre AS animal,
    e.nombre AS especie,
    r.nombre AS raza,
    rg.id_padre,
    padre.nombre AS nombre_padre,
    rg.id_madre,
    madre.nombre AS nombre_madre,
    rg.numero_registro,
    rg.entidad_emisora,
    rg.fecha_emision
FROM fongal.animal a
INNER JOIN fongal.raza r
    ON a.id_raza = r.id_raza
INNER JOIN fongal.especie e
    ON r.id_especie = e.id_especie
LEFT JOIN fongal.registro_genealogico rg
    ON a.id_animal = rg.id_animal
LEFT JOIN fongal.animal padre
    ON rg.id_padre = padre.id_animal
LEFT JOIN fongal.animal madre
    ON rg.id_madre = madre.id_animal;

SELECT *
FROM fongal.vw_arbol_genealogico_animales;
