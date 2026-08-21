-- Indice Tabla 4
-- Índice Tabla 4: carrito
-- NOTA: Para encontrar los carritos que se quedaron abandonados y hacerles seguimiento.

CREATE INDEX idx_carrito_estado 
ON carrito(estado);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT id_carrito, fecha_creacion FROM carrito WHERE estado = 'ABANDONADO';
