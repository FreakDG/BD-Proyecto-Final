BEGIN;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP SCHEMA IF EXISTS fongal CASCADE;
CREATE SCHEMA fongal;

SET search_path TO fongal, public;


-- MODULO 1: Personas y Asociatividad
CREATE TABLE persona (
    id_persona integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_persona char(1) NOT NULL,
    tipo_documento varchar(120) NOT NULL, 
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
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_departamento_nombre UNIQUE (nombre) -- (c4)
);

CREATE TABLE provincia (
    id_provincia integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_departamento integer NOT NULL,
    nombre varchar(120) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_provincia_id_departamento_nombre UNIQUE (id_departamento, nombre) -- (c4)
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
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_raza_id_especie_nombre UNIQUE (id_especie, nombre) -- (c4)
);

CREATE TABLE categoria_animal (
    id_categoria_animal integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_especie integer NOT NULL,
    nombre varchar(120) NOT NULL,
    edad_min_meses smallint,
    edad_max_meses smallint,
    sexo_aplicable char(1),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_categoria_animal_id_especie_nombre UNIQUE (id_especie, nombre), -- (c4)
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

-- animal: sin id_socio (correccion aplicada, ver punto B2 del encabezado).
-- El socio dueno del animal se obtiene con:
--   SELECT a.*, e.id_socio FROM animal a JOIN establo e ON a.id_establo = e.id_establo
CREATE TABLE animal (
    id_animal integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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

-- Pendiente documentado: no se valida aqui que id_padre sea sexo 'M'
-- y id_madre sexo 'F' (se resolvera con trigger en el Cap. 6).
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
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_tipo_evento_nombre UNIQUE (nombre) -- (c4)
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
    CONSTRAINT uq_evento_nombre_fecha_inicio UNIQUE (nombre, fecha_inicio), -- (c4)
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
    CONSTRAINT uq_criterio_evaluacion_id_concurso_nombre UNIQUE (id_concurso, nombre), -- (c4)
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

-- Pendiente documentado: id_evento aqui deberia coincidir con
-- venta.id_evento de la venta referenciada; sin CHECK/trigger todavia.
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

-- MODULO 4: Comercial y Ventas
CREATE TABLE categoria_producto (
    id_categoria_producto integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    descripcion text,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

-- precio_unitario y stock_actual son valores vigentes cacheados desde
-- historial_precio y movimiento_inventario respectivamente (denormalizacion
-- intencional por rendimiento, igual que en el script original).
CREATE TABLE producto (
    id_producto integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_categoria_producto integer NOT NULL,
    id_socio_proveedor integer,
    codigo_sku varchar(30) NOT NULL,
    nombre varchar(120) NOT NULL,
    tipo_item varchar(30),
    unidad_medida varchar(30),
    requiere_envio boolean DEFAULT false,
    precio_unitario numeric(12,2) NOT NULL,
    stock_actual integer,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_producto_codigo_sku UNIQUE (codigo_sku),
    CONSTRAINT ck_producto_1 CHECK (precio_unitario >= 0),
    CONSTRAINT ck_producto_2 CHECK (tipo_item IN ('BIEN', 'SERVICIO', 'ENTRADA')),
    CONSTRAINT ck_producto_3 CHECK (unidad_medida IN ('UNIDAD', 'KILOGRAMO', 'LITRO', 'SERVICIO'))
);

CREATE TABLE tipo_comprobante (
    id_tipo_comprobante integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo_sunat varchar(4) NOT NULL,
    nombre varchar(120) NOT NULL,
    requiere_ruc boolean DEFAULT false,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_tipo_comprobante_codigo_sunat UNIQUE (codigo_sunat) -- (c3)
);

CREATE TABLE venta (
    id_venta integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_tipo_comprobante integer NOT NULL,
    id_persona_cliente integer NOT NULL,
    id_empleado_vendedor integer,
    id_evento integer,
    serie varchar(6) NOT NULL,
    correlativo varchar(10) NOT NULL,
    canal_venta varchar(30),
    fecha_emision timestamptz NOT NULL,
    subtotal numeric(12,2) NOT NULL,
    igv numeric(12,2) NOT NULL,
    total numeric(12,2) NOT NULL,
    estado_sunat varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_venta_id_tipo_comprobante_serie_correlativo UNIQUE (id_tipo_comprobante, serie, correlativo),
    CONSTRAINT ck_venta_1 CHECK (subtotal >= 0),
    CONSTRAINT ck_venta_2 CHECK (igv >= 0),
    CONSTRAINT ck_venta_3 CHECK (total >= 0),
    CONSTRAINT ck_venta_4 CHECK (canal_venta IN ('PRESENCIAL', 'WEB')),
    CONSTRAINT ck_venta_5 CHECK (estado_sunat IN ('PENDIENTE', 'EMITIDO', 'ACEPTADO', 'RECHAZADO', 'ANULADO'))
);

CREATE TABLE detalle_venta (
    id_venta integer NOT NULL,
    id_producto integer NOT NULL,
    cantidad integer NOT NULL,
    precio_unitario numeric(12,2) NOT NULL,
    subtotal_linea numeric(12,2),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_detalle_venta PRIMARY KEY (id_venta, id_producto),
    CONSTRAINT ck_detalle_venta_1 CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detalle_venta_2 CHECK (subtotal_linea >= 0),
    CONSTRAINT ck_detalle_venta_3 CHECK (cantidad > 0)
);

CREATE TABLE carrito (
    id_carrito integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario integer NOT NULL,
    id_venta_generada integer,
    fecha_creacion timestamptz DEFAULT now() NOT NULL,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_carrito_1 CHECK (estado IN ('ACTIVO', 'CONVERTIDO', 'ABANDONADO'))
);

CREATE TABLE detalle_carrito (
    id_carrito integer NOT NULL,
    id_producto integer NOT NULL,
    cantidad integer NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_detalle_carrito PRIMARY KEY (id_carrito, id_producto),
    CONSTRAINT ck_detalle_carrito_1 CHECK (cantidad > 0)
);

CREATE TABLE direccion_envio (
    id_direccion_envio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta integer NOT NULL,
    id_distrito integer NOT NULL,
    direccion_linea text,
    destinatario varchar(120),
    telefono_contacto varchar(20),
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE estado_pedido (
    id_estado_pedido integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta integer NOT NULL,
    estado varchar(30) NOT NULL,
    fecha_hora timestamptz DEFAULT now() NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE transaccion_pago (
    id_transaccion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_venta integer NOT NULL,
    metodo_pago varchar(30),
    monto numeric(12,2) NOT NULL,
    fecha_hora timestamptz DEFAULT now() NOT NULL,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_transaccion_pago_1 CHECK (monto >= 0),
    CONSTRAINT ck_transaccion_pago_2 CHECK (metodo_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA', 'YAPE', 'PLIN'))
);

CREATE TABLE movimiento_inventario (
    id_movimiento integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto integer NOT NULL,
    id_venta integer,
    tipo varchar(30),
    cantidad integer NOT NULL,
    fecha_hora timestamptz DEFAULT now() NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_movimiento_inventario_1 CHECK (tipo IN ('ENTRADA', 'SALIDA', 'AJUSTE'))
);

CREATE TABLE historial_precio (
    id_historial_precio integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_producto integer NOT NULL,
    precio numeric(12,2) NOT NULL,
    fecha_inicio_vigencia date,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_historial_precio_1 CHECK (precio >= 0)
);



-- MODULO 5: Talento Humano
CREATE TABLE area (
    id_area integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_area_padre integer,
    nombre varchar(120) NOT NULL,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE cargo (
    id_cargo integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    descripcion text,
    sueldo_base_referencial numeric(12,2),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_cargo_nombre UNIQUE (nombre), -- (c4)
    CONSTRAINT ck_cargo_1 CHECK (sueldo_base_referencial >= 0)
);

CREATE TABLE empleado (
    id_empleado integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona integer NOT NULL,
    codigo_empleado varchar(30),
    fecha_ingreso date,
    fecha_cese date,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_empleado_codigo_empleado UNIQUE (codigo_empleado),
    CONSTRAINT uq_empleado_id_persona UNIQUE (id_persona)
);

CREATE TABLE contrato (
    id_contrato integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_empleado integer NOT NULL,
    id_cargo integer NOT NULL,
    id_area integer NOT NULL,
    tipo_contrato varchar(30),
    fecha_inicio date NOT NULL,
    fecha_fin date,
    jornada_semanal_horas smallint,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_contrato_1 CHECK (tipo_contrato IN ('PLAZO_FIJO', 'INDEFINIDO', 'LOCACION', 'PRACTICAS')),
    CONSTRAINT ck_contrato_2 CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio),
    CONSTRAINT ck_contrato_3 CHECK (jornada_semanal_horas > 0)
);

CREATE TABLE horario_trabajo (
    id_horario integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_contrato integer NOT NULL,
    dia_semana smallint,
    hora_inicio time,
    hora_fin time,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_horario_trabajo_1 CHECK (dia_semana BETWEEN 1 AND 7),
    CONSTRAINT ck_horario_trabajo_2 CHECK (hora_fin > hora_inicio)
);

CREATE TABLE historial_salarial (
    id_historial integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_contrato integer NOT NULL,
    monto_remuneracion numeric(12,2),
    fecha_inicio_vigencia date,
    motivo varchar(30),
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT ck_historial_salarial_1 CHECK (monto_remuneracion >= 0)
);



-- MODULO 6: Seguridad, Usuarios y Accesos
CREATE TABLE usuario (
    id_usuario integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_persona integer NOT NULL,
    nombre_usuario varchar(50) NOT NULL,
    correo_acceso varchar(120),
    contrasena_hash varchar(255) NOT NULL,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_usuario_nombre_usuario UNIQUE (nombre_usuario),
    CONSTRAINT uq_usuario_id_persona UNIQUE (id_persona),
    CONSTRAINT ck_usuario_1 CHECK (correo_acceso ~ '^[^@[:space:]]+@[^@[:space:]]+[.][^@[:space:]]+$')
);

CREATE TABLE rol (
    id_rol integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nombre varchar(120) NOT NULL,
    ambito_rol varchar(30),
    descripcion text,
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_rol_nombre UNIQUE (nombre), -- (c4)
    CONSTRAINT ck_rol_1 CHECK (ambito_rol IN ('INTERNO', 'WEB'))
);

CREATE TABLE permiso (
    id_permiso integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    codigo varchar(30) NOT NULL, -- (c2) antes nullable
    nombre varchar(120) NOT NULL,
    modulo varchar(120),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_permiso_codigo UNIQUE (codigo)
);

CREATE TABLE usuario_rol (
    id_usuario integer NOT NULL,
    id_rol integer NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_usuario_rol PRIMARY KEY (id_usuario, id_rol)
);

CREATE TABLE rol_permiso (
    id_rol integer NOT NULL,
    id_permiso integer NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT pk_rol_permiso PRIMARY KEY (id_rol, id_permiso)
);

CREATE TABLE sesion (
    id_sesion integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_usuario integer NOT NULL,
    token_hash varchar(128) NOT NULL,
    fecha_hora_inicio timestamptz NOT NULL,
    fecha_hora_expiracion timestamptz,
    origen varchar(30),
    estado varchar(30) NOT NULL,
    fecha_registro timestamptz NOT NULL DEFAULT now(),
    CONSTRAINT uq_sesion_token_hash UNIQUE (token_hash),
    CONSTRAINT ck_sesion_1 CHECK (origen IN ('BACKOFFICE', 'FRONTOFFICE'))
);

-- CLAVES FORANEAS:
ALTER TABLE socio ADD CONSTRAINT fk_socio_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE socio ADD CONSTRAINT fk_socio_id_categoria_socio FOREIGN KEY (id_categoria_socio) REFERENCES categoria_socio (id_categoria_socio) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE aporte ADD CONSTRAINT fk_aporte_id_socio FOREIGN KEY (id_socio) REFERENCES socio (id_socio) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE provincia ADD CONSTRAINT fk_provincia_id_departamento FOREIGN KEY (id_departamento) REFERENCES departamento (id_departamento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE distrito ADD CONSTRAINT fk_distrito_id_provincia FOREIGN KEY (id_provincia) REFERENCES provincia (id_provincia) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE direccion ADD CONSTRAINT fk_direccion_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE direccion ADD CONSTRAINT fk_direccion_id_distrito FOREIGN KEY (id_distrito) REFERENCES distrito (id_distrito) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE raza ADD CONSTRAINT fk_raza_id_especie FOREIGN KEY (id_especie) REFERENCES especie (id_especie) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE categoria_animal ADD CONSTRAINT fk_categoria_animal_id_especie FOREIGN KEY (id_especie) REFERENCES especie (id_especie) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE establo ADD CONSTRAINT fk_establo_id_socio FOREIGN KEY (id_socio) REFERENCES socio (id_socio) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE establo ADD CONSTRAINT fk_establo_id_distrito FOREIGN KEY (id_distrito) REFERENCES distrito (id_distrito) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE animal ADD CONSTRAINT fk_animal_id_raza FOREIGN KEY (id_raza) REFERENCES raza (id_raza) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE animal ADD CONSTRAINT fk_animal_id_establo FOREIGN KEY (id_establo) REFERENCES establo (id_establo) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE registro_genealogico ADD CONSTRAINT fk_registro_genealogico_id_animal FOREIGN KEY (id_animal) REFERENCES animal (id_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE registro_genealogico ADD CONSTRAINT fk_registro_genealogico_id_padre FOREIGN KEY (id_padre) REFERENCES animal (id_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE registro_genealogico ADD CONSTRAINT fk_registro_genealogico_id_madre FOREIGN KEY (id_madre) REFERENCES animal (id_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE control_peso ADD CONSTRAINT fk_control_peso_id_animal FOREIGN KEY (id_animal) REFERENCES animal (id_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE evento ADD CONSTRAINT fk_evento_id_tipo_evento FOREIGN KEY (id_tipo_evento) REFERENCES tipo_evento (id_tipo_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE evento ADD CONSTRAINT fk_evento_id_distrito FOREIGN KEY (id_distrito) REFERENCES distrito (id_distrito) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE concurso ADD CONSTRAINT fk_concurso_id_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE concurso ADD CONSTRAINT fk_concurso_id_categoria_animal FOREIGN KEY (id_categoria_animal) REFERENCES categoria_animal (id_categoria_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE criterio_evaluacion ADD CONSTRAINT fk_criterio_evaluacion_id_concurso FOREIGN KEY (id_concurso) REFERENCES concurso (id_concurso) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE participacion ADD CONSTRAINT fk_participacion_id_concurso FOREIGN KEY (id_concurso) REFERENCES concurso (id_concurso) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE participacion ADD CONSTRAINT fk_participacion_id_animal FOREIGN KEY (id_animal) REFERENCES animal (id_animal) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE participacion ADD CONSTRAINT fk_participacion_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE equipo_participante ADD CONSTRAINT fk_equipo_participante_id_participacion FOREIGN KEY (id_participacion) REFERENCES participacion (id_participacion) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE integrante_equipo ADD CONSTRAINT fk_integrante_equipo_id_equipo FOREIGN KEY (id_equipo) REFERENCES equipo_participante (id_equipo) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE integrante_equipo ADD CONSTRAINT fk_integrante_equipo_id_persona FOREIGN KEY (id_persona) REFERENCES persona_natural (id_persona) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE juez ADD CONSTRAINT fk_juez_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE juez_concurso ADD CONSTRAINT fk_juez_concurso_id_juez FOREIGN KEY (id_juez) REFERENCES juez (id_juez) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE juez_concurso ADD CONSTRAINT fk_juez_concurso_id_concurso FOREIGN KEY (id_concurso) REFERENCES concurso (id_concurso) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE evaluacion ADD CONSTRAINT fk_evaluacion_id_participacion FOREIGN KEY (id_participacion) REFERENCES participacion (id_participacion) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE evaluacion ADD CONSTRAINT fk_evaluacion_id_juez FOREIGN KEY (id_juez) REFERENCES juez (id_juez) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE detalle_evaluacion ADD CONSTRAINT fk_detalle_evaluacion_id_evaluacion FOREIGN KEY (id_evaluacion) REFERENCES evaluacion (id_evaluacion) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE detalle_evaluacion ADD CONSTRAINT fk_detalle_evaluacion_id_criterio FOREIGN KEY (id_criterio) REFERENCES criterio_evaluacion (id_criterio) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE premio ADD CONSTRAINT fk_premio_id_concurso FOREIGN KEY (id_concurso) REFERENCES concurso (id_concurso) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE premio ADD CONSTRAINT fk_premio_id_participacion_ganadora FOREIGN KEY (id_participacion_ganadora) REFERENCES participacion (id_participacion) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE stand ADD CONSTRAINT fk_stand_id_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE asignacion_stand ADD CONSTRAINT fk_asignacion_stand_id_stand FOREIGN KEY (id_stand) REFERENCES stand (id_stand) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE asignacion_stand ADD CONSTRAINT fk_asignacion_stand_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE auspicio ADD CONSTRAINT fk_auspicio_id_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE auspicio ADD CONSTRAINT fk_auspicio_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE entrada_emitida ADD CONSTRAINT fk_entrada_emitida_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE entrada_emitida ADD CONSTRAINT fk_entrada_emitida_id_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE producto ADD CONSTRAINT fk_producto_id_categoria_producto FOREIGN KEY (id_categoria_producto) REFERENCES categoria_producto (id_categoria_producto) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE producto ADD CONSTRAINT fk_producto_id_socio_proveedor FOREIGN KEY (id_socio_proveedor) REFERENCES socio (id_socio) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT fk_venta_id_tipo_comprobante FOREIGN KEY (id_tipo_comprobante) REFERENCES tipo_comprobante (id_tipo_comprobante) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT fk_venta_id_persona_cliente FOREIGN KEY (id_persona_cliente) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT fk_venta_id_empleado_vendedor FOREIGN KEY (id_empleado_vendedor) REFERENCES empleado (id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE venta ADD CONSTRAINT fk_venta_id_evento FOREIGN KEY (id_evento) REFERENCES evento (id_evento) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE detalle_venta ADD CONSTRAINT fk_detalle_venta_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE detalle_venta ADD CONSTRAINT fk_detalle_venta_id_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE carrito ADD CONSTRAINT fk_carrito_id_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE carrito ADD CONSTRAINT fk_carrito_id_venta_generada FOREIGN KEY (id_venta_generada) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE detalle_carrito ADD CONSTRAINT fk_detalle_carrito_id_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE direccion_envio ADD CONSTRAINT fk_direccion_envio_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE direccion_envio ADD CONSTRAINT fk_direccion_envio_id_distrito FOREIGN KEY (id_distrito) REFERENCES distrito (id_distrito) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE estado_pedido ADD CONSTRAINT fk_estado_pedido_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE transaccion_pago ADD CONSTRAINT fk_transaccion_pago_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE movimiento_inventario ADD CONSTRAINT fk_movimiento_inventario_id_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE movimiento_inventario ADD CONSTRAINT fk_movimiento_inventario_id_venta FOREIGN KEY (id_venta) REFERENCES venta (id_venta) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE historial_precio ADD CONSTRAINT fk_historial_precio_id_producto FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE area ADD CONSTRAINT fk_area_id_area_padre FOREIGN KEY (id_area_padre) REFERENCES area (id_area) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE empleado ADD CONSTRAINT fk_empleado_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE contrato ADD CONSTRAINT fk_contrato_id_empleado FOREIGN KEY (id_empleado) REFERENCES empleado (id_empleado) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE contrato ADD CONSTRAINT fk_contrato_id_cargo FOREIGN KEY (id_cargo) REFERENCES cargo (id_cargo) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE contrato ADD CONSTRAINT fk_contrato_id_area FOREIGN KEY (id_area) REFERENCES area (id_area) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE horario_trabajo ADD CONSTRAINT fk_horario_trabajo_id_contrato FOREIGN KEY (id_contrato) REFERENCES contrato (id_contrato) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE historial_salarial ADD CONSTRAINT fk_historial_salarial_id_contrato FOREIGN KEY (id_contrato) REFERENCES contrato (id_contrato) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE usuario ADD CONSTRAINT fk_usuario_id_persona FOREIGN KEY (id_persona) REFERENCES persona (id_persona) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE usuario_rol ADD CONSTRAINT fk_usuario_rol_id_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE usuario_rol ADD CONSTRAINT fk_usuario_rol_id_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE rol_permiso ADD CONSTRAINT fk_rol_permiso_id_rol FOREIGN KEY (id_rol) REFERENCES rol (id_rol) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE rol_permiso ADD CONSTRAINT fk_rol_permiso_id_permiso FOREIGN KEY (id_permiso) REFERENCES permiso (id_permiso) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE sesion ADD CONSTRAINT fk_sesion_id_usuario FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON UPDATE CASCADE ON DELETE RESTRICT;
-- FK compuesta con discriminador (garantiza disyuncion del subtipo)
ALTER TABLE persona_natural ADD CONSTRAINT fk_persona_natural_persona FOREIGN KEY (id_persona, tipo_persona) REFERENCES persona (id_persona, tipo_persona) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE persona_juridica ADD CONSTRAINT fk_persona_juridica_persona FOREIGN KEY (id_persona, tipo_persona) REFERENCES persona (id_persona, tipo_persona) ON UPDATE CASCADE ON DELETE CASCADE;

-- Indices sobre claves foraneas:
CREATE INDEX ix_socio_id_persona ON socio (id_persona);
CREATE INDEX ix_socio_id_categoria_socio ON socio (id_categoria_socio);
CREATE INDEX ix_aporte_id_socio ON aporte (id_socio);
CREATE INDEX ix_provincia_id_departamento ON provincia (id_departamento);
CREATE INDEX ix_distrito_id_provincia ON distrito (id_provincia);
CREATE INDEX ix_direccion_id_persona ON direccion (id_persona);
CREATE INDEX ix_direccion_id_distrito ON direccion (id_distrito);
CREATE INDEX ix_raza_id_especie ON raza (id_especie);
CREATE INDEX ix_categoria_animal_id_especie ON categoria_animal (id_especie);
CREATE INDEX ix_establo_id_socio ON establo (id_socio);
CREATE INDEX ix_establo_id_distrito ON establo (id_distrito);
CREATE INDEX ix_animal_id_raza ON animal (id_raza);
CREATE INDEX ix_animal_id_establo ON animal (id_establo);
CREATE INDEX ix_registro_genealogico_id_animal ON registro_genealogico (id_animal);
CREATE INDEX ix_registro_genealogico_id_padre ON registro_genealogico (id_padre);
CREATE INDEX ix_registro_genealogico_id_madre ON registro_genealogico (id_madre);
CREATE INDEX ix_control_peso_id_animal ON control_peso (id_animal);
CREATE INDEX ix_evento_id_tipo_evento ON evento (id_tipo_evento);
CREATE INDEX ix_evento_id_distrito ON evento (id_distrito);
CREATE INDEX ix_concurso_id_evento ON concurso (id_evento);
CREATE INDEX ix_concurso_id_categoria_animal ON concurso (id_categoria_animal);
CREATE INDEX ix_criterio_evaluacion_id_concurso ON criterio_evaluacion (id_concurso);
CREATE INDEX ix_participacion_id_concurso ON participacion (id_concurso);
CREATE INDEX ix_participacion_id_animal ON participacion (id_animal);
CREATE INDEX ix_participacion_id_persona ON participacion (id_persona);
CREATE INDEX ix_equipo_participante_id_participacion ON equipo_participante (id_participacion);
CREATE INDEX ix_integrante_equipo_id_persona ON integrante_equipo (id_persona);
CREATE INDEX ix_juez_id_persona ON juez (id_persona);
CREATE INDEX ix_juez_concurso_id_concurso ON juez_concurso (id_concurso);
CREATE INDEX ix_evaluacion_id_participacion ON evaluacion (id_participacion);
CREATE INDEX ix_evaluacion_id_juez ON evaluacion (id_juez);
CREATE INDEX ix_detalle_evaluacion_id_criterio ON detalle_evaluacion (id_criterio);
CREATE INDEX ix_premio_id_concurso ON premio (id_concurso);
CREATE INDEX ix_premio_id_participacion_ganadora ON premio (id_participacion_ganadora);
CREATE INDEX ix_stand_id_evento ON stand (id_evento);
CREATE INDEX ix_asignacion_stand_id_stand ON asignacion_stand (id_stand);
CREATE INDEX ix_asignacion_stand_id_persona ON asignacion_stand (id_persona);
CREATE INDEX ix_auspicio_id_evento ON auspicio (id_evento);
CREATE INDEX ix_auspicio_id_persona ON auspicio (id_persona);
CREATE INDEX ix_entrada_emitida_id_venta ON entrada_emitida (id_venta);
CREATE INDEX ix_entrada_emitida_id_evento ON entrada_emitida (id_evento);
CREATE INDEX ix_producto_id_categoria_producto ON producto (id_categoria_producto);
CREATE INDEX ix_producto_id_socio_proveedor ON producto (id_socio_proveedor);
CREATE INDEX ix_venta_id_tipo_comprobante ON venta (id_tipo_comprobante);
CREATE INDEX ix_venta_id_persona_cliente ON venta (id_persona_cliente);
CREATE INDEX ix_venta_id_empleado_vendedor ON venta (id_empleado_vendedor);
CREATE INDEX ix_venta_id_evento ON venta (id_evento);
CREATE INDEX ix_detalle_venta_id_producto ON detalle_venta (id_producto);
CREATE INDEX ix_carrito_id_usuario ON carrito (id_usuario);
CREATE INDEX ix_carrito_id_venta_generada ON carrito (id_venta_generada);
CREATE INDEX ix_detalle_carrito_id_producto ON detalle_carrito (id_producto);
CREATE INDEX ix_direccion_envio_id_venta ON direccion_envio (id_venta);
CREATE INDEX ix_direccion_envio_id_distrito ON direccion_envio (id_distrito);
CREATE INDEX ix_estado_pedido_id_venta ON estado_pedido (id_venta);
CREATE INDEX ix_transaccion_pago_id_venta ON transaccion_pago (id_venta);
CREATE INDEX ix_movimiento_inventario_id_producto ON movimiento_inventario (id_producto);
CREATE INDEX ix_movimiento_inventario_id_venta ON movimiento_inventario (id_venta);
CREATE INDEX ix_historial_precio_id_producto ON historial_precio (id_producto);
CREATE INDEX ix_area_id_area_padre ON area (id_area_padre);
CREATE INDEX ix_empleado_id_persona ON empleado (id_persona);
CREATE INDEX ix_contrato_id_empleado ON contrato (id_empleado);
CREATE INDEX ix_contrato_id_cargo ON contrato (id_cargo);
CREATE INDEX ix_contrato_id_area ON contrato (id_area);
CREATE INDEX ix_horario_trabajo_id_contrato ON horario_trabajo (id_contrato);
CREATE INDEX ix_historial_salarial_id_contrato ON historial_salarial (id_contrato);
CREATE INDEX ix_usuario_id_persona ON usuario (id_persona);
CREATE INDEX ix_usuario_rol_id_rol ON usuario_rol (id_rol);
CREATE INDEX ix_rol_permiso_id_permiso ON rol_permiso (id_permiso);
CREATE INDEX ix_sesion_id_usuario ON sesion (id_usuario);

CREATE UNIQUE INDEX uq_direccion_principal ON direccion (id_persona) WHERE es_principal;
CREATE UNIQUE INDEX uq_carrito_activo ON carrito (id_usuario) WHERE estado = 'ACTIVO';
CREATE UNIQUE INDEX uq_area_padre_nombre ON area (id_area_padre, nombre) WHERE id_area_padre IS NOT NULL;
CREATE UNIQUE INDEX uq_area_nombre_raiz ON area (nombre) WHERE id_area_padre IS NULL;
CREATE UNIQUE INDEX uq_premio_concurso_posicion ON premio (id_concurso, posicion) WHERE posicion IS NOT NULL;


ALTER TABLE asignacion_stand ADD CONSTRAINT ex_asignacion_stand_no_overlap EXCLUDE USING gist (id_stand WITH =, daterange(fecha_inicio, COALESCE(fecha_fin, 'infinity'::date), '[]') WITH &&);
ALTER TABLE contrato ADD CONSTRAINT ex_contrato_no_overlap EXCLUDE USING gist (id_empleado WITH =, daterange(fecha_inicio, COALESCE(fecha_fin, 'infinity'::date), '[]') WITH &&);

COMMIT;
