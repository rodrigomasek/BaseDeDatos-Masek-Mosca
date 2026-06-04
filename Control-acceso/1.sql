USE stock;
/*
DELIMITER $$

CREATE PROCEDURE actualizarStock(
    IN p_codProducto INT,
    IN p_nuevoStock INT
)
BEGIN
    UPDATE producto
    SET stock = p_nuevoStock
    WHERE codProducto = p_codProducto;
END $$


CREATE PROCEDURE reducirPrecio(
    IN p_codProducto INT,
    IN p_porcentaje DECIMAL(5,2)
)
BEGIN
    UPDATE producto
    SET precio = precio - (precio * p_porcentaje / 100)
    WHERE codProducto = p_codProducto;
END $$


CREATE PROCEDURE actualizarPrecioPorProveedor(
    IN p_idProveedor INT,
    IN p_porcentaje DECIMAL(5,2)
)
BEGIN
    UPDATE producto p
        INNER JOIN producto_proveedor pp
        ON p.codProducto = pp.Producto_codProducto
    SET p.precio = p.precio + (p.precio * p_porcentaje / 100)
    WHERE pp.Proveedor_idProveedor = p_idProveedor;
END $$

CREATE PROCEDURE borrarPedido(
    IN p_idPedido INT
)
BEGIN
    DELETE FROM pedido_producto
    WHERE Pedido_idPedido = p_idPedido;

    DELETE FROM pedido
    WHERE idPedido = p_idPedido;
END $$

CREATE PROCEDURE borrarLineaProductos(
    IN p_idPedido INT,
    IN p_item INT
)
BEGIN
    DELETE FROM pedido_producto
    WHERE Pedido_idPedido = p_idPedido
      AND item = p_item;
END $$

CREATE PROCEDURE actualizarComentarios(
    IN p_codCliente VARCHAR(20),
    IN p_categoria VARCHAR(45)
)
BEGIN
    UPDATE cliente
    SET categoria = p_categoria
    WHERE codCliente = p_codCliente;
END $$

DELIMITER ;


USE stock;

DELIMITER $$

-- =====================================
-- STOCK DISPONIBLE DE UN PRODUCTO
-- =====================================
CREATE FUNCTION stockDisponible(
    p_codProducto INT
)
    RETURNS INT
    DETERMINISTIC
BEGIN
    DECLARE v_stock INT;

    SELECT stock
    INTO v_stock
    FROM producto
    WHERE codProducto = p_codProducto;

    RETURN IFNULL(v_stock, 0);
END $$

-- =====================================
-- TOTAL DE VENTAS DE UN CLIENTE
-- =====================================
CREATE FUNCTION totalVentasCliente(
    p_codCliente VARCHAR(20)
)
    RETURNS DECIMAL(12,2)
    DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(12,2);

    SELECT IFNULL(SUM(pp.cantidad * pp.precioUnitario), 0)
    INTO v_total
    FROM pedido p
         JOIN pedido_producto pp
         ON p.idPedido = pp.Pedido_idPedido
    WHERE p.Cliente_codCliente = p_codCliente;

    RETURN v_total;
END $$

DELIMITER ;
*/
#1. Crear seis usuarios diferentes con contraseñas seguras: uno para analista de stock,
-- otro para gestor de productos, uno para analista de órdenes, uno para usuario de
-- reportes, uno para desarrollo y finalmente un administrador de base de datos. Una
-- vez creados, verificar que se hayan creado correctamente consultando la tabla de
-- usuarios del sistema.
/*

CREATE USER analistaStock IDENTIFIED BY 'FLINT AND STEEL';
CREATE USER gestorProductos IDENTIFIED BY 'CHICKEN JOCKEY';
CREATE USER analistaOrdenes IDENTIFIED BY 'I AM STEVE';
CREATE USER usuarioReportes IDENTIFIED BY 'I AM PLACING';
CREATE USER desarrollo IDENTIFIED BY 'BLOCKS AND SHIT';
CREATE USER administrador IDENTIFIED BY 'BECAUSE THIS IS';
*/
#2. Crear cinco roles diferentes. El primero debe tener permisos de ejecución sobre los
-- procedimientos de stock (actualizarStock, reducirPrecio,
-- actualizarPrecioPorProveedor) y permisos de lectura en toda la base de datos stock.
-- El segundo debe permitir ejecutar procedimientos de gestión de órdenes
-- (borrarOrden, borrarLineaProductos, actualizarComentarios) y leer las tablas orders
-- y orderdetails. El tercero debe ser un rol de solo lectura para reportes que permita
-- select en ambas bases de datos y ejecución de funciones de consulta. El cuarto
-- debe ser un rol para desarrollo que permita realizar todas las sentencias de DML,
-- creación y ejecución de todas las rutinas, triggers y eventos. Finalmente, crear un rol
-- de administrador con acceso casi total. Una vez creados, verificar que los roles
-- existan consultando las relaciones de roles en el sistema.

GRANT ALL PRIVILEGES ON *.*
    TO 'alumno27.mosca.jacob.santino'@'localhost'
    WITH GRANT OPTION;
CREATE ROLE IF NOT EXISTS rol_stock;
CREATE ROLE IF NOT EXISTS rol_pedidos;
CREATE ROLE IF NOT EXISTS rol_reportes;
CREATE ROLE IF NOT EXISTS rol_desarrollo;
CREATE ROLE IF NOT EXISTS rol_admin;

GRANT SELECT ON stock.* TO rol_stock;

GRANT EXECUTE ON PROCEDURE stock.actualizarStock TO rol_stock;
GRANT EXECUTE ON PROCEDURE stock.reducirPrecio TO rol_stock;
GRANT EXECUTE ON PROCEDURE stock.actualizarPrecioPorProveedor TO rol_stock;

GRANT SELECT ON stock.pedido TO rol_pedidos;
GRANT SELECT ON stock.pedido_producto TO rol_pedidos;

GRANT EXECUTE ON PROCEDURE stock.borrarPedido TO rol_pedidos;
GRANT EXECUTE ON PROCEDURE stock.borrarLineaProductos TO rol_pedidos;
GRANT EXECUTE ON PROCEDURE stock.actualizarComentarios TO rol_pedidos;

GRANT SELECT ON stock.* TO rol_reportes;


GRANT EXECUTE ON FUNCTION stock.stockDisponible TO rol_reportes;
GRANT EXECUTE ON FUNCTION stock.totalVentasCliente TO rol_reportes;

GRANT SELECT, INSERT, UPDATE, DELETE
    ON stock.* TO rol_desarrollo;

GRANT CREATE, ALTER, DROP
    ON stock.* TO rol_desarrollo;

GRANT CREATE ROUTINE, ALTER ROUTINE, EXECUTE
    ON *.* TO rol_desarrollo;

GRANT TRIGGER
    ON stock.* TO rol_desarrollo;

GRANT EVENT
    ON stock.* TO rol_desarrollo;

GRANT ALL PRIVILEGES
    ON stock.* TO rol_admin;

GRANT CREATE USER,
    PROCESS,
    RELOAD,
    SHOW DATABASES
    ON *.* TO rol_admin;



SELECT *
FROM mysql.role_edges;

SHOW GRANTS FOR rol_stock;
SHOW GRANTS FOR rol_pedidos;
SHOW GRANTS FOR rol_reportes;
SHOW GRANTS FOR rol_desarrollo;
SHOW GRANTS FOR rol_admin;

#3

GRANT rol_stock TO analistaStock;
GRANT rol_stock TO gestorProductos;

GRANT rol_pedidos TO analistaOrdenes;

GRANT rol_reportes To usuarioReportes;

GRANT rol_desarrollo TO desarrollo;

GRANT rol_admin TO administrador;

SELECT *
FROM mysql.role_edges;

SHOW GRANTS FOR analistaStock;
SHOW GRANTS FOR gestorProductos;
SHOW GRANTS FOR analistaOrdenes;
SHOW GRANTS FOR usuarioReportes;
SHOW GRANTS FOR desarrollo;
SHOW GRANTS FOR administrador;


















