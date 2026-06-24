COMMIT TRANSACTION
-- punto 1 
CREATE TABLE items_error(
	order_num SMALLINT PRIMARY KEY,
	item_num SMALLINT,
	stock_num SMALLINT,
	manu_code CHAR(3),
	quantity SMALLINT,
	unit_price DECIMAL(6,2),
	fecha DATETIME
);
GO 

CREATE TRIGGER tgr_insert_items
ON items
INSTEAD OF INSERT AS
BEGIN
	DECLARE cur_insert_items CURSOR FOR
	SELECT ins.order_num, item_num, stock_num, manu_code, quantity, unit_price, state
	FROM inserted ins
		JOIN orders ord ON (ord.order_num = ins.order_num)
		JOIN customer cus ON (cus.customer_num = ord.customer_num)
	DECLARE @order_num SMALLINT; DECLARE @item_num SMALLINT; DECLARE @stock_num SMALLINT;
	DECLARE @manu_code CHAR(3); DECLARE @quantity SMALLINT; 
	DECLARE @unit_price DECIMAL(6,2); DECLARE @state CHAR(2);
	OPEN cur_insert_items;

	FETCH FROM cur_insert_items
	INTO @order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price, @state;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @total_insertados SMALLINT; DECLARE @maximo_items SMALLINT;
		SELECT @maximo_items = COUNT(*) FROM items WHERE @order_num = order_num
		SELECT @total_insertados = COUNT(*) FROM inserted WHERE @order_num = order_num;
		DECLARE @contador SMALLINT; SET @contador = @total_insertados - @maximo_items;
		
		IF (@state = 'CA')
		BEGIN 
			IF (@maximo_items <= 5)
			BEGIN
				INSERT INTO items (order_num, item_num, stock_num, manu_code, quantity, unit_price)
				VALUES (@order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price)
			END;
			ELSE
			BEGIN
				INSERT INTO items_error (order_num, item_num, stock_num, manu_code, quantity, unit_price, fecha)
				VALUES (@order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price, GETDATE())
			END;
		END;
		ELSE
		BEGIN
			IF (@contador > 0)
			BEGIN
				INSERT INTO items (order_num, item_num, stock_num, manu_code, quantity, unit_price)
				VALUES (@order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price)
				SET @contador = @contador - 1
			END;
			ELSE
			BEGIN 
				INSERT INTO items_error (order_num, item_num, stock_num, manu_code, quantity, unit_price, fecha)
				VALUES (@order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price, GETDATE())
			END;
		END;


		FETCH NEXT FROM cur_insert_items
		INTO @order_num, @item_num, @stock_num, @manu_code, @quantity, @unit_price, @state;
	END;

	CLOSE cur_insert_items;
	DEALLOCATE cur_insert_items;
END;
GO

ROLLBACK TRANSACTION