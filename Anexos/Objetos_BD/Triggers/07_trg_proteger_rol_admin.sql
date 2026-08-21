-- Trigger Tabla 7
-- TRIGGER 7: Tabla ROL
-- CUMPLE: Impedir que se modifique el nombre del rol clave 'ADMINISTRADOR'.

CREATE OR REPLACE FUNCTION fn_proteger_rol_admin() RETURNS TRIGGER AS $$
BEGIN
    IF OLD.nombre = 'ADMINISTRADOR' THEN
        RAISE EXCEPTION 'Seguridad: El rol ADMINISTRADOR es del sistema y no puede renombrarse.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_proteger_rol_admin
BEFORE UPDATE ON rol
FOR EACH ROW EXECUTE FUNCTION fn_proteger_rol_admin();


-- PRUEBA Y COMPROBACIÓN (Captura el error):
-- 1. Creamos el rol
INSERT INTO rol (nombre, estado) VALUES ('ADMINISTRADOR', 'ACTIVO');

-- 2. Intentamos cambiarle el nombre a 'SUPERADMIN' (El trigger lo rechaza)
UPDATE rol SET nombre = 'SUPERADMIN' WHERE nombre = 'ADMINISTRADOR';
