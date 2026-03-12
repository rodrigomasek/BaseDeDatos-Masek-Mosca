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
















