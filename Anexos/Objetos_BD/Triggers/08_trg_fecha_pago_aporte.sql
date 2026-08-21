-- Trigger Tabla 8
-- TRIGGER 8: Tabla APORTE
-- CUMPLE: Si el usuario no ingresa la fecha de pago, se asigna la fecha del servidor automáticamente.

CREATE OR REPLACE FUNCTION fn_fecha_pago_aporte() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.fecha_pago IS NULL THEN
        NEW.fecha_pago = CURRENT_DATE;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_fecha_pago_aporte
BEFORE INSERT ON aporte
FOR EACH ROW EXECUTE FUNCTION fn_fecha_pago_aporte();


-- PRUEBA Y COMPROBACIÓN (Captura esto):
-- Insertamos el aporte pero NO enviamos la columna fecha_pago
INSERT INTO aporte (id_socio, periodo, monto) VALUES (1, '2026-08', 50.00);

-- Consultamos y comprobaremos que la fecha_pago se llenó sola con el día de hoy
SELECT periodo, monto, fecha_pago FROM aporte WHERE periodo = '2026-08';
