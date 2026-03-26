#1 Crear un SP que liste todos los productos que tengan un precio de compra mayor al precio
-- promedio y que devuelva la cantidad de productos que cumplan con esa condición.

use classicmodels;

delimiter //
create procedure producto(out productos int)
begin

	select count(*) into productos
	from products p
	where p.buyPrice > 
	(select avg(p2.buyPrice)
	from products p2);
	
end//
delimiter ;


-- Crear variable de sesión
set @messi = 0;

-- Llamar al procedimiento
call producto(@messi);

-- Ver el resultado
select @messi;
#2 Crear un SP que reciba un orderNumber y la borre. Previamente debe eliminar todos los
-- ítems de la tabla orderDetails asociados a él. Tiene que devolver 0 si no encontró filas para
-- ese orderNumber, o la cantidad ítems borrados si encontró el orderNumber.

delimiter //

create procedure borrarxd(inout numeroOrden int)
begin
    declare cantidadItems int default 0;

    -- Borrar ítems de orderdetails
    delete from orderdetails
    where orderNumber = numeroOrden;

    -- Guardar cantidad de ítems borrados
    set cantidadItems = row_count();

    -- Borrar la orden si existía
    delete from orders
    where orderNumber = numeroOrden;

    -- Actualizar parámetro con la cantidad de ítems borrados, o 0 si no existía
    set numeroOrden = cantidadItems;
end//

delimiter ;

set @locuraextrema = 0;

-- Llamar al procedimiento
call borrarxd(@locuraextrema);

-- Ver el resultado
select @locuraextrema;


#3 Crear un SP que borre una línea de productos de la tabla Productlines. Tenga en cuenta que
-- la línea de productos no podrá ser borrada si tiene productos asociados. El procedure debe
-- devolver un mensaje que contenga una de las siguientes leyendas

delimiter //

create procedure borrarLineaProducto(
    in nombreLinea varchar(50),
    out mensaje varchar(100)
)
begin
    declare cantidadProductos int;

        if not exists (select 1 from productlines where productLine = nombreLinea) then
        set mensaje = 'Línea de productos no encontrada';
    else
        select count(*) into cantidadProductos
        from products
        where productLine = nombreLinea;

        if cantidadProductos > 0 then
            set mensaje = 'No se puede borrar, hay productos asociados';
        else
            delete from productlines
            where productLine = nombreLinea;
            set mensaje = 'Línea de productos borrada correctamente';
        end if;
    end if;
end//

delimiter ;





















