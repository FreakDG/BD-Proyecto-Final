-- Indice Tabla 6
-- Índice Tabla 6: empleado
-- NOTA: Para listar rápidamente al personal que sigue trabajando en la feria.

CREATE INDEX idx_empleado_estado 
ON empleado(estado);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT codigo_empleado FROM empleado WHERE estado = 'ACTIVO';
