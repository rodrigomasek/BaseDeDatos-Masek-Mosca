USE base_de_datos;

-- =========================================================
-- STORED FUNCTIONS
-- =========================================================

DELIMITER //


-- =========================================================
-- FUNCTION 1
-- Tiempo promedio que tarda en vender
-- Devuelve días
-- =========================================================

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


-- =========================================================
-- FUNCTION 2
-- Comisión del sistema
-- =========================================================

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


-- =========================================================
-- FUNCTION 3
-- Porcentaje de ventas concretadas
-- =========================================================

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


-- =========================================================
-- FUNCTION 4
-- Mayor oferta de una subasta
-- =========================================================

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


-- =========================================================
-- FUNCTION 5
-- Precio promedio de productos de una categoria
-- =========================================================

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


-- =========================================================
-- FUNCTION 6
-- Ultima fecha de compra
-- =========================================================

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


-- =========================================================
-- STORED PROCEDURES
-- =========================================================


-- =========================================================
-- PROCEDURE 1
-- Buscar publicaciones por nombre de producto
-- =========================================================

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


-- =========================================================
-- PROCEDURE 2
-- Pujar en una subasta
-- =========================================================

CREATE PROCEDURE sp_pujar(
    IN p_id_subasta INT,
    IN p_id_ofertante INT,
    IN p_monto DECIMAL(15,2),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_publicacion INT;
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_fecha_fin DATETIME;
    DECLARE v_mayor DECIMAL(15,2);

    SET p_ok = FALSE;

    SELECT
        s.id_publicacion,
        p.id_vendedor,
        p.estado,
        s.fecha_fin
    INTO
        v_publicacion,
        v_vendedor,
        v_estado,
        v_fecha_fin
    FROM subastas s
    INNER JOIN publicaciones p
        ON p.id = s.id_publicacion
    WHERE s.id = p_id_subasta;

    IF v_publicacion IS NULL THEN

        SET p_ok = FALSE;

    ELSEIF v_estado <> 1 THEN

        SET p_ok = FALSE;

    ELSEIF v_fecha_fin <= NOW() THEN

        SET p_ok = FALSE;

    ELSEIF p_id_ofertante = v_vendedor THEN

        SET p_ok = FALSE;

    ELSE

        SELECT COALESCE(MAX(monto), 0)
        INTO v_mayor
        FROM ofertas
        WHERE id_subasta = p_id_subasta;

        IF p_monto > v_mayor THEN

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


-- =========================================================
-- PROCEDURE 3
-- Pausar publicacion
-- =========================================================

CREATE PROCEDURE sp_pausar_publicacion(
    IN p_id_publicacion INT,
    IN p_id_usuario INT,
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;
    DECLARE v_es_directa INT;

    SET p_ok = FALSE;

    SELECT
        p.id_vendedor,
        p.estado,
        EXISTS(
            SELECT 1
            FROM ventas_directas vd
            WHERE vd.id_publicacion = p.id
        )
    INTO
        v_vendedor,
        v_estado,
        v_es_directa
    FROM publicaciones p
    WHERE p.id = p_id_publicacion;

    IF v_vendedor = p_id_usuario
       AND v_estado = 1
       AND v_es_directa = 1 THEN

        UPDATE publicaciones
        SET estado = 2
        WHERE id = p_id_publicacion;

        SET p_ok = TRUE;

    END IF;

END//


-- =========================================================
-- PROCEDURE 4
-- Actualizar nivel del usuario
-- =========================================================

CREATE PROCEDURE sp_actualizar_nivel(
    IN p_id_usuario INT,
    OUT p_nuevo_nivel VARCHAR(30),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_ventas INT;
    DECLARE v_facturacion DECIMAL(15,2);

    SET p_ok = FALSE;
    SET p_nuevo_nivel = NULL;

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

END//


-- =========================================================
-- PROCEDURE 5
-- Calificar usuario
-- =========================================================

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

    SET p_ok = FALSE;

    IF p_puntuacion < 0
       OR p_puntuacion > 100 THEN

        SET p_ok = FALSE;

    ELSE

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

        IF v_comprador IS NOT NULL THEN

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

    END IF;

END//


-- =========================================================
-- PROCEDURE 6
-- Ganador de subasta
-- =========================================================

CREATE PROCEDURE sp_ganador_subasta(
    IN p_id_subasta INT,
    OUT p_ok BOOLEAN
)
BEGIN

    SET p_ok = FALSE;

    SELECT
        u.nombre AS usuario,
        u.email,
        pr.nombre AS producto,
        COUNT(DISTINCT o.id_ofertante) AS cantidad_oferentes,
        p.precio_etiqueta AS valor_inicial,
        MAX(o.monto) AS valor_ganador
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
    GROUP BY
        u.id,
        u.nombre,
        u.email,
        pr.nombre,
        p.precio_etiqueta;

    SET p_ok = TRUE;

END//


-- =========================================================
-- PROCEDURE 7
-- Crear pregunta
-- =========================================================

CREATE PROCEDURE sp_crear_pregunta(
    IN p_id_usuario INT,
    IN p_id_publicacion INT,
    IN p_texto VARCHAR(350),
    OUT p_ok BOOLEAN
)
BEGIN
    DECLARE v_vendedor INT;
    DECLARE v_estado INT;

    SET p_ok = FALSE;

    SELECT
        id_vendedor,
        estado
    INTO
        v_vendedor,
        v_estado
    FROM publicaciones
    WHERE id = p_id_publicacion;

    IF v_vendedor IS NOT NULL
       AND v_estado = 1
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

END//


-- =========================================================
-- PROCEDURE 8
-- Estadisticas de vendedor
-- =========================================================

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


-- =========================================================
-- PROCEDURE 9
-- Top 10 vendedores
-- =========================================================

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


-- =========================================================
-- VIEWS
-- =========================================================


//


-- =========================================================
-- VIEW 1
-- Preguntas de publicaciones activas sin respuesta
-- =========================================================

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


// =========================================================
// VIEW 2
// Top 10 categorias de esta semana
// =========================================================

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


// =========================================================
// VIEW 3
// Publicaciones en tendencia de hoy
// Mayor cantidad de preguntas
// =========================================================

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


// =========================================================
// VIEW 4
// Mejor vendedor por categoria
// =========================================================

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


// =========================================================
// TRIGGERS
// =========================================================


// =========================================================
// TRIGGER 1
// Antes de eliminar pregunta,
// elimina respuestas asociadas
// =========================================================

CREATE TRIGGER trg_eliminar_respuestas
BEFORE DELETE ON preguntas
FOR EACH ROW
BEGIN

    DELETE FROM respuestas
    WHERE id_pregunta = OLD.id;

END//


-- =========================================================
-- TRIGGER 2
-- Despues de una venta actualiza nivel del vendedor
-- =========================================================

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


-- =========================================================
-- TRIGGER 3
-- Actualizar reputacion
-- =========================================================

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


-- =========================================================
-- TRIGGER 4
-- Validar puja
-- =========================================================

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


-- =========================================================
// EVENTOS
// =========================================================


// =========================================================
// EVENTO 1
// Eliminar publicaciones pausadas con mas de 90 dias
// =========================================================

CREATE EVENT ev_eliminar_publicaciones_pausadas
ON SCHEDULE EVERY 1 WEEK
DO
BEGIN

    DELETE FROM publicaciones
    WHERE estado = 2
      AND fecha < NOW() - INTERVAL 90 DAY;

END//


-- =========================================================
// EVENTO 2
// Marcar como observadas publicaciones directas
// sin medio de pago
// =========================================================

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


-- =========================================================
// EVENTO 3
// Notificar preguntas sin responder
// Todos los dias a las 10:00
// =========================================================

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


-- =========================================================
// EVENTO 4
// Estadisticas diarias
// Todos los dias a las 00:00
// =========================================================

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


-- =========================================================
-- EVENT SCHEDULER
-- =========================================================

SET GLOBAL event_scheduler = ON;


-- =========================================================
-- TRANSACCIONES
-- =========================================================


-- ---------------------------------------------------------
-- TRANSACCION DE COMPRA
-- ---------------------------------------------------------

START TRANSACTION;

-- Verificar que la publicacion este activa
SELECT *
FROM publicaciones
WHERE id = 1
  AND estado = 1
FOR UPDATE;

-- Registrar compra
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

-- Finalizar publicacion
UPDATE publicaciones
SET estado = 3
WHERE id = 1
  AND estado = 1;

COMMIT;


-- ---------------------------------------------------------
-- TRANSACCION DE OFERTA
-- ---------------------------------------------------------

START TRANSACTION;

-- Bloquear subasta
SELECT *
FROM subastas
WHERE id = 1
FOR UPDATE;

-- Insertar oferta
INSERT INTO ofertas(
    monto,
    id_subasta,
    id_ofertante
)
VALUES(
    50000,
    1,
    3
);

-- Actualizar oferta mayor
UPDATE subastas
SET oferta_mayor = 50000
WHERE id = 1;

COMMIT;


-- =========================================================
-- ROLES
-- =========================================================


-- ---------------------------------------------------------
-- AUDITOR
-- ---------------------------------------------------------

CREATE ROLE auditor;

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


-- ---------------------------------------------------------
-- DESARROLLADOR
-- ---------------------------------------------------------

CREATE ROLE desarrollador;

GRANT SELECT
ON base_de_datos.*
TO desarrollador;

GRANT CREATE ROUTINE
ON base_de_datos.*
TO desarrollador;


-- ---------------------------------------------------------
-- ADMIN
-- ---------------------------------------------------------

CREATE ROLE admin;

GRANT ALL PRIVILEGES
ON base_de_datos.*
TO admin;


-- =========================================================
-- CONSULTAS PARA VERIFICAR LOS OBJETOS
-- =========================================================

SHOW TABLES;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';

SHOW TRIGGERS;

SELECT
    ROUTINE_TYPE,
    ROUTINE_NAME
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_SCHEMA = 'base_de_datos';

SELECT
    EVENT_NAME,
    STATUS
FROM INFORMATION_SCHEMA.EVENTS
WHERE EVENT_SCHEMA = 'base_de_datos';

SHOW GRANTS FOR auditor;

SHOW GRANTS FOR desarrollador;

SHOW GRANTS FOR admin;
