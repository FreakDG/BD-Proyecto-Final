-- Trigger Tabla 10
-- TRIGGER 10: Tabla DETALLE_EVALUACION
-- CUMPLE: Evitar errores de tipeo de los jueces, bloqueando puntajes mayores a 10.

CREATE OR REPLACE FUNCTION fn_validar_puntaje_evaluacion() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.puntaje > 10 THEN
        RAISE EXCEPTION 'El puntaje ingresado (%), supera el máximo de 10 permitido.', NEW.puntaje;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_puntaje_evaluacion
BEFORE INSERT OR UPDATE ON detalle_evaluacion
FOR EACH ROW EXECUTE FUNCTION fn_validar_puntaje_evaluacion();

-- PRUEBA Y COMPROBACIÓN (Captura el error):
-- Intentamos ingresar un puntaje de 15, el cual es ilegal.
INSERT INTO detalle_evaluacion (id_evaluacion, id_criterio, puntaje) 
VALUES (1, 1, 15.00);
