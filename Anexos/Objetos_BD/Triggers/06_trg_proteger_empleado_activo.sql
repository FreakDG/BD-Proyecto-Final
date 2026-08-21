-- Trigger Tabla 6
-- TRIGGER 6: Tabla EMPLEADO
-- CUMPLE: Proteger la información evitando que se borre un empleado con estado 'ACTIVO'.

CREATE OR REPLACE FUNCTION fn_proteger_empleado_activo() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.estado = 'ACTIVO' THEN
        RAISE EXCEPTION 'Regla de negocio: No se puede eliminar a un empleado ACTIVO.';
    END IF;
    RETURN OLD; 
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_proteger_empleado_activo
BEFORE DELETE ON empleado
FOR EACH ROW EXECUTE FUNCTION fn_proteger_empleado_activo();

-- PRUEBA Y COMPROBACIÓN (Captura el error que saldrá aquí):
-- Intentamos borrar a cualquier empleado que tenga el estado 'ACTIVO'.
-- El trigger interceptará esto y bloqueará la eliminación para proteger los datos.
DELETE FROM empleado WHERE estado = 'ACTIVO';
