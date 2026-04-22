-- 1)
/*
SELECT c.customer_num, c.company, o.order_num
FROM customer c
INNER JOIN orders o 
 ON  c.customer_num = o.customer_num
ORDER BY o.order_num DESC;
*/
-- 2)
/*
SELECT i.order_num AS numero_de_orden, 
	i.item_num AS numero_de_item, 
	pt.description AS descripcion_producto, 
	i.manu_code AS codigo_fabricante, 
	i.quantity AS cantidad, 
(p.unit_price * i.quantity) AS precio_total
FROM items i
INNER JOIN products p ON i.stock_num = p.stock_num
INNER JOIN product_types pt ON i.stock_num = p.stock_num
WHERE order_num = 1004;
*/
-- 3)
/*
SELECT distinct i.order_num AS numero_de_orden, 
	i.item_num AS numero_de_item, 
	pt.description AS descripcion_producto, 
	i.manu_code AS codigo_fabricante, 
	i.quantity AS cantidad, 
	(p.unit_price * i.quantity) AS precio_total,
	m.manu_name AS nombre_del_fabricante
FROM items i
	INNER JOIN products p ON i.stock_num = p.stock_num
	INNER JOIN product_types pt ON i.stock_num = p.stock_num
	INNER JOIN manufact m ON i.manu_code = m.manu_code
WHERE order_num = 1004;
*/
-- 4) 
/*
SELECT distinct o.order_num AS orden_compra,
	c.customer_num AS numero_cliente, 
	c.fname AS nombre, 
	c.lname AS apellido, 
	c.company AS compania
FROM customer c
	JOIN orders o ON o.customer_num = c.customer_num
WHERE o.order_num IS NOT NULL;
*/

-- 5)
/* PENDIENTE
SELECT o.order_num AS orden_compra,
	c.customer_num AS numero_cliente, 
	c.fname AS nombre, 
	c.lname AS apellido, 
	c.company AS compania
FROM customer c
INNER JOIN orders o ON o.customer_num = c.customer_num
WHERE o.order_num IS NOT NULL
COUNT(c.customer_num);
*/
-- 6) 
/*
SELECT m.manu_name AS nombre_fabricante, 
	p.stock_num AS numero_stock, 
	pt.description AS descripcion, 
	u.unit AS unidad, 
	p.unit_price AS precio_unitario, 
	p.unit_price * 1.2 AS precio_junio
FROM products p
JOIN manufact m ON (m.manu_code = p.manu_code)
JOIN product_types pt ON (pt.stock_num = p.stock_num)
JOIN units u ON (p.unit_code = u.unit_code);
*/

-- 7)

-- 8)
/*
SELECT DISTINCT m.manu_name, m.lead_time
FROM manufact m
	JOIN items i ON (m.manu_code = i.manu_code)
	JOIN orders o ON (i.order_num = o.order_num)
WHERE o.customer_num = 104;
*/
-- 9)

-- 10)

-- 11)
/*
SELECT o.ship_date AS fecha_embarque,
	c.fname + ', ' + c.lname AS nombre,
	COUNT(o.order_num) AS cantidad_ordenes
FROM orders o
	JOIN customer c ON (c.customer_num = o.customer_num)
	JOIN state s ON (s.state = c.state)
WHERE s.sname = 'California' 
		AND zipcode BETWEEN 94000 AND 94100
GROUP BY ship_date, lname, fname
ORDER BY ship_date, lname, fname;
*/
-- 12)

SELECT m.manu_name AS nombre_fabricante,
	m.manu_code AS codigo_fabricante,
	pt.description AS producto,
	SUM(i.quantity) AS cantidad_vendido,
	SUM(i.quantity * i.unit_price) AS total_vendido
FROM manufact m
	JOIN items i ON (i.manu_code = m.manu_code)
	JOIN product_types pt ON (pt.stock_num = i.stock_num)
	JOIN orders o ON (o.order_num = i.order_num)
WHERE m.manu_code IN ('ANZ', 'HRO', 'HSK', 'SMT') 
	AND YEAR(o.ship_date) = 2015 AND MONTH(o.ship_date) IN (5,6)
GROUP BY m.manu_code, m.manu_name, i.stock_num, pt.description
ORDER BY SUM(i.quantity * i.unit_price) DESC;