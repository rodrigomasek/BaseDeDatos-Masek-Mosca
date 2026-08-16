USE base_de_datos;

DELIMITER //


-- Funcion 1

CREATE FUNCTION fn_tiempo_promedio_venta(
    p_id_usuario INT
)
RETURNS DECIMAL(10,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(10,2);

    SELECT COALESCE(
        AVG(
            TIMESTAMPDIFF(
                SECOND,
                p.fecha,
                c.fecha
            ) / 86400
        ),
        0
    )
    INTO v_promedio
    FROM publicaciones p
    INNER JOIN compras c
        ON c.id_publicacion = p.id
    WHERE p.id_vendedor = p_id_usuario;

    RETURN v_promedio;
END//


-- Funcion 2

CREATE FUNCTION fn_comision(
    p_monto DECIMAL(15,2),
    p_nivel VARCHAR(30)
)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    CASE LOWER(p_nivel)

        WHEN 'normal' THEN
            RETURN p_monto * 0.08;

        WHEN 'platinum' THEN
            RETURN p_monto * 0.05;

        WHEN 'gold' THEN
            RETURN p_monto * 0.03;

        ELSE
            RETURN -1;

    END CASE;
END//


-- Funcion 3

CREATE FUNCTION fn_porcentaje_ventas(
    p_id_usuario INT
)
RETURNS DECIMAL(5,2)
READS SQL DATA
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

    SELECT COUNT(DISTINCT c.id)
    INTO v_concretadas
    FROM compras c
    INNER JOIN publicaciones p
        ON p.id = c.id_publicacion
    WHERE p.id_vendedor = p_id_usuario;

    RETURN (v_concretadas * 100.0) / v_total;
END//


-- Funcion 4

CREATE FUNCTION fn_mayor_oferta(
    p_id_subasta INT
)
RETURNS DECIMAL(15,2)
READS SQL DATA
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

    SELECT COALESCE(MAX(monto), 0)
    INTO v_mayor
    FROM ofertas
    WHERE id_subasta = p_id_subasta;

    RETURN v_mayor;
END//


-- Funcion 5

CREATE FUNCTION fn_precio_promedio_categoria(
    p_id_categoria INT
)
RETURNS DECIMAL(15,2)
READS SQL DATA
BEGIN
    DECLARE v_promedio DECIMAL(15,2);

    SELECT COALESCE(AVG(p.precio_etiqueta), 0)
    INTO v_promedio
    FROM publicaciones p
    INNER JOIN publicaciones_productos pp
        ON pp.id_publicacion = p.id
    INNER JOIN productos pr
        ON pr.id = pp.id_producto
    WHERE pr.id_categoria = p_id_categoria;

    RETURN v_promedio;
END//


-- Funcion 6

CREATE FUNCTION fn_ultima_compra(
    p_id_usuario INT
)
RETURNS DATETIME
READS SQL DATA
BEGIN
    DECLARE v_fecha DATETIME;

    SELECT MAX(fecha)
    INTO v_fecha
    FROM compras
    WHERE id_comprador = p_id_usuario;

    RETURN v_fecha;
END//


-- Procedure 1

CREATE PROCEDURE sp_buscar_publicaciones(
    IN p_texto VARCHAR(200),
    OUT p_ok BOOLEAN
)
BEGIN

    SET p_ok = FALSE;

    IF p_texto IS NULL OR TRIM(p_texto) = '' THEN

        SELECT
            NULL AS id,
            NULL AS titulo,
            NULL AS precio
        WHERE FALSE;

    ELSE

        SELECT DISTINCT
            p.id,
            p.nombre AS titulo,
            p.precio_etiqueta AS precio
        FROM publicaciones p
        INNER JOIN publicaciones_productos pp
            ON pp.id_publicacion = p.id
        INNER JOIN productos pr
            ON pr.id = pp.id_producto
        WHERE pr.nombre LIKE CONCAT('%', p_texto, '%')
           OR p.nombre LIKE CONCAT('%', p_texto, '%')
           OR p.detalles LIKE CONCAT('%', p_texto, '%');

        SET p_ok = TRUE;

    END IF;

END//


-- Procedure 2

CREATE PROCEDURE sp_pujar(
    IN p_id_subasta INT,
    IN p_id_ofertante INT,
    IN p_monto DECIMAL(15,2),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_fecha_fin DATETIME;
    DECLARE v_mayor DECIMAL(15,2);

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM subastas s
    INNER JOIN publicaciones p
        ON p.id = s.id_publicacion
    WHERE s.id = p_id_subasta;

    IF v_existe = 0 THEN

        SET p_ok = FALSE;

    ELSE

        SELECT
            p.id_vendedor,
            p.estado,
            s.fecha_fin
        INTO
            v_vendedor,
            v_estado,
            v_fecha_fin
        FROM subastas s
        INNER JOIN publicaciones p
            ON p.id = s.id_publicacion
        WHERE s.id = p_id_subasta;

        SELECT COALESCE(MAX(monto), 0)
        INTO v_mayor
        FROM ofertas
        WHERE id_subasta = p_id_subasta;

        IF v_estado = 1
           AND v_fecha_fin > NOW()
           AND p_id_ofertante <> v_vendedor
           AND p_monto > v_mayor THEN

            INSERT INTO ofertas(
                monto,
                id_subasta,
                id_ofertante
            )
            VALUES(
                p_monto,
                p_id_subasta,
                p_id_ofertante
            );

            UPDATE subastas
            SET oferta_mayor = p_monto
            WHERE id = p_id_subasta;

            SET p_ok = TRUE;

        END IF;

    END IF;

END//


-- Procedure 3

CREATE PROCEDURE sp_pausar_publicacion(
    IN p_id_publicacion INT,
    IN p_id_usuario INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_es_directa INT DEFAULT 0;
    DECLARE v_existe INT DEFAULT 0;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM publicaciones
    WHERE id = p_id_publicacion;

    IF v_existe > 0 THEN

        SELECT
            p.id_vendedor,
            p.estado
        INTO
            v_vendedor,
            v_estado
        FROM publicaciones p
        WHERE p.id = p_id_publicacion;

        SELECT COUNT(*)
        INTO v_es_directa
        FROM ventas_directas vd
        WHERE vd.id_publicacion = p_id_publicacion;

        IF v_vendedor = p_id_usuario
           AND v_estado = 1
           AND v_es_directa = 1 THEN

            UPDATE publicaciones
            SET estado = 2
            WHERE id = p_id_publicacion;

            SET p_ok = TRUE;

        END IF;

    END IF;

END//


-- Procedure 4

CREATE PROCEDURE sp_actualizar_nivel(
    IN p_id_usuario INT,
    OUT p_nuevo_nivel VARCHAR(30),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_ventas INT;
    DECLARE v_facturacion DECIMAL(15,2);
    DECLARE v_existe INT;

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
        INNER JOIN publicaciones p
            ON p.id = c.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        SELECT COALESCE(
            SUM(p.precio_etiqueta * c.cant),
            0
        )
        INTO v_facturacion
        FROM compras c
        INNER JOIN publicaciones p
            ON p.id = c.id_publicacion
        WHERE p.id_vendedor = p_id_usuario;

        IF v_ventas >= 11 OR v_facturacion >= 1000000 THEN

            UPDATE usuarios
            SET id_nivel = 3
            WHERE id = p_id_usuario;

            SET p_nuevo_nivel = 'Gold';

        ELSEIF v_ventas >= 6 OR v_facturacion >= 100000 THEN

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

            SET p_nuevo_nivel = NULL;

        END IF;

        SET p_ok = TRUE;

    END IF;

END//


-- Procedure 5

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
    DECLARE v_existe INT DEFAULT 0;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM compras c
    INNER JOIN publicaciones p
        ON p.id = c.id_publicacion
    WHERE c.id = p_id_compra;

    IF v_existe > 0
       AND p_puntuacion >= 0
       AND p_puntuacion <= 100 THEN

        SELECT
            c.id_comprador,
            p.id_vendedor
        INTO
            v_comprador,
            v_vendedor
        FROM compras c
        INNER JOIN publicaciones p
            ON p.id = c.id_publicacion
        WHERE c.id = p_id_compra;

        IF (
            p_id_calificador = v_comprador
            AND p_id_calificado = v_vendedor
        )
        OR (
            p_id_calificador = v_vendedor
            AND p_id_calificado = v_comprador
        ) THEN

            SELECT COUNT(*)
            INTO v_existe
            FROM calificaciones
            WHERE id_compra = p_id_compra
              AND id_calificador = p_id_calificador
              AND id_calificado = p_id_calificado;

            IF v_existe = 0 THEN

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


-- Procedure 6

CREATE PROCEDURE sp_ganador_subasta(
    IN p_id_subasta INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_existe INT DEFAULT 0;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM subastas
    WHERE id = p_id_subasta;

    IF v_existe > 0 THEN

        SELECT
            u.nombre AS usuario,
            u.email,
            pr.nombre AS producto,

            (
                SELECT COUNT(DISTINCT o2.id_ofertante)
                FROM ofertas o2
                WHERE o2.id_subasta = s.id
            ) AS cantidad_oferentes,

            p.precio_etiqueta AS valor_inicial,
            o.monto AS valor_ganador

        FROM subastas s
        INNER JOIN publicaciones p
            ON p.id = s.id_publicacion
        INNER JOIN publicaciones_productos pp
            ON pp.id_publicacion = p.id
        INNER JOIN productos pr
            ON pr.id = pp.id_producto
        INNER JOIN ofertas o
            ON o.id_subasta = s.id
        INNER JOIN usuarios u
            ON u.id = o.id_ofertante

        WHERE s.id = p_id_subasta
          AND o.monto = (
              SELECT MAX(o2.monto)
              FROM ofertas o2
              WHERE o2.id_subasta = s.id
          )

        LIMIT 1;

        SET p_ok = TRUE;

    END IF;

END//


-- Procedure 7

CREATE PROCEDURE sp_crear_pregunta(
    IN p_id_usuario INT,
    IN p_id_publicacion INT,
    IN p_texto VARCHAR(350),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_existe INT DEFAULT 0;

    SET p_ok = FALSE;

    SELECT COUNT(*)
    INTO v_existe
    FROM publicaciones
    WHERE id = p_id_publicacion;

    IF v_existe > 0 THEN

        SELECT
            id_vendedor,
            estado
        INTO
            v_vendedor,
            v_estado
        FROM publicaciones
        WHERE id = p_id_publicacion;

        IF v_estado = 1
           AND p_texto IS NOT NULL
           AND TRIM(p_texto) <> ''
           AND p_id_usuario <> v_vendedor THEN

            INSERT INTO preguntas(
                texto,
                id_usuario_pregunta,
                id_publicacion
            )
            VALUES(
                p_texto,
                p_id_usuario,
                p_id_publicacion
            );

            SET p_ok = TRUE;

        END IF;

    END IF;

END//


-- Procedure 8

CREATE PROCEDURE sp_estadisticas_vendedor(
    IN p_id_usuario INT,
    OUT p_ok BOOLEAN
)
BEGIN

    SET p_ok = EXISTS(
        SELECT 1
        FROM usuarios
        WHERE id = p_id_usuario
    );

    IF p_ok THEN

        SELECT
            u.id,
            CONCAT(u.nombre, ' ', u.apellido) AS vendedor,

            (
                SELECT COUNT(*)
                FROM publicaciones p1
                WHERE p1.id_vendedor = u.id
                  AND p1.estado = 1
            ) AS publicaciones_activas,

            (
                SELECT COUNT(*)
                FROM publicaciones p2
                WHERE p2.id_vendedor = u.id
                  AND p2.estado = 3
            ) AS publicaciones_finalizadas,

            (
                SELECT COUNT(*)
                FROM compras c
                INNER JOIN publicaciones p3
                    ON p3.id = c.id_publicacion
                WHERE p3.id_vendedor = u.id
            ) AS ventas_totales,

            (
                SELECT COALESCE(
                    SUM(p4.precio_etiqueta * c2.cant),
                    0
                )
                FROM compras c2
                INNER JOIN publicaciones p4
                    ON p4.id = c2.id_publicacion
                WHERE p4.id_vendedor = u.id
            ) AS facturacion_total,

            (
                SELECT COALESCE(
                    AVG(p5.precio_etiqueta),
                    0
                )
                FROM publicaciones p5
                WHERE p5.id_vendedor = u.id
            ) AS precio_promedio,

            (
                SELECT COUNT(*)
                FROM preguntas q
                INNER JOIN publicaciones p6
                    ON p6.id = q.id_publicacion
                WHERE p6.id_vendedor = u.id
            ) AS preguntas_recibidas,

            fn_tiempo_promedio_venta(u.id)
                AS tiempo_promedio_venta_dias

        FROM usuarios u
        WHERE u.id = p_id_usuario;

    END IF;

END//


-- Procedure 9

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
        INNER JOIN publicaciones p
            ON p.id_vendedor = u.id
        INNER JOIN compras c
            ON c.id_publicacion = p.id
        WHERE DATE(c.fecha)
              BETWEEN p_fecha_inicio AND p_fecha_fin
        GROUP BY
            u.id,
            u.nombre,
            u.apellido
        ORDER BY ventas DESC
        LIMIT 10;

        SET p_ok = TRUE;

    END IF;

END//


-- vista 1

CREATE VIEW vw_preguntas_sin_responder AS
SELECT
    q.id AS id_pregunta,
    q.texto AS descripcion,
    p.nombre AS publicacion,
    pr.nombre AS producto,
    NULL AS usuario_respondio
FROM preguntas q
INNER JOIN publicaciones p
    ON p.id = q.id_publicacion
INNER JOIN publicaciones_productos pp
    ON pp.id_publicacion = p.id
INNER JOIN productos pr
    ON pr.id = pp.id_producto
LEFT JOIN respuestas r
    ON r.id_pregunta = q.id
WHERE p.estado = 1
  AND r.id IS NULL;


-- vista 2

CREATE VIEW vw_top_categorias_semana AS
SELECT
    c.id,
    c.nombre,
    COUNT(DISTINCT p.id) AS cantidad_publicaciones
FROM categorias c
INNER JOIN productos pr
    ON pr.id_categoria = c.id
INNER JOIN publicaciones_productos pp
    ON pp.id_producto = pr.id
INNER JOIN publicaciones p
    ON p.id = pp.id_publicacion
WHERE p.fecha >= DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY)
  AND p.fecha < DATE_ADD(
      DATE_SUB(CURDATE(), INTERVAL WEEKDAY(CURDATE()) DAY),
      INTERVAL 7 DAY
  )
GROUP BY
    c.id,
    c.nombre
ORDER BY cantidad_publicaciones DESC
LIMIT 10;


-- vista 3

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
GROUP BY
    p.id,
    p.nombre
ORDER BY cantidad_preguntas DESC;


-- vista 4

CREATE VIEW vw_mejor_vendedor_categoria AS
SELECT DISTINCT
    c.nombre AS categoria,
    CONCAT(u.nombre, ' ', u.apellido) AS vendedor,
    u.reputacion
FROM categorias c
INNER JOIN productos pr
    ON pr.id_categoria = c.id
INNER JOIN publicaciones_productos pp
    ON pp.id_producto = pr.id
INNER JOIN publicaciones p
    ON p.id = pp.id_publicacion
INNER JOIN usuarios u
    ON u.id = p.id_vendedor
WHERE u.reputacion = (
    SELECT MAX(u2.reputacion)
    FROM productos pr2
    INNER JOIN publicaciones_productos pp2
        ON pp2.id_producto = pr2.id
    INNER JOIN publicaciones p2
        ON p2.id = pp2.id_publicacion
    INNER JOIN usuarios u2
        ON u2.id = p2.id_vendedor
    WHERE pr2.id_categoria = c.id
);


-- trigger 1

CREATE TRIGGER trg_eliminar_respuestas
BEFORE DELETE ON preguntas
FOR EACH ROW
BEGIN

    DELETE FROM respuestas
    WHERE id_pregunta = OLD.id;

END//


-- trigger 2

CREATE TRIGGER trg_actualizar_nivel_venta
AFTER INSERT ON compras
FOR EACH ROW
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_ventas INT;
    DECLARE v_facturacion DECIMAL(15,2);

    SELECT id_vendedor
    INTO v_vendedor
    FROM publicaciones
    WHERE id = NEW.id_publicacion;

    SELECT COUNT(*)
    INTO v_ventas
    FROM compras c
    INNER JOIN publicaciones p
        ON p.id = c.id_publicacion
    WHERE p.id_vendedor = v_vendedor;

    SELECT COALESCE(
        SUM(p.precio_etiqueta * c.cant),
        0
    )
    INTO v_facturacion
    FROM compras c
    INNER JOIN publicaciones p
        ON p.id = c.id_publicacion
    WHERE p.id_vendedor = v_vendedor;

    IF v_ventas >= 11
       OR v_facturacion >= 1000000 THEN

        UPDATE usuarios
        SET id_nivel = 3
        WHERE id = v_vendedor;

    ELSEIF v_ventas >= 6
       OR v_facturacion >= 100000 THEN

        UPDATE usuarios
        SET id_nivel = 2
        WHERE id = v_vendedor;

    ELSEIF v_ventas >= 1 THEN

        UPDATE usuarios
        SET id_nivel = 1
        WHERE id = v_vendedor;

    END IF;

END//


-- trigger 3

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


-- trigger 4

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
    INNER JOIN publicaciones p
        ON p.id = s.id_publicacion
    WHERE s.id = NEW.id_subasta;

    SELECT COALESCE(MAX(monto),0)
    INTO v_mayor
    FROM ofertas
    WHERE id_subasta = NEW.id_subasta;

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


-- trigger 5

CREATE TRIGGER trg_validar_respuesta
BEFORE INSERT ON respuestas
FOR EACH ROW
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;

    SELECT
        p.id_vendedor,
        p.estado
    INTO
        v_vendedor,
        v_estado
    FROM preguntas q
    INNER JOIN publicaciones p
        ON p.id = q.id_publicacion
    WHERE q.id = NEW.id_pregunta;

    IF v_estado <> 1 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La publicacion no esta activa';

    ELSEIF NEW.id_usuario_responde <> v_vendedor THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Solo el vendedor puede responder';

    END IF;

END//


-- trigger 6

CREATE TRIGGER trg_validar_pregunta
BEFORE INSERT ON preguntas
FOR EACH ROW
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;

    SELECT
        id_vendedor,
        estado
    INTO
        v_vendedor,
        v_estado
    FROM publicaciones
    WHERE id = NEW.id_publicacion;

    IF v_estado <> 1 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La publicacion no esta activa';

    ELSEIF NEW.id_usuario_pregunta = v_vendedor THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El vendedor no puede realizar preguntas';

    END IF;

END//


-- trigger 7

CREATE TRIGGER trg_eliminar_producto
BEFORE DELETE ON productos
FOR EACH ROW
BEGIN
    DECLARE v_publicaciones INT;

    SELECT COUNT(*)
    INTO v_publicaciones
    FROM publicaciones_productos pp
    INNER JOIN publicaciones p
        ON p.id = pp.id_publicacion
    WHERE pp.id_producto = OLD.id
      AND p.estado IN (1,2,4);

    IF v_publicaciones > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El producto tiene publicaciones activas, pausadas u observadas';

    END IF;

END//


-- trigger 8

CREATE TRIGGER trg_eliminar_categoria
BEFORE DELETE ON categorias
FOR EACH ROW
BEGIN
    DECLARE v_publicaciones INT;

    SELECT COUNT(*)
    INTO v_publicaciones
    FROM productos pr
    INNER JOIN publicaciones_productos pp
        ON pp.id_producto = pr.id
    INNER JOIN publicaciones p
        ON p.id = pp.id_publicacion
    WHERE pr.id_categoria = OLD.id
      AND p.estado = 1;

    IF v_publicaciones > 0 THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La categoria tiene publicaciones activas';

    END IF;

END//


-- trigger 9

CREATE TRIGGER trg_finalizar_venta
AFTER INSERT ON compras
FOR EACH ROW
BEGIN

    UPDATE publicaciones
    SET estado = 3
    WHERE id = NEW.id_publicacion
      AND estado = 1;

END//


-- evento 1

CREATE EVENT ev_eliminar_publicaciones_pausadas
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN

    DELETE r
    FROM respuestas r
    INNER JOIN preguntas q
        ON q.id = r.id_pregunta
    INNER JOIN publicaciones p
        ON p.id = q.id_publicacion
    WHERE p.estado = 2
      AND p.fecha < NOW() - INTERVAL 90 DAY;

    DELETE q
    FROM preguntas q
    INNER JOIN publicaciones p
        ON p.id = q.id_publicacion
    WHERE p.estado = 2
      AND p.fecha < NOW() - INTERVAL 90 DAY;

    DELETE pp
    FROM publicaciones_productos pp
    INNER JOIN publicaciones p
        ON p.id = pp.id_publicacion
    WHERE p.estado = 2
      AND p.fecha < NOW() - INTERVAL 90 DAY;

    DELETE vd
    FROM ventas_directas vd
    INNER JOIN publicaciones p
        ON p.id = vd.id_publicacion
    WHERE p.estado = 2
      AND p.fecha < NOW() - INTERVAL 90 DAY;

    DELETE FROM publicaciones
    WHERE estado = 2
      AND fecha < NOW() - INTERVAL 90 DAY;

END//


-- evento 2

CREATE EVENT ev_observar_sin_pago
ON SCHEDULE EVERY 1 DAY
DO
BEGIN

    UPDATE publicaciones p
    INNER JOIN ventas_directas vd
        ON vd.id_publicacion = p.id
    SET p.estado = 4
    WHERE p.estado = 1
      AND vd.id_metodo_pago IS NULL;

END//


-- evento 3

CREATE EVENT ev_notificar_preguntas
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '10:00:00')
DO
BEGIN

    INSERT INTO notificaciones(
        id_usuario,
        mensaje
    )
    SELECT
        p.id_vendedor,
        CONCAT(
            'La publicacion sobre ',
            p.nombre,
            ' tiene ',
            COUNT(q.id),
            ' preguntas sin responder'
        )
    FROM publicaciones p
    INNER JOIN preguntas q
        ON q.id_publicacion = p.id
    LEFT JOIN respuestas r
        ON r.id_pregunta = q.id
    WHERE p.estado = 1
      AND r.id IS NULL
    GROUP BY
        p.id,
        p.id_vendedor,
        p.nombre;

END//


-- evento 4

CREATE EVENT ev_estadisticas_diarias
ON SCHEDULE EVERY 1 DAY
STARTS TIMESTAMP(CURRENT_DATE, '00:00:00')
DO
BEGIN

    INSERT INTO estadisticas(
        fecha,
        tipo,
        valor,
        descripcion
    )
    SELECT
        CURDATE(),
        'VENDEDORES',
        COUNT(DISTINCT id_vendedor),
        'Cantidad de vendedores con publicaciones activas'
    FROM publicaciones
    WHERE estado = 1;


    INSERT INTO estadisticas(
        fecha,
        tipo,
        valor,
        descripcion
    )
    SELECT
        CURDATE(),
        'COMPRADORES',
        COUNT(DISTINCT id_comprador),
        'Cantidad de compradores del dia'
    FROM compras
    WHERE DATE(fecha) = CURDATE();


    INSERT INTO estadisticas(
        fecha,
        tipo,
        valor,
        descripcion
    )
    SELECT
        CURDATE(),
        'PRODUCTOS',
        COUNT(DISTINCT pp.id_producto),
        'Cantidad de productos publicados durante el dia'
    FROM publicaciones_productos pp
    INNER JOIN publicaciones p
        ON p.id = pp.id_publicacion
    WHERE DATE(p.fecha) = CURDATE();

END//


DELIMITER ;


-- even scheduler

SET GLOBAL event_scheduler = ON;


-- indices

CREATE INDEX idx_productos_nombre
ON productos(nombre);


CREATE INDEX idx_publicaciones_nombre
ON publicaciones(nombre);


CREATE INDEX idx_publicaciones_estado
ON publicaciones(estado);


CREATE INDEX idx_publicaciones_estado_fecha
ON publicaciones(estado, fecha);


CREATE INDEX idx_preguntas_publicacion
ON preguntas(id_publicacion);


CREATE INDEX idx_compras_publicacion
ON compras(id_publicacion);


CREATE INDEX idx_compras_comprador
ON compras(id_comprador);


CREATE INDEX idx_ofertas_subasta
ON ofertas(id_subasta);


-- transaccion de compra

START TRANSACTION;

SELECT *
FROM publicaciones
WHERE id = 1
  AND estado = 1
FOR UPDATE;

INSERT INTO compras(
    cant,
    id_publicacion,
    id_comprador
)
VALUES(
    1,
    1,
    2
);

UPDATE publicaciones
SET estado = 3
WHERE id = 1
  AND estado = 1;

COMMIT;


-- transaccion de oferta

START TRANSACTION;

SELECT *
FROM subastas
WHERE id = 1
FOR UPDATE;

INSERT INTO ofertas(
    monto,
    id_subasta,
    id_ofertante
)
VALUES(
    100000,
    1,
    3
);

UPDATE subastas
SET oferta_mayor = 100000
WHERE id = 1;

COMMIT;


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