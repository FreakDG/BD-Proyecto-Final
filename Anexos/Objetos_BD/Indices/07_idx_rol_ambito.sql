-- Indice Tabla 7
-- Índice Tabla 7: rol
-- NOTA: Para separar rápidamente los roles de sistema web de los roles internos.

CREATE INDEX idx_rol_ambito 
ON rol(ambito_rol);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT nombre FROM rol WHERE ambito_rol = 'WEB';
