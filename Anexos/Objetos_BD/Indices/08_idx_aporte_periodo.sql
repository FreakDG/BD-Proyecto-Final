-- Indice Tabla 8
-- Índice Tabla 8: aporte
-- NOTA: Para generar los balances mensuales agrupando y buscando los pagos por periodo.

CREATE INDEX idx_aporte_periodo 
ON aporte(periodo);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT monto, fecha_pago FROM aporte WHERE periodo = '2026-08';
