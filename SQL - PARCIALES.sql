USE GD2015C1

-- EJERCICIO 1

/*Armar una consulta SQL que muestre aquel/aquellos clientes que en 2 a�os consecutivos (de existir), fueron los mejores compradores, es decir, 
los que en monto total facturado anual fue el m�ximo. De esos clientes mostrar , razon social, domicilio, cantidad de unidades compradas 
en el �ltimo a�o.
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

/*Se necesita saber que productos no han sido vendidos durante el a�o 2012 pero que s� tuvieron ventas en a�o anteriores. 
De esos productos mostrar:
1.C�digo de producto
2.Nombre de Producto
3.Un string que diga si es compuesto o no.

El resultado deber� ser ordenado por cantidad vendida en a�os anteriores.
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
	year(f.fact_fecha) < 2012 -- vendidos en a�os anteriores
	and it.item_producto not in (
	select it2.item_producto from Item_Factura it2 join Factura f on f.fact_numero + f.fact_sucursal + f.fact_tipo = it2.item_numero + it2.item_sucursal + it2.item_tipo
	where year(f.fact_fecha) = 2012) -- no vendidos en 2012
group by
	it.item_producto, p.prod_detalle 
order by 
	sum(it.item_cantidad) asc

-- EJERCICIO 3
/* Foto 1
La empresa esta muy comprometida con el desarrollos sustentable y como consecuencia de ello propone cambiar todos los envases de sus productos por envases 
reciclados. Si bien entiende la importancia de este cambio tambi�n es consciente de los costos que esto conlleva, por lo cual se realizar� de manera paulatina.
 
Se solicita un listado con los 12 productos m�s vendidos y los 12 productos menos vendidos del �ltimo a�o. 
Comparar la cantidad vendidad de cada uno de estos productos con la cantidad vendida del a�o anterior e indicar 
el String 'Mas ventas' o 'Menos ventas', seg�n corresponda. Adem�s indicar el envase.
Nota: No se puede usar select en el from.
*/

--EJERCICIO 4

/* FOTO 3
Armar una consulta que muestra para todos los productos:
-Producto
-Detalle del producto
-Detalle Composici�n (Si no es compuesto usar string "SIN COMPOSICION" y si es compuesto poner "CON COMPOSICI�N")
-Cantidad de componentes (Si no es compuesto se tiene que mostrar cero)
-Cantidad de veces que fue comprado por distintos clientes
Nota: No se permite usar sub select en el FROM.
*/

--EJERCICIO 5


/* FOTO 6
Mostrar los dos empleados del mes, estos son:
a) El empleado que en el mes actual (en el cual se ejecuta la query) vendi� m�s en dinero(fact_total).
b) El segundo empleado del mes, es aquel que en el mes actual (en el cual se ejecuta la query) vendi� m�s cantidades (unidades de productos).
Se deber� mostrar apellido y nombre del empleado en una sola columna y para el primero un string que diga 'MEJOR FACTURACION' y para el segundo
'VENDI� M�S UNIDADES'.
NOTA: Si el empleado que m�s vendi� en facturaci�n y cantidades es el mismo, solo mostrar una fila que diga el empleado y 'MEJOR EN TODO'.
NOTA2: No se debe usar subselect en el from
*/


--EJERCICIO 6

/* FOTO 7
Se pide realizar una consulta SQL que retorne POR CADA A�O, el cliente que m�s compro (fact_total), 
la cantidad de art�culos distintos comprados, la cantidad de rubros distintos comprados.
Solamente se deber�n mostrar aquellos clientes que posean al menos 10 facturas o m�s por a�o.
El resultado debe ser ordenado por a�o.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el 
usuario para este punto.
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

-- EJERCICIO 8

/*PARCIALES DEL 09/11*/
/* 1)
Se necesita saber que productos no son vendidos durante el a�o 2011 y cuales si. La consulta debe mostrar:

� C�digo de producto
� Nombre de Producto
� Fue Vendido (Si o No) seg�n el caso.
� Cantidad de componentes.
El resultado deber� ser ordenado por cantidad total de clientes que los compraron en la historia ascendente.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/

--EJERCICIO 9


/*Realizar una consulta SQL que retorne, para cada producto con m�s de 2 art�culos distintos en su composici�n la siguiente informaci�n.

1)      Detalle del producto

2)      Rubro del producto

3)      Cantidad de veces que fue vendido

 El resultado deber� mostrar ordenado por la cantidad de los productos que lo componen.

 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.*/



 -- EJERCICIO 10

/*
Mostrar las 5 zonas donde menor cantidad de ventas se est�n realizando en el a�o actual. 
Recordar que un empleado est� puesto como fact_vendedor en factura. 
De aquellas zonas donde menores ventas tengamos, se deber� mostrar (cantidad de clientes distintos que operan en esa zona), 
cantidad de clientes que aparte de ese zona, compran en otras zonas (es decir, a otros vendedores de la zona). 
El resultado se deber� mostrar por cantidad de productos vendidos en la zona en cuesti�n de manera descendiente.

 Nota: No se puede usar select en el from.
*/



--EJERCICIO 11

/*
se requiere mostrar los productos que sean componentes y 
que se hayan vendido en forma unitaria o a trav�s del producto al cual compone, 
por ejemplo una hamburguesa se deber� mostrar si se vendi� como hamburguesa y si se vendi� un combo que est� compuesto por una hamburguesa. 

Se deber� mostrar:

C�digo de producto, nombre de producto, cantidad de facturas vendidas solo, 
cantidad de facturas vendidas de los productos que compone, cantidad de productos a los cuales compone que se vendieron

El resultado deber� ser ordenado por el componente que se haya vendido solo en m�s facturas 

Aclaracion: se debe resolver en una sola consulta sin utilizar subconsultas en ning�n lugar del Select 
*/

-- EJERCICIO 12
/*
Realizar una consulta SQL que retorne, para cada producto con m�s de 2 art�culos distintos en su composici�n 
la siguiente informaci�n.

1)      Detalle del producto
2)      Rubro del producto
3)      Cantidad de veces que fue vendido

 El resultado deber� mostrar ordenado por la cantidad de los productos que lo componen.
 NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.

*/

-- EJERCICIO 13

/*
De las 10 familias de productos que menores ventas tuvieron en el 2011 (considerar como menor tambi�n si no se tuvo ventas), se le pide mostrar:

Detalle de la Familia

Monto total Facturado por familia en el a�o

Cantidad de productos distintos comprados de la familia

Cantidad de productos con composici�n que tiene la familia

Cliente que m�s compro productos de esa familia.

Nota: No se permiten sub select en el FROM.
*/

-- EJERCICIO 14


/* Se solicita una estad�stica por A�o y familia, para ello se deber� mostrar:

A�o, C�digo de familia, Detalle de familia, cantidad de facturas, cantidad de productos con composici�n vendidos, monto total vendido

Solo se deber�n considerar las familias que tengan al menos un producto con composici�n y que se hayan vendido conjuntamente (en la misma factura) con otra familia distinta

Nota: No se puede usar select en el from.
*/

-- EJERCIO 15

/*
Realizar una consulta SQL que retorne: A�o, cantidad de productos compuestos vendidos en el A�o, cantidad de facturas realizadas en el A�o, monto total facturado en el A�o, 
monto total facturado en el A�o anterior.
Solamente considerar aquellos A�os donde la cantidad de unidades vendidas de todos los art�culos sea mayor a 1000.
Se debera ordenar el resultado por cantidad vendida en el a�o
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto.
*/


-- EJERCICIO 16

/*
Con el fin de analizar el posicionamiento de ciertos productos se necesita mostrar solo los 5 rubros de productos m�s vendidos y adem�s, 
por cada uno de estos rubros  saber cu�l es el producto m�s exitoso (es decir, con m�s ventas) y si el mismo es �simple� o �compuesto�. 
Por otro lado, se pide se indique si hay �stock disponible� o si hay �faltante� para afrontar las ventas del pr�ximo mes. 
Considerar que se estima que la venta aumente un 10% respecto del mes de diciembre del a�o pasado.
Armar una consulta SQL que retorne esta informaci�n.
NOTA: No se permite el uso de sub-selects en el FROM ni funciones definidas por el usuario para este punto
*/


