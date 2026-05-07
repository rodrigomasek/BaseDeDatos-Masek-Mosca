#1 Crear un trigger que ante cada fila insertada en la tabla Pedido_Producto modifique la tabla
-- IngresoStock_Producto restando de la columna cantidad de esta tabla la cantidad informada en
-- Pedido_Producto.

delimiter //
create trigger modifiISP after INSERT on pedido_producto for each row
begin
	update ingresostock_producto 
	SET cantidad = cantidad - new.cantidad
	where Producto_codProducto = Producto_codProducto;
end//
delimiter ;

#3  Imaginando que agregamos una columna categoría en la tabla de clientes, hacer un trigger que, cada vez
-- que se agrega un pedido, se calcule el monto total gastado por ese cliente en los últimos dos años y
-- actualice la categoría del cliente. Las categorías son “bronce” hasta $50.000 inclusive, “ plata”de $50.000 a
-- $100.000 inclusive y “oro” más de $100.000.

delimiter //
create trigger after_insert_pedido  after INSERT on pedido for each row
begin
	declare monto int;
	
	select sum(pp.cantidad * pp.precioUnitario) into monto
	from pedido_producto pp
	join pedido p on p.idPedido = pp.Pedido_idPedido
	where p.Cliente_codCliente = new.Cliente_codCliente
	AND 
	p.fecha >= DATE_sub(NOW(), INTERVAL 2 YEAR);
	
	if (monto <= 50000) then
		update cliente
		set categoria = "bronce"
		where codCliente = new.Cliente_codCliente;
	else if (monto > 100000) then
		update cliente
		set categoria = "oro"
		where codCliente = new.Cliente_codCliente;
	else
		update cliente
		set categoria = "plata"
		where codCliente = new.Cliente_codCliente;
	end if;
	end if;
end//
delimiter ;              

#5 crear un trigger que me permita llevar a cabo la acción de borrado en la tabla de pedidos. Planteen y desarrollen
-- cuáles serían otras alternativas de solución que se les ocurra, como por ejemplo utilizando una función o
-- definiendo cambio de restricciones, alguna otra característica que le parezca contemplar

delimiter //
create trigger modifiISP after INSERT on pedido_producto for each row
begin
	update ingresostock_producto 
	SET cantidad = cantidad - new.cantidad
	where Producto_codProducto = Producto_codProducto;
end//
delimiter ;


