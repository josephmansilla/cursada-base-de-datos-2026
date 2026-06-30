-- PUNTO 1
--Las diferencias entre funciones y stored procedures:
--Las funciones no pueden cambiar el estado interno de valores y que retorna una tabla con n valores siendo n >= 0.
--Son usados para integrar consultas SQL, mientras que los stored procedures para secuencias de operaciones de instrucciones.

---- PUNTO 2 

--Triggers: se puede hacer validaciones correspondientes para asegurarse de que los valores ingresados no sean distintos
--a supuestos valores almacenados en la columna.
--PK: por propiedad de univocavidad permite que no haya un valor en esa columna de esa tabla igual.
--FK: debe referir a una PK de otra tabla y genera una dependencia donde se debe eliminar en un cierto orden.
--Mantiene la integridad de esa forma.

-- PUNTO 3
--Crear una consulta que muestre de las tres Estados que tengan la mayor cantidad de VENTAS (no
--compras): Nombre del Estado, monto total vendido en ese Estado, nombre del fabricante y cantidad vendida total de ese fabricante en esa provincia.
--Solo se deberán mostrar en la consulta los fabricantes cuyas ventas totales superen el 15% de las ventas de su provincia.
--Ordenar el resultado por el monto total vendido del Estado de mayor a menor y por monto vendido del fabricante de manera descendente.
--Notas: Se puede utilizar SOLO UN subquery. No usar Store procedures, ni funciones de usuarios, ni tablas temporales.

-- subqueries necesarias para entender el dominio necesario

SELECT DISTINCT TOP 3 m2.state AS estado, SUM(i2.quantity * i2.unit_price) AS venta_total
FROM items i2 
	JOIN manufact m2 ON (i2.manu_code = m2.manu_code)
	JOIN orders o2 ON (i2.order_num = o2.order_num)
GROUP BY state
ORDER BY 2 DESC

SELECT DISTINCT
		m.state AS estado,
		m.manu_name,
		SUM(i.quantity * i.unit_price) AS venta_fabricantes
FROM manufact m
	JOIN items i ON (i.manu_code = m.manu_code)
	JOIN orders o ON (i.order_num = o.order_num)
GROUP BY state, manu_name
ORDER BY 1 ASC, 3 DESC

-- respuesta 

SELECT 
	st.sname AS estado,
	ee.venta_total,
	m.manu_name AS nombre_fabricante,
	SUM(i.quantity * i.unit_price) AS monto_total_fabricante
FROM manufact m
	JOIN state st ON (st.state = m.state)
	JOIN (SELECT DISTINCT TOP 3 m2.state AS estado, SUM(i2.quantity * i2.unit_price) AS venta_total
		  FROM items i2 
				JOIN manufact m2 ON (i2.manu_code = m2.manu_code)
				JOIN orders o2 ON (i2.order_num = o2.order_num)
		  GROUP BY state
		  ORDER BY 2 DESC
		) ee ON (ee.estado = m.state)
	 JOIN items i ON (i.manu_code = m.manu_code)
	 JOIN orders o ON (o.order_num = i.order_num)
GROUP BY st.sname, m.manu_name, ee.venta_total
HAVING (ee.venta_total) > ((0.15) * SUM(i.quantity * i.unit_price))
ORDER BY 2 DESC, 4 DESC;


-- PUNTO 4

--Crear un procedimiento ResumenMensualPR que reciba una fecha como parámetro. Este
--Procedure deberá guardar en una tabla VENTASxMES el Monto total y las cantidades totales
--de unidades vendidas de productos para el Año y mes (yyyymm) de la fecha ingresada como
--parámetro.
--Dependiendo del atributo unit correspondiente a la unidad del producto las cantidades
--deberán ser “ajustadas” según la siguiente tabla:
--		Box: Se multiplica la cantidad x 12
--		Case: Se multiplica la cantidad x 6
--		Pair: Se multiplica la cantidad x 2
--		Each: Las cantidades no se ajustan.

--Tabla VENTASxMES
--	anioMes varchar(6) PK
--	stock_num smallint PK
--	manu_code char(3) PK
--	Cantidad int
--	Monto decimal(10,2)
--El procedimiento debe manejar TODO el proceso en una transacción y deshacer todas
--las operaciones en caso de error.

CREATE TABLE #ventas_por_mes(
	anioMes VARCHAR(6), --yyyymm
	stock_num SMALLINT,
	manu_code CHAR(3),
	cantidad INT,
	monto DECIMAL(10,2)
	CONSTRAINT PK_ventas_por_mes PRIMARY KEY (anioMes, stock_num, manu_code),
	CONSTRAINT FK_producto FOREIGN KEY (stock_num, manu_code)
		REFERENCES products (stock_num, manu_code)
);

GO
CREATE PROCEDURE resumen_mensual_products (@fecha DATE) 
AS BEGIN
	DECLARE @cantidad SMALLINT; DECLARE @stock_num SMALLINT; DECLARE @ajuste INT;
	DECLARE @anioMes VARCHAR(6); DECLARE @precio DECIMAL(8,2);
	DECLARE @tipo_unidad CHAR(4); DECLARE @manu_code CHAR(3);

	DECLARE cur_ventas_mes CURSOR FOR
	SELECT  CONVERT(VARCHAR(6), order_date, 112),
			p.stock_num, p.manu_code, 
			quantity, i.unit_price, unit
	FROM orders o
		JOIN items i ON (i.order_num = o.order_num)
		JOIN products p ON (p.stock_num = i.stock_num AND p.manu_code = i.manu_code)
		JOIN units u ON (u.unit_code = p.unit_code)
	WHERE MONTH(order_date) = MONTH(@fecha);
	
	OPEN cur_ventas_mes;

	FETCH FROM cur_ventas_mes
	INTO @anioMes, @stock_num, @manu_code, @cantidad, @precio, @tipo_unidad;

	BEGIN TRY
		WHILE (@@FETCH_STATUS = 0)
		BEGIN
			BEGIN TRANSACTION
			
			IF (@tipo_unidad = 'Box') SET @ajuste = 12;
			ELSE IF (@tipo_unidad = 'Case') SET @ajuste = 6;
			ELSE IF (@tipo_unidad = 'Pair') SET @ajuste = 2;
			ELSE IF (@tipo_unidad = 'Each') SET @ajuste = 1;
			ELSE THROW 50010, 'tipo unidad no tiene la forma correcta', 16;

			INSERT INTO #ventas_por_mes
			VALUES (@anioMes, @stock_num, @manu_code, @cantidad * @ajuste, CAST(@ajuste * @cantidad * @precio AS DECIMAL(10,2)))

			COMMIT TRANSACTION

			FETCH NEXT FROM cur_ventas_mes
			INTO @anioMes, @stock_num, @manu_code, @cantidad, @precio, @tipo_unidad;					
		END;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION
		PRINT (ERROR_MESSAGE())
	END CATCH
	
	CLOSE cur_ventas_mes;
	DEALLOCATE cur_ventas_mes;
END;

---- PUNTO 5
--Se cuenta con una tabla PermisosxProducto que contiene por cada customer_num los
--productos que este cliente puede comprar.
--La estructura de la tabla es la siguiente:
--(Customer_num, Manu_code, Stock_num)
--Se pide crear un trigger que ante la inserción de una o varias filas en la tabla ítems,
--valide que el customer_num de la orden a la que pertenece cada ítem tenga permiso de
--compra sobre el producto asociado a dicho ítem (manu_code+stock_num).

--En caso que el cliente (customer_num) no tenga permisos (no exista un registro en la
--tabla permisosPorProducto) se deberá cancelar la inserción enviando un mensaje de
--error y deshacer todas las operaciones realizadas
--Nota: Las inserciones pueden ser masivas.

CREATE TABLE permisos_x_producto(
	customer_num SMALLINT,
	manu_code CHAR(3),
	stock_num SMALLINT
	CONSTRAINT PK_producto PRIMARY KEY (customer_num, manu_code, stock_num)
	CONSTRAINT FK_customer_num FOREIGN KEY (customer_num)
		REFERENCES customer (customer_num),
	CONSTRAINT FK_producto FOREIGN KEY (manu_code, stock_num)
		REFERENCES products (manu_code, stock_num),
);


GO
CREATE TRIGGER tgr_ins_items
ON items 
INSTEAD OF INSERT AS
BEGIN 
		IF EXISTS (
					SELECT o.customer_num, ins.manu_code, ins.stock_num
					FROM inserted ins
						JOIN orders o ON (o.order_num = ins.order_num)
					EXCEPT
					SELECT customer_num, manu_code, stock_num FROM permisos_x_producto
					)  THROW 50001, 'no tiene permisos para comprar', 16;
		
		INSERT INTO items (order_num, item_num, stock_num, manu_code, quantity, unit_price)
		SELECT order_num, item_num, stock_num, manu_code, quantity, unit_price FROM inserted ; 
END;


