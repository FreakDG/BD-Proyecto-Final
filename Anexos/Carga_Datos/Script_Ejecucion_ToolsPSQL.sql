
-- CARGA MASIVA ADJG a FONGAL - PARTE 2 (solo PostgreSQL)

SET search_path TO fongal, public;

CREATE EXTENSION IF NOT EXISTS unaccent;

-- 1) cargo
CREATE TEMP TABLE stg_cargo (
    nombre varchar(120),
    descripcion text,
    sueldo_base_referencial numeric(12,2)
);
\copy stg_cargo FROM 'C:\carga\cargo.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

-- Si ya existe con el mismo nombre normalizado pero SIN tilde, y la version entrante SI trae tilde, se corrige el nombre existente en vez
-- de descartar la version correcta.
UPDATE fongal.cargo c
SET nombre = s.nombre
FROM stg_cargo s
WHERE unaccent(lower(c.nombre)) = unaccent(lower(s.nombre))
  AND c.nombre <> s.nombre
  AND s.nombre <> unaccent(s.nombre);

INSERT INTO fongal.cargo (nombre, descripcion, sueldo_base_referencial)
SELECT DISTINCT s.nombre, s.descripcion, s.sueldo_base_referencial
FROM stg_cargo s
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.cargo c WHERE unaccent(lower(c.nombre)) = unaccent(lower(s.nombre))
);

DROP TABLE stg_cargo;

-- 2) departamento
CREATE TEMP TABLE stg_departamento (
    nombre varchar(120)
);
\copy stg_departamento FROM 'C:\carga\departamento.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

UPDATE fongal.departamento d
SET nombre = s.nombre
FROM stg_departamento s
WHERE unaccent(lower(d.nombre)) = unaccent(lower(s.nombre))
  AND d.nombre <> s.nombre
  AND s.nombre <> unaccent(s.nombre);

INSERT INTO fongal.departamento (nombre)
SELECT DISTINCT s.nombre
FROM stg_departamento s
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.departamento d WHERE unaccent(lower(d.nombre)) = unaccent(lower(s.nombre))
);

DROP TABLE stg_departamento;

-- 3) provincia (resolver id_departamento por nombre; se salta si ya
--    existe esa provincia dentro de ese mismo departamento)
CREATE TEMP TABLE stg_provincia (
    nombre varchar(120),
    nombre_departamento varchar(120)
);
\copy stg_provincia FROM 'C:\carga\provincia.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

UPDATE fongal.provincia p
SET nombre = s.nombre
FROM stg_provincia s
JOIN fongal.departamento d ON unaccent(lower(d.nombre)) = unaccent(lower(s.nombre_departamento))
WHERE p.id_departamento = d.id_departamento
  AND unaccent(lower(p.nombre)) = unaccent(lower(s.nombre))
  AND p.nombre <> s.nombre
  AND s.nombre <> unaccent(s.nombre);

INSERT INTO fongal.provincia (id_departamento, nombre)
SELECT DISTINCT d.id_departamento, s.nombre
FROM stg_provincia s
JOIN fongal.departamento d ON unaccent(lower(d.nombre)) = unaccent(lower(s.nombre_departamento))
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.provincia p2
    WHERE p2.id_departamento = d.id_departamento AND unaccent(lower(p2.nombre)) = unaccent(lower(s.nombre))
);

DROP TABLE stg_provincia;

-- 4) distrito (resolver id_provincia por nombre + departamento; se salta si ya existe el distrito por nombre dentro de esa provincia, o si
--    su codigo_ubigeo ya existe -- fongal exige codigo_ubigeo UNIQUE)
CREATE TEMP TABLE stg_distrito (
    nombre varchar(120),
    codigo_ubigeo varchar(6),
    nombre_provincia varchar(120),
    nombre_departamento varchar(120)
);
\copy stg_distrito FROM 'C:\carga\distrito.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

UPDATE fongal.distrito di
SET nombre = s.nombre
FROM stg_distrito s
JOIN fongal.departamento d ON unaccent(lower(d.nombre)) = unaccent(lower(s.nombre_departamento))
JOIN fongal.provincia p ON p.id_departamento = d.id_departamento AND unaccent(lower(p.nombre)) = unaccent(lower(s.nombre_provincia))
WHERE di.id_provincia = p.id_provincia
  AND unaccent(lower(di.nombre)) = unaccent(lower(s.nombre))
  AND di.nombre <> s.nombre
  AND s.nombre <> unaccent(s.nombre);

INSERT INTO fongal.distrito (id_provincia, nombre, codigo_ubigeo)
SELECT DISTINCT p.id_provincia, s.nombre, s.codigo_ubigeo
FROM stg_distrito s
JOIN fongal.departamento d ON unaccent(lower(d.nombre)) = unaccent(lower(s.nombre_departamento))
JOIN fongal.provincia p ON p.id_departamento = d.id_departamento AND unaccent(lower(p.nombre)) = unaccent(lower(s.nombre_provincia))
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.distrito di
    WHERE di.id_provincia = p.id_provincia AND unaccent(lower(di.nombre)) = unaccent(lower(s.nombre))
)
AND NOT EXISTS (
    SELECT 1 FROM fongal.distrito di2 WHERE di2.codigo_ubigeo = s.codigo_ubigeo
);

DROP TABLE stg_distrito;

-- 5) persona, aqui se incluye persona + persona_natural/persona_juridica
CREATE TEMP TABLE stg_persona (
    tipo_persona char(1),
    tipo_documento varchar(120),
    numero_documento varchar(20),
    correo varchar(120),
    telefono varchar(20),
    estado varchar(30),
    fecha_registro timestamptz,
    nombres varchar(120),
    apellido_paterno varchar(120),
    apellido_materno varchar(120),
    fecha_nacimiento date,
    razon_social varchar(120),
    nombre_comercial varchar(120)
);
\copy stg_persona FROM 'C:\carga\persona.csv' WITH (FORMAT csv, DELIMITER ';', NULL 'NULL', ENCODING 'UTF8');

INSERT INTO fongal.persona (tipo_persona, tipo_documento, numero_documento, correo, telefono, estado, fecha_registro)
SELECT s.tipo_persona, s.tipo_documento, s.numero_documento, s.correo, s.telefono, s.estado, s.fecha_registro
FROM stg_persona s
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.persona p2
    WHERE p2.tipo_documento = s.tipo_documento AND p2.numero_documento = s.numero_documento
);

INSERT INTO fongal.persona_natural (id_persona, nombres, apellido_paterno, apellido_materno, fecha_nacimiento)
SELECT p.id_persona, s.nombres, s.apellido_paterno, s.apellido_materno, s.fecha_nacimiento
FROM stg_persona s
JOIN fongal.persona p ON p.tipo_documento = s.tipo_documento AND p.numero_documento = s.numero_documento
WHERE s.tipo_persona = 'N'
AND NOT EXISTS (SELECT 1 FROM fongal.persona_natural pn WHERE pn.id_persona = p.id_persona);

INSERT INTO fongal.persona_juridica (id_persona, razon_social, nombre_comercial)
SELECT p.id_persona, s.razon_social, s.nombre_comercial
FROM stg_persona s
JOIN fongal.persona p ON p.tipo_documento = s.tipo_documento AND p.numero_documento = s.numero_documento
WHERE s.tipo_persona = 'J'
AND NOT EXISTS (SELECT 1 FROM fongal.persona_juridica pj WHERE pj.id_persona = p.id_persona);

DROP TABLE stg_persona;

-- 6) direccion -> direccion 
CREATE TEMP TABLE stg_direccion (
    tipo_documento varchar(120),
    numero_documento varchar(20),
    direccion_linea text,
    referencia text,
    nombre_distrito varchar(120),
    nombre_provincia varchar(120),
    nombre_departamento varchar(120),
    es_principal boolean
);
\copy stg_direccion FROM 'C:\carga\direccion.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

-- es_principal se fuerza a false: en el origen (ADJG) puede haber mas de
-- una direccion marcada como principal para la misma persona lo que viola el indice unico parcial
-- uq_direccion_principal de fongal (maximo una direccion principal por
-- persona). Las direcciones migradas entran como secundarias.
INSERT INTO fongal.direccion (id_persona, id_distrito, direccion_linea, referencia, es_principal)
SELECT p.id_persona, dist.id_distrito, s.direccion_linea, s.referencia, false
FROM stg_direccion s
JOIN fongal.persona p ON p.tipo_documento = s.tipo_documento AND p.numero_documento = s.numero_documento
JOIN fongal.departamento dep ON dep.nombre = s.nombre_departamento
JOIN fongal.provincia prov ON prov.id_departamento = dep.id_departamento AND prov.nombre = s.nombre_provincia
JOIN fongal.distrito dist ON dist.id_provincia = prov.id_provincia AND dist.nombre = s.nombre_distrito
WHERE NOT EXISTS (
    SELECT 1 FROM fongal.direccion dd
    WHERE dd.id_persona = p.id_persona AND dd.direccion_linea = s.direccion_linea
);

DROP TABLE stg_direccion;

-- VERIFICACION

SELECT 'cargo' AS tabla, count(*) FROM fongal.cargo
UNION ALL
SELECT 'departamento', count(*) FROM fongal.departamento
UNION ALL
SELECT 'provincia', count(*) FROM fongal.provincia
UNION ALL
SELECT 'distrito', count(*) FROM fongal.distrito
UNION ALL
SELECT 'persona', count(*) FROM fongal.persona
UNION ALL
SELECT 'persona_natural', count(*) FROM fongal.persona_natural
UNION ALL
SELECT 'persona_juridica', count(*) FROM fongal.persona_juridica
UNION ALL
SELECT 'direccion', count(*) FROM fongal.direccion;
