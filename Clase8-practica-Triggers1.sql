CREATE TABLE Products_historia_precios (
	stock_historia_Id INT IDENTITY(1,1) PRIMARY KEY,
	stock_num SMALLINT,
	manu_code CHAR(1),
	fechaHora DATETIME,
	usuario CHAR(1),
	unit_price_old DECIMAL(18, 2),
	unit_price_new DECIMAL(18, 2),
	estado CHAR(1) DEFAULT 'A' CHECK (estado IN ('A', 'I'))
); GO

-- PUNTO 2
--Crear un trigger sobre la tabla Products_historia_precios que ante un delete sobre la misma
--realice en su lugar un update del campo estado de ‘A’ a ‘I’ (inactivo).

CREATE TRIGGER Products_historia_precios ON Products_historia_precios
AFTER DELETE AS
BEGIN
	UPDATE Products_historia_precios 
	SET estado = 'I'
	WHERE Stock_historia_Id IN (SELECT Stock_historia_Id FROM deleted);
END; GO

-- PUNTO 3
--Validar que sólo se puedan hacer inserts en la tabla Products en un horario entre las 8:00 AM y
--8:00 PM. En caso contrario enviar un error por pantalla.


CREATE TRIGGER Trigger_Products_Insert ON products
AFTER INSERT AS
BEGIN 
	DECLARE @hora TIME;
	SET @hora = CAST(GETDATE() AS TIME);

	IF (@hora < '08:00:00' OR @hora > '20:00:00')
	BEGIN
		RAISERROR('No se pueden hacer inserts en la tabla Products fuera del horario permitido (8:00 AM - 8:00 PM)',16, 1);
		ROLLBACK TRANSACTION;
	END
END; GO

-- PUNTO 4
--Crear un trigger que ante un borrado sobre la tabla ORDERS realice un borrado en cascada
--sobre la tabla ITEMS, validando que sólo se borre 1 orden de compra.
--Si detecta que están queriendo borrar más de una orden de compra, informará un error y
--abortará la operación.

CREATE TRIGGER Trigger_Orders_Delete ON Orders
AFTER DELETE AS 
BEGIN
	IF (SELECT COUNT(*) FROM deleted) > 1
	BEGIN
		RAISERROR('Se está borrando más de una orden de compra',16, 1);
		ROLLBACK TRANSACTION;
		RETURN;
	END

	DELETE FROM items WHERE order_num IN (SELECT order_num FROM deleted);
END; GO

-- PUNTO 5
--Crear un trigger de insert sobre la tabla ítems que al detectar que el código de fabricante
--(manu_code) del producto a comprar no existe en la tabla manufact, inserte una fila en dicha
--tabla con el manu_code ingresado, en el campo manu_name la descripción ‘Manu Orden 999’
--donde 999 corresponde al nro. de la orden de compra a la que pertenece el ítem y en el campo
--lead_time el valor 1.

CREATE TRIGGER Trigger_Items_Insert ON items
AFTER INSERT AS 
BEGIN
	
END; GO


-- PUNTO 6
--Crear tres triggers (Insert, Update y Delete) sobre la tabla Products para replicar todas las
--operaciones en la tabla Products _replica, la misma deberá tener la misma estructura de la tabla
--Products.

CREATE TABLE Products_replica (
	stock_num SMALLINT,
	manu_code CHAR(3),
	unit_price DECIMAL,
	unit_code SMALLINT,
	CONSTRAINT PK_products PRIMARY KEY (stock_num, manu_code),
	CONSTRAINT FK_manu_code FOREIGN KEY (manu_code)
		REFERENCES manufact (manu_code),
	CONSTRAINT FK_stock_num FOREIGN KEY (stock_num)
		REFERENCES product_types (stock_num),
	CONSTRAINT FK_unit_code FOREIGN KEY (unit_code)
		REFERENCES units (unit_code)); GO


CREATE TRIGGER Trigger_Products_Replica ON products
AFTER INSERT, UPDATE, DELETE AS
BEGIN
    IF EXISTS (SELECT * FROM inserted)
       AND NOT EXISTS (SELECT * FROM deleted)
    BEGIN
		INSERT INTO Products_replica 
			SELECT * FROM inserted;
    END

    IF EXISTS (SELECT * FROM deleted)
       AND NOT EXISTS (SELECT * FROM inserted)
    BEGIN
		DELETE pr FROM Products_replica pr
		INNER JOIN deleted d ON
			pr.stock_num = d.stock_num
			AND pr.manu_code = d.manu_code;

    END

    IF EXISTS (SELECT * FROM inserted)
       AND EXISTS (SELECT * FROM deleted)
    BEGIN
        UPDATE pr SET
			pr.unit_price = i.unit_price,
			pr.unit_code = i.unit_code
		FROM Products_replica pr
		INNER JOIN inserted i 
			ON pr.stock_num = i.stock_num
			AND pr.manu_code = i.manu_code
    END
END; GO

-- PUNTO 7
--Crear la vista Productos_x_fabricante que tenga los siguientes atributos:
--Stock_num, description, manu_code, manu_name, unit_price
--Crear un trigger de Insert sobre la vista anterior que ante un insert, inserte una fila en la tabla
--Products, pero si el manu_code no existe en la tabla manufact, inserte además una fila en dicha
--tabla con el campo lead_time en 1.

