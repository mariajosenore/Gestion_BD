-- =====================================================
-- TALLER DE TRIGGERS - MYSQL WORKBENCH
-- BASE DE DATOS: new_schema1
-- =====================================================

-- 1. LIMPIAR TODO 
DROP DATABASE IF EXISTS new_schema1;
CREATE DATABASE new_schema1;
USE new_schema1;

-- =====================================================
-- CREAR TABLAS
-- =====================================================

-- Tabla: productos
CREATE TABLE productos (
    id_producto INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL,
    precio DECIMAL(10,2) NOT NULL,
    stock INT NOT NULL DEFAULT 0
);

-- Tabla: ventas
CREATE TABLE ventas (
    id_venta INT PRIMARY KEY AUTO_INCREMENT,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    fecha_venta DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_producto) REFERENCES productos(id_producto)
);

-- Tabla: auditoria
CREATE TABLE auditoria (
    id_auditoria INT PRIMARY KEY AUTO_INCREMENT,
    nombre_producto VARCHAR(100),
    fecha_eliminacion DATETIME,
    usuario VARCHAR(50)
);

-- Tabla: log_modificaciones
CREATE TABLE log_modificaciones (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    tabla VARCHAR(50),
    campo_modificado VARCHAR(50),
    valor_anterior VARCHAR(200),
    valor_nuevo VARCHAR(200),
    fecha_cambio DATETIME DEFAULT CURRENT_TIMESTAMP,
    usuario VARCHAR(50)
);

-- =====================================================
-- PARTE 2: TRIGGERS DEL TALLER
-- =====================================================

-- Trigger 1: Actualizar stock cuando se inserta una venta
DELIMITER $$
CREATE TRIGGER actualizar_stock_venta
AFTER INSERT ON ventas
FOR EACH ROW
BEGIN
    UPDATE productos 
    SET stock = stock - NEW.cantidad
    WHERE id_producto = NEW.id_producto;
END$$
DELIMITER ;

-- Trigger 2: Registrar en auditoria cuando se elimina un producto
DELIMITER $$
CREATE TRIGGER registrar_eliminacion_producto
BEFORE DELETE ON productos
FOR EACH ROW
BEGIN
    INSERT INTO auditoria (nombre_producto, fecha_eliminacion, usuario)
    VALUES (OLD.nombre, NOW(), USER());
END$$
DELIMITER ;

-- Trigger 3: Evitar precio menor que cero
DELIMITER $$
CREATE TRIGGER validar_precio_positivo
BEFORE UPDATE ON productos
FOR EACH ROW
BEGIN
    IF NEW.precio < 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El precio no puede ser menor que cero';
    END IF;
END$$
DELIMITER ;

-- Trigger 4: Guardar en log_modificaciones los cambios en ventas
DELIMITER $$
CREATE TRIGGER log_cambios_ventas
AFTER UPDATE ON ventas
FOR EACH ROW
BEGIN
    -- Log para cambios en cantidad
    IF OLD.cantidad != NEW.cantidad THEN
        INSERT INTO log_modificaciones (tabla, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES ('ventas', 'cantidad', CAST(OLD.cantidad AS CHAR), CAST(NEW.cantidad AS CHAR), USER());
    END IF;
    
    -- Log para cambios en id_producto
    IF OLD.id_producto != NEW.id_producto THEN
        INSERT INTO log_modificaciones (tabla, campo_modificado, valor_anterior, valor_nuevo, usuario)
        VALUES ('ventas', 'id_producto', CAST(OLD.id_producto AS CHAR), CAST(NEW.id_producto AS CHAR), USER());
    END IF;
END$$
DELIMITER ;

-- =====================================================
-- DATOS DE PRUEBA
-- =====================================================

-- Insertar productos de ejemplo
INSERT INTO productos (nombre, precio, stock) VALUES 
('Laptop', 800.00, 10),
('Mouse', 25.00, 50),
('Teclado', 45.00, 30);

-- Ver productos insertados
SELECT * FROM productos;

-- =====================================================
-- PRUEBAS DE LOS TRIGGERS
-- =====================================================

-- PRUEBA 1: Insertar venta (debe actualizar stock)
SELECT '=== PRUEBA 1: Insertar venta ===' AS '';
INSERT INTO ventas (id_producto, cantidad) VALUES (1, 2);

-- Verificar que el stock bajó de 10 a 8
SELECT * FROM productos WHERE id_producto = 1;

-- PRUEBA 2: Eliminar producto (debe registrar en auditoria)
SELECT '=== PRUEBA 2: Eliminar producto ===' AS '';
DELETE FROM productos WHERE id_producto = 3;

-- Verificar auditoria
SELECT * FROM auditoria;

-- PRUEBA 3: Actualizar precio negativo (debe dar ERROR)
SELECT '=== PRUEBA 3: Precio negativo (DEBE DAR ERROR) ===' AS '';
-- Esta línea debe generar error
UPDATE productos SET precio = -10 WHERE id_producto = 1;

-- PRUEBA 4: Actualizar venta (debe registrar en log)
SELECT '=== PRUEBA 4: Actualizar venta ===' AS '';
UPDATE ventas SET cantidad = 5 WHERE id_venta = 1;

-- Verificar log_modificaciones
SELECT * FROM log_modificaciones;

-- =====================================================
-- CONSULTAS ADICIONALES PARA VERIFICAR
-- =====================================================

-- Ver todos los productos
SELECT * FROM productos;

-- Ver todas las ventas
SELECT * FROM ventas;

-- Ver auditoría de eliminaciones
SELECT * FROM auditoria;

-- Ver log de modificaciones
SELECT * FROM log_modificaciones;

-- =====================================================
-- MOSTRAR TODOS LOS TRIGGERS CREADOS
-- =====================================================

SHOW TRIGGERS;

-- =====================================================
-- LIMPIAR DATOS DE PRUEBA 
-- =====================================================
/*
DELETE FROM log_modificaciones;
DELETE FROM auditoria;
DELETE FROM ventas;
DELETE FROM productos;
ALTER TABLE productos AUTO_INCREMENT = 1;
ALTER TABLE ventas AUTO_INCREMENT = 1;
ALTER TABLE auditoria AUTO_INCREMENT = 1;
ALTER TABLE log_modificaciones AUTO_INCREMENT = 1;
*/