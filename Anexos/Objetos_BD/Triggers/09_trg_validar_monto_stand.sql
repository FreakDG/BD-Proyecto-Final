-- Trigger Tabla 9
-- TRIGGER 9: Tabla ASIGNACION_STAND
-- CUMPLE: Validar que el monto de alquiler de un stand ferial no sea menor a 100.

CREATE OR REPLACE FUNCTION fn_validar_monto_stand() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.monto_pactado < 100 THEN
        RAISE EXCEPTION 'Finanzas FONGAL: El monto pactado por el stand no puede ser menor a 100.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_monto_stand
BEFORE INSERT OR UPDATE ON asignacion_stand
FOR EACH ROW EXECUTE FUNCTION fn_validar_monto_stand();

-- PRUEBA Y COMPROBACIÓN (Captura el error):
-- Intentamos hacer un contrato de alquiler por solo 50 soles
INSERT INTO asignacion_stand (id_stand, id_persona, fecha_inicio, monto_pactado, estado) 
VALUES (1, 1, CURRENT_DATE, 50.00, 'ACTIVO');
