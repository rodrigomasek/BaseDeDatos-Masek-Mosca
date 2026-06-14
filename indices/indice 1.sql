1)
/*
DROP PROCEDURE IF EXISTS cargar_pedidos_masivos;

DELIMITER $$

CREATE PROCEDURE cargar_pedidos_masivos()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE ultimo_id INT;

    DECLARE v_cliente VARCHAR(20);
    DECLARE v_estado INT;
    DECLARE v_fecha DATETIME;

    SELECT COALESCE(MAX(idPedido),0)
    INTO ultimo_id
    FROM pedido;

    WHILE i <= 20000 DO

        -- Cliente aleatorio entre los 3 existentes
        SET v_cliente =
        CASE FLOOR(1 + RAND()*3)
            WHEN 1 THEN 'CLI001'
            WHEN 2 THEN 'CLI002'
            ELSE 'CLI003'
        END;

        -- Estado aleatorio (1, 2 o 3)
        SET v_estado = FLOOR(1 + RAND()*3);

        -- Fecha aleatoria entre 2022 y hoy
        SET v_fecha = TIMESTAMP(
            DATE_ADD(
                '2022-01-01',
                INTERVAL FLOOR(
                    RAND() * DATEDIFF(CURDATE(),'2022-01-01')
                ) DAY
            )
        );

        INSERT INTO pedido(
            idPedido,
            fecha,
            Estado_idEstado,
            Cliente_codCliente
        )
        VALUES(
            ultimo_id + i,
            v_fecha,
            v_estado,
            v_cliente
        );

        SET i = i + 1;

    END WHILE;

END$$

DELIMITER ;

*/

2)
/*
EXPLAIN ANALYZE
SELECT *
FROM pedido
WHERE idPedido = 19999;
*/

3)
/*
EXPLAIN ANALYZE
SELECT *
FROM pedido
WHERE fecha = '2024-05-10';
*/

4)
/*
CREATE INDEX idx_pedido_fecha
ON pedido(fecha);
*/

5)
/*
EXPLAIN ANALYZE
SELECT *
FROM pedido
WHERE fecha = '2024-05-10';
*/

6)
/*
CREATE INDEX idx_pedido_cliente_estado
ON pedido(Cliente_codCliente, Estado_idEstado);
*/

7)
/*
SELECT *
FROM pedido
WHERE Cliente_codCliente = 'CLI001'
  AND Estado_idEstado = 1;
*/