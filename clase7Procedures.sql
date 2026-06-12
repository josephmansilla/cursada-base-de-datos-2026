/*========================================================
  DROP TABLES IF EXISTS
========================================================*/

IF OBJECT_ID('dbo.CustomerStatistics', 'U') IS NOT NULL
    DROP TABLE dbo.CustomerStatistics;

IF OBJECT_ID('dbo.informeStock', 'U') IS NOT NULL
    DROP TABLE dbo.informeStock;


/*========================================================
  DROP PROCEDURES IF EXISTS
========================================================*/

IF OBJECT_ID('dbo.actualizaEstadisticas', 'P') IS NOT NULL
    DROP PROCEDURE dbo.actualizaEstadisticas;

IF OBJECT_ID('dbo.generarInformeGerencial', 'P') IS NOT NULL
    DROP PROCEDURE dbo.generarInformeGerencial;



CREATE TABLE CustomerStatistics(
	customer_num SMALLINT PRIMARY KEY IDENTITY(1,1),
	ordersqty INTEGER,
	maxdate DATE,
	uniqueProducts INTEGER
);
GO

CREATE PROCEDURE actualizaEstadisticas (@customer_numDES SMALLINT, @customer_numHAS SMALLINT)
AS BEGIN
	DECLARE CustomerCursor CURSOR FOR
	SELECT customer_num FROM customer WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS
	
	DECLARE @customer_num SMALLINT, @ordersqty INT, @maxdate DATE, @uniqueProducts INT;
	OPEN CustomerCursor;
	FETCH NEXT FROM CustomerCursor INTO @customer_num
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @ordersqty = COUNT(DISTINCT order_num), @maxdate = max(order_date)
		FROM orders o 
		WHERE o.customer_num = @customer_num;

		SELECT @uniqueProducts = COUNT(DISTINCT item_num)
		FROM items i
				JOIN orders o2 ON o2.order_num = i.order_num
		WHERE @customer_num = o2.customer_num;

		IF NOT EXISTS (SELECT 1 FROM CustomerStatistics WHERE @customer_num = customer_num)
		BEGIN
			INSERT INTO CustomerStatistics VALUES (@customer_num, @ordersqty, @maxdate, @uniqueProducts)
		END
		ELSE
		BEGIN
			UPDATE CustomerStatistics SET ordersqty=@ordersqty, maxdate=@maxdate, uniqueProducts=@uniqueProducts
				WHERE customer_num = @customer_num;
		END
		FETCH NEXT FROM CustomerCursor INTO @customer_num;
	END;

	CLOSE CustomerCursor;
	DEALLOCATE CustomerCursor;
END;
GO

SELECT * INTO customer_modificada FROM customer WHERE state = 'CA';
SELECT * INTO ClientesCalifornia FROM customer_modificada WHERE state = 'CA';
GO




SELECT cus.customer_num, fname, lname, company, 
address1, address2, city, state, zipcode, phone
INTO ClientesNoCaBaja 
FROM customer cus
		JOIN orders ord ON ord.customer_num = cus.customer_num
		JOIN items it ON it.order_num = ord.order_num
WHERE state != 'CA'
HAVING SUM(quantity * unit_price) > 999;
GO

ALTER TABLE customer_modificada ADD status CHAR(1);
GO
-- ====== PUNTO B ======
CREATE PROCEDURE migraClientes (@customer_numDES SMALLINT, @customer_numHAS SMALLINT)
AS BEGIN 
	BEGIN TRY
	DECLARE MigrationCursor CURSOR FOR
	SELECT customer_num FROM customer WHERE customer_num BETWEEN @customer_numDES AND @customer_numHAS;

	DECLARE @customer_num SMALLINT, @fname VARCHAR(15), @lname VARCHAR(15),
	@company VARCHAR(20), @address1 VARCHAR(20), @address2 VARCHAR(20), 
	@city VARCHAR(15), @state CHAR(2), @zipcode CHAR(5), @phone VARCHAR(18);


	OPEN MigrationCursor;
	FETCH NEXT FROM MigrationCursor INTO @customer_num;
	WHILE @@FETCH_STATUS = 0
	

	END TRY

	BEGIN CATCH
	CLOSE MigrationCursor;
	DEALLOCATE MigrationCursor;
	END CATCH
	
	
END;

BEGIN TRANSACTION
ROLLBACK TRANSACTION 