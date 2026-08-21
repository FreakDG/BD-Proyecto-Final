-- Trigger Tabla 2
-- TRIGGER 2: Tabla SOCIO
-- CUMPLE: Forzar automáticamente que el código del socio se guarde en MAYÚSCULAS.

CREATE OR REPLACE FUNCTION fn_socio_mayusculas() RETURNS TRIGGER AS $$
BEGIN
    NEW.codigo_socio = UPPER(NEW.codigo_socio);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_socio_mayusculas
BEFORE INSERT OR UPDATE ON socio
FOR EACH ROW EXECUTE FUNCTION fn_socio_mayusculas();

-- PRUEBA Y COMPROBACIÓN (Captura esto):
-- 1. Actualizamos el socio que ya existe, enviándole el código en minúsculas a propósito:
UPDATE socio 
SET codigo_socio = 'soc-xyz' 
WHERE id_persona = 1;

-- 2. Consultamos para comprobar que el trigger lo interceptó y lo guardó en mayúsculas ('SOC-XYZ'):
SELECT id_persona, codigo_socio, estado_afiliacion 
FROM socio 
WHERE id_persona = 1;
