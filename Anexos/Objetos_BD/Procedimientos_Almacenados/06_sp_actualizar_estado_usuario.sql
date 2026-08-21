-- SP Tabla 6
--10. Actualizar estado de usuario
CREATE OR REPLACE PROCEDURE fongal.sp_actualizar_estado_usuario(
    p_id_usuario integer,
    p_nuevo_estado varchar(30)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fongal.usuario
    SET estado = p_nuevo_estado
    WHERE id_usuario = p_id_usuario;
END;
$$;

CALL fongal.sp_actualizar_estado_usuario(
    1,
    'INACTIVO'
);

SELECT
    id_usuario,
    nombre_usuario,
    estado
FROM fongal.usuario
WHERE id_usuario = 1;
