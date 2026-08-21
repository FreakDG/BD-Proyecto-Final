-- Trigger Tabla 1
-- TRIGGER 1: Tabla VENTA
-- CUMPLE: Autocalcular el IGV (18%) y el Total basándose en el subtotal ingresado.

CREATE OR REPLACE FUNCTION fn_calcular_totales_venta() RETURNS TRIGGER AS $$
BEGIN
    NEW.igv = NEW.subtotal * 0.18;
    NEW.total = NEW.subtotal + NEW.igv;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_calcular_totales_venta
BEFORE INSERT ON venta
FOR EACH ROW EXECUTE FUNCTION fn_calcular_totales_venta();

-- PRUEBA Y COMPROBACIÓN (Captura esto):
-- Insertamos una venta mandando el IGV y Total en 0. El trigger hará el cálculo.
INSERT INTO venta (id_tipo_comprobante, id_persona_cliente, serie, correlativo, fecha_emision, subtotal, igv, total, estado_sunat) 
VALUES (1, 1, 'F001', '00001', CURRENT_DATE, 100.00, 0, 0, 'EMITIDO');

-- Consultamos para ver si se calcularon los 18 de IGV y 118 de Total
SELECT serie, subtotal, igv, total FROM venta WHERE serie = 'F001';
