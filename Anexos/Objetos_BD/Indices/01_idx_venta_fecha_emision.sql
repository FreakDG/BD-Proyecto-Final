-- Indice Tabla 1
-- Índice Tabla 1: venta
-- NOTA: Para acelerar los reportes de ventas filtrados por fecha.

CREATE INDEX idx_venta_fecha_emision 
ON venta(fecha_emision);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT * FROM venta WHERE fecha_emision >= '2026-01-01';
