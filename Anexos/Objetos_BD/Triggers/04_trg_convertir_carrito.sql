-- Trigger Tabla 4
-- TRIGGER 4: Tabla CARRITO
-- CUMPLE: Si se enlaza una venta al carrito, su estado cambia a 'CONVERTIDO' automáticamente.

CREATE OR REPLACE FUNCTION fn_convertir_carrito() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.id_venta_generada IS NOT NULL THEN
        NEW.estado = 'CONVERTIDO';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_convertir_carrito
BEFORE UPDATE ON carrito
FOR EACH ROW EXECUTE FUNCTION fn_convertir_carrito();

-- PRUEBA Y COMPROBACIÓN (Captura esto):
-- 1. Creamos un carrito temporal
INSERT INTO carrito (id_usuario, estado) VALUES (1, 'ABANDONADO');

-- 2. Lo actualizamos enlazándole una venta (esto dispara el trigger)
UPDATE carrito SET id_venta_generada = 1 WHERE estado = 'ABANDONADO';

-- 3. Verificamos que el estado ya no es ABANDONADO sino CONVERTIDO
SELECT id_carrito, id_venta_generada, estado FROM carrito WHERE id_venta_generada = 1;
