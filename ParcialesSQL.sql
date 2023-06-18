USE GD2015C1

/* Los que hicimos con Nacho */

/*Armar una consulta SQL que muestre aquel/aquellos clientes que en 2 años consecutivos (de existir), fueron los mejores compradores, es decir, 
los que en monto total facturado anual fue el máximo. De esos clientes mostrar , razon social, domicilio, cantidad de unidades compradas 
en el último año.
Nota: No se puede usar select en el from.
*/


SELECT C1.clie_razon_social,C1.clie_domicilio,(SELECT SUM(item_cantidad*item_precio) FROM Item_Factura 
											   JOIN Factura ON fact_numero+fact_tipo+fact_sucursal=item_numero+item_tipo+item_sucursal
											   WHERE fact_cliente=C1.clie_codigo AND YEAR(fact_fecha) = (SELECT MAX(YEAR(F2.fact_fecha)) FROM Factura F2)) 
FROM Cliente C1
JOIN Factura F1 ON F1.fact_cliente=C1.clie_codigo
WHERE C1.clie_codigo IN
(
	SELECT TOP 1 fact_cliente FROM Factura 
	JOIN Item_Factura ON item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
	WHERE YEAR(F1.fact_fecha)=YEAR(fact_fecha)
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad * item_precio) DESC
) AND C1.clie_codigo IN 
(
	SELECT TOP 1 fact_cliente FROM Factura 
	JOIN Item_Factura ON item_numero+item_tipo+item_sucursal=fact_numero+fact_tipo+fact_sucursal
	WHERE YEAR(F1.fact_fecha) + 1=YEAR(fact_fecha)
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad * item_precio) DESC
)
GROUP BY C1.clie_razon_social,C1.clie_domicilio,C1.clie_codigo


/*Se necesita saber que productos no han sido vendidos durante el año 2012 pero que sí tuvieron ventas en año anteriores. 
De esos productos mostrar:
1.Código de producto
2.Nombre de Producto
3.Un string que diga si es compuesto o no.

El resultado deberá ser ordenado por cantidad vendida en años anteriores.
*/

select prod_codigo, prod_detalle, 
case
	when prod_codigo in (select distinct comp_producto from composicion)
		then 'El producto es compuesto'
	else 'El producto no tiene composicion'
	end resultado
from producto
join Item_Factura on item_producto = prod_codigo
join Factura on fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
where year(fact_fecha) < 2012 and prod_codigo not in (select item_producto from Factura join Item_Factura
		 on item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
			where year(fact_fecha)=2012)
group by prod_codigo, prod_detalle
order by sum(item_cantidad) desc

/* Foto 1
La empresa esta muy comprometida con el desarrollos sustentable y como consecuencia de ello propone cambiar todos los envases de sus productos por envases 
reciclados. Si bien entiende la importancia de este cambio también es consciente de los costos que esto conlleva, por lo cual se realizará de manera paulatina.
 
Se solicita un listado con los 12 productos más vendidos y los 12 productos menos vendidos del último año. 
Comparar la cantidad vendidad de cada uno de estos productos con la cantidad vendida del año anterior e indicar 
el String 'Mas ventas' o 'Menos ventas', según corresponda. Además indicar el envase.
Nota: No se puede usar select en el from.
*/

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

/* FOTO 3
Armar una consulta que muestra para todos los productos:
-Producto
-Detalle del producto
-Detalle Composición (Si no es compuesto usar string "SIN COMPOSICION" y si es compuesto poner "CON COMPOSICIÓN")
-Cantidad de componentes (Si no es compuesto se tiene que mostrar cero)
-Cantidad de veces que fue comprado por distintos clientes
Nota: No se permite usar sub select en el FROM.
*/

SELECT prod_codigo,prod_detalle,
CASE
	WHEN prod_codigo IN (SELECT comp_producto FROM Composicion)
		THEN 'CON COMPOSICION'
		ELSE 'SIN COMPOSICION'
END,
ISNULL((SELECT COUNT(*) FROM Composicion WHERE comp_producto= prod_codigo),0),
COUNT(DISTINCT fact_cliente)
FROM Producto
JOIN Item_Factura ON item_producto=prod_codigo
JOIN Factura ON fact_numero+fact_sucursal+fact_tipo=item_numero+item_sucursal+item_tipo
GROUP BY prod_codigo,prod_detalle

/* FOTO 4
Realizar una consulta SQL que retorne para todos los productos que se vendieron en 2 años consecutivos:
- Nombre de producto
- Cantidad de unidades vendidas en toda la historia

El resultado debera ser ordenado por precio unitario maximo vendido en la historia
*/

SELECT prod_detalle,SUM(item_cantidad) FROM Producto
JOIN Item_Factura ON item_producto=prod_codigo
JOIN Factura F1 ON F1.fact_numero+F1.fact_sucursal+F1.fact_tipo=item_numero+item_sucursal+item_tipo
WHERE prod_codigo IN (SELECT prod_codigo FROM Producto
					 JOIN Item_Factura ON item_producto=prod_codigo
					 JOIN Factura F2 ON F2.fact_numero+F2.fact_sucursal+F2.fact_tipo=item_numero+item_sucursal+item_tipo
					 WHERE YEAR(F1.fact_fecha) = YEAR(F2.fact_fecha) AND 
prod_codigo IN (SELECT prod_codigo FROM Producto
				JOIN Item_Factura ON item_producto=prod_codigo
				JOIN Factura F3 ON F3.fact_numero+F3.fact_sucursal+F3.fact_tipo=item_numero+item_sucursal+item_tipo
				WHERE YEAR(F1.fact_fecha) + 1 = YEAR(F3.fact_fecha) 
				) 
					 )
GROUP BY prod_detalle
ORDER BY MAX(item_precio)

/* FOTO 6
Mostrar los dos empleados del mes, estos son:
a) El empleado que en el mes actual (en el cual se ejecuta la query) vendió más en dinero(fact_total).
b) El segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) vendió más cantidades (unidades de productos).
Se deberá mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 'MEJOR FACTURACION' y para el segundo
'VENDIÓ MÁS UNIDADES'.
NOTA: Si el empleado que más vendió en facturación y cantidades es el mismo, solo mostrar una fila que diga el empleado y 'MEJOR EN TODO'.
NOTA2: No se debe usar subselect en el from
*/

SELECT RTRIM(LTRIM(E.empl_apellido)) + ' ' + RTRIM(LTRIM(E.empl_nombre)) AS [Nombre Empleado]
    , CASE WHEN E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(fact_total) DESC)
                THEN 'Mejor Facturación'
            WHEN E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(item_cantidad) DESC)
                THEN 'Vendió más unidades'
            WHEN E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(item_cantidad) DESC) AND E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(fact_total) DESC)
                THEN 'Mejor en Todo'
        END AS [Razón]
FROM Empleado E
GROUP BY E.empl_nombre, E.empl_apellido, E.empl_codigo
HAVING
    E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(fact_total) DESC) OR
    E.empl_codigo IN (SELECT TOP 1 empl_codigo FROM Empleado
                    JOIN Factura ON fact_vendedor=empl_codigo
                    JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
                    WHERE MONTH(fact_fecha) = MONTH(GETDATE())
                    GROUP BY empl_codigo
                    ORDER BY SUM(item_cantidad) DESC)
ORDER BY E.empl_codigo ASC


/* FOTO 7
Se pide realizar una consulta SQL que retorne POR CADA AÑO, el cliente que más compro (fact_total), 
la cantidad de artículos distintos comprados, la cantidad de rubros distintos comprados.
Solamente se deberán mostrar aquellos clientes que posean al menos 10 facturas o más por año.
El resultado debe ser ordenado por año.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el 
usuario para este punto.
*/

SELECT YEAR(fact_fecha), 
(SELECT TOP 1 fact_cliente FROM Factura
WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
GROUP BY fact_cliente
ORDER BY SUM(fact_total) DESC
),
COUNT(DISTINCT prod_codigo),
COUNT(DISTINCT prod_rubro) 
FROM Cliente
JOIN Factura F1 ON F1.fact_cliente=clie_codigo
JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=F1.fact_numero+F1.fact_sucursal+F1.fact_tipo
JOIN Producto ON prod_codigo = item_producto
WHERE fact_cliente IN (SELECT fact_cliente 
					   FROM Factura
					   WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha)
					   GROUP BY fact_cliente
					   HAVING COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) >= 10
					   )
GROUP BY YEAR(F1.fact_fecha)
ORDER BY YEAR(F1.fact_fecha)


SELECT fact_cliente FROM Factura
WHERE YEAR(fact_fecha) = 2010
GROUP BY fact_cliente
HAVING COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) >= 10
ORDER BY fact_cliente

----2012 -> 01742 | 2011 -> 01742 | 2010  ->01772 Y 01634


/* FOTO 8 S2L
Se pide realizar una consulta SQL que retorne todos los clientes que tuvieron mas ventas
(cantidad de articulos vendidos) en el 2012 que en el 2011 y ademas mostraar
1) codigo del cliente
2) razon social
3) cantidad de productos compuestos (en unidades) que vendio en 2019 
El resultado debe ser ordenado por limite de credito del cliente de mayor a menor
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto
*/
--Mi solución
SELECT clie_codigo,clie_razon_social,
(SELECT SUM(item_cantidad) FROM Item_Factura
JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
WHERE YEAR(fact_fecha) = 2019 AND item_producto IN (SELECT comp_producto FROM Composicion))
FROM Cliente
JOIN Factura ON fact_cliente = clie_codigo
WHERE (SELECT SUM(item_cantidad) FROM Factura
	  JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
	  WHERE YEAR(fact_fecha) = 2012 AND fact_cliente = clie_codigo
	   ) > 
	   (SELECT SUM(item_cantidad) FROM Factura
	    JOIN Item_Factura ON item_numero+item_sucursal+item_tipo=fact_numero+fact_sucursal+fact_tipo
	    WHERE YEAR(fact_fecha) = 2011 AND fact_cliente = clie_codigo
	    )
GROUP BY clie_codigo,clie_razon_social,clie_limite_credito
ORDER BY clie_limite_credito DESC

--Lucho
 SELECT C.clie_codigo AS [Código de cliente]
    , C.clie_razon_social AS [Razón Social]
    , (SELECT ISNULL(SUM(item_cantidad),0) 
        FROM Item_Factura
            JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
            JOIN Composicion ON comp_producto = item_producto
        WHERE fact_cliente = C.clie_codigo 
            AND YEAR(fact_fecha) = 2019) AS [Cantidad de productos compuestos que vendió en el 2019]
FROM Cliente C
    JOIN Factura ON fact_cliente = C.clie_codigo
    JOIN Item_Factura ON item_numero+item_sucursal+item_tipo = fact_numero+fact_sucursal+fact_tipo
WHERE  (SELECT SUM(item_cantidad) 
        FROM Item_Factura
            JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
        WHERE fact_cliente = C.clie_codigo 
            AND YEAR(fact_fecha) = 2012) 
            > 
       (SELECT SUM(item_cantidad) 
        FROM Item_Factura
            JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
        WHERE fact_cliente = C.clie_codigo 
            AND YEAR(fact_fecha) = 2011)
GROUP BY C.clie_codigo, C.clie_razon_social, C.clie_limite_credito
ORDER BY C.clie_limite_credito DESC

/*PARCIALES DEL 09/11*/
/* 1)
Se necesita saber que productos no son vendidos durante el año 2011 y cuales si. La consulta debe mostrar:

• Código de producto
• Nombre de Producto
• Fue Vendido (Si o No) según el caso.
• Cantidad de componentes.
El resultado deberá ser ordenado por cantidad total de clientes que los compraron en la historia ascendente.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/

SELECT P.prod_codigo AS [Código de Producto]
	, P.prod_detalle AS [Nombre de Producto]
	, CASE WHEN P.prod_codigo IN (SELECT item_producto 
								  FROM Item_Factura
									  JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
								  WHERE YEAR(fact_fecha) = 2011)
				THEN 'SI'
			ELSE 'NO'
	  END AS [Fue Vendido en 2011]
	, ISNULL((SELECT COUNT(comp_componente) FROM Composicion 
			  WHERE comp_producto = P.prod_codigo), 0) AS [Cantidad de componentes]
FROM Producto P
GROUP BY P.prod_codigo, P.prod_detalle
ORDER BY (SELECT COUNT(DISTINCT fact_cliente) 
		  FROM Item_Factura
			  JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		  WHERE item_producto = P.prod_codigo) ASC


/*Realizar una consulta SQL que retorne, para cada producto con más de 2 artículos distintos en su composición la siguiente información.

1)      Detalle del producto

2)      Rubro del producto

3)      Cantidad de veces que fue vendido

 El resultado deberá mostrar ordenado por la cantidad de los productos que lo componen.

 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/

SELECT prod_detalle,prod_rubro,COUNT(DISTINCT item_numero+item_sucursal+item_tipo)
FROM Producto
JOIN Item_Factura ON item_producto=prod_codigo
WHERE (SELECT COUNT(DISTINCT comp_componente) FROM Composicion WHERE comp_producto=prod_codigo) >=1
GROUP BY prod_detalle,prod_rubro,prod_codigo
ORDER BY (SELECT COUNT(DISTINCT comp_componente) FROM Composicion WHERE comp_producto=prod_codigo) DESC

--LA FORMA DEL PIBE SE SACÓ 8 OCTAVIO LOZANO
select prod_detalle [Producto], 
	   rubr_id [Rubro],
	   count(distinct item_tipo+item_sucursal+item_numero) [Cantidad de veces vendido]
from Composicion left join Producto on prod_codigo = comp_producto
				 join Rubro on prod_rubro = rubr_id
				 left join Item_Factura on prod_codigo = item_producto
group by prod_codigo, prod_detalle, rubr_id
having count(distinct comp_componente) >= 1
order by count(distinct comp_componente) desc;


/*
Mostrar las 5 zonas donde menor cantidad de ventas se están realizando en el año actual. 
Recordar que un empleado está puesto como fact_vendedor en factura. 
De aquellas zonas donde menores ventas tengamos, se deberá mostrar (cantidad de clientes distintos que operan en esa zona), 
cantidad de clientes que aparte de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). 
El resultado se deberá mostrar por cantidad de productos vendidos en la zona en cuestión de manera descendiente.

 Nota: No se puede usar select en el from.
*/

--Se sacó 10 castigliani ezequiel

select depa_zona, count(distinct fact_cliente),
(
	select count(distinct fact_cliente)
	from Factura
	join Empleado on empl_codigo = fact_vendedor
	--having count(distinct fact_vendedor) > 1
	where fact_cliente in	(
								select fact_cliente from Factura
								Join Empleado on empl_codigo = fact_vendedor
								Join Departamento on depa_codigo = empl_departamento
								where depa_zona <> d.depa_zona 
							)
		and fact_cliente in	(
								select fact_cliente from Factura
								Join Empleado on empl_codigo = fact_vendedor
								Join Departamento on depa_codigo = empl_departamento
								where depa_zona = d.depa_zona
							)
)
from Departamento d
Join Empleado on empl_departamento = d.depa_codigo
Join Factura on fact_vendedor = empl_codigo
Join Item_Factura on item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
where depa_zona in	(
						select top 5 depa_zona
						from Departamento
						Join Empleado on empl_departamento = depa_codigo
						Join Factura on fact_vendedor = empl_codigo
						group by depa_zona
						order by count(distinct fact_tipo+fact_sucursal+fact_numero) asc
					)
	and year(fact_fecha) = 2012 --year(GETDATE())
group by depa_zona
order by sum(item_cantidad) desc


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

--Se sacó 10 Mattioli Martina

SELECT	prod_codigo, prod_detalle,
		count(DISTINCT I1.item_tipo+I1.item_numero+I1.item_sucursal),
		count(DISTINCT I2.item_tipo+I2.item_numero+I2.item_sucursal),
		count(DISTINCT I2.item_producto)
FROM Item_Factura I1
RIGHT JOIN Producto ON I1.item_producto = prod_codigo 
JOIN Composicion ON prod_codigo = comp_componente
JOIN Item_Factura I2 ON I2.item_producto = comp_producto
GROUP BY prod_codigo, prod_detalle
ORDER BY 3 DESC

/*
Realizar una consulta SQL que retorne, para cada producto con más de 2 artículos distintos en su composición 
la siguiente información.

1)      Detalle del producto
2)      Rubro del producto
3)      Cantidad de veces que fue vendido

 El resultado deberá mostrar ordenado por la cantidad de los productos que lo componen.
 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.

*/

select  p1.prod_detalle as [detalle del producto],
		p1.prod_rubro  as [rubro del producto],
		( 
			select count(i1.item_numero+i1.item_sucursal+i1.item_tipo)
			from Item_Factura i1
				where i1.item_producto=p1.prod_codigo
		) as [cantidad de veces que fue vendido]
	
from Producto p1
join Composicion on comp_producto=p1.prod_codigo
	group by p1.prod_detalle,p1.prod_rubro,p1.prod_codigo
	HAVING COUNT(comp_componente) > 1
	order by count(comp_componente) desc 

/*
De las 10 familias de productos que menores ventas tuvieron en el 2011 (considerar como menor también si no se tuvo ventas), se le pide mostrar:

Detalle de la Familia

Monto total Facturado por familia en el año

Cantidad de productos distintos comprados de la familia

Cantidad de productos con composición que tiene la familia

Cliente que más compro productos de esa familia.

Nota: No se permiten sub select en el FROM.
*/

SELECT fami_detalle, SUM(item_cantidad*item_precio), COUNT(DISTINCT item_producto), 
		(SELECT COUNT(*) FROM Composicion
		JOIN Producto ON prod_codigo = comp_producto WHERE prod_familia = fami_id),
		(SELECT TOP 1 fact_cliente FROM Factura
		JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
		JOIN Producto ON prod_codigo = item_producto
		WHERE prod_familia = fami_id
		GROUP BY fact_cliente
		ORDER BY SUM(item_cantidad) DESC
		)
FROM Familia
JOIN Producto ON prod_familia = fami_id 
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
WHERE fami_id IN (SELECT TOP 10 prod_familia FROM Producto 
					JOIN Item_Factura ON item_producto = prod_codigo
				    JOIN Factura ON item_tipo+item_sucursal+item_numero = fact_tipo+fact_sucursal+fact_numero
					WHERE YEAR(fact_fecha) = 2011
					GROUP BY prod_familia
					ORDER BY ISNULL(SUM(item_cantidad*item_precio),0)
				  )
GROUP BY fami_detalle,fami_id



/* Se solicita una estadística por Año y familia, para ello se deberá mostrar:

Año, Código de familia, Detalle de familia, cantidad de facturas, cantidad de productos con composición vendidos, monto total vendido

Solo se deberán considerar las familias que tengan al menos un producto con composición y que se hayan vendido conjuntamente (en la misma factura) con otra familia distinta

Nota: No se puede usar select en el from.
*/

SELECT YEAR(F1.fact_fecha),FA1.fami_id,FA1.fami_detalle,COUNT(DISTINCT F1.fact_numero+F1.fact_sucursal+F1.fact_tipo),COUNT(DISTINCT P1.prod_codigo),SUM(I1.item_cantidad*I1.item_precio) 
FROM Factura F1
JOIN Item_Factura I1 ON I1.item_numero+I1.item_sucursal+I1.item_tipo = F1.fact_numero+F1.fact_sucursal+F1.fact_tipo
JOIN Producto P1 ON P1.prod_codigo = I1.item_producto
JOIN Familia FA1 ON FA1.fami_id = P1.prod_familia,
Item_Factura I2 
JOIN Producto P2 ON P2.prod_codigo = I2.item_producto
WHERE FA1.fami_id IN (SELECT prod_familia FROM Producto
				 JOIN Composicion ON comp_producto = prod_codigo
				 GROUP BY prod_codigo,prod_familia
				 )
AND I1.item_numero+I1.item_sucursal+I1.item_tipo = I2.item_numero+I2.item_sucursal+I2.item_tipo AND FA1.fami_id > P2.prod_familia
GROUP BY YEAR(F1.fact_fecha),FA1.fami_id,FA1.fami_detalle

/*
Realizar una consulta SQL que retorne: Año, cantidad de productos compuestos vendidos en el Año, cantidad de facturas realizadas en el Año, monto total facturado en el Año, 
monto total facturado en el Año anterior.
Solamente considerar aquellos Años donde la cantidad de unidades vendidas de todos los artículos sea mayor a 1000.
Se debera ordenar el resultado por cantidad vendida en el año
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/

SELECT YEAR(F1.fact_fecha),
(SELECT COUNT(DISTINCT prod_codigo) 
FROM Producto
JOIN Item_Factura ON item_producto = prod_codigo
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE prod_codigo IN (SELECT comp_producto FROM Composicion) AND YEAR(fact_fecha) = YEAR(F1.fact_fecha)),
COUNT(DISTINCT F1.fact_tipo+F1.fact_sucursal+F1.fact_numero),
SUM(item_cantidad*item_precio),
(SELECT SUM(item_cantidad * item_precio) FROM Item_Factura
JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
WHERE YEAR(fact_fecha) = YEAR(F1.fact_fecha) - 1) 
FROM Factura F1
JOIN Item_Factura ON item_tipo+item_sucursal+item_numero = F1.fact_tipo+F1.fact_sucursal+F1.fact_numero
GROUP BY YEAR(fact_fecha)
HAVING SUM(item_cantidad) > 1000
ORDER BY SUM(item_cantidad)


/*
Con el fin de analizar el posicionamiento de ciertos productos se necesita mostrar solo los 5 rubros de productos más vendidos y además, 
por cada uno de estos rubros  saber cuál es el producto más exitoso (es decir, con más ventas) y si el mismo es “simple” o “compuesto”. 
Por otro lado, se pide se indique si hay “stock disponible” o si hay “faltante” para afrontar las ventas del próximo mes. 
Considerar que se estima que la venta aumente un 10% respecto del mes de diciembre del año pasado.
Armar una consulta SQL que retorne esta información.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto
*/

SELECT (SELECT TOP 1 prod_codigo FROM Producto
		JOIN Item_Factura ON item_producto = prod_codigo
		WHERE prod_rubro = P1.prod_rubro
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad*item_precio)
		),
CASE
	WHEN (SELECT TOP 1 prod_codigo FROM Producto
		JOIN Item_Factura ON item_producto = prod_codigo
		WHERE prod_rubro = P1.prod_rubro
		GROUP BY prod_codigo
		ORDER BY SUM(item_cantidad*item_precio)
		) IN (SELECT comp_componente FROM Composicion)

	THEN 'COMPUESTO'
	ELSE 'SIMPLE'
END,
CASE 
	WHEN (SELECT SUM(stoc_cantidad) FROM STOCK WHERE stoc_producto=P1.prod_codigo) > (SELECT SUM(item_cantidad*item_precio) * 1.10 FROM Item_Factura
																					  JOIN Factura ON fact_tipo+fact_sucursal+fact_numero = item_tipo+item_sucursal+item_numero
																					  WHERE YEAR(fact_fecha) > DATEDIFF(DD,YEAR(F1.fact_fecha),1) AND YEAR(fact_fecha) < YEAR(F1.fact_fecha)
																					  )
		THEN 'STOCK DISPONIBLE'
		ELSE 'FALTANTE'
END
FROM Producto P1
JOIN Item_Factura I1 ON I1.item_producto = P1.prod_codigo
JOIN Factura F1 ON F1.fact_tipo+F1.fact_sucursal+F1.fact_numero = I1.item_tipo+I1.item_sucursal+I1.item_numero
WHERE P1.prod_rubro IN (SELECT TOP 5 prod_rubro FROM Producto
					JOIN Item_Factura ON item_producto = prod_codigo
					GROUP BY prod_rubro
					ORDER BY SUM(item_cantidad*item_precio) DESC
					)
GROUP BY P1.prod_rubro,P1.prod_codigo,fact_fecha