-- Vista Tabla 2
--2. Top 5 de productos más vendidos
CREATE OR REPLACE VIEW fongal.vw_top_productos_vendidos AS
SELECT
    p.id_producto,
    p.nombre AS producto,
    SUM(dv.cantidad) AS cantidad_vendida,
    SUM(dv.subtotal_linea) AS importe_vendido
FROM fongal.detalle_venta dv
INNER JOIN fongal.producto p
    ON dv.id_producto = p.id_producto
INNER JOIN fongal.venta v
    ON dv.id_venta = v.id_venta
WHERE v.estado_sunat IN ('EMITIDO', 'ACEPTADO')
GROUP BY
    p.id_producto,
    p.nombre
ORDER BY cantidad_vendida DESC
LIMIT 5;

SELECT *
FROM fongal.vw_top_productos_vendidos;
