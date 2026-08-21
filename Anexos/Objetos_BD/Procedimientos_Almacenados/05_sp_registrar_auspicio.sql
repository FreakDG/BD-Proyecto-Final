-- SP Tabla 5
--8. Registrar un auspicio
CREATE OR REPLACE PROCEDURE fongal.sp_registrar_auspicio(
    p_id_evento integer,
    p_id_persona integer,
    p_monto numeric(12,2),
    p_contraprestacion text,
    p_fecha_convenio date
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fongal.auspicio (
        id_evento,
        id_persona,
        monto,
        contraprestacion,
        fecha_convenio
    )
    VALUES (
        p_id_evento,
        p_id_persona,
        p_monto,
        p_contraprestacion,
        p_fecha_convenio
    );
END;
$$;

CALL fongal.sp_registrar_auspicio(
    1,
    20,
    1000.00,
    'Publicidad durante el evento',
    CURRENT_DATE
);


SELECT
    au.id_auspicio,
    au.id_evento,
    e.nombre AS evento,
    au.id_persona,
    au.monto,
    au.contraprestacion,
    au.fecha_convenio
FROM fongal.auspicio au
INNER JOIN fongal.evento e
    ON au.id_evento = e.id_evento
WHERE au.id_evento = 1
ORDER BY au.fecha_convenio DESC;
