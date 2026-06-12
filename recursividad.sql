CREATE VIEW v_fabricantes AS
SELECT m.manu_code,m.manu_name,
count(stock_num) cant_productos,
(SELECT max(order_date)
	FROM orders o 
			JOIN items i ON o.order_num=i.order_num
				AND i.manu_code=m.manu_code
) ult_compra
FROM manufact m 
		LEFT JOIN products s ON s.manu_code = m.manu_code
GROUP BY m.manu_code,m.manu_name
HAVING count(stock_num)=0 OR count(stock_num)>2

CREATE synonym fab_x_productos FOR dbo.v_fabricantes;


WITH deptos AS (SELECT d.nro_depto, e.legajo 
				FROM departamentos d JOIN empleados e
						ON d.nro_depto = e.nro_depto
				WHERE d.presupuesto > 10000 AND e.fechaNacimiento > '20000101')
SELECT deptos.legajo, e2.nombre
FROM deptos JOIN empleados e2 ON deptos.nro_depto = e2.nro_depto;

SELECT deptos.legajo, e2.nombre
FROM (SELECT d.nro_depto, e.legajo 
				FROM departamentos d JOIN empleados e
						ON d.nro_depto = e.nro_depto
				WHERE d.presupuesto > 10000 AND e.fechaNacimiento > '20000101')
	JOIN empleados e2 ON deptos.nro_depto = e2.nro_depto;