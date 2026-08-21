-- SP Tabla 3
--3. Actualizar el precio de un producto
CREATE OR REPLACE PROCEDURE fongal.sp_actualizar_precio_producto(
    p_id_producto integer,
    p_nuevo_precio numeric(12,2)
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE fongal.producto
    SET precio_unitario = p_nuevo_precio
    WHERE id_producto = p_id_producto;

    INSERT INTO fongal.historial_precio (
        id_producto,
        precio,
        fecha_inicio_vigencia
    )
    VALUES (
        p_id_producto,
        p_nuevo_precio,
        CURRENT_DATE
    );
END;
$$;

CALL fongal.sp_actualizar_precio_producto(1, 85.50);

SELECT
    id_producto,
    codigo_sku,
    nombre,
    precio_unitario
FROM fongal.producto
WHERE id_producto = 1;
