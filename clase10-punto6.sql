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