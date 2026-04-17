use classicmodels;
/*
9-
Crear un SP que utilice un cursor para recorrer la tabla de offices y que genere una lista con
las ciudades en las cuales hay oficinas. La lista tendrá que devolverse en un parámetro de
salida VARCHAR(4000) que contenga todas las ciudades separadas por coma.
getCiudadesOffices()
*/
delimiter //
drop procedure productosOrden;
create procedure productosOrden (out listadoCiudades text) 
begin
declare hayFilas boolean default 1;
declare ciudadObtenida varchar(100) default '';
declare ciudadesCursor cursor for select o.city from offices o;
declare continue handler for not found set hayFilas = 0;
set listadoCiudades = '';
open ciudadesCursor;
ciudadesLoop:loop
fetch ciudadesCursor into ciudadObtenida;
if hayFilas = 0 then
leave ciudadesLoop;
end if;
set listadoCiudades = concat(ciudadObtenida, ', ', listadoCiudades);
end loop ciudadesLoop;
close ciudadesCursor;
end//
delimiter ;

set @ciudades = '';
call productosOrden (@ciudades);
select @ciudades;

/*
11-
Realizar un SP que reciba el customerNumber y para todas las órdenes de ese
customerNumber, si el campo comments esta vacío que lo complete con el siguiente
comentario: “El total de la orden es … “ Y el total de la orden tendrá que calcularlo el
procedimiento sumando todos los productos incluidos en la orden de la tabla OrderDetails.
alterCommentOrder()
*/
delimiter //
create procedure nombreSP (in numeroDeCliente int) 
begin
declare hayFilas boolean default 1;
declare comentario varchar(100);
declare ordenesCursor cursor for select o.comments from orders o;
declare continue handler for not found set hayFilas = 0;
open ordenesCursor;
bucle:loop
fetch nombreCursor into comentario;
if hayFilas = 0 then
leave bucle;
end if;
if comentario is null then

UPDATE orders o
SET o.comments = concat("El total de la orden es ", (select sum(od.quantityOrdered) from orderdetails od)  
WHERE condicion;




end if;
end loop bucle;
close nombre_cursor;
end//
delimiter 













