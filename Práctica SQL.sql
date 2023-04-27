-- GU�A DE EJERCICIOS DE SQL

USE GD2015C1
GO

/*OBSERVACIONES DEL MODELO:
1. No hay rubros no relacionados con productos. En otras palabras, todo rubro pertenece s� o s� a al menos un producto.
*/

/*Ejercicio 1: mostrar el c�digo, raz�n social de todos los clientes cuyo l�mite de cr�dito sea mayor o
igual a $ 1000 ordenado por c�digo de cliente.*/

SELECT clie_codigo, clie_razon_social, clie_limite_credito
FROM Cliente 
WHERE clie_limite_credito >= 1000
ORDER BY clie_codigo ASC

/*Ejercicio 2: mostrar el c�digo, detalle de todos los art�culos vendidos en el a�o 2012 ordenados por
cantidad vendida.*/

SELECT prod_codigo, prod_detalle, SUM(itf.item_cantidad) AS 'Cantidad vendida'
FROM Producto p
JOIN Item_Factura itf ON p.prod_codigo = itf.item_producto
JOIN Factura f on itf.item_tipo = f.fact_tipo AND itf.item_sucursal = f.fact_sucursal AND itf.item_numero = f.fact_numero
WHERE YEAR(fact_fecha) = 2012
GROUP BY p.prod_codigo, prod_detalle
ORDER BY SUM(itf.item_cantidad) ASC

/*Ejercicio 3: realizar una consulta que muestre c�digo de producto, nombre de producto y el stock
total, sin importar en que deposito se encuentre, los datos deben ser ordenados por
nombre del art�culo de menor a mayor.*/

SELECT p.prod_codigo, p.prod_detalle, SUM(s.stoc_cantidad) AS Stock --Con esto se consideran los productos que no tienen unidades en stock
FROM Producto p
LEFT JOIN STOCK s ON p.prod_codigo = s.stoc_producto --S�lo se consideran los productos que tienen un stock definido para cierto dep�sito
GROUP BY p.prod_codigo, p.prod_detalle
ORDER BY p.prod_detalle ASC

--Muchas veces el usar una subconsulta, peude generar el mismo efecto que un LEFT o RIGHT JOIN, tal y como se ve a continuaci�n:
SELECT p.prod_codigo, p.prod_detalle, (SELECT ISNULL(SUM(stoc_cantidad), 0) FROM STOCK WHERE stoc_producto = prod_codigo) AS Stock --Se incorporan los productos que no matchean con stock, por lo qeu su stoc_cantidad es desconocida, o sea NULL
FROM Producto p
ORDER BY p.prod_detalle ASC

--Obs�rvese lo qeu sucede si se pone SUM(ISNULL(stoc_cantidad, 0)):
SELECT p.prod_codigo, p.prod_detalle, (SELECT SUM(ISNULL(stoc_cantidad, 0)) FROM STOCK WHERE stoc_producto = prod_codigo) AS Stock --Se incorporan los productos que no matchean con stock, por lo qeu su stoc_cantidad es desconocida, o sea NULL
FROM Producto p
ORDER BY p.prod_detalle ASC

/*Ejercicio 4: realizar una consulta que muestre para todos los art�culos c�digo, detalle y cantidad de
art�culos que lo componen. Mostrar solo aquellos art�culos para los cuales el stock
promedio por dep�sito sea mayor a 100.*/

SELECT p.prod_codigo, p.prod_detalle, COUNT(DISTINCT c.comp_componente) AS 'Cantidad de art�culos que lo componen'--, AVG(stoc_cantidad) AS 'Promedio por dep�sito'
FROM Producto p
LEFT JOIN Composicion c ON p.prod_codigo = c.comp_producto
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
GROUP BY p.prod_codigo, p.prod_detalle
HAVING AVG(s.stoc_cantidad) > 100

/*Obs�rvese que el promedio por dep�sito hace referencia a la suma de las cantidades en stock para un producto determinado, dividido la cantidad de dep�sitos.
No es la suma en un dep�sito.
Por otra parte, se utiliza DISTINCT porque la tabla STOCK tiene mucha atomicidad, es decir, tiene muchos registros, y multiplica la cantidad de registros de 
las talbas producto y composicion joineadas, y si no se utilizara DISTINCT, la resoluci�n del ejercicio no ser�a correcta. Sin embargo, si no se desea 
utilizar DISTINCT, puede hacerse un subselect: */

SELECT p.prod_codigo, p.prod_detalle, COUNT(c.comp_componente) AS 'Cantidad de art�culos que lo componen'
FROM Producto p
LEFT JOIN Composicion c ON p.prod_codigo = c.comp_producto
GROUP BY p.prod_codigo, p.prod_detalle
HAVING (SELECT AVG(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo) > 100

--Otra forma es la que sigue:
SELECT p.prod_codigo, p.prod_detalle, COUNT(c.comp_componente) AS 'Cantidad de art�culos que lo componen'
FROM Producto p
LEFT JOIN Composicion c ON p.prod_codigo = c.comp_producto
WHERE prod_codigo IN (SELECT stoc_producto FROM STOCK GROUP BY stoc_producto HAVING AVG(stoc_cantidad) > 100)
GROUP BY p.prod_codigo, p.prod_detalle

--Con un subselect en un WHERE queda como sigue:
SELECT p.prod_codigo, p.prod_detalle, COUNT(c.comp_componente) AS 'Cantidad de art�culos que lo componen'
FROM Producto p
LEFT JOIN Composicion c ON p.prod_codigo = c.comp_producto
WHERE (SELECT AVG(s.stoc_cantidad) FROM STOCK s WHERE s.stoc_producto = p.prod_codigo) > 100
GROUP BY p.prod_codigo, p.prod_detalle

/*Ejercicio 5: realizar una consulta que muestre c�digo de art�culo, detalle y cantidad de egresos de
stock que se realizaron para ese art�culo en el a�o 2012 (egresan los productos que
fueron vendidos). Mostrar solo aquellos que hayan tenido m�s egresos que en el 2011.*/

SELECT p.prod_codigo, p.prod_detalle/*, i.item_cantidad*/, SUM(i.item_cantidad) AS 'Cantidad de egresos'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2012 /*AND p.prod_codigo = '00010340'*/
GROUP BY p.prod_codigo, p.prod_detalle
HAVING (SUM(i.item_cantidad) > 
	ISNULL((SELECT SUM(i1.item_cantidad)
	FROM Producto p1
	JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
	JOIN Factura f1 ON i1.item_numero = f1.fact_numero AND i1.item_sucursal = f1.fact_sucursal AND i1.item_tipo = f1.fact_tipo
	WHERE p.prod_codigo = p1.prod_codigo AND YEAR(f1.fact_fecha) = 2011 
	GROUP BY p1.prod_codigo, p1.prod_detalle),0))
ORDER BY p.prod_codigo

--No es necesario buscar en la tabla Producto
SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) AS 'Cantidad de egresos'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY p.prod_codigo, p.prod_detalle
HAVING (SUM(i.item_cantidad) > 
	ISNULL((SELECT SUM(i1.item_cantidad)
	FROM Item_Factura i1 
	JOIN Factura f1 ON i1.item_numero = f1.fact_numero AND i1.item_sucursal = f1.fact_sucursal AND i1.item_tipo = f1.fact_tipo
	WHERE i1.item_producto = p.prod_codigo AND YEAR(f1.fact_fecha) = 2011),0))
ORDER BY p.prod_codigo

--Con la siguiente query nos evitamos un JOIN
SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) AS 'Cantidad de egresos'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY p.prod_codigo, p.prod_detalle
HAVING (SUM(i.item_cantidad) > 
	ISNULL((SELECT SUM(i1.item_cantidad)
	FROM Item_Factura i1 
	JOIN Factura f1 ON i1.item_numero = f1.fact_numero AND i1.item_sucursal = f1.fact_sucursal AND i1.item_tipo = f1.fact_tipo
	WHERE YEAR(f1.fact_fecha) = 2011 AND p.prod_codigo = i1.item_producto
	GROUP BY i1.item_producto),0))
ORDER BY p.prod_codigo

/*A continuaci�n, se muestran los egresos para cada producto vendido, en los a�os 2012 y 2011*/

SELECT p.prod_codigo, p.prod_detalle, SUM(i.item_cantidad) AS 'Cantidad de egresos 2012', ISNULL((SELECT SUM(i1.item_cantidad)
	FROM Producto p1
	JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
	JOIN Factura f1 ON i1.item_numero = f1.fact_numero AND i1.item_sucursal = f1.fact_sucursal AND i1.item_tipo = f1.fact_tipo
	WHERE p.prod_codigo = p1.prod_codigo AND YEAR(f1.fact_fecha) = 2011
	GROUP BY p1.prod_codigo, p1.prod_detalle),0) AS 'Cantidad de egresos 2011'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2012 
GROUP BY p.prod_codigo, p.prod_detalle

/*Ejercicio 6: mostrar para todos los rubros de art�culos c�digo, detalle, cantidad de art�culos de ese
rubro y stock total de ese rubro de art�culos. Solo tener en cuenta aquellos art�culos que
tengan un stock mayor al del art�culo �00000000� en el dep�sito �00�.*/

SELECT
	r.rubr_id AS 'C�digo de rubro',
	r.rubr_detalle AS 'Detalle de Rubro',
	COUNT(p.prod_codigo) AS 'Cantidad de productos en el rubro',
	(SELECT SUM(s.stoc_cantidad)
	FROM STOCK s
	JOIN Producto p1 ON s.stoc_producto = p1.prod_codigo AND
					 p1.prod_rubro = r.rubr_id
					 AND p1.prod_codigo IN 
	                 ((SELECT stoc_producto FROM STOCK GROUP BY stoc_producto HAVING SUM(stoc_cantidad) >
					 (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = '00000000' AND stoc_deposito = '00')))) AS 'Cantidad de stock del rubro'
FROM Rubro r 
LEFT JOIN Producto p ON r.rubr_id = p.prod_rubro --Uso ISNULL y LEFT JOIN, debido a que, si bien est� hecha la observaci�n 1, en el modelo podr�an tenerse rubros sin productos (modalidad opcional).
WHERE (SELECT SUM(s1.stoc_cantidad) FROM STOCK s1 WHERE s1.stoc_producto = p.prod_codigo) >
	  (SELECT SUM(s1.stoc_cantidad)
	   FROM STOCK s1
	   WHERE s1.stoc_producto = '00000000' AND s1.stoc_deposito = '00')
GROUP BY r.rubr_id, r.rubr_detalle
ORDER BY r.rubr_id

--Otra forma de hacerlo es la siguiente:
SELECT r.rubr_id AS 'C�digo de rubro',
	   r.rubr_detalle AS 'Detalle de Rubro',
       COUNT(DISTINCT p.prod_codigo) AS 'Cantidad de productos en el rubro',
       SUM(stoc_cantidad) AS 'Cantidad de stock del rubro' FROM Rubro r
LEFT JOIN Producto p ON r.rubr_id = p.prod_rubro
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
WHERE p.prod_codigo IN (SELECT stoc_producto
					   FROM STOCK GROUP BY stoc_producto HAVING SUM(stoc_cantidad) >
					   (SELECT stoc_cantidad FROM STOCK WHERE stoc_producto = '00000000' AND stoc_deposito = '00'))
GROUP BY r.rubr_id, r.rubr_detalle

--La cantidad de productos por rubro es: 
SELECT r.rubr_id AS 'C�digo de rubro', r.rubr_detalle AS 'Detalle de Rubro', count(*) AS 'Cantidad de productos por rubro'
FROM Rubro r 
LEFT JOIN Producto p ON r.rubr_id = p.prod_rubro 
group by r.rubr_id, r.rubr_detalle
order BY r.rubr_id, r.rubr_detalle

--La cantidad de stock por rubro es la siguiente:
SELECT R.rubr_id, R.rubr_detalle, SUM(S.stoc_cantidad) FROM RUBRO R
JOIN Producto P ON P.prod_rubro = R.rubr_id 
JOIN STOCK S ON P.prod_codigo = S.stoc_producto
GROUP BY R.rubr_id, R.rubr_detalle

/*Ejercicio 7: generar una consulta que muestre para cada art�culo c�digo, detalle, mayor precio
menor precio y % de la diferencia de precios (respecto del menor Ej.: menor precio =
10, mayor precio =12 => mostrar 20 %). Mostrar solo aquellos art�culos que posean
stock.*/

SELECT
	p.prod_codigo,
	p.prod_detalle,
	MAX(i.item_precio) AS 'Mayor precio',
	MIN(i.item_precio) AS 'Menor precio',
	((MAX(i.item_precio) - MIN(i.item_precio)) * 100 / MIN(i.item_precio)) AS 'Diferencia porcentual entre el mayor y el menor precio, respecto del menor'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
WHERE p.prod_codigo IN (SELECT stoc_producto FROM STOCK GROUP BY stoc_producto HAVING SUM(stoc_cantidad) > 0)
GROUP BY p.prod_codigo, p.prod_detalle

/*Ejercicio 8: mostrar para el o los art�culos que tengan stock en todos los dep�sitos, nombre del
art�culo, stock del dep�sito que m�s stock tiene.*/

/*Esta consulta muestra todos los productos con stock mayor que 0 en todos los dep�sitos en los cuales hay stock de esos productos, con las cantidades de stock.
Sirve para entender mejor qu� es lo que se est� haciendo.*/
SELECT t.prod_detalle, depo_detalle, s.stoc_cantidad, t.[Stock del dep�sito con m�s stock]
FROM (SELECT p.prod_detalle, MAX(s.stoc_cantidad) AS 'Stock del dep�sito con m�s stock'
	FROM Producto p
	JOIN STOCK s ON p.prod_codigo = s.stoc_producto
	JOIN DEPOSITO d ON s.stoc_deposito = d.depo_codigo
	GROUP BY p.prod_detalle) t 
JOIN Producto p ON t.prod_detalle = p.prod_detalle 
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
JOIN DEPOSITO d ON s.stoc_deposito = d.depo_codigo
ORDER BY t.prod_detalle ASC

--Resoluci�n del ejercicio:
SELECT p.prod_detalle, MAX(s.stoc_cantidad) AS 'Stock del dep�sito con m�s stock'
FROM Producto p
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
WHERE s.stoc_cantidad > 0 
GROUP BY p.prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) FROM DEPOSITO)
--ORDER BY p.prod_detalle

/*Ejercicio 9: mostrar el c�digo del jefe, c�digo del empleado que lo tiene como jefe, nombre del
mismo y la cantidad de dep�sitos que ambos tienen asignados.*/

SELECT
	jefe.empl_codigo AS 'C�digo de jefe',
	empl.empl_codigo AS 'C�digo del empelado que lo tiene como jefe',
	empl.empl_nombre AS 'Nombre del empleado',
	COUNT(d.depo_codigo) AS 'Cantidad de dep�sitos a cargo del empleado',
	(SELECT COUNT(depo_codigo) FROM DEPOSITO d1 WHERE d1.depo_encargado = jefe.empl_codigo) AS 'Cantidad de dep�sitos a cargo del jefe'
FROM Empleado jefe
JOIN Empleado empl ON empl.empl_jefe = jefe.empl_codigo
LEFT JOIN DEPOSITO d ON empl.empl_codigo = d.depo_encargado
GROUP BY jefe.empl_codigo, empl.empl_codigo, empl.empl_nombre
ORDER BY empl.empl_nombre

--Contando la cantidad de dep�sitos en total que ambos tinene asignados queda as�:
SELECT
	jefe.empl_codigo AS 'C�digo de jefe',
	empl.empl_codigo AS 'C�digo del empelado que lo tiene como jefe',
	empl.empl_nombre AS 'Nombre del empleado',
	COUNT(d.depo_codigo) AS 'Cantidad de dep�sitos a cargo entre ambos'
FROM Empleado jefe
JOIN Empleado empl ON empl.empl_jefe = jefe.empl_codigo
LEFT JOIN DEPOSITO d ON empl.empl_codigo = d.depo_encargado OR jefe.empl_codigo = d.depo_encargado
GROUP BY jefe.empl_codigo, empl.empl_codigo, empl.empl_nombre
ORDER BY empl.empl_nombre

/*Ejercicio 10: mostrar los 10 productos m�s vendidos en la historia y tambi�n los 10 productos menos
vendidos en la historia. Adem�s mostrar de esos productos, quien fue el cliente que
mayor compra realizo.*/

SELECT 
	masYMenosVendidos.prod_codigo AS 'C�digo de producto',
	masYMenosVendidos.prod_detalle AS 'Detalle de producto',
	masYMenosVendidos.cantidad AS 'Cantidad de producto',
	(SELECT TOP 1 fact_cliente
	FROM Factura f
	JOIN Item_Factura if2 ON f.fact_numero = item_numero AND f.fact_tipo = item_tipo AND f.fact_sucursal = item_sucursal 
	WHERE item_producto = masYMenosVendidos.prod_codigo
	GROUP BY fact_cliente
	ORDER BY SUM(item_cantidad) DESC) AS 'Cliente que mayor cantidad de compras realiz�'
FROM (SELECT prod_codigo,
		prod_detalle,
		SUM(item_cantidad) AS cantidad,
		ROW_NUMBER() OVER (ORDER BY SUM(item_cantidad) DESC) AS ordenDesc,
		ROW_NUMBER() OVER (ORDER BY SUM(item_cantidad) ASC) AS ordenAsc
	  FROM Producto JOIN Item_Factura ON prod_codigo = item_producto
	  GROUP BY prod_detalle, prod_codigo
	) AS masYMenosVendidos
WHERE (masYMenosVendidos.ordenDesc < 10) or (masYMenosVendidos.ordenAsc < 10)

--La forma correcta de resolverlo es la siguiente:
SELECT p.prod_detalle AS 'Nombre de producto',
	   (SELECT TOP 1 f.fact_cliente
	   FROM Factura f
	   JOIN Item_Factura i ON f.fact_numero = i.item_numero AND f.fact_sucursal = i.item_sucursal AND f.fact_tipo = i.item_tipo
	   WHERE i.item_producto = p.prod_codigo
	   GROUP BY f.fact_cliente
	   ORDER BY SUM(i.item_cantidad)) AS 'Cliente que m�s compras realiz�'
FROM Producto p
WHERE p.prod_codigo IN (SELECT TOP 10 i.item_producto
					   FROM Item_Factura i
					   GROUP BY item_producto
					   ORDER BY SUM(i.item_cantidad) DESC)
					   OR p.prod_codigo IN
					   (SELECT TOP 10 i.item_producto
					   FROM Item_Factura i
					   GROUP BY item_producto
					   ORDER BY SUM(i.item_cantidad) ASC)

/*Ejercicio 11: realizar una consulta que retorne el detalle de la familia, la cantidad diferentes de
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
HAVING (SELECT SUM(fac.fact_total) --Este select es el mismo de arriba, s�lo que no se puede reutilizar el alias
		FROM Producto p
		JOIN Item_Factura i ON p.prod_codigo = i.item_producto
		JOIN Factura fac ON i.item_numero = fac.fact_numero AND i.item_sucursal = fac.fact_sucursal AND i.item_tipo = fac.fact_tipo
		WHERE p.prod_familia = f.fami_id AND YEAR(fac.fact_fecha) = 2012) > 20000 
ORDER BY COUNT(DISTINCT p.prod_codigo) DESC

--Total de ventas por familia
SELECT fam.fami_detalle, SUM(fac.fact_total) AS 'Total ventas por familia'
FROM Familia fam
JOIN Producto p ON p.prod_familia = fam.fami_id
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura fac ON i.item_numero = fac.fact_numero AND i.item_sucursal = fac.fact_sucursal AND i.item_tipo = fac.fact_tipo
GROUP BY fam.fami_detalle

/*Ejercicio 12: mostrar nombre de producto, cantidad de clientes distintos que lo compraron importe
promedio pagado por el producto, cantidad de dep�sitos en los cuales hay stock del
producto y stock actual del producto en todos los dep�sitos. Se deber�n mostrar
aquellos productos que hayan tenido operaciones en el a�o 2012 y los datos deber�n
ordenarse de mayor a menor por monto vendido del producto.*/

SELECT p.prod_detalle,
	   COUNT(DISTINCT c.clie_codigo) AS 'Cantidad de clientes que lo compraron',
	   AVG(i.item_precio) AS 'Importe promedio pagado por el producto',
	   (SELECT COUNT(d.depo_codigo)
	   FROM Producto p1
	   JOIN STOCK s ON p1.prod_codigo = s.stoc_producto
	   JOIN DEPOSITO d ON s.stoc_deposito = d.depo_codigo
	   WHERE p1.prod_codigo = p.prod_codigo AND s.stoc_cantidad > 0) AS 'Cantidad de dep�sitos en los cuales hay stock del producto',
	   (SELECT SUM(ISNULL(s.stoc_cantidad, 0))
	   FROM Producto p1
	   JOIN STOCK s ON p1.prod_codigo = s.stoc_producto
	   WHERE p1.prod_codigo = p.prod_codigo) AS 'Cantidad de stock actual en todos los dep�sitos'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
JOIN Cliente c ON f.fact_cliente = c.clie_codigo
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_detalle, p.prod_codigo
ORDER BY AVG(i.item_precio) DESC

--Cantidad de dep�sitos en los cuales cada producto vendido tiene stock
SELECT p.prod_codigo AS 'C�dgio de producto',
	   p.prod_detalle AS 'Detalle del producto',
	   d.depo_codigo AS 'C�digo de dep�sito con stock para el producto',
	   (SELECT COUNT(d1.depo_codigo) FROM Producto p1
       JOIN STOCK s1 ON p1.prod_codigo = s1.stoc_producto
       JOIN DEPOSITO d1 ON s1.stoc_deposito = d1.depo_codigo
	   WHERE p1.prod_codigo = p.prod_codigo
	   GROUP BY p1.prod_codigo, p1.prod_detalle) AS 'Cantidad de dep�sitos con stock por producto'
FROM Producto p
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
JOIN DEPOSITO d ON s.stoc_deposito = d.depo_codigo
WHERE s.stoc_cantidad > 0
ORDER BY p.prod_detalle

/*Ejercicio 13: realizar una consulta que retorne para cada producto que posea composici�n nombre
del producto, precio del producto, precio de la sumatoria de los precios por la cantidad de los productos que lo componen.
Solo se deber�n mostrar los productos que est�n compuestos por m�s de 2 productos y deben ser ordenados de mayor a menor por
cantidad de productos que lo componen.*/

SELECT p.prod_detalle AS 'Nombre del producto',
	   p.prod_precio AS 'Precio del producto', 
	   SUM(p1.prod_precio * c.comp_cantidad) AS 'Precio de la sumatoria de las cantidades de componentes por precio unitario de cada uno de ellos'
FROM Producto p 
JOIN Composicion c ON p.prod_codigo = c.comp_producto
JOIN Producto p1 ON p1.prod_codigo = c.comp_componente
GROUP BY p.prod_detalle, p.prod_precio
HAVING COUNT(*) > 2
ORDER BY COUNT(*) DESC

--Resuelto con un WHERE
SELECT p.prod_detalle AS 'Nombre del producto',
	   p.prod_precio AS 'Precio del producto', 
	   SUM(p1.prod_precio * c.comp_cantidad) AS 'Precio de la sumatoria de las cantidades de componentes por precio unitario de cada uno de ellos'
FROM Producto p 
JOIN Composicion c ON p.prod_codigo = c.comp_producto
JOIN Producto p1 ON p1.prod_codigo = c.comp_componente
WHERE (SELECT COUNT(*)
	  FROM Producto p1
	  JOIN Composicion c1 ON P1.prod_codigo = c1.comp_producto
	  WHERE p1.prod_codigo = p.prod_codigo
	  GROUP BY p1.prod_codigo) > 2
GROUP BY p.prod_detalle, p.prod_precio
ORDER BY COUNT(*) DESC

--La consulta no devuelve ning�n resultado porque todos los productos que son composici�n est�n compuestos exactamente por 2 productos, como se ve a continuaci�n
SELECT p.prod_detalle AS 'Nombre del producto',
       p.prod_precio AS 'Precio del producto'
	   FROM Producto p 
JOIN Composicion c ON p.prod_codigo = c.comp_producto
GROUP BY p.prod_detalle, p.prod_precio

/*Ejercicio 14: escriba una consulta que retorne una estad�stica de ventas por cliente. Los campos que
debe retornar son:
C�digo del cliente
Cantidad de veces que compro en el �ltimo a�o
Promedio por compra en el �ltimo a�o
Cantidad de productos diferentes que compro en el �ltimo a�o
Monto de la mayor compra que realizo en el �ltimo a�o
Se deber�n retornar todos los clientes ordenados por la cantidad de veces que compro en
el �ltimo a�o.
No se deber�n visualizar NULLs en ninguna columna*/

SELECT c.clie_codigo AS 'C�digo de cliente',
       COUNT(DISTINCT f.fact_numero) AS 'Cantidad de veces que compr� en el �ltimo a�o',
	   AVG(ISNULL(f.fact_total, 0)) AS 'Promedio por compra en el �ltimo a�o',
	   COUNT(i.item_producto) AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
	   MAX(f.fact_total) AS 'Monto de la mayor compra que realiz� en el �ltimo a�o'
FROM Cliente c
LEFT JOIN Factura f ON c.clie_codigo = f.fact_cliente
LEFT JOIN Item_Factura i ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY c.clie_codigo

UNION

SELECT DISTINCT c.clie_codigo AS 'C�digo de cliente',
       0 AS 'Cantidad de veces que compr� en el �ltimo a�o',
	   0 AS 'Promedio por compra en el �ltimo a�o',
	   0 AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
	   0 AS 'Monto de la mayor compra que realiz� en el �ltimo a�o'
FROM Cliente c
WHERE c.clie_codigo NOT IN (SELECT fact_cliente FROM Factura WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura))
GROUP BY c.clie_codigo
ORDER BY 2 DESC

--Esta hab�a sido planteada como una soluci�n inicial, aunque incompleta:
SELECT c.clie_codigo AS 'C�digo de cliente',
       COUNT(f.fact_numero) AS 'Cantidad de veces que compr� en el �ltimo a�o',
	   AVG(ISNULL(f.fact_total, 0)) AS 'Promedio por compra en el �ltimo a�o',
	   (SELECT COUNT(DISTINCT i.item_producto)
	   FROM Item_Factura i
	   JOIN Factura f1 ON i.item_numero = f1.fact_numero AND i.item_sucursal = f1.fact_sucursal AND i.item_tipo = f1.fact_tipo
	   WHERE f1.fact_cliente = c.clie_codigo AND YEAR(f1.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)) AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
	   MAX(f.fact_total) AS 'Monto de la mayor compra que realiz� en el �ltimo a�o'
FROM Cliente c
LEFT JOIN Factura f ON c.clie_codigo = f.fact_cliente
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
GROUP BY c.clie_codigo
ORDER BY COUNT(f.fact_numero)

/*Ejercicio 15: escriba una consulta que retorne los pares de productos que hayan sido vendidos juntos
(en la misma factura) m�s de 500 veces. El resultado debe mostrar el c�digo y
descripci�n de cada uno de los productos y la cantidad de veces que fueron vendidos
juntos. El resultado debe estar ordenado por la cantidad de veces que se vendieron
juntos dichos productos. Los distintos pares no deben retornarse m�s de una vez.
Ejemplo de lo que retornar�a la consulta:
PROD1 DETALLE1 PROD2 DETALLE2 VECES
1731 MARLBORO KS 1 7 1 8 P H ILIPS MORRIS KS 5 0 7
1718 PHILIPS MORRIS KS 1 7 0 5 P H I L I P S MORRIS BOX 10 5 6 2*/

--Esta es la opci�n menos eficiente, ya que se tienen 4 joins
SELECT p1.prod_codigo AS 'PROD1', p1.prod_detalle AS 'DETALLE1', p2.prod_codigo AS 'PROD2', p2.prod_detalle AS ' DETALLE2', COUNT(*) AS 'VECES'
FROM Producto p1
JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
JOIN Factura f ON i1.item_numero = f.fact_numero AND i1.item_sucursal = f.fact_sucursal AND i1.item_tipo = f.fact_tipo
JOIN Item_Factura i2 ON i2.item_numero = f.fact_numero AND i2.item_sucursal = f.fact_sucursal AND i2.item_tipo = f.fact_tipo
JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
WHERE p1.prod_codigo > p2.prod_codigo AND i1.item_numero = i2.item_numero AND i1.item_sucursal = i2.item_sucursal AND i1.item_tipo = i2.item_tipo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY COUNT(*)

/*Esta es una opci�n un poco mejor, ya que se tienen 3 joins (no se hace un join por Factura, ya que se busca que los dos �tems pertenezcan a la misma factura,
y esto se hace haciendo un join entre las tablas i1 e i2, por la PK de factura, que es FK en i1 e i2, y este join se logra "hacer" con un HWERE*/
SELECT p1.prod_codigo AS 'PROD1', p1.prod_detalle AS 'DETALLE1', p2.prod_codigo AS 'PROD2', p2.prod_detalle AS ' DETALLE2', COUNT(*) AS 'VECES'
FROM Producto p1
JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto
JOIN Item_Factura i2 ON i1.item_numero = i2.item_numero AND i1.item_sucursal = i2.item_sucursal AND i1.item_tipo = i2.item_tipo
JOIN Producto p2 ON p2.prod_codigo = i2.item_producto
WHERE p1.prod_codigo > p2.prod_codigo AND i1.item_numero = i2.item_numero AND i1.item_sucursal = i2.item_sucursal AND i1.item_tipo = i2.item_tipo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY COUNT(*)

/*Esta es la mejor opci�n*/
SELECT p1.prod_codigo AS 'PROD1', p1.prod_detalle AS 'DETALLE1', p2.prod_codigo AS 'PROD2', p2.prod_detalle AS ' DETALLE2', COUNT(*) AS 'VECES'
FROM Producto p1
JOIN Item_Factura i1 ON p1.prod_codigo = i1.item_producto, Producto p2 JOIN Item_Factura i2 ON p2.prod_codigo = i2.item_producto
WHERE p1.prod_codigo > p2.prod_codigo AND i1.item_numero = i2.item_numero AND i1.item_sucursal = i2.item_sucursal AND i1.item_tipo = i2.item_tipo
GROUP BY p1.prod_codigo, p1.prod_detalle, p2.prod_codigo, p2.prod_detalle
HAVING COUNT(*) > 500
ORDER BY COUNT(*)

/*Obs�rvese que no se usa != en la cl�usula WHERE p1.prod_codigo > p2.prod_codigo, ya que las filas quedar�an alternadas*/

/*Ejercicio 16: con el fin de lanzar una nueva campa�a comercial para los clientes que menos compran
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
Los clientes deben ser ordenados por c�digo de provincia ascendente.*/

/*
SELECT c.clie_razon_social,
       (SELECT SUM(CASE WHEN i.item_producto IN (SELECT comp_producto FROM Composicion) THEN (SELECT ) ELSE i.item_cantidad END) FROM Item_Factura i
	   JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
	   WHERE f.fact_cliente = c.clie_codigo AND YEAR(f.fact_fecha) = 2012) AS 'Cantidad de unidades totales vendidas en 2012 para este cliente',
	   1 AS 'C�digo de producto con mayor venta en 2012'
	   
FROM Cliente c
GROUP BY c.clie_codigo*/


/*Ejercicio 17: escriba una consulta que retorne una estad�stica de ventas por a�o y mes para cada
producto.
La consulta debe retornar:
PERIODO: A�o y mes de la estad�stica con el formato YYYYMM
PROD: C�digo de producto
DETALLE: Detalle del producto
CANTIDAD_VENDIDA= Cantidad vendida del producto en el periodo
VENTAS_A�O_ANT= Cantidad vendida del producto en el mismo mes del periodo
pero del a�o anterior
CANT_FACTURAS= Cantidad de facturas en las que se vendi� el producto en el
periodo
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por periodo y c�digo de producto.
*/

/*Ejercicio 18: escriba una consulta que retorne una estad�stica de ventas para todos los rubros.
La consulta debe retornar:
DETALLE_RUBRO: Detalle del rubro
VENTAS: Suma de las ventas en pesos de productos vendidos de dicho rubro
PROD1: C�digo del producto m�s vendido de dicho rubro
PROD2: C�digo del segundo producto m�s vendido de dicho rubro
CLIENTE: C�digo del cliente que compro m�s productos del rubro en los �ltimos 30
d�as
La consulta no puede mostrar NULL en ninguna de sus columnas y debe estar ordenada
por cantidad de productos diferentes vendidos del rubro.*/

/*Ejercicio 19: en virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto
- Detalle del producto
- Codigo de la familia del producto
- Detalle de la familia actual del producto
- Codigo de la familia sugerido para el producto
- Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyo
detalle coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

/*Ejercicio 20: escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el a�o, para los que tengan menos de 50
facturas en el a�o el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho a�o.*/

/*Ejercicio 21: escriba una consulta sql que retorne para todos los a�os, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta al menos una factura
y que cantidad de facturas se realizaron de manera incorrecta. Seconsidera que una factura es incorrecta cuando
la diferencia entre el total de la factura menos el total de impuesto tiene una diferencia mayor a $ 1 respecto
a la sumatoria de los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar son:
- A�o
- Clientes a los que se les facturo mal en ese a�o
- Facturas mal realizadas en ese a�o
*/

/*Ejercicio 22:*/
/*Ejercicio 23:*/
/*Ejercicio 24:*/
/*Ejercicio 25:*/
/*Ejercicio 26:*/
/*Ejercicio 27:*/
/*Ejercicio 28:*/
/*Ejercicio 29:*/
/*Ejercicio 30:*/
/*Ejercicio 31:*/
/*Ejercicio 32:*/
/*Ejercicio 33:*/
/*Ejercicio 34:*/
/*Ejercicio 35:*/
