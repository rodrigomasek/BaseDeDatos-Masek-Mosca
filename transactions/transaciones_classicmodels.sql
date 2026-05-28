#1. Crear una transacción que permita realizar una compra de manera segura. Se debe
-- crear un procedure que reciba id de cliente, id de producto, cantidad y fecha esperada
-- de envío. Se debe chequear que haya stock disponible para esa cantidad, de no ser el
-- caso se debe mostrar “Error, stock insuficiente”.

DELIMITER //
CREATE PROCEDURE debitarDinero(
    IN idc INT,
    IN idp INT,
    IN cant INT,
    IN fecha DATE
)
BEGIN
    DECLARE stock INT;

    START TRANSACTION ;

    SELECT p.quantityInStock
    INTO stock
    FROM products p
    WHERE p.productCode = idp
        FOR
    UPDATE;

    IF stock < cant THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error, stock insuficiente';

    ELSE
        UPDATE products
        SET quantityInStock = quantityInStock - cant
        WHERE productCode = idp;
        COMMIT;
    END IF;
END //
DELIMITER ;

#2. Crear una transacción usando un procedimiento que reciba como parámetro el número
-- de pedido y cambié el estado del pedido a 'Cancelled'. Debe buscar todos los productos
-- y cantidades que formaban parte de ese pedido en la tabla orderdetails, y devolver esas
-- cantidades al stock de cada producto. Se debe chequear que el pedido no esté ya en
-- estado Shipped, si ya fue enviado no se puede cancelar y debe lanzar el mensaje:"Error:
-- No se puede cancelar un pedido que ya fue enviado"-
DELIMITER //
DROP PROCEDURE IF EXISTS cancelar;
CREATE PROCEDURE cancelar(IN numPedido INT)
BEGIN
    DECLARE estado VARCHAR(15) DEFAULT '';
    START TRANSACTION;

    SELECT o.status
    INTO estado
    FROM orders o
    WHERE o.orderNumber = numPedido
        FOR
    UPDATE;

    IF estado = 'Shipped' THEN
        ROLLBACK;
        SIGNAL SQLSTATE '45067' SET MESSAGE_TEXT = 'Error, no se puede cancelar un pedido que ya fue enviado';
    ELSE
        UPDATE products p
            JOIN orderdetails od ON od.productCode = p.productCode
        SET quantityInStock = quantityInStock + od.quantityOrdered
        WHERE od.orderNumber = numPedido;
        UPDATE orders
        SET status = 'Cancelled'
        WHERE orderNumber = numPedido;
        COMMIT;
    END IF;

END //
DELIMITER ;

#4. Crear una transacción utilizando un procedimiento que reciba el id del vendedor que
-- se borró y el id del vendedor que toma el puesto. Se debe actualizar la tabla customers
-- modificando el campo salesRepEmployeeNumber para todos los clientes que eran
-- atendidos por el vendedor viejo. Debe verificar que el nuevo id realmente exista en la
-- tabla employees y que pertenezca a la misma oficina. Si el nuevo vendedor es de otra
-- oficina o no existe, debe lanzar el mensaje:"Error: Vendedor no apto para esta zona".

DELIMITER //

DROP PROCEDURE IF EXISTS reasignarVendedor //

CREATE PROCEDURE reasignarVendedor(
    IN vendedorViejo INT,
    IN vendedorNuevo INT
)
BEGIN

    DECLARE oficinaVieja INT;
    DECLARE oficinaNueva INT;

    START TRANSACTION;

    -- Obtener oficina del vendedor viejo
    SELECT officeCode
    INTO oficinaVieja
    FROM employees
    WHERE employeeNumber = vendedorViejo;

    -- Obtener oficina del vendedor nuevo
    SELECT officeCode
    INTO oficinaNueva
    FROM employees
    WHERE employeeNumber = vendedorNuevo;

    -- Validaciones
    IF oficinaNueva IS NULL OR oficinaVieja != oficinaNueva THEN

        ROLLBACK;

        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Error: Vendedor no apto para esta zona';

    ELSE

        -- reasignar clientes
        UPDATE customers
        SET salesRepEmployeeNumber = vendedorNuevo
        WHERE salesRepEmployeeNumber = vendedorViejo;

        COMMIT;

    END IF;

END //

DELIMITER ;
