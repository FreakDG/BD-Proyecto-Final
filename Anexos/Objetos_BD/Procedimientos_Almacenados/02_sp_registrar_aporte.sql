-- SP Tabla 2
--2. Registrar un aporte de socio
CREATE OR REPLACE PROCEDURE fongal.sp_registrar_aporte(
    p_id_socio integer,
    p_periodo varchar(7),
    p_monto numeric(12,2),
    p_fecha_pago date,
    p_metodo_pago varchar(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO fongal.aporte (
        id_socio,
        periodo,
        monto,
        fecha_pago,
        metodo_pago
    )
    VALUES (
        p_id_socio,
        p_periodo,
        p_monto,
        p_fecha_pago,
        p_metodo_pago
    );
END;
$$;

CALL fongal.sp_registrar_aporte(
    1,
    '2026-08',
    50.00,
    CURRENT_DATE,
    'YAPE'
);

SELECT
    a.id_aporte,
    a.id_socio,
    s.codigo_socio,
    a.periodo,
    a.monto,
    a.fecha_pago,
    a.metodo_pago
FROM fongal.aporte a
INNER JOIN fongal.socio s
    ON a.id_socio = s.id_socio
WHERE a.id_socio = 1
ORDER BY a.fecha_pago DESC;
