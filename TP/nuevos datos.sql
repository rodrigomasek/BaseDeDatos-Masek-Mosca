USE base_de_datos;


INSERT INTO niveles_usuario
(id, nombre)
VALUES
(1, 'Normal'),
(2, 'Platinum'),
(3, 'Gold');


INSERT INTO niveles_publicacion
(id, nombre)
VALUES
(1, 'Bronce'),
(2, 'Plata'),
(3, 'Oro'),
(4, 'Platino');


INSERT INTO metodos_pago
(id, nombre)
VALUES
(1, 'Tarjeta de credito'),
(2, 'Tarjeta de debito'),
(3, 'Pago Facil'),
(4, 'Rapipago');


INSERT INTO metodos_envio
(id, nombre)
VALUES
(1, 'OCA'),
(2, 'Correo Argentino');


INSERT INTO usuarios
(id, dni, nombre, apellido, email, id_nivel, reputacion)
VALUES
(1, 40111222, 'Juan', 'Perez', 'juan.perez@gmail.com', 1, 85),
(2, 40222333, 'Maria', 'Gomez', 'maria.gomez@gmail.com', 2, 92),
(3, 40333444, 'Lucas', 'Fernandez', 'lucas.fernandez@gmail.com', 3, 97),
(4, 40444555, 'Sofia', 'Martinez', 'sofia.martinez@gmail.com', 1, 78),
(5, 40555666, 'Pedro', 'Rodriguez', 'pedro.rodriguez@gmail.com', 2, 88),
(6, 40666777, 'Ana', 'Lopez', 'ana.lopez@gmail.com', 3, 99),
(7, 40777888, 'Diego', 'Sanchez', 'diego.sanchez@gmail.com', 1, 75),
(8, 40888999, 'Laura', 'Diaz', 'laura.diaz@gmail.com', 2, 90),
(9, 40999111, 'Martin', 'Torres', 'martin.torres@gmail.com', 1, 82),
(10, 41000111, 'Camila', 'Romero', 'camila.romero@gmail.com', 3, 96);


INSERT INTO categorias
(id, nombre)
VALUES
(1, 'Electronica'),
(2, 'Computacion'),
(3, 'Hogar'),
(4, 'Indumentaria'),
(5, 'Deportes'),
(6, 'Videojuegos'),
(7, 'Celulares');


INSERT INTO productos
(id, nombre, descripcion, cant, id_categoria)
VALUES
(1, 'PlayStation 5',
 'Consola PlayStation 5 nueva con joystick incluido.',
 5, 6),

(2, 'Xbox Series X',
 'Consola Xbox Series X nueva.',
 4, 6),

(3, 'Notebook Lenovo IdeaPad',
 'Notebook Lenovo con procesador Intel y 16GB de RAM.',
 8, 2),

(4, 'Monitor Samsung 24',
 'Monitor Samsung de 24 pulgadas Full HD.',
 10, 2),

(5, 'Teclado Mecanico Redragon',
 'Teclado mecanico RGB para gaming.',
 15, 2),

(6, 'Mouse Logitech G502',
 'Mouse gamer Logitech G502.',
 20, 2),

(7, 'iPhone 15',
 'Apple iPhone 15 de 128GB.',
 6, 7),

(8, 'Samsung Galaxy S24',
 'Samsung Galaxy S24 256GB.',
 7, 7),

(9, 'Zapatillas Nike Air',
 'Zapatillas Nike deportivas.',
 12, 5),

(10, 'Campera Adidas',
 'Campera deportiva Adidas.',
 10, 4),

(11, 'Sillon Reclinable',
 'Sillon reclinable para living.',
 3, 3),

(12, 'Auriculares Sony',
 'Auriculares inalambricos Sony.',
 15, 1);


-- Publicaciones

INSERT INTO publicaciones
(id, nombre, detalles, precio_etiqueta, fecha, estado, id_nivel, id_vendedor)
VALUES

-- Activas
(1,
 'PlayStation 5 nueva',
 'PlayStation 5 nueva, garantia oficial y joystick incluido.',
 850000,
 DATE_SUB(NOW(), INTERVAL 2 DAY),
 1, 3, 3),

(2,
 'Notebook Lenovo IdeaPad',
 'Notebook Lenovo IdeaPad con 16GB RAM y SSD.',
 650000,
 DATE_SUB(NOW(), INTERVAL 3 DAY),
 1, 2, 2),

(3,
 'Monitor Samsung 24 pulgadas',
 'Monitor Full HD ideal para gaming y trabajo.',
 180000,
 DATE_SUB(NOW(), INTERVAL 1 DAY),
 1, 1, 5),

(4,
 'Mouse Logitech G502',
 'Mouse gamer profesional con RGB.',
 120000,
 DATE_SUB(NOW(), INTERVAL 5 DAY),
 1, 2, 6),

(5,
 'iPhone 15 128GB',
 'iPhone 15 nuevo sellado.',
 1200000,
 DATE_SUB(NOW(), INTERVAL 4 DAY),
 1, 4, 6),

-- Pausada
(6,
 'Campera Adidas deportiva',
 'Campera Adidas original.',
 150000,
 DATE_SUB(NOW(), INTERVAL 100 DAY),
 2, 1, 4),

-- Finalizadas
(7,
 'Zapatillas Nike Air',
 'Zapatillas Nike originales.',
 200000,
 DATE_SUB(NOW(), INTERVAL 15 DAY),
 3, 1, 1),

(8,
 'Auriculares Sony',
 'Auriculares Sony inalambricos.',
 180000,
 DATE_SUB(NOW(), INTERVAL 20 DAY),
 3, 2, 5),

-- Subastas activas
(9,
 'Teclado Mecanico Redragon',
 'Teclado RGB mecanico.',
 90000,
 DATE_SUB(NOW(), INTERVAL 6 DAY),
 1, 1, 3),

(10,
 'Sillon Reclinable',
 'Sillon reclinable para living.',
 350000,
 DATE_SUB(NOW(), INTERVAL 8 DAY),
 1, 1, 8);


INSERT INTO publicaciones_productos
(id, id_publicacion, id_producto)
VALUES
(1, 1, 1),
(2, 2, 3),
(3, 3, 4),
(4, 4, 6),
(5, 5, 7),
(6, 6, 10),
(7, 7, 9),
(8, 8, 12),
(9, 9, 5),
(10, 10, 11);


INSERT INTO ventas_directas
(id, id_publicacion, id_metodo_pago, id_metodo_envio)
VALUES
(1, 1, 1, 1),
(2, 2, 2, 2),
(3, 3, 1, 1),
(4, 4, 3, 2),
(5, 5, 4, 1),
(6, 6, NULL, NULL),
(7, 7, 1, 2),
(8, 8, 2, 1);


INSERT INTO subastas
(id, fecha_fin, oferta_mayor, id_publicacion)
VALUES
(1,
 DATE_ADD(NOW(), INTERVAL 3 DAY),
 95000,
 9),

(2,
 DATE_ADD(NOW(), INTERVAL 5 DAY),
 400000,
 10);


INSERT INTO ofertas
(id, fecha, monto, id_subasta, id_ofertante)
VALUES

(1,
 DATE_SUB(NOW(), INTERVAL 2 HOUR),
 91000,
 1,
 1),

(2,
 DATE_SUB(NOW(), INTERVAL 1 HOUR),
 93000,
 1,
 4),

(3,
 DATE_SUB(NOW(), INTERVAL 30 MINUTE),
 95000,
 1,
 5),

(4,
 DATE_SUB(NOW(), INTERVAL 2 HOUR),
 370000,
 2,
 2),

(5,
 DATE_SUB(NOW(), INTERVAL 1 HOUR),
 400000,
 2,
 6);


INSERT INTO compras
(id, fecha, cant, id_publicacion, id_comprador)
VALUES

(1,
 DATE_SUB(NOW(), INTERVAL 1 DAY),
 1,
 7,
 2),

(2,
 DATE_SUB(NOW(), INTERVAL 3 DAY),
 2,
 8,
 4),

(3,
 DATE_SUB(NOW(), INTERVAL 5 DAY),
 1,
 7,
 5),

(4,
 DATE_SUB(NOW(), INTERVAL 10 DAY),
 1,
 8,
 7),

(5,
 DATE_SUB(NOW(), INTERVAL 2 DAY),
 1,
 7,
 8);


INSERT INTO preguntas
(id, fecha, texto, id_usuario_pregunta, id_publicacion)
VALUES

(1,
 NOW(),
 '¿La consola incluye joystick?',
 1,
 1),

(2,
 NOW(),
 '¿Tiene garantia oficial?',
 4,
 1),

(3,
 DATE_SUB(NOW(), INTERVAL 1 HOUR),
 '¿Cuanta memoria RAM tiene?',
 7,
 2),

(4,
 DATE_SUB(NOW(), INTERVAL 2 HOUR),
 '¿Es compatible con PC?',
 1,
 3),

(5,
 DATE_SUB(NOW(), INTERVAL 3 HOUR),
 '¿Haces envios?',
 2,
 4),

(6,
 DATE_SUB(NOW(), INTERVAL 1 DAY),
 '¿Es nuevo?',
 4,
 5),

(7,
 DATE_SUB(NOW(), INTERVAL 2 DAY),
 '¿Que talle es?',
 2,
 6),

(8,
 DATE_SUB(NOW(), INTERVAL 3 DAY),
 '¿Tiene cancelacion de ruido?',
 7,
 8);


INSERT INTO respuestas
(id, fecha, texto, id_usuario_responde, id_pregunta)
VALUES

(1,
 DATE_SUB(NOW(), INTERVAL 30 MINUTE),
 'Si, incluye un joystick original.',
 3,
 1),

(2,
 DATE_SUB(NOW(), INTERVAL 1 DAY),
 'Si, tiene garantia oficial.',
 3,
 2),

(3,
 DATE_SUB(NOW(), INTERVAL 30 MINUTE),
 'Tiene 16GB de RAM.',
 2,
 3),

(4,
 DATE_SUB(NOW(), INTERVAL 1 DAY),
 'Si, es compatible con PC.',
 5,
 4),

(5,
 DATE_SUB(NOW(), INTERVAL 2 DAY),
 'Si, realizamos envios.',
 5,
 5);


INSERT INTO calificaciones
(id, id_compra, id_calificador, id_calificado, puntuacion, fecha)
VALUES

(1, 1, 2, 1, 90, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(2, 1, 1, 2, 95, DATE_SUB(NOW(), INTERVAL 1 DAY)),

(3, 2, 4, 5, 85, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(4, 2, 5, 4, 100, DATE_SUB(NOW(), INTERVAL 2 DAY)),

(5, 3, 5, 1, 80, DATE_SUB(NOW(), INTERVAL 4 DAY)),
(6, 3, 1, 5, 90, DATE_SUB(NOW(), INTERVAL 4 DAY));


INSERT INTO notificaciones
(id, id_usuario, mensaje, fecha, leida)
VALUES

(1,
 3,
 'La publicacion sobre PlayStation 5 nueva tiene 2 preguntas sin responder',
 NOW(),
 0),

(2,
 5,
 'La publicacion sobre Monitor Samsung 24 pulgadas tiene 1 pregunta sin responder',
 NOW(),
 0);


INSERT INTO estadisticas
(id, fecha, tipo, valor, descripcion)
VALUES

(1,
 CURDATE(),
 'VENDEDORES',
 5,
 'Cantidad de vendedores con publicaciones activas'),

(2,
 CURDATE(),
 'COMPRADORES',
 4,
 'Cantidad de compradores del dia'),

(3,
 CURDATE(),
 'PRODUCTOS',
 6,
 'Cantidad de productos publicados durante el dia');