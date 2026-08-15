drop database if exists base_de_datos;
create database if not exists base_de_datos;
use base_de_datos;

create table niveles_usuario(
	id int primary key,
	nombre text not null
);

create table usuarios(
	id int primary key,
	dni int not null,
	nombre text not null,
	apellido text not null,
	id_nivel int default null,
	reputacion float default 50 check (reputacion >= 0 and reputacion <= 100),
	foreign key (id_nivel) references niveles_usuario(id)
);

create table niveles_publicacion(
	id int primary key,
	nombre text not null
);

create table publicaciones (
	id int primary key,
	nombre text not null,
	detalles text,
	precio_etiqueta float not null,
	fecha datetime default current_timestamp,
	estado tinyint default 1,
	id_nivel int,
	id_vendedor int,
	foreign key (id_nivel) references niveles_publicacion(id),
	foreign key (id_vendedor) references usuarios(id)
);

create table metodos_pago(
	id int primary key,
	nombre text not null
);

create table metodos_envio(
	id int primary key,
	nombre text not null
);

create table ventas_directas(
	id int primary key,
	id_publicacion int,
	id_metodo_pago int,
	id_metodo_envio int,
	foreign key (id_publicacion) references publicaciones(id),
	foreign key (id_metodo_pago) references metodos_pago(id),
	foreign key (id_metodo_envio) references metodos_envio(id)
);

create table subastas(
	id int primary key,
	fecha_fin datetime default current_timestamp,
	oferta_mayor float,
	id_publicacion int,
	foreign key (id_publicacion) references publicaciones(id)
);

create table categorias(
	id int primary key,
	nombre text not null
);

create table productos(
	id int primary key,
	nombre text not null,
	descripcion text,
	cant int check (cant > 0),
	id_categoria int,
	foreign key (id_categoria) references categorias(id)
);

create table publicaciones_productos(
	id int primary key,
	id_publicacion int,
	id_producto int,
	foreign key (id_publicacion) references publicaciones(id),
	foreign key (id_producto) references productos(id)
);

create table compras(
	id int primary key,
	fecha datetime default current_timestamp,
	cant int not null check (cant > 0),
	id_publicacion int,
	id_comprador int,
	foreign key (id_publicacion) references publicaciones(id),
	foreign key (id_comprador) references usuarios(id)
);

create table ofertas(
	id int primary key,
	fecha datetime default current_timestamp,
	monto float not null,
	id_subasta int,
	id_ofertante int,
	foreign key (id_subasta) references subastas(id),
	foreign key (id_ofertante) references usuarios(id)
);

create table preguntas(
	id int primary key,
	fecha datetime default current_timestamp,
	texto varchar(350),
	id_usuario_pregunta int not null,
	id_publicacion int not null,
	foreign key (id_usuario_pregunta) references usuarios(id),
	foreign key (id_publicacion) references publicaciones(id)
);

create table respuestas(
	id int primary key,
	fecha datetime default current_timestamp,
	texto varchar(350),
	id_usuario_responde int not null,
	id_pregunta int not null,
	foreign key (id_usuario_responde) references usuarios(id),
	foreign key (id_pregunta) references preguntas(id)
);