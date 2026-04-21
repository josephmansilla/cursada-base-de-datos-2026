SELECT manu_code AS codigo_fabricante, 
	COUNT(DISTINCT(order_num)) AS cantidad_compras,
	SUM(quantity) AS cantidad_comprado,
	SUM(unit_price * quantity) AS precio_total
FROM items
GROUP BY manu_code
HAVING COUNT(quantity) > 4
ORDER BY precio_total DESC;