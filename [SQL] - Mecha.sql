/*
1. Mostrar el código, razón social de todos los clientes cuyo límite de crédito sea mayor o
igual a $ 1000 ordenado por código de cliente.
*/







SELECT 
	clie_codigo, 
	clie_razon_social
FROM Cliente 
WHERE
clie_limite_credito >= 1000
ORDER BY  clie_codigo

/*
2. Mostrar el código, detalle de todos los artículos vendidos en el año 2012 ordenados por
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
3. Realizar una consulta que muestre código de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del artículo de menor a mayor.
*/


SELECT 
p.prod_codigo as [CODIGO PRODUCTO], 
p.prod_detalle as [NOMBRE PRODUCTO],
ISNULL(sum(s.stoc_cantidad),0) as [STOCK]
FROM STOCK s RIGHT JOIN Producto p on s.stoc_producto = p.prod_codigo
group by p.prod_codigo, p.prod_detalle
order by p.prod_detalle DESC


/*
4. Realizar una consulta que muestre para todos los artículos código, detalle y cantidad de
artículos que lo componen. Mostrar solo aquellos artículos para los cuales el stock
promedio por depósito sea mayor a 100.
*/

-- estoy parada en los códigos más "grandes", entonces al joinear con la que me da los procutos que la componen, me pueden dar dos posibilidades
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

-- promedio de cantidades por porducto por deposito
select s.stoc_deposito, avg(s.stoc_cantidad) from stock s
group by s.stoc_deposito, s.stoc_producto
order by 1, 2


select s.stoc_deposito as [deposito], 
	 s.stoc_producto as [prod], 
	 s.stoc_cantidad as [cantidad] from stock s
--group by s.stoc_deposito, s.stoc_producto
where stoc_producto = '00000102'
order by 2

select s.stoc_producto as [prod], 
	avg(s.stoc_cantidad) as [cantidad]
	from stock s
group by  s.stoc_producto
order by avg(s.stoc_cantidad)  desc


select
	 s.stoc_producto as [prod], 
	 AVG(stoc_cantidad) as [cantidad] from stock s
group by s.stoc_producto, s.stoc_deposito
order by 1

SELECT 
	*
FROM 
	Producto pr left join Composicion c on pr.prod_codigo = c.comp_producto
	join STOCK s on s.stoc_producto = pr.prod_codigo
where stoc_producto = '00000102'

-- comp_producto -> codigo del producto compuesto 
-- comp_componente -> codigo del producto que lo compone
select * from Composicion

/*
5. Realizar una consulta que muestre código de artículo, detalle y cantidad de egresos de
stock que se realizaron para ese artículo en el año 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido más egresos que en el 2011.
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

select * from Item_Factura it join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero
where it.item_producto = '00000136'


/*
6. Mostrar para todos los rubros de artículos código, detalle, cantidad de artículos de ese
rubro y stock total de ese rubro de artículos. Solo tener en cuenta aquellos artículos que
tengan un stock mayor al del artículo ‘00000000’ en el depósito ‘00’.
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
7. Generar una consulta que muestre para cada artículo código, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos artículos que posean
stock.
*/

-- que los articulos tengan stock lo pienso como que la suma de todos las cantidades x deposito > 0 

--asi me genera que los que nunca se vendieron, entren en la lista, esto sería esperado? 
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




---cantidad de stock de un producto 

SELECT p1.prod_codigo, sum(s1.stoc_cantidad) FROM STOCK s1 JOIN Producto p1 ON s1.stoc_producto = p1.prod_codigo
GROUP BY p1.prod_codigo
HAVING SUM(S1.STOC_CANTIDAD) > 0
order by SUM(s1.stoc_cantidad) ASC


SELECT 
P.prod_codigo as [CODIGO], 
P.prod_detalle as [DETALLE], 
1 as [PRECIO MINIMO],
2 AS [PRECIO MAXIMO], 
3 AS [PORCENTAJE INCREMENTO]
FROM 
STOCK s JOIN Producto P on P.prod_codigo = s.stoc_producto
ORDER BY stoc_cantidad asc

--------------------------------------------------


/*
8. Mostrar para el o los artículos que tengan stock en todos los depósitos, nombre del
artículo, stock del depósito que más stock tiene.
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


SELECT p.prod_detalle, MAX(s.stoc_cantidad) AS 'Stock del depósito con más stock'
FROM Producto p
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
WHERE s.stoc_cantidad > 0 
GROUP BY p.prod_detalle
HAVING COUNT(*) = 12


-- STOCK DEL DEPOSITO QUE MÁS TIENE  (hay que ponerle top)
SELECT prod_codigo, stoc_deposito, stoc_cantidad FROM Producto p JOIN STOCK s on s.stoc_producto = p.prod_codigo  
group by  prod_codigo, stoc_deposito, stoc_cantidad
having prod_codigo = '00001703'
order by 1,2,3



--- TERCIARIZO LA QUERY 

SELECT prod_codigo FROM Producto p JOIN STOCK s on s.stoc_producto = p.prod_codigo  
group by prod_codigo
HAVING COUNT(stoc_deposito) = 12
--HAVING COUNT(stoc_deposito) = (SELECT COUNT(*) FROM DEPOSITO)

-- creo que aca se puede ver que no hay ninguno que tenga stock en todos (hay 33 depositos) y el máximo que tiene es 12

SELECT prod_codigo, count(stoc_deposito) FROM Producto p JOIN STOCK s on s.stoc_producto = p.prod_codigo  
group by prod_codigo


--- deposito en el que más stock tiene 

SELECT prod_codigo, stoc_deposito, stoc_cantidad FROM Producto p JOIN STOCK s on s.stoc_producto = p.prod_codigo  
group by prod_codigo, stoc_deposito, stoc_cantidad
order by 1,2,3

select * from DEPOSITO

/*
9. Mostrar el código del jefe, código del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de depósitos que ambos tienen asignados.

*/


/*
10. Mostrar los 10 productos más vendidos en la historia y también los 10 productos menos
vendidos en la historia. Además mostrar de esos productos, quien fue el cliente que
mayor compra realizo.
*/

/*
Ejercicio 11: realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
productos vendidos y el monto de dichas ventas sin impuestos. Los datos se deberán
ordenar de mayor a menor, por la familia que más productos diferentes vendidos tenga,
solo se deberán mostrar las familias que tengan una venta superior a 20000 pesos para
el año 2012.*/


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

--------- pruebas para llegar al resultado


SELECT 
	f.fami_detalle as [DETALE FAMILIA], 
	'1' as [CANTIDAD DE PRODS DIF VENDIDOS], 
	'2' as [MONTO SIN IMPUESTOS] 
FROM Producto p join Familia f on f.fami_id = p.prod_familia

-- cantidad de productos vendidos de una familia 

SELECT 
	f.fami_detalle as [DETALE FAMILIA],
	p.prod_codigo 
FROM Producto p join Familia f on f.fami_id = p.prod_familia
JOIN Item_Factura it on it.item_producto = p.prod_codigo
GROUP BY f.fami_detalle, p.prod_codigo
order by 1

SELECT 
	f.fami_detalle as [DETALE FAMILIA],
	COUNT(distinct p.prod_codigo) 
FROM Producto p join Familia f on f.fami_id = p.prod_familia
JOIN Item_Factura it on it.item_producto = p.prod_codigo
GROUP BY f.fami_detalle
order by 1


/*
Ejercicio 12: mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de depósitos en los cuales hay stock del
producto y stock actual del producto en todos los depósitos. Se deberán mostrar
aquellos productos que hayan tenido operaciones en el año 2012 y los datos deberán
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


---- version sin hacer dos subconsultas, pero me genera más stock pq me aumenta la atomicidad el join con las tablas 
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


---- CANTIDAD DE STOCK POR PRODUCTO

select distinct
p.prod_codigo, 
sum(s.stoc_cantidad)
from 
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
	JOIN STOCK s on s.stoc_producto = p.prod_codigo
group by p.prod_codigo
order by 1, 2


SELECT s.stoc_producto, sum(s.stoc_cantidad)
FROM STOCK s group by s.stoc_producto
order by 1

----- CANTIDAD DE DEPOSITOS DONDE HAY STOCK DEL PRODUCTO 

SELECT s1.stoc_producto, count(s1.stoc_deposito) FROM
STOCK s1 
where s1.stoc_cantidad > 0 
group by s1.stoc_producto


SELECT 
*
FROM 
	Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
	join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
	JOIN STOCK s on s.stoc_producto = p.prod_codigo

SELECT
*
FROM Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto 
JOIN Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero
JOIN STOCK s on s.stoc_producto = p.prod_codigo


---- cantidad de clientes que compraron un producto 
SELECT
prod_codigo as [CODIGO PRODUCTO], 
COUNT(distinct f.fact_cliente)
FROM Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
JOIN STOCK s on s.stoc_producto = p.prod_codigo
group by prod_codigo
order by 1

----- PRECIO PROMEDIO PAGADO POR PRODUCTO 
SELECT
p.prod_codigo, 
AVG(it.item_precio)
FROM Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
JOIN STOCK s on s.stoc_producto = p.prod_codigo
group by prod_codigo
order by 1


SELECT distinct 
p.prod_codigo, 
avg(it.item_precio)
FROM Item_Factura it JOIN Producto p on p.prod_codigo = it.item_producto
join Factura f on f.fact_tipo + f.fact_sucursal + f.fact_numero = it.item_tipo + it.item_sucursal + it.item_numero 
JOIN STOCK s on s.stoc_producto = p.prod_codigo
group by prod_codigo
having prod_codigo = '00000102'


/*
EJERCICIO13: Realizar una consulta que retorne para cada producto que posea composición nombre
	del producto, precio del producto, precio de la sumatoria de los precios por la cantidad
	de los productos que lo componen. Solo se deberán mostrar los productos que estén
	compuestos por más de 2 productos y deben ser ordenados de mayor a menor por
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


SELECT DISTINCT
p.prod_codigo as [NOMBRE], 
p2.prod_precio as [PRECIO], 
c.comp_cantidad as [CANTIDAD] 
FROM 
	Composicion c join Producto p on p.prod_codigo = c.comp_producto
	JOIN Producto p2 on p2.prod_codigo = c.comp_componente
where comp_producto = '00001104'
--GROUP BY 


SELECT DISTINCT
*
FROM 
	Composicion c join Producto p on p.prod_codigo = c.comp_producto
	JOIN Producto p2 on p2.prod_codigo = c.comp_componente
where comp_producto = '00001104'


/*

Escriba una consulta que retorne una estadística de ventas por cliente. Los campos que
debe retornar son:
Código del cliente
Cantidad de veces que compro en el último año
Promedio por compra en el último año
Cantidad de productos diferentes que compro en el último año
Monto de la mayor compra que realizo en el último año
Se deberán retornar todos los clientes ordenados por la cantidad de veces que compro en
el último año.
No se deberán visualizar NULLs en ninguna columna

*/

SELECT 
	 c.clie_codigo				AS [CODIGO CLIENTE], 
	 count(distinct F.fact_tipo + F.fact_sucursal + fact_numero) as [CANTIDAD DE VECES QUE COMPRO], 
	 AVG(F.fact_total)			as [PROMEDIO DE COMPRA], 
		 (
			SELECT 
				count(distinct it.item_producto)
				FROM 
					Item_Factura it join Factura f1 on  F1.fact_tipo + F1.fact_sucursal + f1.fact_numero =  it.item_tipo + it.item_sucursal + it.item_numero
				where f1.fact_cliente = c.clie_codigo and YEAR(f1.fact_fecha) = (select year(max(f3.fact_fecha)) from Factura f3)
				GROUP BY f1.fact_cliente 
		 )						as [CANTIDAD DE PRODUCTOS DIFERENTES], 
	 MAX(fact_total)			as [MONTO DE LA MAYOR COMPRA]
FROM 
	Cliente c left join Factura F ON F.fact_cliente = c.clie_codigo
WHERE 
	YEAR(f.fact_fecha) = (select year(max(f2.fact_fecha)) from Factura f2)
GROUP BY 
	clie_codigo
ORDER BY 2


------

SELECT 
 c.clie_codigo AS [CODIGO CLIENTE], 
 count(distinct F.fact_tipo + F.fact_sucursal + fact_numero) as [CANTIDAD DE VECES QUE COMPRO], 
 AVG(F.fact_total) as [PROMEDIO DE COMPRA], 
 count(distinct it.item_producto) as [CANTIDAD DE PRODUCTOS DIFERENTES], 
 MAX(f.fact_total) as [MONTO DE LA MAYOR COMPRA]
FROM 
	Cliente c left join Factura F ON F.fact_cliente = c.clie_codigo
	join Item_Factura it  on  F.fact_tipo + F.fact_sucursal + f.fact_numero =  it.item_tipo + it.item_sucursal + it.item_numero
WHERE 
	YEAR(f.fact_fecha) = (select year(max(f2.fact_fecha)) from Factura f2)
GROUP BY 
	clie_codigo
ORDER BY 2

-- mayor compra hecha

SELECT 
clie_codigo, 
MAX(fact_total)
FROM 
	Cliente c join Factura F ON F.fact_cliente = c.clie_codigo
WHERE 
	YEAR(f.fact_fecha) = 2012
GROUP BY clie_codigo

-----CANTIDAD DE VCES QUE COMPRO EN EL ÚLTIMO AÑO (2012)

SELECT 
 clie_codigo, 
 count(distinct F.fact_tipo + F.fact_sucursal + fact_numero)
FROM 
	Cliente c join Factura F ON F.fact_cliente = c.clie_codigo
WHERE 
	YEAR(f.fact_fecha) = 2012
GROUP BY clie_codigo


--- PROMEDIO POR COMPRA EN EL ULTIMO AÑO 

SELECT 
 c.clie_codigo, 
 AVG(F.fact_total)
FROM 
	Cliente c join Factura F ON F.fact_cliente = c.clie_codigo
WHERE 	
	YEAR(f.fact_fecha) = 2012
GROUP BY clie_codigo


-- cantidad de productos diferentes que compro en el ultimo año 

SELECT 
f.fact_cliente, 
count(distinct it.item_producto)
FROM 
	Item_Factura it join Factura f on  F.fact_tipo + F.fact_sucursal + fact_numero =  it.item_tipo + it.item_sucursal + it.item_numero
GROUP BY f.fact_cliente 



/*
16. Con el fin de lanzar una nueva campaña comercial para los clientes que menos compran
en la empresa, se pide una consulta SQL que retorne aquellos clientes cuyas ventas son
inferiores a 1/3 del promedio de ventas del producto que más se vendió en el 2012.
Además mostrar
1. Nombre del Cliente
2. Cantidad de unidades totales vendidas en el 2012 para ese cliente.
3. Código de producto que mayor venta tuvo en el 2012 (en caso de existir más de 1,
mostrar solamente el de menor código) para ese cliente.
Aclaraciones:
La composición es de 2 niveles, es decir, un producto compuesto solo se compone de
productos no compuestos.
Los clientes deben ser ordenados por código de provincia ascendente.*/SELECT*FROM Item_Factura it 