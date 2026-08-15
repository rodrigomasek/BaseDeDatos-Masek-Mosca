use base_de_datos;

insert into niveles_usuario (id, nombre) values
(1, 'Normal'),
(2, 'Platinum'),
(3, 'Gold');

insert into niveles_publicacion (id, nombre) values
(1, 'Bronce'),
(2, 'Plata'),
(3, 'Oro'),
(4, 'Platino');

insert into metodos_pago (id, nombre) values
(1, 'Tarjeta de credito'),
(2, 'Tarjeta de debito'),
(3, 'Pago Facil'),
(4, 'Rapipago');

insert into metodos_envio (id, nombre) values
(1, 'OCA'),
(2, 'Correo Argentino');

insert into usuarios
(id, dni, nombre, apellido, id_nivel, reputacion)
values
(1, 38452719, 'Martin', 'Gonzalez', 3, 97.5),
(2, 41783952, 'Lucia', 'Fernandez', 2, 94.0),
(3, 40156283, 'Nicolas', 'Rodriguez', 1, 88.5),
(4, 42917465, 'Sofia', 'Martinez', 2, 91.0),
(5, 39563821, 'Federico', 'Lopez', 3, 99.0),
(6, 44629173, 'Camila', 'Sanchez', null, 50.0),
(7, 41837592, 'Tomas', 'Romero', 1, 84.5),
(8, 43271658, 'Valentina', 'Diaz', 1, 79.0),
(9, 38745126, 'Agustin', 'Torres', 2, 93.5),
(10, 45182937, 'Julieta', 'Acosta', 1, 86.0);

insert into categorias (id, nombre) values
(1, 'Computacion'),
(2, 'Perifericos'),
(3, 'Componentes'),
(4, 'Monitores'),
(5, 'Audio'),
(6, 'Almacenamiento');

insert into productos
(id, nombre, descripcion, cant, id_categoria)
values
(1, 'Notebook Lenovo IdeaPad 3',
     'Notebook de 15.6 pulgadas, Intel Core i5, 16 GB de RAM y SSD de 512 GB.',
     4, 1),

(2, 'Teclado mecanico Redragon Kumara',
     'Teclado mecanico compacto con switches mecanicos e iluminacion RGB.',
     12, 2),

(3, 'Mouse Logitech G502 Hero',
     'Mouse gamer con sensor de alta precision y botones programables.',
     8, 2),

(4, 'NVIDIA GeForce RTX 4060',
     'Placa de video de 8 GB GDDR6 para gaming y tareas de procesamiento grafico.',
     3, 3),

(5, 'Monitor Samsung Odyssey G5',
     'Monitor gamer curvo de 27 pulgadas, resolucion 1440p y 144 Hz.',
     5, 4),

(6, 'Auriculares HyperX Cloud II',
     'Auriculares gamer con microfono desmontable y sonido envolvente.',
     9, 5),

(7, 'SSD Kingston NV2 1TB',
     'Unidad de almacenamiento NVMe de 1 TB.',
     15, 6),

(8, 'Memoria RAM Kingston Fury 16GB',
     'Modulo de memoria DDR4 de 16 GB a 3200 MHz.',
     10, 3),

(9, 'Webcam Logitech C920',
     'Camara web Full HD 1080p con microfono integrado.',
     6, 2),

(10, 'Disco rigido Seagate 2TB',
     'Disco rigido SATA de 2 TB para almacenamiento.',
     7, 6);

insert into publicaciones
(id, nombre, detalles, precio_etiqueta, fecha, estado, id_nivel, id_vendedor)
values
(1,
 'Notebook Lenovo IdeaPad 3',
 'Notebook en excelente estado, poco uso. Incluye cargador original y caja.',
 850000,
 '2026-08-01 10:15:00',
 1,
 4,
 2),

(2,
 'Teclado mecanico Redragon Kumara',
 'Teclado practicamente nuevo. Switches mecanicos e iluminacion RGB.',
 75000,
 '2026-08-02 14:30:00',
 1,
 3,
 4),

(3,
 'Mouse Logitech G502 Hero',
 'Mouse utilizado durante aproximadamente seis meses. Funciona perfectamente.',
 95000,
 '2026-08-03 18:20:00',
 1,
 2,
 1),

(4,
 'NVIDIA GeForce RTX 4060',
 'Placa de video en excelente estado. Se entrega con caja y accesorios originales.',
 600000,
 '2026-08-04 11:00:00',
 1,
 4,
 5),

(5,
 'Monitor Samsung Odyssey G5',
 'Monitor gamer de 27 pulgadas. Sin pixeles muertos y con todos sus accesorios.',
 420000,
 '2026-08-05 16:45:00',
 1,
 3,
 5),

(6,
 'Auriculares HyperX Cloud II',
 'Auriculares con poco uso. Incluyen adaptador USB, microfono y caja.',
 120000,
 '2026-08-06 09:30:00',
 1,
 2,
 3),

(7,
 'SSD Kingston NV2 1TB',
 'SSD nuevo, sellado y con garantia.',
 135000,
 '2026-08-07 13:10:00',
 1,
 1,
 7),

(8,
 'Memoria RAM Kingston Fury 16GB',
 'Memoria DDR4 de 16 GB a 3200 MHz. Perfecto estado.',
 70000,
 '2026-08-08 17:25:00',
 1,
 1,
 9),

(9,
 'Webcam Logitech C920',
 'Webcam Full HD utilizada durante pocos meses.',
 110000,
 '2026-08-09 12:40:00',
 1,
 2,
 2),

(10,
 'Disco rigido Seagate 2TB',
 'Disco rigido usado en buen estado, sin sectores defectuosos.',
 80000,
 '2026-08-10 15:50:00',
 0,
 1,
 1);

insert into publicaciones_productos
(id, id_publicacion, id_producto)
values
(1, 1, 1),
(2, 2, 2),
(3, 3, 3),
(4, 4, 4),
(5, 5, 5),
(6, 6, 6),
(7, 7, 7),
(8, 8, 8),
(9, 9, 9),
(10, 10, 10);

insert into ventas_directas
(id, id_publicacion, id_metodo_pago, id_metodo_envio)
values
(1, 1, 1, 2),
(2, 2, 2, 1),
(3, 3, 1, 2),
(4, 6, 3, 1),
(5, 7, 4, 2),
(6, 9, 1, 2),
(7, 10, 2, 1);

insert into subastas
(id, fecha_fin, oferta_mayor, id_publicacion)
values
(1, '2026-08-20 23:59:00', 635000, 4),
(2, '2026-08-22 23:59:00', 435000, 5),
(3, '2026-08-25 23:59:00', 72000, 8);

insert into compras
(id, fecha, cant, id_publicacion, id_comprador)
values
(1, '2026-08-07 11:20:00', 1, 1, 6),
(2, '2026-08-08 16:40:00', 1, 2, 8),
(3, '2026-08-09 10:15:00', 1, 3, 10),
(4, '2026-08-10 18:30:00', 2, 6, 6),
(5, '2026-08-11 12:05:00', 1, 7, 3),
(6, '2026-08-12 14:50:00', 1, 9, 8),
(7, '2026-08-13 09:45:00', 1, 10, 4);

insert into ofertas
(id, fecha, monto, id_subasta, id_ofertante)
values
(1, '2026-08-06 13:20:00', 570000, 1, 3),
(2, '2026-08-07 15:10:00', 590000, 1, 8),
(3, '2026-08-08 19:35:00', 615000, 1, 6),
(4, '2026-08-09 11:25:00', 635000, 1, 9),
(5, '2026-08-07 17:40:00', 390000, 2, 1),
(6, '2026-08-08 12:30:00', 410000, 2, 7),
(7, '2026-08-10 20:15:00', 435000, 2, 3),
(8, '2026-08-09 14:10:00', 60000, 3, 10),
(9, '2026-08-10 16:45:00', 68000, 3, 6),
(10, '2026-08-11 18:20:00', 72000, 3, 8);

insert into preguntas
(id, fecha, texto, id_usuario_pregunta, id_publicacion)
values
(1,
 '2026-08-02 11:30:00',
 'La notebook incluye el cargador original?',
 6, 1),

(2,
 '2026-08-02 17:15:00',
 'El teclado funciona correctamente en Linux?',
 8, 2),

(3,
 '2026-08-04 09:45:00',
 'El mouse tiene algun problema con la rueda?',
 10, 3),

(4,
 '2026-08-05 13:20:00',
 'La placa fue utilizada para mineria?',
 3, 4),

(5,
 '2026-08-06 10:10:00',
 'El monitor tiene garantia?',
 7, 5),

(6,
 '2026-08-07 15:35:00',
 'Los auriculares incluyen el adaptador USB?',
 6, 6),

(7,
 '2026-08-08 12:50:00',
 'El SSD esta sellado de fabrica?',
 10, 7),

(8,
 '2026-08-09 18:05:00',
 'La memoria es compatible con una placa madre AM4?',
 3, 8),

(9,
 '2026-08-10 11:40:00',
 'La webcam incluye la tapa para cubrir el lente?',
 8, 9);

insert into respuestas
(id, fecha, texto, id_usuario_responde, id_pregunta)
values
(1,
 '2026-08-02 12:05:00',
 'Si, incluye el cargador original y funciona perfectamente.',
 2, 1),

(2,
 '2026-08-02 18:00:00',
 'Si, la probe en Ubuntu y funciona sin problemas.',
 4, 2),

(3,
 '2026-08-04 10:20:00',
 'No, la rueda funciona correctamente.',
 1, 3),

(4,
 '2026-08-05 14:00:00',
 'No, nunca fue utilizada para mineria.',
 5, 4),

(5,
 '2026-08-06 11:00:00',
 'Si, tiene garantia y conservo la factura de compra.',
 5, 5),

(6,
 '2026-08-07 16:10:00',
 'Si, incluye el adaptador USB original.',
 3, 6),

(7,
 '2026-08-08 13:30:00',
 'Si, esta completamente sellado de fabrica.',
 7, 7),

(8,
 '2026-08-09 19:00:00',
 'Si, es compatible con placas madre AM4 que utilicen DDR4.',
 9, 8),

(9,
 '2026-08-10 12:30:00',
 'No incluye tapa para el lente, pero la webcam funciona perfectamente.',
 2, 9);