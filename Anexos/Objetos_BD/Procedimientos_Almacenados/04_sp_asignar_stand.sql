-- SP Tabla 4
--7. Registrar asignación de stand
CREATE OR REPLACE PROCEDURE fongal.sp_asignar_stand(
    p_id_stand integer,
    p_id_persona integer,
    p_fecha_inicio date,
    p_fecha_fin date,
    p_monto_pactado numeric(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fongal.asignacion_stand (
        id_stand,
        id_persona,
        fecha_inicio,
        fecha_fin,
        monto_pactado,
        estado
    )
    VALUES (
        p_id_stand,
        p_id_persona,
        p_fecha_inicio,
        p_fecha_fin,
        p_monto_pactado,
        'ACTIVO'
    );
END;
$$;

CALL fongal.sp_asignar_stand(
    1,
    20,
    CURRENT_DATE,
    CURRENT_DATE + 3,
    500.00
);

SELECT
    a.id_asignacion,
    a.id_stand,
    s.codigo AS codigo_stand,
    s.zona,
    a.id_persona,
    a.fecha_inicio,
    a.fecha_fin,
    a.monto_pactado,
    a.estado
FROM fongal.asignacion_stand a
INNER JOIN fongal.stand s
    ON a.id_stand = s.id_stand
WHERE a.id_stand = 1
ORDER BY a.id_asignacion DESC;
