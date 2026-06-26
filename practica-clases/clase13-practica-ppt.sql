--1. Seleccionar los datos de todas las exportaciones de los países ordenados por fecha. Mostrar el continente,
--país, fecha, monto acumulado y total del país y en otra columna el total del continente al que pertenece
--dicho país.

Select Continente,  p.Pais, e.fechaExpo, e.cantidad, 
            sum(cantidad) over 
                     (partition by p.IdPais ORDER BY e.fechaExpo) Acumulado,
			sum(cantidad) over 
                     (partition by p.IdPais) Total,
            sum(cantidad) over 
                     (partition by p.IdContinente)  'Total continente'
  from paises p join exportaciones e 
                 on p.IdPais = e.Idpais
ORDER BY pais, e.fechaExpo;


--2. Mostar las cantidades totales de Exportaciones de los países y para cada país el promedio del mes
--corriente, mes anterior y mes siguiente a la fecha de exportación

Select p.Continente,  p.Pais, e.fechaExpo, 
       LAG(cantidad) OVER (PARTITION BY pais
                          ORDER BY fechaExpo) "Cantidad Anterior",
       cantidad,
	   LEAD(cantidad) OVER (PARTITION BY pais
                          ORDER BY fechaExpo) "Cantidad Posterior",
       avg(cantidad) over
         (partition by pais order by fechaExpo
           ROWS BETWEEN 1 PRECEDING and 1 FOLLOWING) promedio,
	   sum(cantidad) over (partition by p.IdPais) Total
  from paises p join exportaciones e 
                 on p.IdPais = e.Idpais
order by 1, 2, 3;

--3. Numerar los países del mundo ordenados por monto total exportado, y rankearlos por ambos tipos de
--ranking.

Select p.Pais,
       ROW_NUMBER() OVER (ORDER BY SUM(E.montoTotal) DESC) Nro,
       RANK() OVER (ORDER BY SUM(E.montoTotal) DESC) Ranking,
       DENSE_RANK() OVER (ORDER BY SUM(E.montoTotal) DESC) Denso,
 	  sum(montoTotal) TOTAL
  from paises p join exportaciones e on p.IdPais = e.Idpais
group by p.Pais
ORDER BY total desc;



--4. Mostrar el percentil 20 para la sumatoria total de unidades vendidas por cada país. Las países deberán
--estar ordenados por las cantidades totales vendidas ordenadas de mayor a menor.

-- alternativa 1
SELECT pais, SUM(montoTotal) Montos,
       PERCENTILE_CONT(0.2) 
           WITHIN GROUP(ORDER BY sum(montoTotal) desc)
                          OVER () AS perCont,
       PERCENTILE_DISC(0.2) 
           WITHIN GROUP(ORDER BY sum(montoTotal) desc)  
                          OVER () AS perDisc
 FROM paises p join exportaciones e  
              on e.IdPais = p.IdPais
GROUP BY pais

-- alternativa 2
SELECT pais, SUM(montoTotal) Montos,
       PERCENTILE_CONT(0.2) 
           WITHIN GROUP(ORDER BY sum(montoTotal) desc)
                          OVER () AS perCont,
       PERCENTILE_DISC(0.2) 
           WITHIN GROUP(ORDER BY sum(montoTotal) desc)  
                          OVER () AS perDisc
 FROM paises p join exportaciones e  
              on e.IdPais = p.IdPais;