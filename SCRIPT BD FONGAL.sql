
BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP SCHEMA IF EXISTS fongal CASCADE;
CREATE SCHEMA fongal;

SET search_path TO fongal, public;


-- MODULO 1: Personas y Asociatividad
CREATE TABLE persona (
    id_persona integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_persona char(1) NOT NULL,
    tipo_documento varchar(120),
    numero_documento varchar(20) NOT NULL,
    correo varchar(120),
    telefono varchar(20),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_persona_tipo_documento_numero_documento UNIQUE (tipo_documento, numero_documento),
    CONSTRAINT uq_persona_id_persona_tipo_persona UNIQUE (id_persona, tipo_persona),
    CONSTRAINT ck_persona_1 CHECK (correo ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$'),
    CONSTRAINT ck_persona_2 CHECK (tipo_persona IN ('N','J'))
);

CREATE TABLE persona_natural (
    id_persona integer PRIMARY KEY,
    nombres varchar(120) NOT NULL,
    apellido_paterno varchar(120) NOT NULL,
    apellido_materno varchar(120),
    fecha_nacimiento date,
    sexo char(1),
    tipo_persona char(1) NOT NULL DEFAULT 'N' CHECK (tipo_persona = 'N'),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_persona_natural_1 CHECK (sexo IN ('M','F'))
);

CREATE TABLE persona_juridica (
    id_persona integer PRIMARY KEY,
    razon_social varchar(120) NOT NULL,
    nombre_comercial varchar(120),
    representante varchar(120),
    tipo_persona char(1) NOT NULL DEFAULT 'J' CHECK (tipo_persona = 'J'),
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE categoria_socio (
    id_categoria_socio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    cuota_base numeric(12,2),
    descripcion_derechos text,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_categoria_socio_nombre UNIQUE (nombre),
    CONSTRAINT ck_categoria_socio_1 CHECK (cuota_base >= 0)
);

CREATE TABLE socio (
    id_socio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona integer NOT NULL,
    id_categoria_socio integer NOT NULL,
    codigo_socio varchar(30) NOT NULL,
    fecha_afiliacion date,
    estado_afiliacion varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_socio_codigo_socio UNIQUE (codigo_socio),
    CONSTRAINT uq_socio_id_persona UNIQUE (id_persona)
);

CREATE TABLE aporte (
    id_aporte integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_socio integer NOT NULL,
    periodo varchar(7),
    monto numeric(12,2) NOT NULL,
    fecha_pago date,
    metodo_pago varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_aporte_1 CHECK (monto >= 0),
    CONSTRAINT ck_aporte_2 CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'YAPE', 'PLIN'))
);

CREATE TABLE departamento (
    id_departamento integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE provincia (
    id_provincia integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_departamento integer NOT NULL,
    nombre varchar(120) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE distrito (
    id_distrito integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_provincia integer NOT NULL,
    nombre varchar(120) NOT NULL,
    codigo_ubigeo varchar(6) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_distrito_codigo_ubigeo UNIQUE (codigo_ubigeo)
);

CREATE TABLE direccion (
    id_direccion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona integer NOT NULL,
    id_distrito integer NOT NULL,
    direccion_linea text,
    referencia text,
    es_principal boolean DEFAULT false,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);


-- MODULO 2: Ganadera y Pecuaria
CREATE TABLE especie (
    id_especie integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    nombre_cientifico varchar(120),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_especie_nombre UNIQUE (nombre)
);

CREATE TABLE raza (
    id_raza integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_especie integer NOT NULL,
    nombre varchar(120) NOT NULL,
    origen varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE categoria_animal (
    id_categoria_animal integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_especie integer NOT NULL,
    nombre varchar(120) NOT NULL,
    edad_min_meses smallint,
    edad_max_meses smallint,
    sexo_aplicable char(1),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_categoria_animal_1 CHECK (sexo_aplicable IN ('M','F','A')),
    CONSTRAINT ck_categoria_animal_2 CHECK (edad_max_meses IS NULL OR edad_min_meses IS NULL OR edad_max_meses > edad_min_meses)
);

CREATE TABLE establo (
    id_establo integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_socio integer NOT NULL,
    id_distrito integer NOT NULL,
    nombre varchar(120) NOT NULL,
    codigo_senasa varchar(30),
    area_hectareas numeric(10,2),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_establo_1 CHECK (area_hectareas >= 0)
);

CREATE TABLE animal (
    id_animal integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_socio integer NOT NULL,
    id_raza integer NOT NULL,
    id_establo integer NOT NULL,
    codigo_arete varchar(30) NOT NULL,
    nombre varchar(120) NOT NULL,
    fecha_nacimiento date,
    sexo char(1),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_animal_codigo_arete UNIQUE (codigo_arete),
    CONSTRAINT ck_animal_1 CHECK (sexo IN ('M','F'))
);

CREATE TABLE registro_genealogico (
    id_registro integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_animal integer NOT NULL,
    id_padre integer,
    id_madre integer,
    numero_registro varchar(30),
    entidad_emisora varchar(120),
    fecha_emision date NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE control_peso (
    id_control integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_animal integer NOT NULL,
    fecha date,
    peso_kg numeric(6,2) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_control_peso_id_animal_fecha UNIQUE (id_animal, fecha),
    CONSTRAINT ck_control_peso_1 CHECK (peso_kg >= 0)
);



-- MODULO 3: Ferias y Eventos
CREATE TABLE tipo_evento (
    id_tipo_evento integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    descripcion text,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE evento (
    id_evento integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_evento integer NOT NULL,
    id_distrito integer NOT NULL,
    nombre varchar(120) NOT NULL,
    edicion varchar(120),
    fecha_inicio date NOT NULL,
    fecha_fin date,
    sede varchar(120),
    aforo_maximo integer,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_evento_1 CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT ck_evento_2 CHECK (aforo_maximo IS NULL OR aforo_maximo > 0)
);

CREATE TABLE concurso (
    id_concurso integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_evento integer NOT NULL,
    id_categoria_animal integer NOT NULL,
    nombre varchar(120) NOT NULL,
    tipo_concurso varchar(30),
    modalidad varchar(30),
    fecha_juzgamiento date,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE criterio_evaluacion (
    id_criterio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_concurso integer NOT NULL,
    nombre varchar(120) NOT NULL,
    peso numeric(5,2) NOT NULL,
    puntaje_maximo numeric(5,2),
    orden smallint,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_criterio_evaluacion_1 CHECK (peso >= 0),
    CONSTRAINT ck_criterio_evaluacion_2 CHECK (puntaje_maximo >= 0),
    CONSTRAINT ck_criterio_evaluacion_3 CHECK (peso >= 0 AND peso <= 100)
);

CREATE TABLE participacion (
    id_participacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_concurso integer NOT NULL,
    id_animal integer,
    id_persona integer NOT NULL,
    numero_orden smallint,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE equipo_participante (
    id_equipo integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_participacion integer NOT NULL,
    nombre_equipo varchar(120),
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE integrante_equipo (
    id_equipo integer NOT NULL,
    id_persona integer NOT NULL,
    rol_integrante varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_integrante_equipo PRIMARY KEY (id_equipo, id_persona)
);

CREATE TABLE juez (
    id_juez integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona integer NOT NULL,
    especialidad varchar(120),
    entidad_acreditadora varchar(120),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_juez_id_persona UNIQUE (id_persona)
);

CREATE TABLE juez_concurso (
    id_juez integer NOT NULL,
    id_concurso integer NOT NULL,
    fecha_designacion date,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_juez_concurso PRIMARY KEY (id_juez, id_concurso)
);

CREATE TABLE evaluacion (
    id_evaluacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_participacion integer NOT NULL,
    id_juez integer NOT NULL,
    fecha_hora timestamptz DEFAULT now() NOT NULL,
    observaciones text,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE detalle_evaluacion (
    id_evaluacion integer NOT NULL,
    id_criterio integer NOT NULL,
    puntaje numeric(6,2),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_detalle_evaluacion PRIMARY KEY (id_evaluacion, id_criterio),
    CONSTRAINT ck_detalle_evaluacion_1 CHECK (puntaje >= 0)
);

CREATE TABLE premio (
    id_premio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_concurso integer NOT NULL,
    id_participacion_ganadora integer,
    denominacion varchar(120),
    posicion smallint,
    monto_efectivo numeric(12,2),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_premio_1 CHECK (monto_efectivo >= 0)
);

CREATE TABLE stand (
    id_stand integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_evento integer NOT NULL,
    codigo varchar(30),
    zona varchar(120),
    area_m2 numeric(10,2),
    tarifa_base numeric(12,2),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_stand_id_evento_codigo UNIQUE (id_evento, codigo),
    CONSTRAINT ck_stand_1 CHECK (area_m2 >= 0),
    CONSTRAINT ck_stand_2 CHECK (tarifa_base >= 0)
);

CREATE TABLE asignacion_stand (
    id_asignacion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_stand integer NOT NULL,
    id_persona integer NOT NULL,
    fecha_inicio date NOT NULL,
    fecha_fin date,
    monto_pactado numeric(12,2),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_asignacion_stand_1 CHECK (monto_pactado >= 0),
    CONSTRAINT ck_asignacion_stand_2 CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);

CREATE TABLE auspicio (
    id_auspicio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_evento integer NOT NULL,
    id_persona integer NOT NULL,
    monto numeric(12,2) NOT NULL,
    contraprestacion text,
    fecha_convenio date,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_auspicio_1 CHECK (monto >= 0)
);

CREATE TABLE entrada_emitida (
    id_entrada integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta integer NOT NULL,
    id_evento integer NOT NULL,
    numero_linea smallint,
    codigo_qr varchar(100),
    estado varchar(30) NOT NULL,
    fecha_uso timestamptz,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);
