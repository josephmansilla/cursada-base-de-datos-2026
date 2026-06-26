BEGIN TRANSACTION

CREATE TABLE products_historia_precios(
	stock_historia_id SMALLINT PRIMARY KEY IDENTITY(1,1),
	stock_num SMALLINT,
	manu_code CHAR(3),
	fechaHora DATETIME,
	usuario VARCHAR(67),
	unit_price_old DECIMAL(6,2),
	unit_price_new DECIMAL(6,2),
	estado_char CHAR 
		DEFAULT ('A') 
		CHECK(estado_char IN ('A', 'I'))
);
GO


-- punto 1
CREATE TRIGGER update_precio
ON products
AFTER UPDATE AS
BEGIN
	INSERT INTO products_historia_precios (stock_num, manu_code, fechaHora, usuario, unit_price_old, unit_price_new, estado_char)
	SELECT i.stock_num, i.manu_code, GETDATE(),CURRENT_USER, d.unit_price, i.unit_price, 'A'
	FROM inserted i JOIN deleted d 
		ON (i.stock_num = d.stock_num AND i.manu_code = d.manu_code)
	WHERE i.unit_price != d.unit_price
END;
GO

-- punto 2
CREATE TRIGGER delete_precios
ON products_historia_precios
AFTER DELETE AS
BEGIN
	UPDATE products_historia_precios 
	SET estado_char = 'I'
	WHERE stock_historia_id IN (SELECT stock_historia_id FROM deleted);
END;
GO

-- punto 3
CREATE TRIGGER alarm_inserts_products
ON products
AFTER INSERT AS 
BEGIN 
	IF (DATEPART(HOUR, GETDATE()) NOT BETWEEN 8 AND 20)
	BEGIN
		ROLLBACK TRANSACTION;
		THROW 50000, 'No es posible editar fuera de horario laboral', 1;
	END
END;
GO

-- punto 4
CREATE TRIGGER delete_orders
ON orders 
INSTEAD OF DELETE AS
BEGIN
	IF ((SELECT COUNT(*) FROM deleted) > 1)
		THROW 50001, 'No se puede borrar multiples ordenes', 1;
	
	DECLARE @order_num SMALLINT;
	SELECT @order_num = order_num FROM deleted;

	DELETE FROM items WHERE order_num = @order_num;
	DELETE FROM orders WHERE order_num = @order_num;
END;
GO


-- punto 5
CREATE TRIGGER insert_items_manufacts
ON items
INSTEAD OF INSERT AS 
BEGIN
	DECLARE manufact_non_existent CURSOR FOR 
	SELECT manu_code, order_num FROM inserted; 
	DECLARE @manu_code CHAR(3);
	DECLARE @order_num SMALLINT;
	DECLARE @lead_time SMALLINT;
	SET @lead_time = 1;

	OPEN manufact_non_existent;

	FETCH NEXT FROM manufact_non_existent
	INTO @manu_code, @order_num

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF (@manu_code NOT IN (SELECT manu_code FROM manufact))
		BEGIN
			INSERT INTO manufact (manu_code, manu_name, lead_time)
			VALUES (@manu_code, 'Manu Orden ' + CAST(@order_num AS VARCHAR(15)), @lead_time)
		END;
		FETCH NEXT FROM manufact_non_existent
		INTO @manu_code, @order_num
	END;

	CLOSE manufact_non_existent;
	DEALLOCATE manufact_non_existent;

	INSERT INTO items(item_num, order_num, manu_code, stock_num, quantity, unit_price)
	SELECT item_num, order_num, manu_code, stock_num, quantity, unit_price FROM inserted
END;
GO


-- punto 6

CREATE TABLE products_replica(
	stock_num SMALLINT,
	manu_code CHAR(3),
	unit_price DECIMAL(6,2),
	unit_code SMALLINT
	CONSTRAINT FK_products_replica PRIMARY KEY (stock_num, manu_code)
);
GO

CREATE TRIGGER duplicate_products_ins
ON products
AFTER INSERT AS
BEGIN
	INSERT INTO products_replica (stock_num, manu_code, unit_price, unit_code)
	SELECT stock_num, manu_code, unit_price, unit_code FROM inserted
END;
GO

CREATE TRIGGER duplicate_products_del
ON products
AFTER DELETE AS
BEGIN
	DELETE pr FROM products_replica pr
	JOIN deleted d ON (d.manu_code = pr.manu_code AND d.stock_num = pr.stock_num)
END;
GO

CREATE TRIGGER duplicate_products_upd
ON products
AFTER UPDATE AS
BEGIN
	UPDATE pr SET pr.unit_price = i.unit_price,
				  pr.unit_code = i.unit_code 
	FROM products_replica pr
	JOIN inserted i ON (i.manu_code = pr.manu_code AND i.stock_num = pr.stock_num)
END;
GO

-- punto 7

CREATE VIEW prodcuts_x_fabricante AS
SELECT i.stock_num, pt.description, i.manu_code, m.manu_name, i.unit_price
FROM items i
	JOIN product_types pt ON (pt.stock_num = i.stock_num)
	JOIN manufact m ON (m.manu_code = i.manu_code);
GO

CREATE TRIGGER tgr_pxf
ON prodcuts_x_fabricante
INSTEAD OF INSERT AS
BEGIN
	DECLARE cur_pxf CURSOR FOR
	SELECT stock_num, description, manu_code, manu_name, unit_price FROM inserted;

	OPEN cur_pxf;
	
	DECLARE @manu_code CHAR(3); DECLARE @manu_name VARCHAR(15);
	DECLARE @description VARCHAR(15); DECLARE @stock_num SMALLINT;
	DECLARE @unit_price DECIMAL(6,2); DECLARE @unit_code SMALLINT;
	DECLARE @lead_time SMALLINT; SET @lead_time = 1;

	FETCH NEXT FROM cur_pxf
	INTO @stock_num, @description, @manu_code, @manu_name, @unit_price; 

	WHILE (@@FETCH_STATUS = 0)
	BEGIN

		INSERT INTO products (stock_num, manu_code, unit_price, unit_code)
		VALUES (@stock_num, @manu_code, @unit_price, @unit_code);

		INSERT INTO product_types (stock_num, description)
		VALUES (@stock_num, @description);

		IF NOT EXISTS (SELECT * FROM manufact WHERE manu_code = @manu_code)
		BEGIN
			INSERT INTO manufact(manu_code, manu_name, lead_time)
			VALUES (@manu_code, @manu_name, @lead_time);
		END;

		FETCH NEXT FROM cur_pxf
		INTO @stock_num, @description, @manu_code, @manu_name, @unit_price; 
		
	END;

	CLOSE cur_pxf;
	DEALLOCATE cur_pxf;
END;
GO

ROLLBACK TRANSACTION 