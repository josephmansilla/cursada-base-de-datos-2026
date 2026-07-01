---- QUERRY ---
/*Realizar una consulta que muestre para cada par (cliente, fabricante) los clientes que hayan comprado todos los productos fabricados por ese fabricante. 
Mostrar la informacion ordenada por numero de cliente y codigo de fabricante*/


-- mi forma rebuscada de hacer las cosas!
SELECT DISTINCT cus.customer_num AS num_cliente,
	   lname+', '+fname AS nombre_cliente,
	   it.manu_code AS codigo_manu,
	   COUNT(DISTINCT it.stock_num) AS cantidad_comprado
FROM customer cus
	JOIN orders ord ON (ord.customer_num = cus.customer_num)
	JOIN items it ON (it.order_num = ord.order_num)
WHERE NOT EXISTS
(
	SELECT stock_num FROM products
	WHERE products.manu_code = it.manu_code
	EXCEPT
	SELECT stock_num 
	FROM orders ord2
		JOIN items it2 ON (it2.order_num = ord2.order_num)
	WHERE ord2.customer_num = cus.customer_num AND it2.manu_code = it.manu_code	
)
GROUP BY cus.customer_num, it.manu_code, fname, lname
ORDER BY cus.customer_num, it.manu_code ASC 


-- la mejor alternativa.. más fácil!

SELECT DISTINCT cus.customer_num AS num_cliente,
	   lname+', '+fname AS nombre_cliente,
	   it.manu_code AS codigo_manu,
	   COUNT(DISTINCT it.stock_num) AS cantidad_comprado
FROM customer cus
	JOIN orders ord ON (ord.customer_num = cus.customer_num)
	JOIN items it ON (it.order_num = ord.order_num)
GROUP BY cus.customer_num, it.manu_code, fname, lname
HAVING (SELECT COUNT(DISTINCT stock_num) FROM products p2 WHERE p2.manu_code = it.manu_code) = 
		COUNT(DISTINCT it.stock_num)
ORDER BY cus.customer_num, it.manu_code ASC 


-- STORE PROCEDURE --
/*
Crear un procedimiento historicoVentasPR que reciba como parametro una fecha y que en base a las ordenes emitidas hasta esa fecha realice:
  a. En una tabla NivelFabricante registre si dicho fabricante ha vendido o no, alguno de sus productos. Debera guardar la cantidad de tipos
	  productos fabricados por el y la cantidad de tipos de productos vendidos hasta la fecha pasada como parametro. Ej el fabricante produde
	  10 productos pero solo vendio 3 tipos de productos
  
  b. En caso que el fabricante haya vendido productos, guardar en una tabla NivelProductos la cantidad total de unidades vendidas de cada
     prorduto del fabricante segun las ordenes emitidas hasta esa fecha(si no se vendio nada nivel bajo)
  
   En la tabla nivel productos existe una columna nivel que se debera asignar el valor alto para aquellos productos que hayan sifo
   vendidos en 10 o mas unidades mientras que los productos que se hayan vendido en menos de 10 unidades o no hayan tenido ventas se les debera
   asignar el valor bajo. Si la fecha pasada como parametro ya ha sido procesada mostrar el mensaje "Periodo ya proccesado" y no realizar ninguna
   operacion.
   En caso que produzca un error mostrarlo y dehacer todo lo procesado.
 
   La estructura de las tablas:
   NivelFabricantes: fechaHta DATE, not null, manu_cod char(3) not null, cantFabricados int, cantVendidos int
   NivelProductos:  FechaHta Date not null, stock_num int not null, manu_cod char(3) not null, cantidad int not nill, nivel varchar(4)
*/
CREATE TABLE nivelFabricantes(
    id_nivel_fab   INT      IDENTITY(1, 1) PRIMARY KEY,
    fechaLimite    DATE     NOT NULL, --PK
    manu_code      CHAR(3)  NOT NULL,
    cantFabricados INT,
    cantVendidos   INT      
	CONSTRAINT fk_manu_code FOREIGN KEY (manu_code) REFERENCES manufact
);

CREATE TABLE nivelProductos(
    id_nivel_productos INT         IDENTITY (1, 1) PRIMARY KEY,
    fechaLimite         DATE        NOT NULL, -- PK
    stock_num          SMALLINT    NOT NULL,
    manu_code          CHAR(3)    NOT NULL,
    cantidad           INT         NOT NULL,
    nivel              VARCHAR(4) 
	CONSTRAINT FK_product FOREIGN KEY (stock_num, manu_code) REFERENCES products
);
GO
CREATE PROCEDURE historicoVentasPR (@fechaLimite DATE)
AS BEGIN
	BEGIN TRY 
		IF EXISTS (SELECT 1 FROM nivelFabricantes WHERE fechaLimite = @fechaLimite)
				OR EXISTS (SELECT 1 FROM nivelProductos WHERE fechaLimite = @fechaLimite) THROW 50001, 'fecha limite ya usada', 16 
		
		BEGIN TRANSACTION

		INSERT INTO nivelFabricantes (fechaLimite, manu_code, cantFabricados, cantVendidos)
		SELECT @fechaLimite, 
			   m1.manu_code, 
			   COALESCE((SELECT COUNT(*) FROM products p2 WHERE p2.manu_code = m1.manu_code),0), 
			   COALESCE(COUNT(DISTINCT it.stock_num),0)
		FROM manufact m1
			LEFT JOIN (SELECT i2.stock_num, i2.manu_code
						FROM items i2
							JOIN orders o2 ON (o2.order_num = i2.order_num)
						WHERE order_date < @fechaLimite) t2
					ON (t2.manu_code = m1.manu_code)
		GROUP BY m1.manu_code
		
		INSERT INTO nivelProductos (fechaLimite, stock_num, manu_code, cantidad, nivel)
		SELECT @fechaLimite, 
			   t2.stock_num, 
			   p1.manu_code,
			   SUM(t2.quantity), 
			   IIF(SUM(it.quantity) >= 10, 'alto','bajo') 
		FROM products p1
			LEFT JOIN (SELECT i2.stock_num, i2.manu_code, i2.quantity
					   FROM items i2
						   JOIN orders o2 ON (o2.order_num = i2.order_num)
					   WHERE order_date < @fechaLimite
					   ) t2
					ON (p1.manu_code = t2.manu_code AND p1.stock_num = t2.stock_num)
		WHERE p1.manu_code IN (
			SELECT DISTINCT i3.manu_code
			FROM items i3
				JOIN orders o3 ON (o3.order_num = i3.order_num)
				WHERE o3.order_date < @fechaLimite
		)
		GROUP BY p1.manu_code, t2.stock_num
		
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT(ERROR_MESSAGE());
		ROLLBACK TRANSACTION;
	END CATCH
END;


---------- 5. TRIGGER ----------
/* Por cada operacion guardar el fabricante, el instante en que se produzco la operacion, los valores concatenados que contenian las columnas 
del fabricante borrado o modificado en la columna valoresOld, los valores concatenados de todas las columnas despues de la modificacion 
en la columna valoresNew y los valores 'B' (borrado) o 'M' (Modificado) en la operacion segun corresponda.
Los valores a tener en cuenta para la registracion son los de las columnas manu_name, lead_time y state no se modifica el 
manucode y las operaciones pueden ser masivas 
*/

-- las operaciones puede ser masivas
-- (me indica que los cursores van a bajar la performance en caso de ser masivas, no invalida el punto, pero no te da el puntaje completo)

CREATE TABLE audit_manufact(
	id BIGINT PRIMARY KEY IDENTITY(1,1),
	manu_code CHAR(3),
	fecha_operacion DATETIME,
	valoresOld CHAR(255),
	valoresNew CHAR(255),
	operacion CHAR CHECK(operacion IN ('B', 'M'))
	CONSTRAINT fk_manu_code FOREIGN KEY (manu_code)
		REFERENCES manufact
);

GO
CREATE TRIGGER tgr_del_manufact
ON manufact
AFTER DELETE, UPDATE AS
BEGIN
	BEGIN TRY
		INSERT INTO audit_manufact (manu_code, fecha_operacion, valoresOld, valoresNew, operacion)
		SELECT d.manu_code, 
				GETDATE(),
				d.manu_name + CAST(d.lead_time AS CHAR(255)) + CAST(d.state AS CHAR(255)), 
				ISNULL((i.manu_name + CAST(i.lead_time AS CHAR(255)) + CAST(i.state AS CHAR(255))), ''), 
				--> yo estoy aclarando que sabia que si esto daba null me iba a marcarlo como vacio, entonces le pongo ese isnull realmente solamente para hacerme el canchero
				IIF(EXISTS (SELECT 1 FROM inserted), 'M', 'B')
		FROM deleted d
			LEFT JOIN inserted i ON (i.manu_code = d.manu_code)
	END TRY
	BEGIN CATCH 
		
	END CATCH	
END;
GO
