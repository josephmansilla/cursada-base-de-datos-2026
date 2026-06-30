-- Mas queries complejos 2

-- PUNTO 9
--Listar el Número, nombre, apellido, estado, cantidad de Órdenes y monto total comprado durante el
--año 2015 de todo los clientes que no sean del estado de Florida.
--Mostrar sólo aquellos clientes cuyo monto total comprado sea mayor al promedio del monto total
--comprado de los Clientes que no sean del estado Florida.
--Ordenar la información por el monto total comprado en forma descendente.


-- FILAS ANTES DEL HAVING
SELECT cus.customer_num, 
		cus.fname AS nombre, 
		cus.lname AS apellido,
		st.sname AS estado,
		COUNT(DISTINCT o1.order_num) AS cantidad_ordenes,
		SUM(itm.unit_price * itm.quantity) AS monto_total
FROM orders o1
	JOIN customer cus ON cus.customer_num = o1.customer_num
	JOIN state st ON cus.state = st.state
	JOIN items itm ON itm.order_num = o1.order_num
WHERE sname != 'Florida' AND '2015-01-01' <= o1.order_date AND o1.order_date < '2015-12-31'
GROUP BY cus.customer_num,cus.fname, cus.lname, st.sname
ORDER BY SUM(itm.unit_price * itm.quantity) DESC, sname DESC;

-- PROMEDIO
SELECT SUM(itm2.unit_price * itm2.quantity) / COUNT (DISTINCT o2.customer_num) AS monto_total
FROM items itm2
	JOIN orders o2 ON o2.order_num = itm2.order_num
	JOIN customer cus2 ON o2.customer_num = cus2.customer_num
	JOIN state st2 ON st2.state = cus2.state
WHERE sname != 'Florida' AND '2015-01-01' <= o2.order_date AND o2.order_date < '2015-12-31'

-- RESPUESTA FINAL 
SELECT cus.customer_num AS numero_cliente, 
		cus.fname AS nombre, 
		cus.lname AS apellido,
		st.sname AS estado,
		COUNT(DISTINCT o1.order_num) AS cantidad_ordenes,
		SUM(itm.unit_price * itm.quantity) AS monto_total
FROM orders o1
	JOIN customer cus ON cus.customer_num = o1.customer_num
	JOIN state st ON cus.state = st.state
	JOIN items itm ON itm.order_num = o1.order_num
WHERE sname != 'Florida' 
	AND '2015-01-01' <= o1.order_date 
	AND o1.order_date < '2015-12-31'
GROUP BY cus.customer_num,cus.fname, cus.lname, st.sname
HAVING SUM(itm.unit_price * itm.quantity) >
	(SELECT SUM(unit_price * quantity) / COUNT (DISTINCT o2.customer_num)
	 FROM items itm2
		JOIN orders o2 ON o2.order_num = itm2.order_num
		JOIN customer cus2 ON o2.customer_num = cus2.customer_num
		JOIN state st2 ON st2.state = cus2.state
	 WHERE sname != 'Florida' 
		AND '2015-01-01' <= o2.order_date 
		AND o2.order_date < '2015-12-31')
ORDER BY SUM(itm.unit_price * itm.quantity) DESC;


-- PUNTO 10

--10. Seleccionar todos los clientes cuyo monto total comprado sea mayor al de su refererente durante el
--año 2015. Mostrar número, nombre, apellido y los montos totales comprados de ambos durante ese
--año. Tener en cuenta que un cliente puede no tener referente y que el referente pudo no haber
--comprado nada durante el año 2015, mostrarlo igual.

SELECT cus.customer_num AS numero_cliente,
	cus.fname AS nombre,
	cus.lname AS apellido,
	SUM(itm.unit_price * itm.quantity) AS monto_total, -- 3
	ref.customer_num AS numero_cliente_ref,
	ref.fname AS nombre_referido,
	ref.lname AS apellido_referido,
	cr.total AS monto_total_referente
FROM customer cus
		LEFT JOIN customer ref ON ref.customer_num = cus.customer_num_referedBy
		JOIN orders ord ON cus.customer_num = ord.customer_num
		JOIN items itm ON itm.order_num = ord.order_num
		JOIN (SELECT ord2.customer_num AS cliente, SUM(quantity * unit_price) as total
				FROM items itm2 JOIN orders ord2 ON itm2.order_num = ord2.customer_num
				WHERE '2015-01-01' <= ord2.order_date AND ord2.order_date < '2015-12-31' 
						AND ord2.customer_num = ord2.customer_num
			  ) cr ON cr.cliente = ref.customer_num
WHERE '2015-01-01' <= ord.order_date AND ord.order_date < '2015-12-31'
GROUP BY ord.order_num, cus.customer_num, cus.fname, cus.lname, cus.customer_num_referedBy
HAVING SUM(itm.unit_price * itm.quantity) > COALESCE(cr.total,0)
ORDER BY 3


-- RECURSIVIDAD

SELECT cus.customer_num AS numero_cliente,
	cus.fname AS nombre,
	cus.lname AS apellido,
	cc.monto_total AS monto_total,
	ref.customer_num AS numero_cliente_ref,
	ref.fname AS nombre_referido,
	ref.lname AS apellido_referido,
	cr.monto_total AS monto_total_referido
FROM customer cus
		JOIN (SELECT ord.customer_num, SUM(it.quantity * it.unit_price) monto_total
			  FROM orders ord JOIN items it ON it.order_num = ord.order_num
			  WHERE '2015-01-01' <= ord.order_date AND ord.order_date < '2015-12-31' 
			  GROUP BY ord.customer_num
		) cc ON cc.customer_num = cus.customer_num 
 		LEFT JOIN customer ref ON ref.customer_num = cus.customer_num_referedBy
		LEFT JOIN (
			  SELECT ord.customer_num, SUM(it.quantity * it.unit_price) monto_total
			  FROM orders ord JOIN items it ON it.order_num = ord.order_num
			  WHERE '2015-01-01' <= ord.order_date AND ord.order_date < '2015-12-31' 
			  GROUP BY ord.customer_num
			  ) cr ON cr.customer_num = ref.customer_num
WHERE cc.monto_total > COALESCE(cr.monto_total, 0)
ORDER BY cc.monto_total DESC, cr.monto_total DESC