USE GD2015C1

-- EJERCICIO 1

/*Armar una consulta SQL que muestre aquel/aquellos clientes que en 2 años consecutivos (de existir), fueron los mejores compradores, es decir, 
los que en monto total facturado anual fue el máximo. De esos clientes mostrar , razon social, domicilio, cantidad de unidades compradas 
en el último año.
Nota: No se puede usar select en el from.
*/


SELECT 
	c.clie_razon_social  as [RAZON SOCIAL],
	c.clie_domicilio  as [DOMICILIO], 
	(select sum(it1.item_cantidad) from Item_Factura it1 join Factura f1 
		on f1.fact_tipo + f1.fact_numero + f1.fact_sucursal = it1.item_tipo + it1.item_numero + it1.item_sucursal
	where   c.clie_codigo = f1.fact_cliente and 
			year(f1.fact_fecha) = (select max(year(fact_fecha)) from Factura)
	group by f1.fact_cliente) as [CANTIDAD UNIDADES COMPRADAS]
FROM Factura f JOIN Cliente c on c.clie_codigo = f.fact_cliente 
group by c.clie_razon_social, c.clie_domicilio, year(f.fact_fecha), clie_codigo
having clie_codigo in (
	select TOP 1 f2.fact_cliente from Item_Factura it join Factura f2 on  f2.fact_sucursal + f2.fact_tipo + f2.fact_numero = it.item_sucursal +  it.item_tipo + it.item_numero
	where year(f2.fact_fecha) = year(f.fact_fecha)
	group by f2.fact_cliente
	order by sum(it.item_cantidad * it.item_precio) desc
) and 
clie_codigo in (
select TOP 1 f2.fact_cliente from Item_Factura it join Factura f2 on  f2.fact_sucursal + f2.fact_tipo + f2.fact_numero = it.item_sucursal +  it.item_tipo + it.item_numero
	where year(f2.fact_fecha) = year(f.fact_fecha) + 1
	group by f2.fact_cliente
	order by sum(it.item_cantidad * it.item_precio) desc
)

 

 -- EJERCICIO 2

/*Se necesita saber que productos no han sido vendidos durante el año 2012 pero que sí tuvieron ventas en año anteriores. 
De esos productos mostrar:
1.Código de producto
2.Nombre de Producto
3.Un string que diga si es compuesto o no.

El resultado deberá ser ordenado por cantidad vendida en años anteriores.
*/


SELECT 
		it.item_producto as [CODIGO DE PRODUCTO], 
		p.prod_detalle as [NOMBRE DE PRODUCTO], 
		(case 
			when it.item_producto in (select c.comp_producto from Composicion c) then 'PRODUCTO COMPUESTO'
			else 'PRODUCTO SIN COMPOSICION'
		end) AS [COMPOSICION]
FROM 
	Item_Factura it join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
	join Producto p on p.prod_codigo = it.item_producto
where 
	year(f.fact_fecha) < 2012 -- vendidos en años anteriores
	and it.item_producto not in (
	select it2.item_producto from Item_Factura it2 join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it2.item_numero + it2.item_sucursal + it2.item_tipo
	where year(f.fact_fecha) = 2012) -- no vendidos en 2012
group by
	it.item_producto, p.prod_detalle 
order by 
	sum(it.item_cantidad) asc

-- EJERCICIO 3
/*
 
La empresa esta muy comprometida con el desarrollos sustentable y como consecuencia de ello propone cambiar todos los envases de sus productos por envases 
reciclados. Si bien entiende la importancia de este cambio también es consciente de los costos que esto conlleva, por lo cual se realizará de manera paulatina.
 
Se solicita un listado con los 12 productos más vendidos y los 12 productos menos vendidos del último año. 
Comparar la cantidad vendidad de cada uno de estos productos con la cantidad vendida del año anterior e indicar 
el String 'Mas ventas' o 'Menos ventas', según corresponda. Además indicar el envase.
Nota: No se puede usar select en el from.
*/



-- MI SOLUCION
select 
	p.prod_detalle as [DETALLE], 
	case when SUM(it.item_cantidad) > isnull((SELECT SUM(it.item_cantidad)
				FROM Item_Factura it1 join Factura f1 on f1.fact_numero + f1.fact_sucursal + f1.fact_tipo = it1.item_numero + it1.item_sucursal + it1.item_tipo
				where year(f1.fact_fecha) = (SELECT MAX(YEAR(f1.fact_fecha)) from Factura f1) - 1
				and p.prod_codigo = it1.item_cantidad), 0) then 'MAS VENTAS'
	else 'MENOS VENTAS'
	end			   as [RELACION CON AÑO ANTERIOR], 
	e.enva_detalle as [ENVASE]
from 
	Item_Factura it join Producto p on p.prod_codigo = it.item_producto
	join Envases e on e.enva_codigo = p.prod_envase
group by 
	p.prod_codigo,e.enva_detalle, p.prod_detalle
having 
	p.prod_codigo  in (
		SELECT TOP 12 it.item_producto
		FROM Item_Factura it join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
		where year(f.fact_fecha) = (SELECT MAX(YEAR(f.fact_fecha)) from Factura f)
		group by it.item_producto, year(f.fact_fecha)
		order by SUM(it.item_cantidad) desc
) or p.prod_codigo  in (
		SELECT TOP 12 it.item_producto
		FROM Item_Factura it join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
		where year(f.fact_fecha) = (SELECT MAX(YEAR(f.fact_fecha)) from Factura f)
		group by it.item_producto, year(f.fact_fecha)
		order by SUM(it.item_cantidad) asc
)
order by SUM(it.item_cantidad) desc

------ OTRA SOLUCION (recalcula el sum())

SELECT P.prod_detalle AS [Producto]
    , CASE WHEN (SELECT SUM(item_cantidad)
                 FROM Item_Factura
                    JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
                 WHERE item_producto = P.prod_codigo
                    AND YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)) > 
                    (SELECT SUM(item_cantidad)
                    FROM Item_Factura
                        JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
                    WHERE item_producto = P.prod_codigo
                        AND YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura) - 1)
                THEN 'Más Ventas'
            ELSE 'Menos Ventas'
        END AS [Comparación Años anteriores]
    , enva_detalle AS [Envase]
FROM Producto P
    JOIN Envases ON P.prod_envase = enva_codigo
    JOIN Item_Factura ON item_producto = P.prod_codigo
WHERE P.prod_codigo IN (SELECT TOP 12 item_producto
                         FROM Item_Factura
                            JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
                         WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
                         GROUP BY item_producto
                         ORDER BY SUM(item_cantidad) DESC)
    OR P.prod_codigo IN (SELECT TOP 12 item_producto
                         FROM Item_Factura
                            JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
                         WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
                         GROUP BY item_producto
                         ORDER BY SUM(item_cantidad) ASC)
GROUP BY P.prod_detalle, P.prod_codigo, enva_detalle
ORDER BY SUM(item_cantidad) DESC


--EJERCICIO 4

/* FOTO 3
Armar una consulta que muestra para todos los productos:
-Producto
-Detalle del producto
-Detalle Composición (Si no es compuesto usar string "SIN COMPOSICION" y si es compuesto poner "CON COMPOSICIÓN")
-Cantidad de componentes (Si no es compuesto se tiene que mostrar cero)
-Cantidad de veces que fue comprado por distintos clientes
Nota: No se permite usar sub select en el FROM.
*/


select * from Producto -- 2190


SELECT 
	p.prod_codigo as [CODIGO PRODUCTO], 
	p.prod_detalle as [DETALLE PRODUCTO], 
	(CASE
		WHEN c.comp_producto is null THEN 'SIN COMPOSICION'
		ELSE 'CON COMPOSICION'
	END) as [DETALLE COMPOSICION], 
	count(distinct c.comp_componente) as [CANTIDAD DE COMPONENTES], 
	count(distinct f.fact_cliente) as [CANTIDAD DE VECES COMPRADO]
FROM Producto p left join Item_Factura it on p.prod_codigo = it.item_producto LEFT JOIN Composicion c on c.comp_producto = p.prod_codigo
LEFT JOIN Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
group by p.prod_codigo, p.prod_detalle, c.comp_producto
order by 3 asc



SELECT 
*
FROM Producto p left join Item_Factura it on p.prod_codigo = it.item_producto LEFT JOIN Composicion c on c.comp_producto = p.prod_codigo
LEFT JOIN Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it.item_numero + it.item_sucursal + it.item_tipo
group by p.prod_codigo, p.prod_detalle, c.comp_producto
order by 3 asc



/*Ejercicio 5 (SQL): mostrar los dos empleados del mes, estos son:
a) El empleado que en el mes actual (en el cual se ejecuta la query) vendió más en dinero(fact_total).
b) El segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) 
vendió más cantidades (unidades de productos).
Se deberá mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 
'MEJOR FACTURACION' y para el segundo
'VENDIÓ MÁS UNIDADES'.
NOTA: Si el empleado que más vendió en facturación y cantidades es el mismo, solo mostrar una fila que diga el empleado y 'MEJOR EN TODO'.
NOTA2: No se debe usar subselect en el from.*/



SELECT
	RTRIM(e.empl_apellido)+ ' ' +RTRIM(e.empl_nombre) as [APELLIDO Y NOMBRE], 
	(CASE WHEN  
			e.empl_codigo in (select top 1 f.fact_vendedor from Factura f
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor 					
					        order by sum(f.fact_total) desc) 
							and	
								e.empl_codigo in (SELECT top 1 f.fact_vendedor
							FROM Item_Factura it join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=it.item_tipo+it.item_sucursal+it.item_numero
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor
							order by sum(it.item_cantidad) desc) then  'MEJOR EN TODO'
		WHEN e.empl_codigo in (SELECT top 1 f.fact_vendedor
							FROM Item_Factura it join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=it.item_tipo+it.item_sucursal+it.item_numero
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor
							order by sum(it.item_cantidad) desc
							) then 'MEJOR EN VENTAS'
		WHEN e.empl_codigo in (select top 1 f.fact_vendedor from Factura f
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor
							order by sum(f.fact_total) desc) then 'MEJOR EN FACTURACION'
		
	END) as [MEJOR EN:]
FROM Empleado e
WHERE e.empl_codigo in (select top 1 f.fact_vendedor from Factura f
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor 
							order by sum(f.fact_total) desc) 
							or	e.empl_codigo in (SELECT top 1 f.fact_vendedor
							FROM Item_Factura it join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=it.item_tipo+it.item_sucursal+it.item_numero
							where MONTH(f.fact_fecha) = 12 and YEAR(f.fact_fecha) = 2011
							group by f.fact_vendedor
							order by sum(it.item_cantidad) desc)

/*
EMPLEADO	MEJOR EN
E1			FACTURACION
E2			UNIDADES


E1 Y E2 SON IGUALES


EMPLEADO    MEJOR EN
E1			TODO
*/

--MEJOR EN FACTURACION 

select top 1 f.fact_vendedor, sum(f.fact_total) from Factura f
group by f.fact_vendedor 
having f.fact_vendedor is not null
order by sum(f.fact_total) desc


--- MEJOR EN CANTIDAD DE UNIDADES VENTIDAD

SELECT top 1 f.fact_vendedor, sum(it.item_cantidad)
FROM Item_Factura it join Factura f on f.fact_tipo+f.fact_sucursal+f.fact_numero=it.item_tipo+it.item_sucursal+it.item_numero
group by f.fact_vendedor having f.fact_vendedor is not null
order by sum(it.item_cantidad) desc


select * from empleado



--EJERCICIO 6

/* FOTO 7
Se pide realizar una consulta SQL que retorne POR CADA AÑO, el cliente que más compro (fact_total), 
la cantidad de artículos distintos comprados, la cantidad de rubros distintos comprados.
Solamente se deberán mostrar aquellos clientes que posean al menos 10 facturas o más por año.
El resultado debe ser ordenado por año.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el 
usuario para este punto.
*/


SELECT
	YEAR(f.fact_fecha) as [AÑO],
	f.fact_cliente	as [CLIENTE CON MAS COMPRAS], 
	COUNT(distinct it.item_producto) as [CANT ARTICULOS DISTINTOS COMPRADOS], 
	COUNT(distinct p.prod_rubro) as [CANT RUBROS DISTINTOS COMPRADOS]
FROM Factura f left join Item_factura it on f.fact_numero = it.item_numero and f.fact_sucursal = it.item_sucursal and f.fact_tipo=it.item_tipo
left join Producto p on p.prod_codigo = it.item_producto
where f.fact_cliente in (SELECT TOP 1 f1.fact_cliente FROM Factura f1
		where year(f1.fact_fecha) = YEAR(f.fact_fecha)
		group by f1.fact_cliente 
		order by SUM(f1.fact_total) desc)
group by YEAR(f.fact_fecha), f.fact_cliente
having (SELECT COUNT(f2.fact_numero+ f2.fact_sucursal+ f2.fact_tipo) FROM Factura f2
where YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
and f.fact_cliente = f2.fact_cliente
group by f2.fact_cliente)>=10


---- cantidad de facturas por año para un determinado clinete
SELECT f2.fact_cliente, COUNT(f2.fact_numero+ f2.fact_sucursal+ f2.fact_tipo) FROM Factura f2
--where YEAR(f2.fact_fecha) = YEAR(f.fact_fecha)
-- and f.fact_cliente = f2.fact_cliente
group by f2.fact_cliente

-------CLIENTE QUE MAS COMPRO (historico)

SELECT TOP 1 f.fact_cliente, SUM(f.fact_total) FROM Factura f 
group by f.fact_cliente 
order by SUM(f.fact_total) desc

-------CLIENTE QUE MAS COMPRO (en un año en particular)

SELECT TOP 1 f1.fact_cliente, SUM(f1.fact_total) FROM Factura f1
--where year(f1.fact_fecha) = YEAR(f.fact_fecha)
group by f1.fact_cliente 
order by SUM(f1.fact_total) desc



------ CANTIDAD DE ARTICULOS DISNTINTOS COMPRADOS POR CLIENTE

SELECT f.fact_cliente, count(distinct it.item_producto) FROM Item_Factura it JOIN Factura f on f.fact_numero = it.item_numero and f.fact_sucursal = it.item_sucursal and f.fact_tipo=it.item_tipo
group by f.fact_cliente


/*
	Realizar una consulta SQL que retorne para los 10 clientes que más compraron en el 2012 y que fueron atendidos por más de 3 
	vendedores distintos:
    - Apellido y Nombre del Cliente.
    - Cantidad de Productos distintos comprados en el 2012.
    - Cantidad de unidades compradas dentro del primer semestre del 2012.
	El resultado deberá mostrar ordenado la cantidad de ventas descendente del 2012 de cada cliente, en caso de igualdad de ventas, 
	ordenar por código de cliente.
	NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/



----2012 -> 01742 | 2011 -> 01742 | 2010  ->01772 Y 01634

-- EJERCICIO 7

/* FOTO 8 S2L
Se pide realizar una consulta SQL que retorne todos los clientes que tuvieron mas ventas
(cantidad de articulos vendidos) en el 2012 que en el 2011 y ademas mostraar
1) codigo del cliente
2) razon social
3) cantidad de productos compuestos (en unidades) que vendio en 2019 
El resultado debe ser ordenado por limite de credito del cliente de mayor a menor
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto
*/


SELECT 
	f.fact_cliente as [CODIGO DEL CLIENTE], 
	c.clie_razon_social as [RAZON SOCIAL], 
	isnull((
		SELECT count(it1.item_producto) FROM Item_Factura it1 
		join Factura f1 on  f1.fact_numero = it1.item_numero and f1.fact_sucursal = it1.item_sucursal and f1.fact_tipo=it1.item_tipo
		where it1.item_producto in (select c.comp_producto from Composicion c)
		and f1.fact_cliente = f.fact_cliente and YEAR(f1.fact_fecha) = 2012
		group by f1.fact_cliente
		),0)	 as [CANTIDAD PRODUCTOS COMPUESTOS]
FROM Factura f join Item_factura it on f.fact_numero = it.item_numero and f.fact_sucursal = it.item_sucursal and f.fact_tipo=it.item_tipo 
join Cliente c on f.fact_cliente = c.clie_codigo
WHERE 
(
SELECT count(it1.item_producto) FROM Item_Factura it1 
		join Factura f1 on  f1.fact_numero = it1.item_numero and f1.fact_sucursal = it1.item_sucursal and f1.fact_tipo=it1.item_tipo
		where YEAR(f1.fact_fecha) = 2012
		group by f1.fact_cliente
		having f1.fact_cliente = f.fact_cliente )
 > 
 (
SELECT count(it1.item_producto) FROM Item_Factura it1 
		join Factura f1 on  f1.fact_numero = it1.item_numero and f1.fact_sucursal = it1.item_sucursal and f1.fact_tipo=it1.item_tipo
		where YEAR(f1.fact_fecha) = 2011
		group by f1.fact_cliente
		having f1.fact_cliente = f.fact_cliente )
group by f.fact_cliente, c.clie_razon_social,  c.clie_limite_credito
order by c.clie_limite_credito desc


--- CANTIDAD DE PRODUCTOS VENDIDOS PARA UN CLIENTE EN 2011

SELECT f1.fact_cliente, count(distinct it1.item_producto) FROM Item_Factura it1 
		join Factura f1 on  f1.fact_numero = it1.item_numero and f1.fact_sucursal = it1.item_sucursal and f1.fact_tipo=it1.item_tipo
		where YEAR(f1.fact_fecha) = 2011
		group by f1.fact_cliente
		having f1.fact_cliente = f.fact_cliente 


-- CANTIDAD DE PRODUCTOS VENDIDOS EN 2012 


SELECT * FROM Factura
-- cantidad de productos compuestos comprados por un cliente en 2019

SELECT count(distinct it1.item_producto) FROM Item_Factura it1 
join Factura f1 on  f1.fact_numero = it1.item_numero and f1.fact_sucursal = it1.item_sucursal and f1.fact_tipo=it1.item_tipo
where it1.item_producto in (select c.comp_producto from Composicion c) and YEAR(f1.fact_fecha) = 2019
--and f1.fact_cliente = '01634 '

select * from Factura




-- EJERCICIO 8

/*PARCIALES DEL 09/11*/
/* 1)
Se necesita saber que productos no son vendidos durante el año 2011 y cuales si. La consulta debe mostrar:

• Código de producto
• Nombre de Producto
• Fue Vendido (Si o No) según el caso.
• Cantidad de componentes.
El resultado deberá ser ordenado por cantidad total de clientes que los compraron en la historia ascendente.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/

--EJERCICIO 9


/*Realizar una consulta SQL que retorne, para cada producto con más de 2 artículos distintos en su composición la siguiente información.

1)      Detalle del producto

2)      Rubro del producto

3)      Cantidad de veces que fue vendido

 El resultado deberá mostrar ordenado por la cantidad de los productos que lo componen.

 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/



 -- EJERCICIO 10

/*
Mostrar las 5 zonas donde menor cantidad de ventas se están realizando en el año actual. 
Recordar que un empleado está puesto como fact_vendedor en factura. 
De aquellas zonas donde menores ventas tengamos, se deberá mostrar (cantidad de clientes distintos que operan en esa zona), 
cantidad de clientes que aparte de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). 
El resultado se deberá mostrar por cantidad de productos vendidos en la zona en cuestión de manera descendiente.

 Nota: No se puede usar select en el from.
*/



--EJERCICIO 11

/*
se requiere mostrar los productos que sean componentes y 
que se hayan vendido en forma unitaria o a través del producto al cual compone, 
por ejemplo una hamburguesa se deberá mostrar si se vendió como hamburguesa y si se vendió un combo que está compuesto por una hamburguesa. 

Se deberá mostrar:

Código de producto, nombre de producto, cantidad de facturas vendidas solo, 
cantidad de facturas vendidas de los productos que compone, cantidad de productos a los cuales compone que se vendieron

El resultado deberá ser ordenado por el componente que se haya vendido solo en más facturas 

Aclaracion: se debe resolver en una sola consulta sin utilizar subconsultas en ningún lugar del Select 
*/

-- EJERCICIO 12
/*
Realizar una consulta SQL que retorne, para cada producto con más de 2 artículos distintos en su composición 
la siguiente información.

1)      Detalle del producto
2)      Rubro del producto
3)      Cantidad de veces que fue vendido

 El resultado deberá mostrar ordenado por la cantidad de los productos que lo componen.
 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.

*/

-- EJERCICIO 13

/*
De las 10 familias de productos que menores ventas tuvieron en el 2011 (considerar como menor también si no se tuvo ventas), se le pide mostrar:

Detalle de la Familia

Monto total Facturado por familia en el año

Cantidad de productos distintos comprados de la familia

Cantidad de productos con composición que tiene la familia

Cliente que más compro productos de esa familia.

Nota: No se permiten sub select en el FROM.
*/

-- EJERCICIO 14


/* Se solicita una estadística por Año y familia, para ello se deberá mostrar:

Año, Código de familia, Detalle de familia, cantidad de facturas, cantidad de productos con composición vendidos, monto total vendido

Solo se deberán considerar las familias que tengan al menos un producto con composición y que se hayan vendido conjuntamente (en la misma factura) con otra familia distinta

Nota: No se puede usar select en el from.
*/

-- EJERCIO 15

/*
Realizar una consulta SQL que retorne: Año, cantidad de productos compuestos vendidos en el Año, cantidad de facturas realizadas en el Año, monto total facturado en el Año, 
monto total facturado en el Año anterior.
Solamente considerar aquellos Años donde la cantidad de unidades vendidas de todos los artículos sea mayor a 1000.
Se debera ordenar el resultado por cantidad vendida en el año
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/


-- EJERCICIO 16

/*
Con el fin de analizar el posicionamiento de ciertos productos se necesita mostrar solo los 5 rubros de productos más vendidos y además, 
por cada uno de estos rubros  saber cuál es el producto más exitoso (es decir, con más ventas) y si el mismo es “simple” o “compuesto”. 
Por otro lado, se pide se indique si hay “stock disponible” o si hay “faltante” para afrontar las ventas del próximo mes. 
Considerar que se estima que la venta aumente un 10% respecto del mes de diciembre del año pasado.
Armar una consulta SQL que retorne esta información.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto
*/


