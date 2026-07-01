-- PUNTO 3 - QUERY 
--SELECT numero y apellido del cliente, codifgo de fabricante, tipo de producto y cantidad de producto
--comprados a los fabricantes HSK y NRG. Solo se deben mostrar aquellos clientes que hayan comprado 
--TODOS los productos de ambos fabricantes.
--Ordenar la slida por numero de cliente y cantidad comprada en forma descendente.

SELECT
	c.customer_num AS numero_cliente,
	lname AS apellido,
	i.manu_code AS codigo_manufact,
	i.stock_num AS numero_stock,
	pt.description AS tipo_producto,
	i.quantity AS cantidad
FROM customer c 
	JOIN orders o ON (c.customer_num = o.customer_num)
	JOIN items i ON (o.order_num = i.order_num)
	JOIN product_types pt ON (pt.stock_num = i.stock_num)
WHERE NOT EXISTS (
		SELECT DISTINCT stock_num
		FROM products
		WHERE (manu_code IN ('HSK','NRG'))
		EXCEPT
		SELECT DISTINCT stock_num
		FROM items i2
			JOIN orders o ON (o.order_num = i2.order_num)
		WHERE (o.customer_num = c.customer_num AND (i2.manu_code IN ('HSK','NRG')))
	) AND (manu_code IN ('HSK','NRG'))
ORDER BY 1 DESC, 6 DESC;




-- PUNTO 4 - STORED PROCEDURE
--Crear un procedimeinto registraProductoPR al qu se le envie como parametros stock_num, manu_code, unit_price, unit_code, status,
--cat_descr, cat_picture, cat_advert. Si el producto no existe en la tabla de productos crearlo y si ya existe modfiicarlo. Además 
--ingresar un nuevo registro del producto en la tabla de catalogo.
--Ante cualquier error abortar todas las operaciones y mostrar el numero y descripcion del error.

GO
CREATE PROCEDURE registraProductoPR_v2 (@stock_num SMALLINT, @manu_code CHAR(3), @unit_price DECIMAL(6,2), 
									@unit_code SMALLINT, @status CHAR(1), 
									@cat_descr TEXT, @cat_picture VARCHAR(255), @cat_advert VARCHAR(255))
AS BEGIN
	BEGIN TRY
		BEGIN TRANSACTION

		IF NOT EXISTS (SELECT TOP 1 * FROM products WHERE stock_num = @stock_num AND manu_code = @manu_code) 
		BEGIN
			INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
			VALUES (@stock_num, @manu_code, @unit_price, @unit_code)
		END
		ELSE BEGIN
			UPDATE products
			SET unit_price = @unit_price, unit_code = @unit_code
			WHERE stock_num = @stock_num AND manu_code = @manu_code
		END

		INSERT INTO catalog (catalog_num, stock_num, manu_code, 
							cat_descr, cat_picture, cat_advert)
		VALUES ((SELECT MAX(catalog_num) + 1 FROM catalog), @stock_num, @manu_code,
				 @cat_descr, @cat_picture, @cat_advert)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		THROW @@ERROR_NUMBER, @@ERROR_MESSAGE, 1
		ROLLBACK TRANSACTION
	END CATCH

	
END;

-- PUNTO 5 - TRIGGERS
--Cree las tablas clientes_BK y ordenes_BK que sean copias de las tablas clientes y ordenes respectivamente. Asuma que estas tablas están en bases
--de datos diferentes. Realice los triggers que crea necesarios para asegurar la integridad referencial entre ambas tablas

SELECT *
INTO clientes_bk
FROM customer;

SELECT *
INTO ordenes_bk
FROM orders;

DROP TABLE clientes_bk;
DROP TABLE ordenes_bk;

GO
CREATE TRIGGER trg_cliente_del_ord
ON customer /*cliente_bk*/
AFTER DELETE
AS BEGIN
	IF EXISTS 
		(SELECT TOP 1 1 FROM orders /*ordenes_bk*/ o JOIN deleted d ON (d.customer_num = o.customer_num)) THROW 50002, 'no se puede borrar, todavia existen FKs (ordenes) asociados al cliente', 1
END;

GO
CREATE TRIGGER trg_cliente_upd
ON customer /*cliente_bk*/
AFTER UPDATE
AS BEGIN
	IF UPDATE (customer_num) AND EXISTS
		(SELECT TOP 1 1 FROM orders /*ordenes_bk*/ o JOIN inserted i ON (i.customer_num = o.customer_num)) THROW 50001, 'no se puede modificar, todavia existen FKs (ordenes) asociados al cliente', 2
END;

GO
CREATE TRIGGER trg_orders_ins_upd
ON orders /*ordenes_bk*/
AFTER INSERT, UPDATE
AS BEGIN
	IF NOT EXISTS (SELECT TOP 1 1 FROM customer /*cliente_bk*/ c JOIN inserted i ON (i.customer_num = c.customer_num)) THROW 50003, 'no existe la PK intentando ser insertada como FK', 3
END;