#1 Crear un SP que liste todos los productos que tengan un precio de compra mayor al precio
-- promedio y que devuelva la cantidad de productos que cumplan con esa condición.

use classicmodels;

drop procedure if exists producto;
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

drop procedure if exists borrarxd;
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
drop procedure if exists borrarLineaProducto;
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

#4 Realizar un SP que muestre la cantidad de órdenes que hay en un estado estado. (lo cambie por mi bien)

delimiter //
create procedure listar(in estado varchar(50))
begin
	select count(*) from orders o
    where estado = o.status;
end //
delimiter ;

call listar('Shipped');


/*
delimiter //

create procedure ciudades(out listadoCiudades text) 
begin
    declare hayFilas boolean default 1;
    declare ciudadObtenida varchar(255);
    declare ciudades varchar(4000) default '';
    declare ciudadCursor cursor for select city from offices where city is not null;
    declare continue handler for not found set hayFilas = 0;

    set listadoCiudades = '';
    open ciudadCursor;

    ciudadesLoop: loop
        fetch ciudadCursor into ciudadObtenida;
        if hayFilas = 0 then
            leave ciudadesLoop;
        end if;
        set listadoCiudades = concat(ciudadObtenida, ', ', listadoCiudades);
    end loop ciudadesLoop;

    close ciudadCursor;
end //

delimiter ;
/*
#9 cursores
Crear un SP que utilice un cursor para recorrer la tabla de offices y que genere una lista con
las ciudades en las cuales hay oficinas. La lista tendrá que devolverse en un parámetro de
salida VARCHAR(4000) que contenga todas las ciudades separadas por coma.
getCiudadesOffices()
*/
/*
delimiter //
create procedure productosOrden (in numeroOrden int, out listadoProductos text) 
begin
declare hayFilas boolean default 1;
declare productoObtenido varchar(45) default “”;
declare ciudadesCursor cursor for select nombreProducto from detalleOrden join producto on idProducto =
producto_idProducto where idPedido = numeroOrden;
declare continue handler for not found set hayFilas = 0;
set listadoProductos = “”;
open productosCursor;
ordenesLoop:loop
fetch productosCursor into productoObtenido;
if hayFilas = 0 then
leave ordenesLoop;
end if;
set listadoProducto = concat(productoObtenido, “, “, listadoProductos)
end loop ordenesLoop;
close productosCursor;
end//
delimiter ;

#11 Realizar un SP que reciba el customerNumber y para todas las órdenes de ese
-- customerNumber, si el campo comments esta vacío que lo complete con el siguiente
-- comentario: “El total de la orden es … “ Y el total de la orden tendrá que calcularlo el
-- procedimiento sumando todos los productos incluidos en la orden de la tabla OrderDetails.
-- alterCommentOrder()

delimiter //
create procedure procedimiento(in numeroC int)
begin
	
	declare hayfilas boolean default = 1;
	declare cursamiento cursor for select o.comments, c.customerNumber, sum(od.quantityOrdered)
	from customers c
	join orders o on o.customerNumber = c.customerNumber
	join orderdetails od on od.orderNumber = o.orderNumber
	
	
end //
begin ;


*/










