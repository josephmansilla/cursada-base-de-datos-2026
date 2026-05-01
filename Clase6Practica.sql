-- 1) Mostrar el Código del fabricante, nombre del fabricante, tiempo de entrega y monto
-- Total de productos vendidos, ordenado por nombre de fabricante. En caso que el
-- fabricante no tenga ventas, mostrar el total en NULO.

/*
-- version sin subquery
SELECT m.manu_code, manu_name, lead_time, coalesce(SUM(i.quantity * i.unit_price),0) monto_total
	FROM manufact m LEFT JOIN items i  ON m.manu_code = i.manu_code
	GROUP BY m.manu_code, manu_name, lead_time

-- version con subquery, no tan linda...
SELECT m.manu_code AS codigo_fabricante, 
	m.manu_name AS nombre_fabricante, 
	m.lead_time AS tiempo_de_entrega,
	(SELECT coalesce(SUM(unit_price * quantity), 0) FROM items WHERE order_num IS NOT NULL AND manu_code = m.manu_code) AS total_productos_vendidos 
FROM manufact m
ORDER BY m.manu_code, m.manu_name, m.lead_time

*/

-- 2) Mostrar en una lista de a pares, el código y descripción del producto, y los pares de
-- fabricantes que fabriquen el mismo producto. En el caso que haya un único fabricante
-- deberá mostrar el Código de fabricante 2 en nulo. Ordenar el resultado por código de
-- producto.

/*
SELECT pt.stock_num AS numero_producto,
	pt.description AS descripcion, 
	p.manu_code AS codigo_fabricante_1,
	pp.manu_code AS codigo_fabricante_2
FROM product_types pt
	JOIN products p ON pt.stock_num = p.stock_num
	LEFT JOIN products pp ON p.stock_num = pp.stock_num
		AND p.manu_code < pp.manu_code
ORDER BY pt.stock_num, 3
*/

-- 3) Listar todos los clientes que hayan tenido más de una orden.
-- formato numero nombre apellido

-- a) En primer lugar, escribir una consulta usando una subconsulta.
/*
SELECT customer_num, fname, lname 
  FROM CUSTOMER C
 WHERE (SELECT COUNT(*) FROM ORDERS O where o.customer_num = c.customer_num) > 1;
*/
-- b) reescribir la consulta usando GROUP BY y HAVING
/*
SELECT c.customer_num AS numero_cliente, c.fname AS nombre, c.lname as apellido
FROM customer c
JOIN orders o ON c.customer_num = o.customer_num
GROUP BY c.customer_num, c.fname, c.lname
HAVING COUNT(o.order_num) >= 1;
*/
-- 4) Seleccionar todas las Órdenes de compra cuyo Monto total (Suma de p x q de sus items)
-- sea menor al precio total promedio (avg p x q) de todas las líneas de las ordenes.
-- formato nro_orden - total

/*
SELECT o.order_num AS numero_orden,
	SUM(i.unit_price * i.quantity) AS total
FROM orders o
	LEFT JOIN items i ON (i.order_num = o.order_num)
GROUP BY o.order_num
HAVING SUM(i.unit_price * i.quantity) < (SELECT	AVG(unit_price * quantity) FROM items);
*/

-- 5) Obtener por cada fabricante, el listado de todos los productos de stock con precio
-- unitario (unit_price) mayor que el precio unitario promedio de dicho fabricante.
-- Los campos de salida serán: manu_code, manu_name, stock_num, description, unit_price.
/*
SELECT m.manu_code, m.manu_name, 
		p.stock_num, pt.description, p.unit_price
FROM manufact m
	JOIN products p ON (p.manu_code = m.manu_code)
	JOIN product_types pt ON (pt.stock_num = p.stock_num)
WHERE p.unit_price > (SELECT AVG(unit_price) 
						FROM products p2 JOIN manufact m2 ON (m2.manu_code = p2.manu_code)
						WHERE p2.manu_code = m2.manu_code)
*/

-- 6) Usando el operador NOT EXISTS listar la información de órdenes de compra que NO
-- incluyan ningún producto que contenga en su descripción el string ‘ baseball gloves’.
-- Ordenar el resultado por compañía del cliente ascendente y número de orden descendente.
-- formato numero_cliente, comapñia, numero_orden, fecha_orden

/*
SELECT o.customer_num AS numero_cliente, 
		c.company AS compañía, 
		o.order_num AS numero_orden, 
		o.order_date AS fecha_orden
FROM orders o JOIN customer c ON (c.customer_num = o.customer_num)
WHERE NOT EXISTS (SELECT * FROM items i JOIN product_types pt ON (i.stock_num = pt.stock_num)
				WHERE i.order_num = o.order_num AND pt.description LIKE '%baseball gloves%')
ORDER BY c.customer_num ASC, o.order_num DESC;
*/

-- 7) Obtener el número, nombre y apellido de los clientes que NO hayan comprado productos
--	del fabricante ‘HSK’

/* 
SELECT customer_num AS numero_cliente, fname+' '+lname AS nombre_cliente 
FROM customer c
WHERE customer_num NOT IN (SELECT o.customer_num FROM items i JOIN orders o ON (o.order_num = i.order_num)
					WHERE manu_code LIKE 'HSK');
				*/

-- 8) Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS los
--	productos del fabricante ‘HSK’.

-- fabrica 10 - vende 10 -> se vendió todo (comparaciones)
-- hay algun producto que no le compre a HSK -> no se vendio todo (op. de conj)

SELECT customer_num AS numero_cliente, fname+' '+lname AS nombre_cliente 
FROM customer c 
WHERE NOT EXISTS (SELECT * FROM products W)

SELECT manu_code, COUNT(*) FROM products
GROUP BY manu_code
ORDER BY manu_code ASC;

SELECT DISTINCT manu_code, COUNT(*), o.customer_num FROM items i JOIN orders o ON (i.order_num = o.order_num)
GROUP BY manu_code, o.customer_num
ORDER BY manu_code ASC;




-- 9) Reescribir la siguiente consulta utilizando el operador UNION:
		--SELECT * FROM products
		--WHERE manu_code = 'HRO' OR stock_num = 1

/*
SELECT * FROM products
WHERE manu_code = 'HRO'
UNION 
SELECT * FROM products
WHERE stock_num = 1;
*/

-- 10) Desarrollar una consulta que devuelva las ciudades y compañías de todos los Clientes
-- ordenadas alfabéticamente por Ciudad pero en la consulta deberán aparecer primero las
-- compañías situadas en Redwood City y luego las demás.
-- formato: sortkey - ciudad - compañia
/*
SELECT 1 AS clave_ordenamiento,
	city AS ciudad,
	company AS compañía
FROM customer 
WHERE city LIKE '%Redwood City%'
UNION 
SELECT 2 AS clave_ordenamiento,
	city AS ciudad,
	company AS compañía
FROM customer
ORDER BY 1, 2;
*/

-- 11)  Desarrollar una consulta que devuelva los dos tipos de productos más vendidos y los dos
-- menos vendidos en función de las unidades totales vendidas.
-- FORMATO: tipo - cantidad
/*
SELECT * FROM (
	SELECT TOP 2 pt.stock_num AS tipo_producto, SUM(i.quantity) AS cantidad
		FROM (items i
		JOIN product_types pt ON (pt.stock_num = i.stock_num))
		GROUP BY pt.stock_num
		ORDER BY SUM(i.quantity) DESC
) AS MasVendidos

UNION ALL 

SELECT * FROM (
	SELECT TOP 2 pt.stock_num AS tipo_producto, SUM(i.quantity) AS cantidad
	FROM items i
		JOIN product_types pt ON (pt.stock_num = i.stock_num)
	GROUP BY pt.stock_num
	ORDER BY SUM(i.quantity) ASC
) AS MenosVendidos;
*/