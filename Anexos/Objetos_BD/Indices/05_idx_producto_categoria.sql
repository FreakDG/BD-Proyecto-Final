-- Indice Tabla 5
-- Índice Tabla 5: producto
-- NOTA: Para cargar rápidamente los productos cuando el cliente entra a ver una categoría específica del catálogo.

CREATE INDEX idx_producto_categoria 
ON producto(id_categoria_producto);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT nombre, precio_unitario FROM producto WHERE id_categoria_producto = 2;
