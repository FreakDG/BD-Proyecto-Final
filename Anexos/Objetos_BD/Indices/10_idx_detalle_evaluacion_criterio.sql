-- Indice Tabla 10
-- Índice Tabla 10: detalle_evaluacion
-- NOTA: Para sumar y calcular ágilmente los puntajes cuando un concurso termina y se necesita consultar las notas por criterio.

CREATE INDEX idx_detalle_evaluacion_criterio 
ON detalle_evaluacion(id_criterio);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT puntaje FROM detalle_evaluacion WHERE id_criterio = 3;
