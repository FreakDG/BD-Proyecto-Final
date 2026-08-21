-- SP Tabla 1
--1. Registrar un nuevo socio
CREATE OR REPLACE PROCEDURE fongal.sp_registrar_socio(
    p_tipo_documento varchar(120),
    p_numero_documento varchar(20),
    p_correo varchar(120),
    p_telefono varchar(20),
    p_nombres varchar(120),
    p_apellido_paterno varchar(120),
    p_apellido_materno varchar(120),
    p_fecha_nacimiento date,
    p_sexo char(1),
    p_id_categoria_socio integer,
    p_codigo_socio varchar(30),
    p_fecha_afiliacion date
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_id_persona integer;
BEGIN
    INSERT INTO fongal.persona (
        tipo_persona,
        tipo_documento,
        numero_documento,
        correo,
        telefono,
        estado
    )
    VALUES (
        'N',
        p_tipo_documento,
        p_numero_documento,
        p_correo,
        p_telefono,
        'ACTIVO'
    )
    RETURNING id_persona INTO v_id_persona;

    INSERT INTO fongal.persona_natural (
        id_persona,
        nombres,
        apellido_paterno,
        apellido_materno,
        fecha_nacimiento,
        sexo
    )
    VALUES (
        v_id_persona,
        p_nombres,
        p_apellido_paterno,
        p_apellido_materno,
        p_fecha_nacimiento,
        p_sexo
    );

    INSERT INTO fongal.socio (
        id_persona,
        id_categoria_socio,
        codigo_socio,
        fecha_afiliacion,
        estado_afiliacion
    )
    VALUES (
        v_id_persona,
        p_id_categoria_socio,
        p_codigo_socio,
        p_fecha_afiliacion,
        'ACTIVO'
    );
END;
$$;

CALL fongal.sp_registrar_socio(
    'DNI',
    '12345678',
    'nuevo@correo.com',
    '999888777',
    'Juan',
    'Perez',
    'Lopez',
    '1995-05-10',
    'M',
    2,
    'SOC-0100',
    CURRENT_DATE
);

SELECT
    s.id_socio,
    s.codigo_socio,
    pn.nombres,
    pn.apellido_paterno,
    pn.apellido_materno,
    p.numero_documento,
    p.correo,
    p.telefono,
    s.fecha_afiliacion,
    s.estado_afiliacion
FROM fongal.socio s
INNER JOIN fongal.persona p
    ON s.id_persona = p.id_persona
INNER JOIN fongal.persona_natural pn
    ON p.id_persona = pn.id_persona
WHERE s.codigo_socio = 'SOC-0100';
