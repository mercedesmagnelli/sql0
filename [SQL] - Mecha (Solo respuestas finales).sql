/*
1. Mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o
igual a $ 1000 ordenado por c�digo de cliente.
*/

SELECT 
	clie_codigo, 
	clie_razon_social
FROM Cliente 
WHERE
clie_limite_credito >= 1000
ORDER BY  clie_codigo

/*
2. Mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
cantidad vendida.
*/

SELECT 
p.prod_codigo as [CODIGO PRODUCTO], 
p.prod_detalle as [CODIGO DETALLE] 
FROM 
Item_Factura it INNER JOIN Producto p ON p.prod_codigo = it.item_producto
INNER JOIN Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero
WHERE YEAR(fact_fecha) = 2012 
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY sum(item_cantidad)

/*
3. Realizar una consulta que muestre c�digo de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del art�culo de menor a mayor.
*/


SELECT 
p.prod_codigo as [CODIGO PRODUCTO], 
p.prod_detalle as [NOMBRE PRODUCTO],
ISNULL(sum(s.stoc_cantidad),0) as [STOCK]
FROM STOCK s RIGHT JOIN Producto p on s.stoc_producto = p.prod_codigo
group by p.prod_codigo, p.prod_detalle
order by p.prod_detalle DESC



/*
4. Realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
promedio por dep�sito sea mayor a 100.
*/

-- estoy parada en los c�digos m�s "grandes", entonces al joinear con la que me da los procutos que la componen, me pueden dar dos posibilidades
-- a) null -> no existe un producto compuesto con ese codigo, entonces no tiene productos que lo compongan 
-- b) xxxxx -> codigo de los productos que lo componen (comp_componente). 

-- tengo que contar los comp_componentes que resulten del join. pongo distinct por "inercia" pero en realidad creo que es un tema de atomicidad (ver luego)
SELECT 
	pr.prod_codigo as [CODIGO PRODUCTO], 
	pr.prod_detalle as [DETALLE PRODUCTO],
	COUNT(distinct c.comp_componente) as [CANTIDAD DE PROD QUE LO COMPONEN]
FROM 
	Producto pr left join Composicion c on pr.prod_codigo = c.comp_producto
	join STOCK s on s.stoc_producto = pr.prod_codigo
group by pr.prod_codigo, pr.prod_detalle
having AVG(s.stoc_cantidad) > 100 
-- and pr.prod_codigo ='00010417'
order by 3 desc


/*
5. Realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.
*/

SELECT 
	p.prod_codigo as [CODIGO ARTICULO], 
	p.prod_detalle as [DETALLE],
	sum(it.item_cantidad) as [EGRESOS]
FROM Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
JOIN Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero
where YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_codigo, p.prod_detalle
		HAVING sum(it.item_cantidad) > 
		isnull((SELECT SUM(it2.item_cantidad) 
		FROM Item_Factura it2 join Factura f2 on f2.fact_tipo + f2.fact_sucursal + f2.fact_numero = it2.item_tipo + it2.item_sucursal + it2.item_numero 
		where it2.item_producto = p.prod_codigo and YEAR(f2.fact_fecha) = 2011
		group by it2.item_producto
),0)


/*
6. Mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese
rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que
tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.
*/

SELECT 
	p.prod_rubro as [RUBRO], 
	r.rubr_detalle as [DETALLE], 
	COUNT(distinct p.prod_codigo) as [CANTIDAD PRODS EN RUBRO], 
	SUM(s.stoc_cantidad) AS [CANTIDAD STOCK DEL RUBRO]
FROM Producto p join Rubro r on r.rubr_id = p.prod_rubro
JOIN STOCK s on s.stoc_producto = p.prod_codigo
GROUP BY p.prod_rubro, r.rubr_detalle
HAVING SUM(s.stoc_cantidad) > (
	SELECT s1.stoc_cantidad FROM STOCK s1 
	where s1.stoc_deposito = '00' and s1.stoc_producto = '00000000'
) order by p.prod_rubro


/*
7. Generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos art�culos que posean
stock.
*/

-- que los articulos tengan stock lo pienso como que la suma de todos las cantidades x deposito > 0 

--asi me genera que los que nunca se vendieron, entren en la lista, esto ser�a esperado? 
SELECT 
	P.prod_codigo as [CODIGO], 
	P.prod_detalle as [DETALLE], 
	MAX(it.item_precio) as [PRECIO MAX], 
	MIN(it.item_precio) as [PRECIO MIN], 
	100*((MAX(it.item_precio)- MIN(it.item_precio))/MIN(item_precio)) as [PORCENTAJE INCREMENTO]
FROM 
	STOCK s JOIN Producto P on P.prod_codigo = s.stoc_producto
	left JOIN Item_Factura it on it.item_producto = P.prod_codigo
WHERE (
	SELECT sum(s1.stoc_cantidad) FROM STOCK s1 JOIN Producto p1 ON s1.stoc_producto = p1.prod_codigo

	GROUP BY p1.prod_codigo
	having p1.prod_codigo = P.prod_codigo

) > 0
GROUP BY 
	P.prod_codigo, P.prod_detalle
------------------------------------------

--de esta forma, lo que hago es evaluar los que se vendieron y tienen stock 
SELECT 
	P.prod_codigo as [CODIGO], 
	P.prod_detalle as [DETALLE], 
	MAX(it.item_precio) as [PRECIO MAX], 
	MIN(it.item_precio) as [PRECIO MIN], 
	100*((MAX(it.item_precio)- MIN(it.item_precio))/MIN(item_precio)) as [PORCENTAJE INCREMENTO]
FROM 
	STOCK s JOIN Producto P on P.prod_codigo = s.stoc_producto
	JOIN Item_Factura it on it.item_producto = P.prod_codigo
WHERE (
	SELECT sum(s1.stoc_cantidad) FROM STOCK s1 JOIN Producto p1 ON s1.stoc_producto = p1.prod_codigo

	GROUP BY p1.prod_codigo
	having p1.prod_codigo = P.prod_codigo

) > 0
GROUP BY 
	P.prod_codigo, P.prod_detalle





/*
8. Mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del
art�culo, stock del dep�sito que m�s stock tiene.
*/


SELECT DISTINCT 
s.stoc_producto as [PRODUCTO], 
( 
	SELECT TOP 1 s1.stoc_cantidad FROM Producto p1 JOIN STOCK s1 on s1.stoc_producto = p1.prod_codigo  
	where s.stoc_producto = s1.stoc_producto
	group by  p1.prod_codigo, s1.stoc_cantidad
	order by s1.stoc_cantidad DESC
) as [STOCK MAXIMO]
FROM Producto p JOIN STOCK s on s.stoc_producto = p.prod_codigo
where s.stoc_producto in (
		SELECT prod_codigo FROM Producto p2 JOIN STOCK s2 on s2.stoc_producto = p2.prod_codigo  
		where p2.prod_codigo = p.prod_codigo
		group by p2.prod_codigo
		--HAVING COUNT(stoc_deposito) = (SELECT COUNT(*) FROM DEPOSITO)
		HAVING COUNT(stoc_deposito) = 12
) order by 1


/*
9. Mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de dep�sitos que ambos tienen asignados.

*/


/*
10. Mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos
vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que
mayor compra realizo.
*/

/*
Ejercicio 11: realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deber�n
ordenar de mayor a menor, por la familia que m�s productos diferentes vendidos tenga,
solo se deber�n mostrar las familias que tengan una venta superior a 20000 pesos para
el a�o 2012.*/


SELECT
    f.fami_detalle AS 'Detalle de familia',
    COUNT(DISTINCT p.prod_codigo) AS 'Cantidad de diferentes productos', 
    (SELECT SUM(fac.fact_total - fac.fact_total_impuestos) 
    FROM Producto p
    JOIN Item_Factura i ON p.prod_codigo = i.item_producto
    JOIN Factura fac ON i.item_numero = fac.fact_numero AND i.item_sucursal = fac.fact_sucursal AND i.item_tipo = fac.fact_tipo
    WHERE p.prod_familia = f.fami_id
    ) AS 'Total ventas por familia'
FROM Familia f
JOIN Producto p ON f.fami_id = p.prod_familia
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
GROUP BY f.fami_detalle, f.fami_id
HAVING (SELECT SUM(fac.fact_total) -- Es la misma consulta que el subselect pero sin los impuestos pq no se puede reutilizar el alias :P
        FROM Producto p
        JOIN Item_Factura i ON p.prod_codigo = i.item_producto
        JOIN Factura fac ON i.item_numero = fac.fact_numero AND i.item_sucursal = fac.fact_sucursal AND i.item_tipo = fac.fact_tipo
        WHERE p.prod_familia = f.fami_id AND YEAR(fac.fact_fecha) = 2012) > 20000 
ORDER BY COUNT(DISTINCT p.prod_codigo) DESC


/*
Ejercicio 12: mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de dep�sitos en los cuales hay stock del
producto y stock actual del producto en todos los dep�sitos. Se deber�n mostrar
aquellos productos que hayan tenido operaciones en el a�o 2012 y los datos deber�n
ordenarse de mayor a menor por monto vendido del producto.
*/

SELECT 
	p.prod_codigo as [CODIGO PRODUCTO], 
	p.prod_detalle as [DETALLE],
	COUNT(distinct f.fact_cliente) as [CANTIDAD DE CLIENTES],
	AVG(it.item_precio) AS [IMPORTE PROMEDIO], 
	(
			SELECT count(s1.stoc_deposito) FROM
			STOCK s1 
			where s1.stoc_cantidad > 0 
			AND s1.stoc_producto = p.prod_codigo
			group by s1.stoc_producto

	) AS [CANTIDAD DE DEPOSITOS CON STOCK], 
	(
		SELECT sum(s2.stoc_cantidad)
		FROM STOCK s2 
		where s2.stoc_producto = p.prod_codigo -- si quiero joinear con s.stoc_producto me obliga a agrupar por stoc_producto (es necesario que se vinculen los campos de la query gral con lo del subselect con elementos de la misma tabla?)
		group by s2.stoc_producto

	) AS [STOCK ACTUAL DEL PRODUCTO], 
	SUM(item_cantidad * it.item_precio) as [COLUMNA CONTROL]
FROM
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 

where YEAR(f.fact_fecha) = 2012
group by 
	p.prod_codigo, p.prod_detalle
ORDER BY 
	SUM(item_cantidad * it.item_precio)  DESC


---- version sin hacer dos subconsultas, pero me genera m�s stock pq me aumenta la atomicidad el join con las tablas 
SELECT 
	p.prod_codigo as [CODIGO PRODUCTO], 
	COUNT(distinct f.fact_cliente) as [CANTIDAD DE CLIENTES],
	AVG(it.item_precio) AS [IMPORTE PROMEDIO], 
	(SELECT count(s1.stoc_deposito) FROM
			STOCK s1 
			where s1.stoc_cantidad > 0 
			AND s1.stoc_producto = p.prod_codigo
			group by s1.stoc_producto
	) AS [CANTIDAD DE DEPOSITOS CON STOCK], 
	SUM(s.stoc_cantidad) AS [STOCK ACTUAL DEL PRODUCTO]	
FROM
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
	JOIN STOCK s on s.stoc_producto = p.prod_codigo
--where prod_codigo = '00000102'
group by 
	p.prod_codigo
ORDER BY SUM(item_cantidad * it.item_precio) DESC
	

--- MONTO VENDIDO DEL PRODUCTO 
SELECT 
p.prod_codigo, 
SUM(item_cantidad * it.item_precio)
FROM
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
	GROUP BY prod_codigo--, item_cantidad, item_precio
order by 1

select 
p.prod_codigo,
SUM(item_cantidad * it.item_precio)
FROM
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
	where prod_codigo = '00000302'
group by prod_codigo
order by 1


/*
EJERCICIO13: Realizar una consulta que retorne para cada producto que posea composici�n nombre
	del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
	de los productos que lo componen. Solo se deber�n mostrar los productos que est�n
	compuestos por m�s de 2 productos y deben ser ordenados de mayor a menor por
	cantidad de productos que lo componen.
*/



SELECT
	p.prod_codigo as [NOMBRE],
	p.prod_detalle as [DETALLE], 
	p.prod_precio as [PRECIO],
	SUM(p2.prod_precio * c.comp_cantidad) as [SUMA DE PRECIO * CANTIDAD]
FROM 
	Composicion c join Producto p on p.prod_codigo = c.comp_producto
	JOIN Producto p2 on p2.prod_codigo = c.comp_componente
GROUP BY 
p.prod_codigo, p.prod_detalle, p.prod_precio
HAVING 
	COUNT(*) > 2 -- cuenta las filas de cada grupo 


	
/*
EJERCICIO 14:

Escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que
debe retornar son:
C�digo del cliente
Cantidad de veces que compro en el �ltimo a�o
Promedio por compra en el �ltimo a�o
Cantidad de productos diferentes que compro en el �ltimo a�o
Monto de la mayor compra que realizo en el �ltimo a�o
Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en
el �ltimo a�o.
No se deber�n visualizar NULLs en ninguna columna

*/



SELECT c.clie_codigo AS 'C�digo de cliente',
       COUNT(DISTINCT (f.fact_numero + f.fact_sucursal + f.fact_tipo)) AS 'Cantidad de veces que compr� en el �ltimo a�o', --OBS. 14 a
       ISNULL(AVG(ISNULL(f.fact_total, 0)), 0) AS 'Promedio por compra en el �ltimo a�o',
       COUNT(DISTINCT i.item_producto) AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
       ISNULL(MAX(f.fact_total), 0) AS 'Monto de la mayor compra que realiz� en el �ltimo a�o'
FROM Cliente c
LEFT JOIN Factura f ON c.clie_codigo = f.fact_cliente
LEFT JOIN Item_Factura i ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY c.clie_codigo
ORDER BY [Cantidad de veces que compr� en el �ltimo a�o] dESC


/*
EJERCICIO 15


*/


/*
16. Con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que m�s se vendi� en el 2012.
Adem�s mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. C�digo de producto que mayor venta tuvo en el 2012 (en caso de existir m�s de 1,
mostrar solamente el de menor c�digo) para ese cliente.
Aclaraciones:
La composici�n es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por c�digo de provincia ascendente.
*/

/*Ejercicio 17*/


/*Ejercicio 18: escriba una consulta que retorne una estadística de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: Código del producto más vendido de dicho rubro
PROD2: Código del segundo producto más vendido de dicho rubro
CLIENTE: Código del cliente que compro más productos del rubro en los últimos 30
días
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/


SELECT rubr_detalle AS 'DETALLE_RUBRO',
	   SUM(item_cantidad * item_precio) AS 'VENTAS',
	   ISNULL((SELECT TOP 1 prod_codigo FROM Producto
              JOIN Item_Factura ON prod_codigo = item_producto
              WHERE prod_rubro = rubr_id
              GROUP BY prod_codigo
              ORDER BY SUM(item_cantidad) DESC), 'No existe') AS 'PROD1',
	   ISNULL((SELECT TOP 1 prod_codigo FROM Producto
              JOIN Item_Factura ON prod_codigo = item_producto
              WHERE prod_rubro = rubr_id AND prod_codigo != (SELECT TOP 1 prod_codigo FROM Producto
														     JOIN Item_Factura ON prod_codigo = item_producto
            											     WHERE prod_rubro = rubr_id
             											     GROUP BY prod_codigo
             											     ORDER BY SUM(item_cantidad) DESC)
           	  GROUP BY prod_codigo
              ORDER BY SUM(item_cantidad) DESC), 'No existe') AS 'PROD2',
	   ISNULL((SELECT TOP 1 fact_cliente
	          FROM Factura
              JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
              JOIN Producto ON item_producto = prod_codigo
              WHERE prod_rubro = rubr_id AND fact_fecha BETWEEN (SELECT MAX(fact_fecha) - 30 FROM Factura) AND (SELECT MAX(fact_fecha) FROM Factura)
              GROUP BY fact_cliente
              ORDER BY SUM(item_cantidad) DESC), 'No existe') AS 'CLIENTE'
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
JOIN Item_Factura ON prod_codigo = item_producto
GROUP BY rubr_detalle, rubr_id


/*Ejercicio 19: en virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto

- Detalle del producto

- Codigo de la familia del producto

- Detalle de la familia actual del producto

- Codigo de la familia sugerido para el producto

- Detalle de la familia sugerido para el producto

La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/


-- NO ENTIENDO A QUÉ SE REFIERE EL ENUNCIADO

SELECT 
	p.prod_codigo as [CODIGO PRODUCTO], 
	p.prod_detalle as [DETALLE PRODUCTO], 
	p.prod_familia as [CODIGO FAMILIA ACTUAL], 
	f.fami_detalle as [DETALLE FAMILIA ACTUAL], 
	1 as [CODIGO FAMILIA SUGERIDA], 
	2 as [DETALLE FAMILIA PRODUCTO]
FROM 
Producto p JOIN Familia F on P.prod_familia = f.fami_id


/*Ejercicio 20: escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el a�o, para los que tengan menos de 50
facturas en el a�o el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho a�o.*/

SELECT TOP 3
	e.empl_codigo as [LEGAJO],
	e.empl_nombre as [NOMBRE], 
	e.empl_apellido as [APELLIDO], 
	year(e.empl_ingreso) as [ANIO INGRESO], 
	(
			case when count(fact_numero) >= 50 then (select count(fact_numero) FROM 
														Factura f1
														where f1.fact_total > 100 and f1.fact_vendedor = e.empl_codigo and  year(f1.fact_fecha) = 2011)
				ELSE  0.5 * (select count(fact_numero) from Factura f2  where year(f2.fact_fecha) = 2011 and f2.fact_vendedor in (select empl_codigo from Empleado em  where em.empl_jefe = e.empl_codigo)) 
				end 			
			
	)   as [PUNTAJE 2011], 
	(
			case when count(fact_numero) >= 50 then (select count(fact_numero) FROM 
														Factura f1
														where f1.fact_total > 100 and f1.fact_vendedor = e.empl_codigo and  year(f1.fact_fecha) = 2012)
				ELSE  0.5 * (select count(fact_numero) from Factura f2  where year(f2.fact_fecha) = 2012 and f2.fact_vendedor in (select empl_codigo from Empleado em  where em.empl_jefe = e.empl_codigo)) 
				end 			
			
)
		 as [PUNTAJE 2012]
FROM 
Empleado e join Factura f on f.fact_vendedor = e.empl_codigo 
group by e.empl_codigo, e.empl_codigo,
	e.empl_nombre, 
	e.empl_apellido, 
	year(e.empl_ingreso) 
order by 5 desc


/*
Ejercicio 21. Escriba una consulta sql que retorne para todos los años, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta
al menos una factura y que cantidad de facturas se realizaron de manera incorrecta. Se
considera que una factura es incorrecta cuando la diferencia entre el total de la factura
menos el total de impuesto tiene una diferencia mayor a $ 1 respecto a la sumatoria de
los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar
son:
 Año
 Clientes a los que se les facturo mal en ese año
 Facturas mal realizadas en ese año
*/
-- FALTA TESTEAR 
SELECT 
	 datename(year, f3.fact_fecha) as [ANIO], 
	COUNT(distinct f3.fact_cliente) as [CLIENTES MAL FACTURADOS], 
	COUNT (f3.fact_numero + f3.fact_sucursal + f3.fact_tipo) AS [FACTURAS MAL REALIZADAS]
	
FROM Item_Factura it3
JOIN Factura f3 ON it3.item_numero = f3.fact_numero AND it3.item_sucursal = f3.fact_sucursal AND it3.item_tipo = f3.fact_tipo
where(fact_total - fact_total_impuestos) - (SELECT SUM(item_cantidad * item_precio) FROM Item_Factura it2
											JOIN Factura f2 ON it2.item_numero = f2.fact_numero AND it2.item_sucursal = f2.fact_sucursal AND it2.item_tipo = f2.fact_tipo
											where it2.item_numero +  it2.item_sucursal + it2.item_tipo =  it3.item_numero +  it3.item_sucursal + it3.item_tipo
											)
											
											> 1
GROUP BY datename(year, f3.fact_fecha)



/*EJERCICIO 22
Escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los años. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
 Detalle del rubro
 Numero de trimestre del año (1 a 4)
 Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
 Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.
*/



SELECT 
	r.rubr_detalle as [DETALLE DEL RUBRO], 
	CASE 
		WHEN MONTH(f.fact_fecha) >= 1 and MONTH(f.fact_fecha) <= 3 THEN '1'
		WHEN MONTH(f.fact_fecha) > 3 and MONTH(f.fact_fecha) <= 6 THEN '2'
		WHEN MONTH(f.fact_fecha) > 6 and MONTH(f.fact_fecha) <= 9 THEN '3'
		WHEN MONTH(f.fact_fecha) > 9 and MONTH(f.fact_fecha) <= 12 THEN '4'
	END	as [NUMERO DE TRIMESTRE], 
	count (distinct f.fact_numero + f.fact_tipo + f.fact_sucursal ) as [CANTIDAD DE FACTURAS EMITIDAS EN TRIMESTRE], 
	count(distinct prod_codigo)  as [CANTIDAD DE PRODS DIFERENTES]
FROM  
	Rubro r left join Producto p on p.prod_rubro =  r.rubr_id
	left JOIN Item_Factura it on it.item_producto = p.prod_codigo
	LEFT JOIN Factura f on f.fact_numero + f.fact_tipo + f.fact_sucursal = it.item_numero + it.item_tipo + it.item_sucursal
GROUP BY r.rubr_detalle, CASE 
		WHEN MONTH(f.fact_fecha) >= 1 and MONTH(f.fact_fecha) <= 3 THEN '1'
		WHEN MONTH(f.fact_fecha) > 3 and MONTH(f.fact_fecha) <= 6 THEN '2'
		WHEN MONTH(f.fact_fecha) > 6 and MONTH(f.fact_fecha) <= 9 THEN '3'
		WHEN MONTH(f.fact_fecha) > 9 and MONTH(f.fact_fecha) <= 12 THEN '4'
	END	
HAVING COUNT(DISTINCT f.fact_numero + f.fact_sucursal + f.fact_tipo) >= 100
order by 1,2