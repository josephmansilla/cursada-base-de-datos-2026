--Punto 1 - Explicar la funcionalidad de seguridad de base de datos, explique los conceptos asociados y los objetos de BD 
--que la implementan con un ejemplo de como lo implementan.

--PUNTO 2 - Explique las diferentes formas existenhtes para implementar en un motor de base de datos 
--la regla de integridad referencial.

---- PUNTO 3 - QUERY
--Seleccionar los tipos de productos y sus cantidades vendidadas para las fechas de emision de las ordenes de mayor
--y menor monto vendido. Ordenar el resultado mostrando primero los tipos de productos vendidos en la fecha de mayor
--monto vendido y luego los productos vendidos en la menor, dentro de cada fecha mostrar los productos
--ordenados por el total de cantidades vendidas en forma descendente.

--(Aclaración: solo mostrar la orden de mayor y menor facturacion de TODO el historial de ventas, mostrar cada item que tiene)


SELECT * FROM (
	SELECT TOP 1 
		'Mayor' AS posicion,
		o.order_date AS fecha_orden,
		i.stock_num AS numero_stock,
		pt.description AS tipo_producto,
		SUM(i.quantity * i.unit_price) AS cantidad
	FROM items i
		JOIN product_types pt ON (pt.stock_num = i.stock_num)
		JOIN orders o ON (o.order_num = i.order_num)
	GROUP BY o.order_date, i.stock_num, pt.description
	ORDER BY cantidad DESC
	UNION
	SELECT TOP 1 
		'Menor' AS posicion,
		o.order_date AS fecha_orden,
		i.stock_num AS numero_stock,
		pt.description AS tipo_producto,
		SUM(i.quantity * i.unit_price) AS cantidad
	FROM items i
		JOIN product_types pt ON (pt.stock_num = i.stock_num)
		JOIN orders o ON (o.order_num = i.order_num)
	GROUP BY o.order_date, i.stock_num, pt.description
	ORDER BY cantidad ASC
) as mayor_y_menor_monto_vendido;


---- PUNTO 4 - STORED PROCEDURE
--Crear un procedimiento procesarClientesPR el cual otmara de una tabla NovedadesClienets la siguiente información:

--(customer_num, lname, fname, company, state)

--Por cada registro de la tabla NovedadesClientes se deberá evaluar:
--   - Si el cliente existe en la tabla clientes, se deberá modificar dicho cliente en la tabla Clientes con los datos 
--	leidos de la tabla de novedades.
--   - Si el cliente no existe en la tabla clientes, se deberá insertar el cliente en la tabla Clientes con lkos datos leidos
--   de la tabla de novedades.

CREATE TABLE novedades_cliente(
	customer_num SMALLINT,
	fname VARCHAR(15),
	lname VARCHAR(15),
	company VARCHAR(20),
	state CHAR(2),
);

GO
CREATE PROCEDURE procesarClientePR 
AS BEGIN
	DECLARE @customer_num SMALLINT; DECLARE @fname VARCHAR(15); DECLARE @lname VARCHAR(15);
	DECLARE @company VARCHAR(20); DECLARE @state CHAR(2);

	DECLARE cur_proc_client CURSOR FOR
	SELECT customer_num, fname, lname, company, state FROM novedades_cliente;
	
	OPEN cur_proc_client;

	FETCH FIRST FROM cur_proc_client INTO
	@customer_num, @fname, @lname, @company, @state;
	
	WHILE (@@FETCH_STATUS = 0)
	BEGIN   
		BEGIN TRY 
			BEGIN TRANSACTION;
			
			IF EXISTS (SELECT 1 FROM customer WHERE customer_num = @customer_num)
			-- si existe el cliente hay que modificarlo con los datos nuevos
			BEGIN
				UPDATE customer SET
				fname = @fname, lname = @lname, company = @company, state = @state
				WHERE customer_num = @customer_num;
				-- usamos el customer_num para ubicar la fila deseada
			END
			ELSE BEGIN
				-- no caso de que no exista insertamos todo.
				INSERT INTO customer (customer_num, fname, lname, company, state)
				VALUES (@customer_num, @fname, @lname, @company, @state);
			END

			COMMIT TRANSACTION;
			-- en caso de ningún eerror se commitea (mantenemos conssitencia)
		END TRY
		BEGIN CATCH
			PRINT('Hubo un error en ' + @customer_num + '. Mensaje: ' + ERROR_MESSAGE());
			ROLLBACK TRANSACTION; 
			-- unicamente se hace rollback de ese cliente en particular y se hace el fetch next
		END CATCH

		FETCH NEXT FROM cur_proc_client INTO
			@customer_num, @fname, @lname, @company, @state;
	END;

	CLOSE cur_proc_client;
	DEALLOCATE cur_proc_client;
END;

-- PUNTO 5 - TRIGGER
--Realizar un trigger que no permitea a los fabricantes de new jersey vender a clientes situados en New Jersey. Cuando
--se quiera insertar un fila con una orden no permitida informar el error y no realizar ninguna operacion.

--Además, como las operaciones pueden ser masivas, si hay items que pertenecen a más de una orden, informar el error y
--cancelar todas las operaciones.

--En caso realizar una operación inválida, borrar las órdenes inválidas que hayan sido creadas.

GO
CREATE TRIGGER tgr_orden_tierra_del_fuego
ON orders
INSTEAD OF INSERT -- para poder controlar que se inserta en orders y que no (borro las ordenes invalidas)
AS BEGIN
	IF EXISTS (SELECT TOP 1 1 
			   FROM inserted i
					JOIN customer c ON (i.customer_num = c.customer_num)
					JOIN items it ON (it.order_num = i.order_num)
					JOIN manufact m ON (it.manu_code = m.manu_code)
				WHERE c.state = 'NJ' AND m.state = 'NJ' -- cambiamos por new jersey! no habia tierra del fuego
			   ) THROW 50001, 'Un vendedor de Tierra del Fuego le vendió a un cliente de Tierra del fuego', 16;
			-- nunca se inserta la operación en caso de cumplir la condici{on de ambos muchachos pertenecientes a tierra del fuego
			
	INSERT INTO orders 
	SELECT * FROM inserted;
	-- no usamos cursores porque las operaciones pueden ser masivas
END;

-- SUBJECT: Parcial BD - 010726
-- enviar a hpuelman@gmail.com, jzaffaroni@gmail.com
-- codigo pegado al mail y el archivo.