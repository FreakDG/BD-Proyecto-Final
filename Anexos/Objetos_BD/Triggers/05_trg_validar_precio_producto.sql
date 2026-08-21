-- Trigger Tabla 5
-- TRIGGER 5: Tabla PRODUCTO
-- CUMPLE: Evitar que se edite un producto para rebajarle su precio original.

CREATE OR REPLACE FUNCTION fn_validar_precio_producto() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.precio_unitario < OLD.precio_unitario THEN
        RAISE EXCEPTION 'Seguridad: No está permitido bajar el precio de un producto.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validar_precio_producto
BEFORE UPDATE ON producto
FOR EACH ROW EXECUTE FUNCTION fn_validar_precio_producto();


-- PRUEBA Y COMPROBACIÓN (Captura el error):
-- 1. Insertamos un producto a 50 soles
INSERT INTO producto (id_categoria_producto, codigo_sku, nombre, precio_unitario, stock_actual) 
VALUES (1, 'PROD-01', 'Queso', 50.00, 10);

-- 2. Intentamos bajarle el precio a 20 soles (Aquí debe saltar tu error rojo)
UPDATE producto SET precio_unitario = 20.00 WHERE codigo_sku = 'PROD-01';
