#1. Crear una transacción utilizando un procedimiento que reciba el id de un producto, una
-- estantería y una cantidad que se desea retirar. Se debe modificar la cantidad presente
-- en la estantería y el stock del producto. Se debe validar que las dos cantidades no
-- queden en negativo

DELIMITER //

CREATE PROCEDURE estanterias(
    IN p_idProducto INT,
    IN p_idEstanteria INT,
    IN p_cantidad INT
)
BEGIN
    DECLARE estaAct INT;
    DECLARE stockAct INT;

    START TRANSACTION;

    SELECT cantidad
    INTO estaAct
    FROM producto_ubicacion
    WHERE Producto_codProducto = p_idProducto
      AND idProducto_Ubicacion = p_idEstanteria
        FOR
    UPDATE;

    SELECT stock
    INTO stockAct
    FROM producto
    WHERE codProducto = p_idProducto
        FOR
    UPDATE;

    IF (stockAct < p_cantidad OR estaAct < p_cantidad) THEN
        ROLLBACK;
    ELSE
        UPDATE producto_ubicacion
        SET cantidad = cantidad - p_cantidad
        WHERE Producto_codProducto = p_idProducto
          AND idProducto_Ubicacion = p_idEstanteria;

        UPDATE producto
        SET stock = stock - p_cantidad
        WHERE codProducto = p_idProducto;

        COMMIT;
    END IF;

END //

DELIMITER ;

#3 Crear una transacción utilizando un procedimiento que reciba el id de un proveedor, un
-- código de producto, provincia y la cantidad que llegó en el camión. El procedimiento
-- debe registrar el ingreso en las tablas ingresostock e ingresostock_producto, actualizar
-- el stock general del producto y validar que la provincia del proveedor sea la misma que
-- la que se recibe por parámetro. Si no lo es, debe lanzar el error:"Ingreso rechazado: el
-- proveedor no está habilitado para operar en esta provincia"
DELIMITER //

CREATE PROCEDURE ingreso_stock(
    IN p_idProveedor INT,
    IN p_codProducto INT,
    IN p_provincia VARCHAR(50),
    IN p_cantidad INT
)
BEGIN
    DECLARE provinciaProveedor VARCHAR(50);
    DECLARE idDeIngreso INT;

    START TRANSACTION;

    SELECT pr.nombre
    INTO provinciaProveedor
    FROM proveedor pr
    join provincia pr ON pr.Provincia_idProvincia = pr.idProvincia
    WHERE idproveedor = p_idProveedor
    for update;

    IF provinciaProveedor IS NULL OR provinciaProveedor != p_provincia THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ingreso rechazado: el proveedor no está habilitado para operar en esta provincia';
    END IF;

    INSERT INTO ingresostock (fecha, remitonro, proveedor_idproveedor)
    VALUES (now(), '1', p_idProveedor);

    SET idDeIngreso = last_insert_id();

    INSERT INTO ingresostock_producto (cantidad, IngresoStock_idIngreso, Producto_codProducto)
    VALUES (p_cantidad, idDeIngreso, p_codProducto
           );

    UPDATE producto
    SET stock = stock + p_cantidad
    WHERE codProducto = p_codProducto;
    COMMIT;

END //

DELIMITER ;
