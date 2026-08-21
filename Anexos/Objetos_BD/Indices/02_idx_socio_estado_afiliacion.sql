-- Indice Tabla 2
-- Índice Tabla 2: socio
-- NOTA: Para encontrar rápidamente a los socios según su estado (ej. buscar solo a los activos).

CREATE INDEX idx_socio_estado_afiliacion 
ON socio(estado_afiliacion);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT codigo_socio, estado_afiliacion FROM socio WHERE estado_afiliacion = 'ACTIVO';
