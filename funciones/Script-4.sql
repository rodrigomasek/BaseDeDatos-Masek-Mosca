#6 Crear una vista que refleje todos los clientes que aún no hayan registrado pagos.


use classicmodels

create view sinPagos as
select c.customerNumber
from customers c
where c.customerNumber not IN 
(select p.customerNumber 
from payments p)



#10 Crear una vista que liste el nombre, el teléfono y la dirección de los clientes que hicieron
#una compra hace más de 2 años y de más de $30000.

create view info as select c.customerName, c.phone, c.addressLine1, c.addressLine2 from customers c
join payments p on p.customerNumber = c.customerNumber
where p.amount >= 30000 and YEAR(CURRENT_DATE) - YEAR(p.paymentDate) >= 2;


#11 Crear una vista que muestre todas las órdenes que se entregaron con demora o aquellas
-- que no se llegaron a entregar.

create view malasOrdenes as
select o.orderNumber 
from orders o
where o.shippedDate > o.requiredDate or o.status = "In Process";




#13  Crear una vista que muestre el cliente que compró más productos históricamente.

create view mvp as select c.customerName, count(p.customerNumber) as cantidad from customers c
join payments p on p.customerNumber = c.customerNumber
group by p.customerNumber
order by cantidad desc
limit 1;


#1  Crear una función que devuelva la cantidad de órdenes con determinado estado en el
-- rango de dos fechas (orderDate). La función recibe por parámetro las fechas desde, hasta
-- y el estado.

delimiter //
create function ordenesEstado(fechaInicio date, fechaFin date, estado text) returns int deterministic
begin
		declare cantOrdenes int default 0;
		select count(*) into cantOrdenes
		from orders
		where status = estado 
		and 
		orderDate BETWEEN fechaInicio and fechaFin;
		return cantOrdenes;	
end//
delimiter ;

select ordenesEstado("2023-10-10", current_date(), "Cancelled");

#2  Crear una función que reciba por parámetro dos fechas de envío (shippedDate) desde,
#hasta y devuelve la cantidad de órdenes entregadas.

delimiter //
create function ordenesEntregadas(desde date, hasta date) returns int deterministic
begin
	declare ordenesEntregadas int default 0;
	select count(*) into ordenesEntregadas
	from orders
	where status = "Shipped"
	and
	orderDate between desde and hasta;
	return ordenesEntregadas;
end //
delimiter ;
select ordenesEntregadas("2024-2-2","2025-2-2");

#3 Crear una función que reciba un número de cliente y devuelva la ciudad a la que
-- corresponde el empleado que lo atiende.

delimiter //
create function lugar(numero int) returns varchar(50) deterministic
begin
		declare ciudad varchar(50);	
		select o.city into ciudad
		from offices o
		join employees e on e.officeCode = o.officeCode
		join customers c on c.salesRepEmployeeNumber = e.employeeNumber
		where numero = c.customerNumber;
		return ciudad;
end//
delimiter ;

select lugar(141);

#7 Crear una función que reciba un nro de orden y un nro de producto, y devuelva el beneficio
-- obtenido con ese producto. El beneficio debe calcularse como priceEach – buyPrice.

delimiter //
create function beneficio(numeroOrden int, numeroProducto int) returns float deterministic
begin
	declare benefit float;
	select (od.priceEach - p.buyPrice) into benefit from products p
	join orderdetails od on p.productCode = od.productCode
	where numeroOden = od.orderNumber and numeroProducto = p.productNumber
	retun benefit;
end//
delimiter ;



















