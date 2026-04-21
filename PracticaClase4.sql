-- 1)
SELECT * 
INTO #clientes
FROM customer;

-- 2)
INSERT INTO #clientes (customer_num, fname, lname, company, address1, address2, city, state, zipcode, phone, customer_num_referedBy, status)
VALUES (144, 'Agustín', 'Creevy', 'Jaguares SA', null, null, 'Los Angeles', 'CA', null,null,null,null);
-- DROP TABLE #clientes 

-- 3)
SELECT * 
INTO #clientesCalifornia
FROM customer
WHERE state = 'CA';

SELECT * FROM #clientesCalifornia
DROP TABLE #clientesCalifornia 

-- 4) 
UPDATE #clientes
SET customer_num = 155
WHERE customer_num = 112;

SELECT * FROM #clientes
WHERE customer_num = 155;

-- 5)
-- SELECT * FROM #clientes;
DELETE FROM #clientes
WHERE zipcode >= 94000 AND zipcode <= 94050 AND city LIKE 'M%';
-- SELECT * FROM #clientes;

-- 6) 

UPDATE #clientes
SET state = 'AK', address2 = 'Barrio Las Heras'
WHERE state = 'CO'


-- 7)
SELECT * FROM #clientes;
UPDATE #clientes
SET phone = '+1 ' + phone;
SELECT * FROM #clientes;

DROP TABLE #clientes;