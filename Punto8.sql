-- 8) Obtener el número, nombre y apellido de los clientes que hayan comprado TODOS productos del fabricante ‘HSK’.

-- CASO OPERACIONES
-- fabrica 10 - vende 10 -> se vendió todo

SELECT customer_num AS numero_cliente, fname+' '+lname AS nombre_cliente 
FROM customer c 
WHERE (
	SELECT COUNT(DISTINCT stock_num) FROM products 
	WHERE manu_code = 'HSK'
	)
	=
	(SELECT COUNT(DISTINCT stock_num) FROM orders o
		JOIN items i ON (o.order_num = i.order_num)
	WHERE o.customer_num = c.customer_num AND i.manu_code='HSK'
	)
ORDER BY customer_num ASC;

-- CASO OPERACIONES DE CONJUNTOS 
-- hay algun producto que no le compre a HSK -> no se vendio todo

SELECT customer_num AS numero_cliente, fname+' '+lname AS nombre_cliente 
FROM customer c 
WHERE NOT EXISTS (
	SELECT stock_num FROM products 
	WHERE manu_code = 'HSK'

	EXCEPT

	SELECT stock_num FROM orders o
		JOIN items i ON (o.order_num = i.order_num)
	WHERE c.customer_num = o.customer_num AND i.manu_code='HSK'
)
ORDER BY customer_num;


-- ACÁ se visualiza cuales son los productos de cada manufacturador
SELECT p.stock_num, pt.description, p.manu_code 
	FROM products p 
		JOIN product_types pt ON (pt.stock_num = p.stock_num)
	-- WHERE p.manu_code = 'ANZ'
	ORDER BY p.manu_code ASC;


-- Acá se visualizan los productos que compró cada cliente respecto el manufacturador
SELECT i.stock_num, pt.description, i.manu_code, c.customer_num 
	FROM orders o 
		JOIN items i ON (o.order_num = i.order_num)
		JOIN customer c ON (c.customer_num = o.customer_num)
		JOIN product_types pt ON (i.stock_num = pt.stock_num)
	WHERE c.customer_num = o.customer_num -- AND p.manu_code = 'ANZ'
	ORDER BY manu_code ASC, c.customer_num ASC;
