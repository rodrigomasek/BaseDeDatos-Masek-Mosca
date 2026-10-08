USE base_de_datos;
SET GLOBAL log_bin_trust_function_creators = 1;
DELIMITER //

/* =========================================================
   FUNCIONES
   ========================================================= */

-- 1. Tiempo promedio que tarda un vendedor en concretar una venta.
-- Se devuelve el promedio en dias.
CREATE FUNCTION fn_tiempo_promedio_venta(
    p_id_usuario INT
)
RETURNS DECIMAL(10,2)
BEGIN
    DECLARE v_promedio DECIMAL(10,2);

    SELECT AVG(DATEDIFF(c.fecha, p.fecha))
    INTO v_promedio
    FROM publicaciones p
    JOIN compras c ON c.id_publicacion = p.id
    WHERE p.id_vendedor = p_id_usuario;

    IF v_promedio IS NULL THEN
        SET v_promedio = 0;
    END IF;

    RETURN v_promedio;
END//


-- 2. Comision del sistema segun el nivel del vendedor.
CREATE FUNCTION fn_comision(
    p_monto DECIMAL(15,2),
    p_nivel VARCHAR(30)
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    IF LOWER(p_nivel) = 'normal' THEN
        RETURN p_monto * 0.08;
    ELSEIF LOWER(p_nivel) = 'platinum' THEN
        RETURN p_monto * 0.05;
    ELSEIF LOWER(p_nivel) = 'gold' THEN
        RETURN p_monto * 0.03;
    ELSE
        RETURN -1;
    END IF;
END//


-- 3. Porcentaje de publicaciones de un vendedor que tuvieron ventas.
CREATE FUNCTION fn_porcentaje_ventas(
    p_id_usuario INT
)
RETURNS DECIMAL(5,2)
BEGIN
    DECLARE v_total INT;
    DECLARE v_concretadas INT;

    SELECT COUNT(*)
    INTO v_total
    FROM publicaciones
    WHERE id_vendedor = p_id_usuario;

    IF v_total = 0 THEN
        RETURN 0;
    END IF;

    SELECT COUNT(DISTINCT p.id)
    INTO v_concretadas
    FROM publicaciones p
    JOIN compras c ON c.id_publicacion = p.id
    WHERE p.id_vendedor = p_id_usuario;

    RETURN (v_concretadas * 100.0) / v_total;
END//


-- 4. Mayor oferta de una subasta.
CREATE FUNCTION fn_mayor_oferta(
    p_id_subasta INT
)
RETURNS DECIMAL(15,2)
BEGIN
    DECLARE v_existe INT;
    DECLARE v_mayor DECIMAL(15,2);

    SELECT COUNT(*)
    INTO v_existe
    FROM subastas
    WHERE id = p_id_subasta;

    IF v_existe = 0 THEN
        RETURN -1;
    END IF;

    SELECT MAX(monto)
    INTO v_mayor
    FROM ofertas
    WHERE id_subasta = p_id_subasta;

    IF v_mayor IS NULL THEN
        SET v_mayor = 0;
    END IF;

    RETURN v_mayor;
END//


-- 5. Precio promedio de las publicaciones de una categoria.
CREATE FUNCTION fn_precio_promedio_categoria(
    p_id_categoria INT
)
RETURNS DECIMAL(15,2)
BEGIN
    DECLARE v_promedio DECIMAL(15,2);

    SELECT AVG(p.precio_etiqueta)
    INTO v_promedio
    FROM publicaciones p
    JOIN publicaciones_productos pp ON pp.id_publicacion = p.id
    JOIN productos pr ON pr.id = pp.id_producto
    WHERE pr.id_categoria = p_id_categoria;

    IF v_promedio IS NULL THEN
        SET v_promedio = 0;
    END IF;

    RETURN v_promedio;
END//


-- 6. Ultima fecha de compra de un usuario.
CREATE FUNCTION fn_ultima_compra(
    p_id_usuario INT
)
RETURNS DATETIME
BEGIN
    DECLARE v_fecha DATETIME;

    SELECT MAX(fecha)
    INTO v_fecha
    FROM compras
    WHERE id_comprador = p_id_usuario;

    RETURN v_fecha;
END//


/* =========================================================
   STORED PROCEDURES
   ========================================================= */

-- 1. Buscar publicaciones cuyo titulo o descripcion contienen el texto buscado.
CREATE PROCEDURE sp_buscar_publicaciones(
    IN p_texto VARCHAR(200),
    OUT p_ok BOOLEAN
)
BEGIN
    SET p_ok = FALSE;

    IF p_texto IS NOT NULL AND p_texto <> '' THEN

        SELECT DISTINCT
            p.id,
            p.nombre AS titulo,
            p.precio_etiqueta AS precio
        FROM publicaciones p
        JOIN publicaciones_productos pp ON pp.id_publicacion = p.id
        JOIN productos pr ON pr.id = pp.id_producto
        WHERE p.nombre LIKE CONCAT('%', p_texto, '%')
           OR p.detalles LIKE CONCAT('%', p_texto, '%');

        SET p_ok = TRUE;
    END IF;
END//


-- 2. Realizar una oferta en una subasta.
CREATE PROCEDURE sp_pujar(
    IN p_id_subasta INT,
    IN p_id_ofertante INT,
    IN p_monto DECIMAL(15,2),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT;
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_fecha_fin DATETIME;
    DECLARE v_mayor DECIMAL(15,2);

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM subastas
    WHERE id = p_id_subasta;

    IF v_existe > 0 THEN

        SELECT
            p.id_vendedor,
            p.estado,
            s.fecha_fin
        INTO
            v_vendedor,
            v_estado,
            v_fecha_fin
        FROM subastas s
        JOIN publicaciones p ON p.id = s.id_publicacion
        WHERE s.id = p_id_subasta;

        SELECT MAX(monto)
        INTO v_mayor
        FROM ofertas
        WHERE id_subasta = p_id_subasta;

        IF v_mayor IS NULL THEN
            SET v_mayor = 0;
        END IF;

        IF v_estado = 1
           AND v_fecha_fin > NOW()
           AND p_id_ofertante <> v_vendedor
           AND p_monto > v_mayor THEN

            INSERT INTO ofertas(monto, id_subasta, id_ofertante)
            VALUES(p_monto, p_id_subasta, p_id_ofertante);

            UPDATE subastas
            SET oferta_mayor = p_monto
            WHERE id = p_id_subasta;

            SET p_ok = TRUE;
        END IF;
    END IF;
END//


-- 3. Pausar una publicacion de venta directa.
CREATE PROCEDURE sp_pausar_publicacion(
    IN p_id_publicacion INT,
    IN p_id_usuario INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_es_directa INT;
    DECLARE v_existe INT;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM publicaciones
    WHERE id = p_id_publicacion;

    IF v_existe > 0 THEN

        SELECT id_vendedor, estado
        INTO v_vendedor, v_estado
        FROM publicaciones
        WHERE id = p_id_publicacion;

        SELECT COUNT(*)
        INTO v_es_directa
        FROM ventas_directas
        WHERE id_publicacion = p_id_publicacion;

        IF p_id_usuario = v_vendedor
           AND v_estado = 1
           AND v_es_directa = 1 THEN

            UPDATE publicaciones
            SET estado = 2
            WHERE id = p_id_publicacion;

            SET p_ok = TRUE;
        END IF;
    END IF;
END//


-- 4. Actualizar el nivel de un usuario.
-- Criterio elegido para el TP:
-- 1 a 5 ventas = Normal, 6 a 10 = Platinum, 11 o mas = Gold.
CREATE PROCEDURE sp_actualizar_nivel(
    IN p_id_usuario INT,
    OUT p_nuevo_nivel VARCHAR(30),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT;
    DECLARE v_ventas INT;

    SET p_ok = FALSE;
    SET p_nuevo_nivel = NULL;

    SELECT COUNT(*)
    INTO v_existe
    FROM usuarios
    WHERE id = p_id_usuario;

    IF v_existe > 0 THEN

        SELECT COUNT(*)
        INTO v_ventas
        FROM compras c
        JOIN publicaciones p ON p.id = c.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        IF v_ventas >= 11 THEN
            UPDATE usuarios
            SET id_nivel = 3
            WHERE id = p_id_usuario;

            SET p_nuevo_nivel = 'Gold';

        ELSEIF v_ventas >= 6 THEN
            UPDATE usuarios
            SET id_nivel = 2
            WHERE id = p_id_usuario;

            SET p_nuevo_nivel = 'Platinum';

        ELSEIF v_ventas >= 1 THEN
            UPDATE usuarios
            SET id_nivel = 1
            WHERE id = p_id_usuario;

            SET p_nuevo_nivel = 'Normal';
        ELSE
            UPDATE usuarios
            SET id_nivel = NULL
            WHERE id = p_id_usuario;
        END IF;

        SET p_ok = TRUE;
    END IF;
END//


-- 5. Calificar al vendedor o al comprador de una compra.
CREATE PROCEDURE sp_calificar_usuario(
    IN p_id_compra INT,
    IN p_id_calificador INT,
    IN p_id_calificado INT,
    IN p_puntuacion DECIMAL(5,2),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_comprador INT;
    DECLARE v_vendedor INT;
    DECLARE v_existe INT;
    DECLARE v_ya_califico INT;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM compras
    WHERE id = p_id_compra;

    IF v_existe > 0
       AND p_puntuacion >= 0
       AND p_puntuacion <= 100 THEN

        SELECT c.id_comprador, p.id_vendedor
        INTO v_comprador, v_vendedor
        FROM compras c
        JOIN publicaciones p ON p.id = c.id_publicacion
        WHERE c.id = p_id_compra;

        IF (p_id_calificador = v_comprador AND p_id_calificado = v_vendedor)
           OR (p_id_calificador = v_vendedor AND p_id_calificado = v_comprador) THEN

            SELECT COUNT(*)
            INTO v_ya_califico
            FROM calificaciones
            WHERE id_compra = p_id_compra
              AND id_calificador = p_id_calificador
              AND id_calificado = p_id_calificado;

            IF v_ya_califico = 0 THEN
                INSERT INTO calificaciones(
                    id_compra,
                    id_calificador,
                    id_calificado,
                    puntuacion
                )
                VALUES(
                    p_id_compra,
                    p_id_calificador,
                    p_id_calificado,
                    p_puntuacion
                );

                SET p_ok = TRUE;
            END IF;
        END IF;
    END IF;
END//


-- 6. Mostrar el ganador de una subasta.
CREATE PROCEDURE sp_ganador_subasta(
    IN p_id_subasta INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT;
    DECLARE v_hay_ofertas INT;
    DECLARE v_usuario VARCHAR(100);
    DECLARE v_email VARCHAR(150);
    DECLARE v_producto VARCHAR(200);
    DECLARE v_oferentes INT;
    DECLARE v_inicial DECIMAL(15,2);
    DECLARE v_ganador DECIMAL(15,2);

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM subastas
    WHERE id = p_id_subasta;

    IF v_existe > 0 THEN

        SELECT COUNT(*)
        INTO v_hay_ofertas
        FROM ofertas
        WHERE id_subasta = p_id_subasta;

        IF v_hay_ofertas > 0 THEN

            SELECT
                CONCAT(u.nombre, ' ', u.apellido),
                u.email,
                pr.nombre,
                p.precio_etiqueta,
                o.monto
            INTO
                v_usuario,
                v_email,
                v_producto,
                v_inicial,
                v_ganador
            FROM ofertas o
            JOIN subastas s ON s.id = o.id_subasta
            JOIN publicaciones p ON p.id = s.id_publicacion
            JOIN publicaciones_productos pp ON pp.id_publicacion = p.id
            JOIN productos pr ON pr.id = pp.id_producto
            JOIN usuarios u ON u.id = o.id_ofertante
            WHERE o.id_subasta = p_id_subasta
            ORDER BY o.monto DESC
            LIMIT 1;

            SELECT COUNT(DISTINCT id_ofertante)
            INTO v_oferentes
            FROM ofertas
            WHERE id_subasta = p_id_subasta;

            SELECT
                v_usuario AS usuario,
                v_email AS email,
                v_producto AS producto,
                v_oferentes AS cantidad_oferentes,
                v_inicial AS valor_inicial,
                v_ganador AS valor_ganador;

            SET p_ok = TRUE;
        END IF;
    END IF;
END//


-- 7. Crear una pregunta.
CREATE PROCEDURE sp_crear_pregunta(
    IN p_id_usuario INT,
    IN p_id_publicacion INT,
    IN p_texto VARCHAR(350),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_existe INT;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM publicaciones
    WHERE id = p_id_publicacion;

    IF v_existe > 0 THEN

        SELECT id_vendedor, estado
        INTO v_vendedor, v_estado
        FROM publicaciones
        WHERE id = p_id_publicacion;

        IF v_estado = 1
           AND p_texto IS NOT NULL
           AND p_texto <> ''
           AND p_id_usuario <> v_vendedor THEN

            INSERT INTO preguntas(texto, id_usuario_pregunta, id_publicacion)
            VALUES(p_texto, p_id_usuario, p_id_publicacion);

            SET p_ok = TRUE;
        END IF;
    END IF;
END//


-- 8. Estadisticas de un vendedor.
-- Se realizan consultas simples y luego se muestra un unico resultado.
CREATE PROCEDURE sp_estadisticas_vendedor(
    IN p_id_usuario INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT;
    DECLARE v_activas INT;
    DECLARE v_finalizadas INT;
    DECLARE v_ventas INT;
    DECLARE v_facturacion DECIMAL(15,2);
    DECLARE v_precio_promedio DECIMAL(15,2);
    DECLARE v_preguntas INT;
    DECLARE v_tiempo DECIMAL(10,2);

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM usuarios
    WHERE id = p_id_usuario;

    IF v_existe > 0 THEN

        SELECT COUNT(*)
        INTO v_activas
        FROM publicaciones
        WHERE id_vendedor = p_id_usuario
          AND estado = 1;

        SELECT COUNT(*)
        INTO v_finalizadas
        FROM publicaciones
        WHERE id_vendedor = p_id_usuario
          AND estado = 3;

        SELECT COUNT(*)
        INTO v_ventas
        FROM compras c
        JOIN publicaciones p ON p.id = c.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        SELECT SUM(p.precio_etiqueta * c.cant)
        INTO v_facturacion
        FROM compras c
        JOIN publicaciones p ON p.id = c.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        IF v_facturacion IS NULL THEN
            SET v_facturacion = 0;
        END IF;

        SELECT AVG(p.precio_etiqueta)
        INTO v_precio_promedio
        FROM publicaciones p
        WHERE p.id_vendedor = p_id_usuario;

        IF v_precio_promedio IS NULL THEN
            SET v_precio_promedio = 0;
        END IF;

        SELECT COUNT(*)
        INTO v_preguntas
        FROM preguntas q
        JOIN publicaciones p ON p.id = q.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        SELECT fn_tiempo_promedio_venta(p_id_usuario)
        INTO v_tiempo;

        SELECT
            p_id_usuario AS id_vendedor,
            v_activas AS publicaciones_activas,
            v_finalizadas AS publicaciones_finalizadas,
            v_ventas AS ventas_totales,
            v_facturacion AS facturacion_total,
            v_precio_promedio AS precio_promedio,
            v_preguntas AS preguntas_recibidas,
            v_tiempo AS tiempo_promedio_venta_dias;

        SET p_ok = TRUE;
    END IF;
END//


-- 9. Top 10 vendedores entre dos fechas.
CREATE PROCEDURE sp_top_vendedores(
    IN p_fecha_inicio DATE,
    IN p_fecha_fin DATE,
    OUT p_ok BOOLEAN
)
BEGIN
    SET p_ok = FALSE;

    IF p_fecha_inicio IS NOT NULL
       AND p_fecha_fin IS NOT NULL
       AND p_fecha_inicio <= p_fecha_fin THEN

        SELECT
            u.id,
            CONCAT(u.nombre, ' ', u.apellido) AS vendedor,
            COUNT(c.id) AS ventas
        FROM usuarios u
        JOIN publicaciones p ON p.id_vendedor = u.id
        JOIN compras c ON c.id_publicacion = p.id
        WHERE DATE(c.fecha) BETWEEN p_fecha_inicio AND p_fecha_fin
        GROUP BY u.id, u.nombre, u.apellido
        ORDER BY ventas DESC
        LIMIT 10;

        SET p_ok = TRUE;
    END IF;
END//


/* =========================================================
   VISTAS
   ========================================================= */

-- 1. Preguntas de publicaciones activas que todavia no tienen respuesta.
-- Se muestra el dueño de la publicacion en lugar del usuario que responde.

Delimiter ;

CREATE VIEW vw_preguntas_sin_responder AS
SELECT
    q.id AS id_pregunta,
    q.texto AS descripcion,
    p.nombre AS publicacion,
    pr.nombre AS producto,
    CONCAT(u.nombre, ' ', u.apellido) AS dueño_publicacion
FROM preguntas q
JOIN publicaciones p ON p.id = q.id_publicacion
JOIN publicaciones_productos pp ON pp.id_publicacion = p.id
JOIN productos pr ON pr.id = pp.id_producto
JOIN usuarios u ON u.id = p.id_vendedor
LEFT JOIN respuestas r ON r.id_pregunta = q.id
WHERE p.estado = 1
  AND r.id IS NULL;


-- 2. Top 10 categorias con mas publicaciones durante la semana actual.
CREATE VIEW vw_top_categorias_semana AS
SELECT
    c.id,
    c.nombre,
    COUNT(DISTINCT p.id) AS cantidad_publicaciones
FROM categorias c
JOIN productos pr ON pr.id_categoria = c.id
JOIN publicaciones_productos pp ON pp.id_producto = pr.id
JOIN publicaciones p ON p.id = pp.id_publicacion
WHERE p.fecha >= CURDATE() - INTERVAL WEEKDAY(CURDATE()) DAY
  AND p.fecha < CURDATE() - INTERVAL WEEKDAY(CURDATE()) DAY + INTERVAL 7 DAY
GROUP BY c.id, c.nombre
ORDER BY cantidad_publicaciones DESC
LIMIT 10;


-- 3. Publicaciones activas con mayor cantidad de preguntas realizadas hoy.
CREATE VIEW vw_publicaciones_tendencia AS
SELECT
    p.id,
    p.nombre AS publicacion,
    COUNT(q.id) AS cantidad_preguntas
FROM publicaciones p
LEFT JOIN preguntas q
    ON q.id_publicacion = p.id
   AND DATE(q.fecha) = CURDATE()
WHERE p.estado = 1
GROUP BY p.id, p.nombre
ORDER BY cantidad_preguntas DESC;


-- 4. Vendedor/es con mayor reputacion por categoria.
-- Esta consulta necesita una subconsulta para comparar la reputacion maxima de cada categoria.
CREATE VIEW vw_mejor_vendedor_categoria AS
SELECT DISTINCT
    c.nombre AS categoria,
    CONCAT(u.nombre, ' ', u.apellido) AS vendedor,
    u.reputacion
FROM categorias c
JOIN productos pr ON pr.id_categoria = c.id
JOIN publicaciones_productos pp ON pp.id_producto = pr.id
JOIN publicaciones p ON p.id = pp.id_publicacion
JOIN usuarios u ON u.id = p.id_vendedor
WHERE u.reputacion = (
    SELECT MAX(u2.reputacion)
    FROM productos pr2
    JOIN publicaciones_productos pp2 ON pp2.id_producto = pr2.id
    JOIN publicaciones p2 ON p2.id = pp2.id_publicacion
    JOIN usuarios u2 ON u2.id = p2.id_vendedor
    WHERE pr2.id_categoria = c.id
);


/* =========================================================
   TRIGGERS
   ========================================================= */

DELIMITER //

-- 1. Antes de eliminar una pregunta, eliminar sus respuestas.
CREATE TRIGGER trg_eliminar_respuestas
BEFORE DELETE ON preguntas
FOR EACH ROW
BEGIN
    DELETE FROM respuestas
    WHERE id_pregunta = OLD.id;
END//


-- 2. Despues de una venta, actualizar el nivel del vendedor.
-- Se usan los mismos criterios del procedimiento sp_actualizar_nivel.
CREATE TRIGGER trg_actualizar_nivel_venta
AFTER INSERT ON compras
FOR EACH ROW
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_ventas INT;

    SELECT id_vendedor
    INTO v_vendedor
    FROM publicaciones
    WHERE id = NEW.id_publicacion;

    SELECT COUNT(*)
    INTO v_ventas
    FROM compras c
    JOIN publicaciones p ON p.id = c.id_publicacion
    WHERE p.id_vendedor = v_vendedor;

    IF v_ventas >= 11 THEN
        UPDATE usuarios
        SET id_nivel = 3
        WHERE id = v_vendedor;
    ELSEIF v_ventas >= 6 THEN
        UPDATE usuarios
        SET id_nivel = 2
        WHERE id = v_vendedor;
    ELSEIF v_ventas >= 1 THEN
        UPDATE usuarios
        SET id_nivel = 1
        WHERE id = v_vendedor;
    END IF;
END//


-- 3. Actualizar la reputacion despues de una calificacion.
CREATE TRIGGER trg_actualizar_reputacion
AFTER INSERT ON calificaciones
FOR EACH ROW
BEGIN
    UPDATE usuarios
    SET reputacion = (
        SELECT AVG(c.puntuacion)
        FROM calificaciones c
        WHERE c.id_calificado = NEW.id_calificado
    )
    WHERE id = NEW.id_calificado;
END//


-- 4. Validar una puja.
CREATE TRIGGER trg_validar_puja
BEFORE INSERT ON ofertas
FOR EACH ROW
BEGIN
    DECLARE v_fecha_fin DATETIME;
    DECLARE v_estado INT;
    DECLARE v_vendedor INT;
    DECLARE v_mayor DECIMAL(15,2);

    SELECT
        s.fecha_fin,
        p.estado,
        p.id_vendedor
    INTO
        v_fecha_fin,
        v_estado,
        v_vendedor
    FROM subastas s
    JOIN publicaciones p ON p.id = s.id_publicacion
    WHERE s.id = NEW.id_subasta;

    SELECT MAX(monto)
    INTO v_mayor
    FROM ofertas
    WHERE id_subasta = NEW.id_subasta;

    IF v_mayor IS NULL THEN
        SET v_mayor = 0;
    END IF;

    IF v_fecha_fin <= NOW() THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La subasta ya vencio';

    ELSEIF v_estado <> 1 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La publicacion no esta activa';

    ELSEIF NEW.id_ofertante = v_vendedor THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El vendedor no puede pujar';

    ELSEIF NEW.monto <= v_mayor THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La oferta debe superar la oferta mayor';
    END IF;
END//


/* =========================================================
   EVENTOS
   ========================================================= */

-- 1. Eliminar una vez por semana publicaciones pausadas con mas de 90 dias.
CREATE EVENT ev_eliminar_publicaciones_pausadas
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN
    -- Al eliminar preguntas, el trigger trg_eliminar_respuestas
    -- elimina primero las respuestas.
    DELETE FROM preguntas
    WHERE id_publicacion IN (
        SELECT id
        FROM publicaciones
        WHERE estado = 2
          AND fecha < NOW() - INTERVAL 90 DAY
    );

    DELETE FROM publicaciones_productos
    WHERE id_publicacion IN (
        SELECT id
        FROM publicaciones
        WHERE estado = 2
          AND fecha < NOW() - INTERVAL 90 DAY
    );

    DELETE FROM ventas_directas
    WHERE id_publicacion IN (
        SELECT id
        FROM publicaciones
        WHERE estado = 2
          AND fecha < NOW() - INTERVAL 90 DAY
    );

    DELETE FROM subastas
    WHERE id_publicacion IN (
        SELECT id
        FROM publicaciones
        WHERE estado = 2
          AND fecha < NOW() - INTERVAL 90 DAY
    );

    DELETE FROM publicaciones
    WHERE estado = 2
      AND fecha < NOW() - INTERVAL 90 DAY;
END//


-- 2. Marcar como observadas las ventas directas activas sin medio de pago.
CREATE EVENT ev_observar_sin_pago
ON SCHEDULE EVERY 1 DAY
DO
BEGIN
    UPDATE publicaciones p
    JOIN ventas_directas vd ON vd.id_publicacion = p.id
    SET p.estado = 4
    WHERE p.estado = 1
      AND vd.id_metodo_pago IS NULL;
END//


-- 3. Todos los dias a las 10:00, notificar preguntas sin responder.
CREATE EVENT ev_notificar_preguntas
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '10:00:00')
DO
BEGIN
    INSERT INTO notificaciones(id_usuario, mensaje)
    SELECT
        p.id_vendedor,
        CONCAT(
            'La publicacion sobre ',
            p.nombre,
            ' tiene ',
            COUNT(q.id),
            ' sin responder'
        )
    FROM publicaciones p
    JOIN preguntas q ON q.id_publicacion = p.id
    LEFT JOIN respuestas r ON r.id_pregunta = q.id
    WHERE p.estado = 1
      AND r.id IS NULL
    GROUP BY p.id, p.id_vendedor, p.nombre;
END//


-- 4. Todos los dias a las 00:00 guardar algunas estadisticas simples.
CREATE EVENT ev_estadisticas_diarias
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '00:00:00')
DO
BEGIN
    INSERT INTO estadisticas(fecha, tipo, valor, descripcion)
    SELECT
        CURDATE(),
        'VENDEDORES',
        COUNT(DISTINCT id_vendedor),
        'Cantidad de vendedores con publicaciones activas'
    FROM publicaciones
    WHERE estado = 1;

    INSERT INTO estadisticas(fecha, tipo, valor, descripcion)
    SELECT
        CURDATE(),
        'COMPRADORES',
        COUNT(DISTINCT id_comprador),
        'Cantidad de compradores del dia'
    FROM compras
    WHERE DATE(fecha) = CURDATE();

    INSERT INTO estadisticas(fecha, tipo, valor, descripcion)
    SELECT
        CURDATE(),
        'PRODUCTOS',
        COUNT(DISTINCT pp.id_producto),
        'Cantidad de productos publicados durante el dia'
    FROM publicaciones_productos pp
    JOIN publicaciones p ON p.id = pp.id_publicacion
    WHERE DATE(p.fecha) = CURDATE();
END//

DELIMITER ;


/* =========================================================
   SCHEDULER DE EVENTOS
   ========================================================= */

-- El Event Scheduler debe estar habilitado en el servidor para que los
-- eventos se ejecuten. Se deja comentado porque suele requerir permisos
-- de administrador y no es parte de la logica del TP.
-- SET GLOBAL event_scheduler = ON;


/* =========================================================
   INDICES
   ========================================================= */

-- 1. Busqueda por nombre de producto.
CREATE INDEX idx_productos_nombre
ON productos(nombre);

-- Tambien es util buscar por el titulo de la publicacion.
CREATE INDEX idx_publicaciones_nombre
ON publicaciones(nombre);

-- 2. El email ya tiene UNIQUE en la tabla usuarios del archivo base.
-- MySQL crea automaticamente un indice unico para esa restriccion,
-- por lo tanto no se crea otro indice duplicado aca.

-- 3. Consultas frecuentes por estado y por fecha de las publicaciones.
CREATE INDEX idx_publicaciones_estado
ON publicaciones(estado);

CREATE INDEX idx_publicaciones_estado_fecha
ON publicaciones(estado, fecha);


/* =========================================================
   TRANSACCIONES
   ========================================================= */

-- 1. COMPRA DE UNA PUBLICACION
-- La publicacion debe bloquearse con FOR UPDATE para que dos usuarios
-- no puedan comprarla al mismo tiempo.
--
-- Ejemplo:
-- START TRANSACTION;
--
-- SELECT *
-- FROM publicaciones
-- WHERE id = 1
--   AND estado = 1
-- FOR UPDATE;
--
-- INSERT INTO compras(cant, id_publicacion, id_comprador)
-- VALUES(1, 1, 2);
--
-- UPDATE publicaciones
-- SET estado = 3
-- WHERE id = 1;
--
-- COMMIT;


-- 2. OFERTA EN UNA SUBASTA
-- Se bloquea la subasta antes de consultar la oferta mayor.
--
-- START TRANSACTION;
--
-- SELECT *
-- FROM subastas
-- WHERE id = 1
-- FOR UPDATE;
--
-- INSERT INTO ofertas(monto, id_subasta, id_ofertante)
-- VALUES(100000, 1, 3);
--
-- UPDATE subastas
-- SET oferta_mayor = 100000
-- WHERE id = 1;
--
-- COMMIT;


-- 3. Otra transaccion necesaria: calificar una compra.
-- Se puede comprobar la compra, insertar la calificacion y actualizar
-- la reputacion dentro de una sola transaccion.
--
-- START TRANSACTION;
--
-- SELECT *
-- FROM compras
-- WHERE id = 1
-- FOR UPDATE;
--
-- INSERT INTO calificaciones(
--     id_compra,
--     id_calificador,
--     id_calificado,
--     puntuacion
-- )
-- VALUES(1, 2, 3, 90);
--
-- UPDATE usuarios
-- SET reputacion = 90
-- WHERE id = 3;
--
-- COMMIT;

-- roles

-- auditor

CREATE ROLE IF NOT EXISTS auditor;

GRANT SELECT
ON base_de_datos.vw_preguntas_sin_responder
TO auditor;

GRANT SELECT
ON base_de_datos.vw_top_categorias_semana
TO auditor;

GRANT SELECT
ON base_de_datos.vw_publicaciones_tendencia
TO auditor;

GRANT SELECT
ON base_de_datos.vw_mejor_vendedor_categoria
TO auditor;


-- desarrollador

CREATE ROLE IF NOT EXISTS desarrollador;

GRANT SELECT
ON base_de_datos.*
TO desarrollador;

GRANT CREATE ROUTINE
ON base_de_datos.*
TO desarrollador;


-- admin

CREATE ROLE IF NOT EXISTS admin;

GRANT ALL PRIVILEGES
ON base_de_datos.*
TO admin;
