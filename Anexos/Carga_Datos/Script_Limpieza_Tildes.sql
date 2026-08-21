
-- Limpieza de acentos

SET search_path TO fongal, public;

CREATE EXTENSION IF NOT EXISTS unaccent;

BEGIN;

-- 1) DEPARTAMENTO
CREATE TEMP TABLE dep_map AS
SELECT id_departamento,
       nombre,
       min(id_departamento) OVER (PARTITION BY unaccent(lower(nombre))) AS id_departamento_final,
       first_value(nombre) OVER (
           PARTITION BY unaccent(lower(nombre))
           ORDER BY (nombre <> unaccent(nombre)) DESC, id_departamento
       ) AS nombre_final
FROM fongal.departamento;

SELECT id_departamento AS id_duplicado, nombre AS nombre_duplicado, id_departamento_final AS id_final, nombre_final
FROM dep_map
WHERE id_departamento <> id_departamento_final;

-- Para cada provincia que cuelga de un departamento duplicado, ver si YA
-- existe una provincia equivalente (mismo nombre normalizado) bajo el
-- departamento final. Si existe se fusiona
CREATE TEMP TABLE prov_redirect AS
SELECT p.id_provincia,
       dm.id_departamento_final,
       existente.id_provincia AS id_provincia_destino_si_existe
FROM fongal.provincia p
JOIN dep_map dm ON dm.id_departamento = p.id_departamento AND dm.id_departamento <> dm.id_departamento_final
LEFT JOIN fongal.provincia existente
       ON existente.id_departamento = dm.id_departamento_final
      AND unaccent(lower(existente.nombre)) = unaccent(lower(p.nombre));

-- Caso A: ya existe una provincia equivalente en el departamento final -> fusionar
UPDATE fongal.distrito di
SET id_provincia = pr.id_provincia_destino_si_existe
FROM prov_redirect pr
WHERE di.id_provincia = pr.id_provincia
  AND pr.id_provincia_destino_si_existe IS NOT NULL;

DELETE FROM fongal.provincia p
USING prov_redirect pr
WHERE p.id_provincia = pr.id_provincia
  AND pr.id_provincia_destino_si_existe IS NOT NULL;

-- Caso B: no existe equivalente -> simplemente mover el puntero de departamento
UPDATE fongal.provincia p
SET id_departamento = pr.id_departamento_final
FROM prov_redirect pr
WHERE p.id_provincia = pr.id_provincia
  AND pr.id_provincia_destino_si_existe IS NULL;

DROP TABLE prov_redirect;

-- Ya no quedan provincias colgando de los departamentos duplicados: borrarlos
DELETE FROM fongal.departamento d
USING dep_map m
WHERE d.id_departamento = m.id_departamento
  AND m.id_departamento <> m.id_departamento_final;

-- Recien ahora se corrige el nombre del que sobrevive
UPDATE fongal.departamento d
SET nombre = m.nombre_final
FROM dep_map m
WHERE d.id_departamento = m.id_departamento_final
  AND d.nombre <> m.nombre_final;

DROP TABLE dep_map;

-- 2) PROVINCIA
CREATE TEMP TABLE prov_map AS
SELECT id_provincia,
       id_departamento,
       nombre,
       min(id_provincia) OVER (PARTITION BY id_departamento, unaccent(lower(nombre))) AS id_provincia_final,
       first_value(nombre) OVER (
           PARTITION BY id_departamento, unaccent(lower(nombre))
           ORDER BY (nombre <> unaccent(nombre)) DESC, id_provincia
       ) AS nombre_final
FROM fongal.provincia;

SELECT id_provincia AS id_duplicado, nombre AS nombre_duplicado, id_provincia_final AS id_final, nombre_final
FROM prov_map
WHERE id_provincia <> id_provincia_final;

UPDATE fongal.distrito di
SET id_provincia = m.id_provincia_final
FROM prov_map m
WHERE di.id_provincia = m.id_provincia
  AND m.id_provincia <> m.id_provincia_final;

DELETE FROM fongal.provincia p
USING prov_map m
WHERE p.id_provincia = m.id_provincia
  AND m.id_provincia <> m.id_provincia_final;

UPDATE fongal.provincia p
SET nombre = m.nombre_final
FROM prov_map m
WHERE p.id_provincia = m.id_provincia_final
  AND p.nombre <> m.nombre_final;

DROP TABLE prov_map;

-- 3) DISTRITO (redirige establo, evento, direccion, direccion_envio)
CREATE TEMP TABLE dist_map AS
SELECT id_distrito,
       id_provincia,
       nombre,
       min(id_distrito) OVER (PARTITION BY id_provincia, unaccent(lower(nombre))) AS id_distrito_final,
       first_value(nombre) OVER (
           PARTITION BY id_provincia, unaccent(lower(nombre))
           ORDER BY (nombre <> unaccent(nombre)) DESC, id_distrito
       ) AS nombre_final
FROM fongal.distrito;

SELECT id_distrito AS id_duplicado, nombre AS nombre_duplicado, id_distrito_final AS id_final, nombre_final
FROM dist_map
WHERE id_distrito <> id_distrito_final;

UPDATE fongal.establo e
SET id_distrito = m.id_distrito_final
FROM dist_map m
WHERE e.id_distrito = m.id_distrito
  AND m.id_distrito <> m.id_distrito_final;

UPDATE fongal.evento ev
SET id_distrito = m.id_distrito_final
FROM dist_map m
WHERE ev.id_distrito = m.id_distrito
  AND m.id_distrito <> m.id_distrito_final;

UPDATE fongal.direccion dr
SET id_distrito = m.id_distrito_final
FROM dist_map m
WHERE dr.id_distrito = m.id_distrito
  AND m.id_distrito <> m.id_distrito_final;

UPDATE fongal.direccion_envio de
SET id_distrito = m.id_distrito_final
FROM dist_map m
WHERE de.id_distrito = m.id_distrito
  AND m.id_distrito <> m.id_distrito_final;

DELETE FROM fongal.distrito d
USING dist_map m
WHERE d.id_distrito = m.id_distrito
  AND m.id_distrito <> m.id_distrito_final;

UPDATE fongal.distrito d
SET nombre = m.nombre_final
FROM dist_map m
WHERE d.id_distrito = m.id_distrito_final
  AND d.nombre <> m.nombre_final;

DROP TABLE dist_map;

COMMIT;

-- VERIFICACION
SELECT 'departamento' AS tabla, count(*) FROM fongal.departamento
UNION ALL
SELECT 'provincia', count(*) FROM fongal.provincia
UNION ALL
SELECT 'distrito', count(*) FROM fongal.distrito;

-- Debe salir vacio (confirma que no quedan duplicados por tildes)
SELECT unaccent(lower(nombre)) AS nombre_normalizado, count(*)
FROM fongal.departamento
GROUP BY unaccent(lower(nombre))
HAVING count(*) > 1;

-- Muestra los 4 nombres finales (deben salir CON tilde)
SELECT nombre FROM fongal.departamento
WHERE unaccent(lower(nombre)) IN ('apurimac','huanuco','junin','san martin')
ORDER BY nombre;
