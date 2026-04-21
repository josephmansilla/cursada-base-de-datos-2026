-- Práctica - Clase 3
/*
-- 1)
SELECT customer_num cliente_id, 
	fname + ' ' + lname AS nombre_cliente, 
	address1 AS direccion_primaria,
	address2 AS direccion_secundaria
	FROM customer;

-- 2) 

SELECT customer_num cliente_id, 
	fname + ' ' + lname AS nombre_cliente, 
	address1 AS direccion_primaria,
	address2 AS direccion_secundaria --,
	-- state AS estado
FROM customer
WHERE state = 'CA';

-- 3) 
SELECT city as ciudad
FROM customer
WHERE state = 'CA'
GROUP BY city
-- 4) 
ORDER BY city ASC;


-- 5)
SELECT address1 FROM customer WHERE customer_num = 103;

-- 6)
SELECT * FROM products
WHERE manu_code = 'ANZ'
ORDER BY unit_code ASC;

-- 7)
SELECT DISTINCT(manu_code) AS codigo_fabricantes FROM products
ORDER BY manu_code ASC;

-- 8)
SELECT order_num AS numero_orden, 
	order_date AS fecha_orden,
	customer_num AS numero_cliente,
	ship_date AS fecha_embarque
FROM orders
WHERE paid_date IS NULL AND 
	MONTH(ship_date) > 0 AND MONTH(ship_date) <= 6 AND YEAR(ship_date) = 2015;

-- 9)
SELECT customer_num AS numero_cliente, company AS nombre_empresa
FROM customer
WHERE company LIKE '%town%';

-- 10) 

SELECT MAX(ship_charge) AS precio_maximo ,
	MIN(ship_charge) AS precio_minimo,
	AVG(ship_charge) AS promedio_pagado
FROM orders
GROUP BY order_num;

-- 11)
SELECT order_num AS numero_orden, order_date AS fecha_orden, ship_date AS fecha_embarque
FROM orders
WHERE MONTH(ship_date) = MONTH(order_date);

-- 12)
SELECT ship_date AS fecha_embarque, SUM(ship_weight) AS cantidad_total_libras
FROM orders
WHERE ship_date IS NOT NULL
GROUP BY ship_date
ORDER BY SUM(ship_charge) DESC;

-- 13)
SELECT DAY(ship_date) AS fecha_embarque, SUM(ship_weight) AS cantidad_total_libras
FROM orders
WHERE ship_weight > 30 AND ship_date IS NOT NULL
GROUP BY DAY(ship_date)
ORDER BY SUM(ship_weight) DESC;

-- 14)
SELECT *
FROM customer
WHERE state = 'ca'
ORDER BY company;


-- 15) 
SELECT manu_code
FROM products
GROUP BY manu_code
HAVING SUM(unit_price) > 1500
ORDER BY COUNT(*) ASC;

-- 16) 
SELECT manu_code AS codigo_fabricante, item_num AS numero_producto, quantity AS cantidad, (quantity * unit_price) AS total_vendido
FROM items 
WHERE manu_code LIKE '_R%'
ORDER BY manu_code, item_num;
*/

-- 17) 
/*
SELECT customer_num AS cliente, 
	COUNT(order_num) AS cantidad_ordenes, 
	MIN(order_date) AS primera_fecha_compra, 
	MAX(order_date) AS ultima_fecha_compra
INTO #OrdenesTemp 
FROM orders
GROUP BY customer_num;

SELECT * FROM #OrdenesTemp;

SELECT primera_fecha_compra 
FROM #OrdenesTemp 
WHERE primera_fecha_compra > '2015-05-23 00:00:00.000'
ORDER BY primera_fecha_compra DESC;

DROP TABLE #OrdenesTemp;
*/

-- 18) 
/*
SELECT COUNT(*) 
FROM #OrdenesTemp
ORDER BY cantidad_ordenes DESC;
*/
-- 19) 

-- Desaparece.

-- 20) 
/*
SELECT city AS ciudad, state AS Estado
FROM customer
WHERE company LIKE '%ts%' AND zipcode >= 93000 AND zipcode <= 94100 AND city != 'Mountain View'
ORDER BY city, state;
*/

-- 21) 
/*
SELECT state, COUNT(customer_num) 
FROM customer
WHERE company LIKE '[A-L]%'
GROUP BY state;


-- 22) 

SELECT manu_code AS manufacturadora_id, manu_name AS manufacturadora_id, AVG(lead_time) AS promedio_lead_time
FROM manufact
WHERE manu_name LIKE '%e%' AND lead_time >= 5 AND lead_time <= 20
GROUP BY manu_code, manu_name
ORDER BY AVG(lead_time) DESC;
*/
-- 23) 

SELECT COUNT(unit) + 1 AS cantidad_unidades
FROM units WHERE unit_descr IS NOT NULL
GROUP BY unit HAVING COUNT(unit_code) + 1 > 5;