-- Indice Tabla 9
-- Índice Tabla 9: asignacion_stand
-- NOTA: Para visualizar rápidamente qué stands de la feria están actualmente ocupados.

CREATE INDEX idx_asignacion_stand_estado 
ON asignacion_stand(estado);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT id_stand, monto_pactado FROM asignacion_stand WHERE estado = 'ACTIVO';
