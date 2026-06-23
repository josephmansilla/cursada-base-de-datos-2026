IF OBJECT_ID('audit_cust', 'U') IS NOT NULL
BEGIN
    DROP TABLE audit_cust;
END
GO
IF OBJECT_ID('cust_ins_1', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER cust_ins_1;
END
GO
IF OBJECT_ID('cust_del_1', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER cust_del_1;
END
GO
IF OBJECT_ID('cust_up_1', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER cust_up_1;
END
GO
IF OBJECT_ID('del_ordenes', 'TR') IS NOT NULL
BEGIN
    DROP TRIGGER del_ordenes;
END
-- PUNTO 1
CREATE TABLE audit_cust(
	id_audit INT IDENTITY(1,1),
	customer_num INTEGER,
	operacion CHAR,
	usuario CHAR(20) DEFAULT suser_sname(),
	fechayhora DATETIME DEFAULT getdate(),
	PRIMARY KEY(id_audit)
);
GO

-- PUNTO 2
CREATE TRIGGER cust_ins_1
ON customer
AFTER INSERT AS
BEGIN
	INSERT INTO audit_cust(customer_num, operacion)
	SELECT customer_num, 'I' FROM inserted;
END
GO

DELETE FROM customer WHERE customer_num BETWEEN 1000 AND 1105;
-- PUNTO 3
INSERT INTO customer (customer_num, fname, lname)
VALUES (1000, 'Mario', 'Ledesma');
-- PUNTO 4
-- Se observa un id_audit, un customer_num (1000), un usuario (pepe) y la fecha de ahora

-- PUNTO 5
INSERT INTO customer (customer_num, lname, fname)
SELECT customer_num+1000, fname, lname FROM customer
WHERE customer_num BETWEEN 100 AND 105;

-- se observa todas las inserciones con los datos correspondientes

-- PUNTO 6
GO
CREATE TRIGGER cust_del_1
ON customer
AFTER DELETE AS
BEGIN
	INSERT INTO audit_cust(customer_num, operacion)
	SELECT customer_num, 'D' FROM deleted;
END
GO
-- PUNTO 7
DELETE FROM customer WHERE customer_num = 1000;


-- PUNTO 8
-- se agregó a nuestro nuevo amigo el trigger de borrado :)
--BEGIN TRY
--	DELETE FROM customer;
--END TRY
--BEGIN CATCH
--END CATCH
-- PUNTO 9: no me modificó nada :(
-- PUNTO 10: no hay cambios

-- PUNTO 11
GO
CREATE TRIGGER cust_up_1
ON customer
AFTER UPDATE
AS BEGIN
	INSERT INTO audit_cust(customer_num, operacion)
	SELECT customer_num, 'O' FROM inserted;
	INSERT INTO audit_cust(customer_num, operacion)
	SELECT customer_num, 'N' FROM deleted;
END
GO

-- PUNTO 12
UPDATE customer
SET company = 'NaranjaX'
WHERE customer_num = 1101;
GO
-- PUNTO 13: CONTIENE EL TRIGGER DE ESE EDIT

-- PUNTO 14
CREATE TRIGGER del_ordenes
ON orders
INSTEAD OF DELETE
AS
BEGIN
	DECLARE TrigDelCur CURSOR FOR
	SELECT customer_num, ship_charge, order_num, order_date FROM deleted;

	DECLARE @n_cliente INT, 
		@c_estado NUMERIC, 
		@n_orden INT, 
		@f_orden DATETIME;

	OPEN TrigDelCur;
	FETCH NEXT FROM TrigDelCur
		INTO @n_cliente, @c_estado, @n_orden, @f_orden

	WHILE @@FETCH_STATUS = 0
	BEGIN 
		DELETE FROM items WHERE order_num = @n_orden;
		DELETE FROM orders WHERE order_num = @n_orden;
		FETCH NEXT FROM TrigDelCur
		INTO @n_cliente, @c_estado, @n_orden, @f_orden;
	END;
	CLOSE TrigDelCur;
	DEALLOCATE TrigDelCur;
END
GO

-- PUNTO 15
BEGIN TRANSACTION
	DELETE FROM orders WHERE order_num = 1004;
	--PUNTO 16. SE BORRARON....
	SELECT * FROM orders; 
	SELECT * FROM items;
ROLLBACK TRANSACTION
-- PUNTO 17 ^ SE RESTAURÓ
GO