-- Indice Tabla 3
-- Índice Tabla 3: animal
-- NOTA: Para acelerar la búsqueda de animales que pertenecen a una raza específica (Llave foránea).

CREATE INDEX idx_animal_id_raza 
ON animal(id_raza);

-- Consulta que el sistema ahora hará más rápido gracias al índice
SELECT nombre, codigo_arete FROM animal WHERE id_raza = 1;
