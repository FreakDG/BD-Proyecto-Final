-- Vista Tabla 1
--1. Productos con su categoría

CREATE OR REPLACE VIEW fongal.vw_productos_categoria AS
SELECT
    p.id_producto,
    p.codigo_sku,
    p.nombre AS producto,
    cp.nombre AS categoria,
    p.tipo_item,
    p.unidad_medida,
    p.precio_unitario,
    p.stock_actual,
    p.requiere_envio
FROM fongal.producto p
INNER JOIN fongal.categoria_producto cp
    ON p.id_categoria_producto = cp.id_categoria_producto;

SELECT *
FROM fongal.vw_productos_categoria;
