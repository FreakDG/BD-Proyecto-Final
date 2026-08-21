-- Vista Tabla 10
--10. Carritos y productos
CREATE OR REPLACE VIEW fongal.vw_carritos_productos AS
SELECT
    c.id_carrito,
    u.id_usuario,
    u.nombre_usuario,
    c.fecha_creacion,
    c.estado AS estado_carrito,
    p.id_producto,
    p.nombre AS producto,
    dc.cantidad,
    p.precio_unitario,
    dc.cantidad * p.precio_unitario AS subtotal_estimado
FROM fongal.carrito c
INNER JOIN fongal.usuario u
    ON c.id_usuario = u.id_usuario
INNER JOIN fongal.detalle_carrito dc
    ON c.id_carrito = dc.id_carrito
INNER JOIN fongal.producto p
    ON dc.id_producto = p.id_producto;

SELECT *
FROM fongal.vw_carritos_productos;
