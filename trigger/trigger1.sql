use classicmodels;
/*
1a Definir un trigger que se dispare después de insertar en la tabla de customers y que
inserte la información necesaria en customers_audit
*/
drop trigger before_insert_customers;
delimiter //
create trigger before_insert_customers after insert on customers for each row
begin
	insert into customers_audit values (new.customerName);
end//
delimiter ;

/*
3 Hacer un trigger que ante el intento de borrar un producto verifique que dicho producto
no exista en las órdenes cuya orderDate sea menor a dos meses. Si existe debe tirar un
error que diga “Error, tiene órdenes asociadas”
*/

DELIMITER //

CREATE TRIGGER before_delete_products
BEFORE DELETE ON products
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM orderdetails od
        JOIN orders o ON od.orderNumber = o.orderNumber
        WHERE od.productCode = OLD.productCode
        AND o.orderDate >= DATE_SUB(CURDATE(), INTERVAL 2 MONTH)
    ) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Error, tiene órdenes asociadas';
    END IF;
END//

DELIMITER ;







