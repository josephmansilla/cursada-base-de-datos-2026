-- PUNTO 3 - QUERY


SELECT p.estado, p.numero_cliente, p.nombre_completo, p.monto_total_comprado
FROM 
(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY estado ORDER BY monto_total_comprado DESC) as ranking
	FROM (SELECT  cus.state AS estado,
			  ord.customer_num AS numero_cliente,
		      fname + ' ' + lname AS nombre_completo,
		      SUM(i.quantity * i.unit_price) AS monto_total_comprado
		FROM orders ord
			JOIN customer cus ON (cus.customer_num = ord.customer_num)
			JOIN items i ON (i.order_num = ord.order_num)
		GROUP BY cus.state, ord.customer_num, fname, lname) t1
	
) p
WHERE ranking <= 2
ORDER BY estado, monto_total_comprado DESC;
-- PUNTO 4 - PROCEDURE

CREATE TABLE audit_products(
	id_audit BIGINT PRIMARY KEY IDENTITY(1,1),
	stock_num SMALLINT,
	manu_code CHAR(3),
	message VARCHAR(255)
);

CREATE TABLE productos_deprecados(
	stock_num SMALLINT,
	manu_code CHAR(3)
	CONSTRAINT PK_deprecados PRIMARY KEY (stock_num, manu_code)
);

ALTER TABLE products
ADD status CHAR;

GO
CREATE PROCEDURE borrar_deprecados
AS BEGIN 
	
	DECLARE cur_borrado CURSOR FOR --> es necesario usar un cursor? para mi !,,,,,, posiblemente... pero no se como se podria hacer la parte de auditoria
	SELECT stock_num, manu_code FROM productos_deprecados;

	DECLARE @stock_num SMALLINT; DECLARE @manu_code CHAR(3);
	 
	OPEN cur_borrado;
	
	FETCH FROM cur_borrado
	INTO @stock_num, @manu_code;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
	BEGIN TRANSACTION
	BEGIN TRY 
		
		IF EXISTS (SELECT * FROM products WHERE status = 'D' AND @stock_num = stock_num AND @manu_code = manu_code)
			THROW 50010, 'PRODUCTO YA DEPRECADO', 16; --> en caso de ya estar deprecado, tiramos error y nos vamos al catch
		IF NOT EXISTS (SELECT * FROM products WHERE @stock_num = stock_num AND @manu_code = manu_code)
			THROW 50011, 'PRODUCTO NO EXISTE', 16; --> manejo de error por ahi de más...

		UPDATE products
		SET status = 'D' 
		WHERE stock_num = @stock_num AND @manu_code = manu_code;

		IF EXISTS (SELECT order_num, item_num
				   FROM products p JOIN items it ON (p.manu_code = it.manu_code AND p.stock_num = it.stock_num)
				   WHERE p.stock_num = @stock_num AND @manu_code = p.manu_code)
		BEGIN
			INSERT INTO audit_products (stock_num, manu_code, message)
			VALUES (@stock_num, @manu_code, 'DEPRECADO CON VENTAS'); --> insertamos si tiene ventas
		END;
		ELSE BEGIN
			INSERT INTO audit_products (stock_num, manu_code, message)
			VALUES (@stock_num, @manu_code, 'DEPRECADO'); --> insertamos si no tiene ventas
		END;

		COMMIT TRANSACTION;
	END TRY 
	BEGIN CATCH
		ROLLBACK TRANSACTION --> deshacemos
		INSERT INTO audit_products (stock_num, manu_code, message)
		VALUES (@stock_num, @manu_code, ERROR_MESSAGE()) --> insertamos el error
	END CATCH

		FETCH NEXT FROM cur_borrado
		INTO @stock_num, @manu_code; 
	END;

	CLOSE cur_borrado;
	DEALLOCATE cur_borrado;
END;
GO


-- PUNTO 5 - TRIGGER 

CREATE TABLE precios_hist(
	stock_num SMALLINT,
	manu_code SMALLINT,
	fechaDesde DATETIME DEFAULT(CAST('2000-01-01' AS DATETIME)),
	fechaHasta DATETIME,
	precio_unit DECIMAL(6,2)
);
GO

CREATE TRIGGER tgr_cambio_precio
ON products
AFTER UPDATE AS
BEGIN
	IF NOT UPDATE(unit_price) BEGIN RETURN END;

	INSERT INTO precios_hist
	SELECT stock_num, 
		   manu_code, 
		   (SELECT ISNULL(MAX(fechaHasta), CAST('2000-01-01' AS DATETIME)) 
			FROM precios_hist ph2 
			WHERE ph2.stock_num = stock_num AND manu_code = ph2.manu_code), 
		   GETDATE(), 
		   unit_price 
	FROM deleted d1
END;
GO

-- forma mejorada, pero no necesaria para el parcial!

CREATE TRIGGER tgr_cambio_precio_v2
ON products
AFTER UPDATE AS
BEGIN
	IF NOT UPDATE(unit_price) BEGIN RETURN END;
	INSERT INTO precios_hist
	SELECT d1.stock_num, 
		   d1.manu_code, 
		   ISNULL(ultima_fecha, CAST('2001-01-01' AS DATETIME)),
		   GETDATE(), 
		   unit_price 
	FROM deleted d1
		LEFT JOIN 
		(
			SELECT stock_num,
				   manu_code,
				   MAX(fechaDesde) AS ultima_fecha
			FROM precios_hist
			GROUP BY stock_num, manu_code	
		) ph
		ON (d1.stock_num = ph.stock_num AND d1.manu_code = ph.manu_code)
	
END;
GO


-- forma incorrecta de hacer este trigger...

CREATE TRIGGER tgr_cambio_precio_v3_cursors
ON products
AFTER UPDATE AS
BEGIN
	DECLARE cur_precio CURSOR FOR 
	SELECT stock_num, manu_code, unit_price FROM inserted;
	
	DECLARE @stock_num SMALLINT; DECLARE @manu_code CHAR(3); 
	DECLARE @fechaDesde DATETIME; DECLARE @unit_price DECIMAL(6,2);

	OPEN cur_precio;

	FETCH FROM cur_precio
	INTO @stock_num, @manu_code, @unit_price

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		SELECT @fechaDesde = ISNULL(MAX(fechaHasta), CAST('2000-01-01' AS DATETIME)) FROM precios_hist WHERE stock_num = @stock_num AND @manu_code = manu_code

		INSERT INTO precios_hist (stock_num, manu_code, fechaDesde, fechaHasta, precio_unit)
		VALUES (@stock_num, @manu_code, @fechaDesde, GETDATE(), @unit_price)

		FETCH NEXT FROM cur_precio
		INTO @stock_num, @manu_code, @unit_price
	END;

	CLOSE cur_precio;
	DEALLOCATE cur_precio;
END;
GO
