-- =====================================================================
-- CARGA MASIVA: TurismoPeru_ADJG (SQL Server) -> fongal (PostgreSQL)
-- Script NUEVO e independiente. No modifica ni reemplaza ninguno de los
-- scripts ya entregados (SCRIPT BD FONGAL.sql, SCRIPT BD FONGAL v2
-- (normalizado).sql, DATOS DE PRUEBA BD FONGAL.sql).
--
-- Contexto (Cap. 6.2 del informe): se piden datos cargados masivamente
-- desde TurismoPeru_ADJG hacia fongal. Ambas bases son de dominios
-- distintos (turismo vs. asociacion ganadera) y de motores distintos
-- (SQL Server vs. PostgreSQL), por lo que no existe una via de carga
-- directa (no hay INSERT...SELECT entre motores, ni consultas entre
-- bases cruzadas). De las 36 tablas de ADJG, 6 tienen un destino
-- razonable en fongal (ver analisis de compatibilidad en el informe):
--   cargo, region->departamento, subregion->provincia, ciudad->distrito,
--   persona->persona(+persona_natural/persona_juridica), direccion->direccion.
-- El resto de tablas de ADJG (cliente, reserva, paquete, alojamiento,
-- vehiculo, etc.) son especificas del dominio turistico y no tienen
-- tabla equivalente en fongal. Se descarto tambien empleado->contrato:
-- fongal.contrato exige id_area NOT NULL y ADJG no tiene ningun dato de
-- area organizacional del que partir.
--
-- ORDEN DE CARGA (respeta dependencias de FK):
--   1) cargo  2) departamento  3) provincia  4) distrito
--   5) persona  6) direccion (depende de persona y de distrito)
--
-- Metodo: CSV como formato intermedio neutral.
--   PARTE 1 (ejecutar en SSMS, contra TurismoPeru_ADJG): SELECT de
--   exportacion, ya con columnas nombradas/mapeadas al destino.
--   Exportar cada resultado a un .csv (SSMS "Save Results As..." o
--   bcp por linea de comandos).
--   PARTE 2 (ejecutar en psql/pgAdmin, contra fongal): tablas de
--   staging + \copy desde los .csv generados + INSERT final resolviendo
--   las FK por nombre (clave natural), porque los id GENERATED ALWAYS
--   AS IDENTITY de fongal no van a coincidir con los id IDENTITY de
--   SQL Server.
--
-- Ajustar la ruta de los .csv (placeholder C:\carga\...) segun donde
-- se descarguen los archivos exportados desde SSMS.
-- =====================================================================


-- =====================================================================
-- PARTE 1: SQL Server - TurismoPeru_ADJG
-- Ejecutar cada SELECT por separado en SSMS y exportar su resultado
-- a CSV (una tabla = un archivo). Usar UTF-8 al exportar (revisar
-- tildes/enye si se exporta como ANSI).
-- =====================================================================

-- 1) cargo (sin FK, exportacion directa)
SELECT
    nombre,
    descripcion,
    salario_base AS sueldo_base_referencial
FROM ADJG.cargo
ORDER BY id_cargo;
-- Exportar como: cargo.csv (columnas: nombre, descripcion, sueldo_base_referencial)

-- 2) region -> departamento (filtrando solo Peru; fongal no maneja pais)
SELECT
    r.nombreregion AS nombre
FROM ADJG.region r
JOIN ADJG.pais p ON r.id_pais = p.id_pais
WHERE p.codigo_iso = 'PER' -- ajustar si el codigo ISO cargado es distinto
ORDER BY r.id_region;
-- Exportar como: departamento.csv (columnas: nombre)

-- 3) subregion -> provincia (con el nombre del departamento como clave natural)
SELECT
    s.nombresubregion AS nombre,
    r.nombreregion AS nombre_departamento
FROM ADJG.subregion s
JOIN ADJG.region r ON s.id_region = r.id_region
ORDER BY s.id_subregion;
-- Exportar como: provincia.csv (columnas: nombre, nombre_departamento)

-- 4) ciudad -> distrito (con provincia y departamento como clave natural,
--    para poder resolver la FK sin ambiguedad si hay provincias
--    homonimas en distintos departamentos)
SELECT
    c.nombreciudad AS nombre,
    c.codigo_ubigeo,
    s.nombresubregion AS nombre_provincia,
    r.nombreregion AS nombre_departamento
FROM ADJG.ciudad c
JOIN ADJG.subregion s ON c.id_subregion = s.id_subregion
JOIN ADJG.region r ON s.id_region = r.id_region
ORDER BY c.id_ciudad;
-- Exportar como: distrito.csv (columnas: nombre, codigo_ubigeo, nombre_provincia, nombre_departamento)
-- OJO: en ADJG codigo_ubigeo es char(4); en fongal es varchar(6) UNIQUE NOT NULL.
-- Si hay codigos repetidos o vacios al exportar, la carga en fongal (parte 2)
-- va a fallar por la restriccion UNIQUE: revisar/depurar antes de cargar.

-- 5) persona -> persona (+ persona_natural / persona_juridica)
--    Se resuelve id_tipo_documento a texto (tipo_documento es varchar libre
--    en fongal, no FK a catalogo). fecha_nacimiento solo existe para las
--    personas que ademas son cliente en ADJG (LEFT JOIN); para el resto
--    queda NULL, lo cual es valido en fongal.persona_natural.
-- OJO: ADJG.persona.nombres y .apaterno son nullable. Si algun registro
-- con tipo_persona='N' los tiene vacios, el INSERT en persona_natural va
-- a fallar por NOT NULL: revisar antes de exportar.
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
-- Exportar como: persona.csv (columnas: tipo_persona, tipo_documento, numero_documento,
-- correo, telefono, estado, fecha_registro, nombres, apellido_paterno, apellido_materno,
-- fecha_nacimiento, razon_social, nombre_comercial)

-- 6) direccion -> direccion (UNION de las 3 tablas puente de ADJG que
--    conectan persona con direccion; se identifica al dueno por
--    tipo_documento + numero_documento, igual que en persona)
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
-- Exportar como: direccion.csv (columnas: tipo_documento, numero_documento,
-- direccion_linea, referencia, nombre_distrito, nombre_provincia,
-- nombre_departamento, es_principal)
-- OJO: fongal solo permite UNA direccion principal (es_principal) por
-- persona (indice unico parcial). Si en ADJG una misma persona tiene mas
-- de una marcada como principal entre las 3 tablas puente, el INSERT en
-- fongal (parte 2) va a fallar: revisar antes de exportar.


-- =====================================================================
-- PARTE 2: PostgreSQL - fongal
-- Ejecutar en psql (o pgAdmin) ya conectado a la base fongal, con los
-- 6 archivos .csv generados en la Parte 1 accesibles desde el cliente.
--
-- IMPORTANTE - DUPLICADOS ESPERADOS: DATOS DE PRUEBA BD FONGAL.sql ya
-- carga los 25 departamentos reales del Peru y varias provincias/
-- distritos de Cajamarca. ADJG.region/subregion/ciudad tambien son
-- geografia real del Peru, asi que va a haber nombres repetidos (ej.
-- "Cajamarca" ya existe en fongal.departamento). Por eso TODAS las
-- cargas de esta parte pasan primero por una tabla de staging y el
-- INSERT final usa "WHERE NOT EXISTS" para insertar solo lo que todavia
-- no existe en fongal, en vez de un \copy directo a la tabla real (que
-- fallaria completo con un solo duplicado, por violar la restriccion
-- UNIQUE). El script queda ademas idempotente: se puede volver a correr
-- sin duplicar filas.
--
-- CALIDAD DE DATOS - TILDES: ADJG exporta los nombres geograficos y de
-- cargo con tildes correctas (ej. "Junin" con tilde), mientras que los
-- datos de prueba de fongal los tenian sin tildes. Se habilito la
-- extension unaccent para comparar nombres ignorando tildes/mayusculas,
-- y en cargo/departamento/provincia/distrito se agrego un UPDATE previo
-- al INSERT que corrige el nombre ya existente a la variante con tilde
-- cuando la fuente (ADJG) la trae, en vez de descartarla o duplicarla.
--
-- FORMATO DE LOS CSV: exportados desde SSMS con delimitador ";" (no
-- ","), codificacion UTF-8 sin BOM. El de persona.csv usa ademas la
-- opcion NULL 'NULL' en el \copy porque SQL Server exporta los valores
-- nulos como el texto literal "NULL".
-- =====================================================================

SET search_path TO fongal, public;

CREATE EXTENSION IF NOT EXISTS unaccent;
-- unaccent(): normaliza tildes para que "Huanuco" y "Huanuco" (con
-- tilde) se reconozcan como el mismo nombre y no se dupliquen.

-- 1) cargo
CREATE TEMP TABLE stg_cargo (
    nombre varchar(120),
    descripcion text,
    sueldo_base_referencial numeric(12,2)
);
\copy stg_cargo FROM 'C:\carga\cargo.csv' WITH (FORMAT csv, DELIMITER ';', ENCODING 'UTF8');

-- Si ya existe con el mismo nombre normalizado pero SIN tilde, y la
-- version entrante SI trae tilde, se corrige el nombre existente en vez
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

-- Si ya existe con el mismo nombre normalizado pero SIN tilde, y la
-- version entrante SI trae tilde, se corrige el nombre existente en vez
-- de descartar la version correcta.
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

-- 4) distrito (resolver id_provincia por nombre + departamento; se salta
--    si ya existe el distrito por nombre dentro de esa provincia, o si
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

-- 5) persona -> persona + persona_natural/persona_juridica
--    Se salta cada persona cuyo (tipo_documento, numero_documento) ya
--    exista en fongal.persona (poco probable con datos ficticios, pero
--    se deja por seguridad e idempotencia). Igual se protegen los
--    INSERT en persona_natural/persona_juridica con NOT EXISTS, porque
--    id_persona es PK ahi y no se puede insertar dos veces.
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

-- 6) direccion -> direccion (depende de persona, ya cargada arriba, y de
--    distrito, cargado en el paso 4). Se salta si esa persona ya tiene
--    registrada exactamente esa misma linea de direccion.
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
-- una direccion marcada como principal para la misma persona (una por cada
-- rol: cliente/empleado/proveedor), lo que viola el indice unico parcial
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

-- =====================================================================
-- VERIFICACION (para capturas del informe)
-- =====================================================================
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
