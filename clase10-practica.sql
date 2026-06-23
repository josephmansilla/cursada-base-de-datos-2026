-- PUNTO 1
DROP VIEW V_manufacturadores;
GO

CREATE VIEW V_manufacturadores 
AS SELECT mf.manu_code AS codigo_manufact, 
	manu_name AS nombre_manufact, 
	COUNT(pr.stock_num) AS cantidad_productos,
	(
	SELECT MAX(order_date) FROM orders ord 
		JOIN items it ON ord.order_num = it.order_num 
						AND it.manu_code = mf.manu_code
	)
		AS ult_fecha_orden 
FROM manufact mf LEFT JOIN products pr ON pr.manu_code = mf.manu_code
GROUP BY mf.manu_code, mf.manu_name
HAVING COUNT(pr.stock_num) = 0 OR COUNT(pr.stock_num) > 2
;
GO
-- B) 
SELECT codigo_manufact, 
	nombre_manufact,
	cantidad_productos,
	COALESCE(CAST(ult_fecha_orden AS CHAR), 'No posee orden') ult_fecha_orden
FROM V_manufacturadores;
GO


-- PUNTO 2

SELECT m.manu_code, 
		m.manu_name,
		COUNT(DISTINCT i.order_num) AS cant_ordenes,
		SUM(i.quantity*i.unit_price) monto_total
FROM manufact m
JOIN items i ON i.manu_code = m.manu_code 
JOIN product_types pt ON pt.stock_num = i.stock_num
WHERE 
	(m.manu_code LIKE '[NA]__')  AND
	(pt.description LIKE '%tennis%' OR pt.description LIKE '%ball%')
GROUP BY m.manu_code, m.manu_name
HAVING 4 > 
	(
	SELECT SUM(i1.quantity*i1.unit_price)/COUNT(DISTINCT m.manu_code)
	FROM items i1
	JOIN manufact m on m.manu_code = i1.manu_code 
	)
ORDER BY monto_total DESC;
GO

-- PUNTO 3
DROP VIEW V_cliente;
GO

CREATE VIEW V_cliente AS
SELECT cus.customer_num AS codigo_cliente, 
		lname AS apellido, 
		company AS compania, 
		COALESCE(CAST(COUNT(ords.order_num) AS INT),0) AS cantidad_ordenes, 
		COALESCE(CAST(MAX(order_date) AS CHAR), 'No posee una última compra') AS ultima_fecha_compra, 
		COALESCE(CAST(SUM(unit_price * quantity) AS int), 0) AS monto_total_cliente, 
		(SELECT SUM(i1.unit_price*i1.quantity) FROM items i1) AS total_comprado
FROM customer cus 
LEFT JOIN orders ords ON ords.customer_num = cus.customer_num
LEFT JOIN items itms ON itms.order_num = ords.order_num
GROUP BY cus.customer_num, lname, company
HAVING COUNT(DISTINCT ords.order_num) = 0 OR 
	((COUNT(ords.order_num) >= 3) AND
	cus.customer_num IN (SELECT DISTINCT o2.customer_num FROM orders o2
						JOIN items i2 ON o2.order_num = i2.order_num
						WHERE i2.stock_num IN (SELECT stock_num FROM products
						GROUP BY stock_num HAVING count(*) > 2)));
--ORDER BY cantidad_ordenes DESC, 1; NO SE PUEDE ORDENAR SOBRE VISTAS
GO
SELECT * FROM V_cliente ORDER BY cantidad_ordenes DESC;

-- PUNTO 4

SELECT 
	primero.state AS estado,
	primero.monto_total_estado,
	segundo.description AS descripcion,
	segundo.total_estado_producto
FROM (
	SELECT TOP 5
		st1.state, 
		COALESCE(SUM(it1.unit_price * it1.quantity), 0) monto_total_estado
	FROM customer c1 
		JOIN orders ord1 ON ord1.customer_num = c1.customer_num
		JOIN items it1 ON it1.order_num = ord1.order_num
		JOIN state st1 ON st1.state = c1.state
	GROUP BY st1.state
	ORDER BY monto_total_estado DESC
	) primero
JOIN (SELECT c2.state, it2.stock_num, pt.description, 
				SUM(unit_price * quantity) total_estado_producto
	FROM product_types pt
				JOIN items it2 ON it2.stock_num = pt.stock_num
				JOIN orders ord2 ON ord2.order_num = it2.order_num
				JOIN customer c2 ON c2.customer_num = ord2.customer_num
	GROUP BY c2.state, pt.description, it2.stock_num
	HAVING it2.stock_num IN (SELECT TOP 1 it3.stock_num FROM items it3
										JOIN orders o2 ON it3.order_num = o2.order_num
										JOIN customer c3 ON c3.customer_num = o2.customer_num
							WHERE c2.state = c3.state
							GROUP BY it3.stock_num
							ORDER BY SUM(it3.quantity * it3.unit_price) DESC)
) segundo 
ON primero.state = segundo.state
ORDER BY monto_total_estado DESC;

-- PUNTO 5

SELECT cus.customer_num AS numero_cliente,
		cus.fname AS nombre,
		cus.lname AS apellido,
		COALESCE(CAST(ord.paid_date AS CHAR), '-') AS fecha_pago,
		SUM(it.quantity * it.unit_price) AS suma_total
FROM customer cus 
		JOIN orders ord ON ord.customer_num = cus.customer_num
		JOIN items it ON it.order_num = ord.order_num
WHERE ord.order_num = (SELECT MAX(order_num)
							FROM orders ord1
							WHERE ord1.customer_num = cus.customer_num)
GROUP BY cus.customer_num, cus.fname, cus.lname, paid_date, ord.order_num
HAVING 
	SUM(it.quantity * it.unit_price) 
	>=
	(SELECT SUM(i2.unit_price * i2.quantity) / COUNT(DISTINCT ord2.order_num) 
		FROM customer cus2
				JOIN orders ord2 ON cus2.customer_num = ord2.customer_num
				JOIN items i2 ON i2.order_num = ord2.order_num
		WHERE cus2.customer_num = cus.customer_num AND ord.order_num > ord2.order_num)
UNION
SELECT cus3.customer_num, cus3.fname, lname, '-', 0
FROM customer cus3
			LEFT JOIN orders ord3 ON ord3.customer_num = cus3.customer_num
			LEFT JOIN items i3 ON i3.order_num = ord3.order_num
WHERE ord3.order_num IS NULL
ORDER BY 5 DESC


-- ALTERNATIVA SOLUCION PUNTO 5

SELECT cus.customer_num AS numero_cliente,
		cus.fname AS nombre,
		cus.lname AS apellido,
		COALESCE(CAST(ord.paid_date AS CHAR), '-' ) AS fecha_pago,
		COALESCE(SUM(it.unit_price*it.quantity), 0) total
FROM customer cus 
		LEFT JOIN orders ord ON cus.customer_num = ord.customer_num
		LEFT JOIN items it ON it.order_num = ord.order_num
WHERE ord.order_num IN (SELECT MAX(order_num)
							FROM orders ord1
							WHERE ord1.customer_num = cus.customer_num)
GROUP BY cus.customer_num, cus.fname, cus.lname, ord.order_num, ord.paid_date
HAVING SUM(it.unit_price*it.quantity) is NULL 
			OR SUM(it.unit_price*it.quantity) 
				>= (SELECT SUM(it2.unit_price*it2.quantity)/COUNT(DISTINCT ord2.order_num)
							FROM orders ord2 
									JOIN items it2 ON it2.order_num = ord2.order_num
							WHERE cus.customer_num = ord2.customer_num AND ord.order_num > ord2.order_num)
ORDER BY 5 DESC


-- PUNTO 6

-- PRIMERA ITERACION DONDE SE PUEDE VER LOS TOTALES DE CADA MANUFACT
SELECT p1.stock_num,
		pt1.description,
		p1.manu_code,
		SUM(i1.quantity) AS cantidad_total_manu,
		(SELECT SUM(i2.quantity) FROM items i2 WHERE i2.stock_num = p1.stock_num) AS cantidad_total_producto
FROM products p1
		JOIN product_types pt1 
				ON pt1.stock_num = p1.stock_num
		JOIN items i1 ON i1.stock_num = p1.stock_num AND i1.manu_code = p1.manu_code
GROUP BY p1.stock_num, pt1.description, p1.manu_code
HAVING 1 < ((SELECT COUNT(DISTINCT p2.manu_code) FROM products p2
			WHERE p2.stock_num = p1.stock_num))
ORDER BY cantidad_total_producto DESC;

-- RESPUESTA FINAL

SELECT p1.stock_num,
		pt1.description,
		p1.manu_code,
		SUM(i1.quantity) AS cantidad_total_manu,
		(SELECT SUM(i2.quantity) FROM items i2 WHERE i2.stock_num = p1.stock_num) AS cantidad_total_producto
FROM products p1
		JOIN product_types pt1 
				ON pt1.stock_num = p1.stock_num
		JOIN items i1 ON i1.stock_num = p1.stock_num AND i1.manu_code = p1.manu_code
GROUP BY p1.stock_num, pt1.description, p1.manu_code, i1.manu_code
HAVING 1 < ((SELECT COUNT(DISTINCT p2.manu_code) FROM products p2
			WHERE p2.stock_num = p1.stock_num))
	AND
		SUM(i1.quantity) > (SELECT SUM(i3.quantity) FROM items i3 WHERE p1.manu_code != i3.manu_code AND i3.stock_num = p1.stock_num)
ORDER BY cantidad_total_manu DESC, cantidad_total_producto DESC;