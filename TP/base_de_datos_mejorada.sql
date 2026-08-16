DROP DATABASE IF EXISTS base_de_datos;

CREATE DATABASE base_de_datos;

USE base_de_datos;


CREATE TABLE niveles_usuario(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE
);


CREATE TABLE usuarios(
    id INT PRIMARY KEY AUTO_INCREMENT,
    dni INT NOT NULL UNIQUE,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    id_nivel INT DEFAULT NULL,
    reputacion DECIMAL(5,2) DEFAULT 50
        CHECK (reputacion >= 0 AND reputacion <= 100),

    FOREIGN KEY (id_nivel)
        REFERENCES niveles_usuario(id)
);


CREATE TABLE niveles_publicacion(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(30) NOT NULL UNIQUE
);


-- publicaciones

-- estado:
-- 1 = activa
-- 2 = pausada
-- 3 = finalizada
-- 4 = observada

CREATE TABLE publicaciones(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(200) NOT NULL,
    detalles TEXT,
    precio_etiqueta DECIMAL(15,2) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,

    estado TINYINT NOT NULL DEFAULT 1
        CHECK (estado IN (1,2,3,4)),

    id_nivel INT NOT NULL,
    id_vendedor INT NOT NULL,

    FOREIGN KEY (id_nivel)
        REFERENCES niveles_publicacion(id),

    FOREIGN KEY (id_vendedor)
        REFERENCES usuarios(id)
);


CREATE TABLE metodos_pago(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE metodos_envio(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(50) NOT NULL UNIQUE
);


CREATE TABLE ventas_directas(
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_publicacion INT NOT NULL,
    id_metodo_pago INT DEFAULT NULL,
    id_metodo_envio INT DEFAULT NULL,

    FOREIGN KEY (id_publicacion)
        REFERENCES publicaciones(id),

    FOREIGN KEY (id_metodo_pago)
        REFERENCES metodos_pago(id),

    FOREIGN KEY (id_metodo_envio)
        REFERENCES metodos_envio(id),

    UNIQUE(id_publicacion)
);


CREATE TABLE subastas(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha_fin DATETIME NOT NULL,
    oferta_mayor DECIMAL(15,2) DEFAULT 0,
    id_publicacion INT NOT NULL,

    FOREIGN KEY (id_publicacion)
        REFERENCES publicaciones(id),

    UNIQUE(id_publicacion)
);


CREATE TABLE categorias(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL UNIQUE
);


CREATE TABLE productos(
    id INT PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(200) NOT NULL,
    descripcion TEXT,

    cant INT NOT NULL DEFAULT 1
        CHECK (cant > 0),

    id_categoria INT NOT NULL,

    FOREIGN KEY (id_categoria)
        REFERENCES categorias(id)
);


CREATE TABLE publicaciones_productos(
    id INT PRIMARY KEY AUTO_INCREMENT,
    id_publicacion INT NOT NULL,
    id_producto INT NOT NULL,

    FOREIGN KEY (id_publicacion)
        REFERENCES publicaciones(id),

    FOREIGN KEY (id_producto)
        REFERENCES productos(id),

    UNIQUE(id_publicacion, id_producto)
);


CREATE TABLE compras(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,

    cant INT NOT NULL
        CHECK (cant > 0),

    id_publicacion INT NOT NULL,
    id_comprador INT NOT NULL,

    FOREIGN KEY (id_publicacion)
        REFERENCES publicaciones(id),

    FOREIGN KEY (id_comprador)
        REFERENCES usuarios(id)
);


CREATE TABLE ofertas(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,

    monto DECIMAL(15,2) NOT NULL
        CHECK (monto > 0),

    id_subasta INT NOT NULL,
    id_ofertante INT NOT NULL,

    FOREIGN KEY (id_subasta)
        REFERENCES subastas(id),

    FOREIGN KEY (id_ofertante)
        REFERENCES usuarios(id)
);


CREATE TABLE preguntas(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    texto VARCHAR(350) NOT NULL,

    id_usuario_pregunta INT NOT NULL,
    id_publicacion INT NOT NULL,

    FOREIGN KEY (id_usuario_pregunta)
        REFERENCES usuarios(id),

    FOREIGN KEY (id_publicacion)
        REFERENCES publicaciones(id)
);


CREATE TABLE respuestas(
    id INT PRIMARY KEY AUTO_INCREMENT,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,
    texto VARCHAR(350) NOT NULL,

    id_usuario_responde INT NOT NULL,
    id_pregunta INT NOT NULL,

    FOREIGN KEY (id_usuario_responde)
        REFERENCES usuarios(id),

    FOREIGN KEY (id_pregunta)
        REFERENCES preguntas(id)
);


CREATE TABLE calificaciones(
    id INT PRIMARY KEY AUTO_INCREMENT,

    id_compra INT NOT NULL,
    id_calificador INT NOT NULL,
    id_calificado INT NOT NULL,

    puntuacion DECIMAL(5,2) NOT NULL
        CHECK (puntuacion >= 0 AND puntuacion <= 100),

    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,

    FOREIGN KEY (id_compra)
        REFERENCES compras(id),

    FOREIGN KEY (id_calificador)
        REFERENCES usuarios(id),

    FOREIGN KEY (id_calificado)
        REFERENCES usuarios(id),

    UNIQUE(id_compra, id_calificador, id_calificado)
);


CREATE TABLE notificaciones(
    id INT PRIMARY KEY AUTO_INCREMENT,

    id_usuario INT NOT NULL,
    mensaje VARCHAR(500) NOT NULL,
    fecha DATETIME DEFAULT CURRENT_TIMESTAMP,

    leida TINYINT NOT NULL DEFAULT 0
        CHECK (leida IN (0,1)),

    FOREIGN KEY (id_usuario)
        REFERENCES usuarios(id)
);


CREATE TABLE estadisticas(
    id INT PRIMARY KEY AUTO_INCREMENT,

    fecha DATE NOT NULL,
    tipo VARCHAR(50) NOT NULL,
    valor DECIMAL(15,2) NOT NULL,
    descripcion VARCHAR(255)
);