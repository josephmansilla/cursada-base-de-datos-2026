SELECT lname+' '+fname, c.customer_num
FROM customer c
JOIN cust_calls cc 
	ON c.customer_num = cc.customer_num
	GROUP BY c.customer_num, c.lname, c.fname
	HAVING COUNT(*) > 1


SELECT COUNT(*)
FROM customer c1
INNER JOIN customer c2 ON c1.city = c2.city
WHERE c2.lname = 'Higgins'

