IF OBJECT_ID('dbo.CustomerStatistics', 'U') IS NOT NULL
    DROP TABLE dbo.CustomerStatistics;
IF OBJECT_ID('dbo.informeStock', 'U') IS NOT NULL
    DROP TABLE dbo.informeStock;
IF OBJECT_ID('dbo.CustomerStatisticsUpdate', 'P') IS NOT NULL
    DROP PROCEDURE dbo.CustomerStatisticsUpdate;
IF OBJECT_ID('dbo.generarInformeGerencial', 'P') IS NOT NULL
    DROP PROCEDURE dbo.generarInformeGerencial;

CREATE TABLE CustomerStatistics(
	customer_num SMALLINT IDENTITY(1,1) PRIMARY KEY,
	ordersQty INT,
	maxDate DATE,
	productsQty INT); GO

CREATE PROCEDURE CustomerStatisticsUpdate(@fecha_des DATE)
AS
BEGIN
	DECLARE CurStatisticsUpdate CURSOR FOR
	SELECT customer_num FROM customer;

	DECLARE @customer_num SMALLINT,
		@ordersQty INT,
		@maxDate DATE,
		@productsQty INT;
	OPEN CurStatisticsUpdate;
	FETCH NEXT FROM CurStatisticsUpdate INTO @customer_num

	WHILE @@FETCH_STATUS = 0
	BEGIN
		SELECT @ordersQty = count(*), @maxDate = max(order_date)
		FROM orders WHERE customer_num = @customer_num AND order_date >= @maxDate;

		SELECT @productsQty = COUNT (*)
		FROM (SELECT DISTINCT stock_num, manu_code FROM items i
				JOIN orders o ON o.order_num = i.order_num
				WHERE o.customer_num = @customer_num) A;

		IF NOT EXISTS (SELECT 1 FROM CustomerStatistics WHERE customer_num = @customer_num)
			INSERT INTO CustomerStatistics(customer_num, ordersQty, maxDate, productsQty)
			VALUES(@customer_num, @ordersQty, @maxDate, @productsQty);
		ELSE
			UPDATE CustomerStatistics
				SET ordersQty = ordersQty + @ordersQty,
					maxDate = @maxDate,
					productsQty = @productsQty
				WHERE customer_num = @customer_num
		CLOSE CurStatisticsUpdate;
		DEALLOCATE CurStatisticsUpdate;
	END
END
GO

CREATE TABLE InformeStock(
	fechaInforme DATE,
	stock_num SMALLINT,
	manu_code VARCHAR(3),
	cantOrdenes INT,
	UltCompra DATE,
	cantClientes INT,
	totalVentas DECIMAL
	
	CONSTRAINT pk_informeStock
	PRIMARY KEY (fechaInforme, stock_num, manu_code)
); GO

CREATE PROCEDURE generarInformeGerencial(@fechaInforme DATE)
AS
BEGIN
	DECLARE CurProducts CURSOR FOR
	SELECT * FROM products;

	DECLARE @stock_num SMALLINT, @manu_code VARCHAR(3), @cantOrdenes INT,
		@ultCompra DATE, @cantClientes INT, @totalVentas DECIMAL

	OPEN CurProducts;
	FETCH NEXT FROM CurProducts INTO @fechaInforme;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM InformeStock WHERE fechaInforme = @fechaInforme)
			THROW 203, 'fechaInforme ya existente', 1;
	
		-- consigo stock_num
		SELECT DISTINCT * FROM products p JOIN items i ON p.stock_num = i.stock_num

		SELECT @cantClientes = COUNT(*) , @totalVentas = COUNT(*) * i.unit_price 
		FROM orders o JOIN items i ON o.order_num = i.order_num
		JOIN products p ON p.

		SELECT @cantOrdenes = count(*), @ultCompra = max(order_date) FROM products p
		JOIN orders o ON p.stock_num = @stock_num -- ?
		WHERE stock_num = @stock_num
			
		INSERT INTO InformeStock(fechaInforme, stock_num, manu_code, cantOrdenes,
				UltCompra, cantClientes, totalVentas)
		VALUES(@fechaInforme, @stock_num, @manu_code, @cantClientes,
				@ultCompra, @cantClientes, @totalVentas)
	END
	CLOSE CurProducts;
	DEALLOCATE CurProducts;

END
GO