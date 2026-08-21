-- Trigger Tabla 3
-- TRIGGER 3: Tabla ANIMAL
-- CUMPLE: Bloquear el registro si la fecha de nacimiento es una fecha del futuro.

CREATE OR REPLACE FUNCTION fn_validar_nacimiento_animal() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_nacimiento > CURRENT_DATE THEN
        RAISE EXCEPTION 'Error FONGAL: La fecha de nacimiento no puede ser en el futuro.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_nacimiento_animal
BEFORE INSERT OR UPDATE ON animal
FOR EACH ROW EXECUTE FUNCTION fn_validar_nacimiento_animal();

-- PRUEBA Y COMPROBACIÓN (Captura el error que saldrá aquí):
-- Intentamos registrar un animal nacido en el año 2030 (quitando la columna id_socio que no existe)
INSERT INTO animal (id_raza, id_establo, codigo_arete, nombre, fecha_nacimiento, sexo, estado) 
VALUES (1, 1, 'A001', 'Toro Fuerte', '2030-01-01', 'M', 'VIVO');
