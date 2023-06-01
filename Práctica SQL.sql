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

--Resoluci�n del ejercicio:
SELECT p.prod_detalle, MAX(s.stoc_cantidad) AS 'Stock del dep�sito con m�s stock'
FROM Producto p
JOIN STOCK s ON p.prod_codigo = s.stoc_producto
WHERE s.stoc_cantidad > 0 
GROUP BY p.prod_detalle
HAVING COUNT(*) = (SELECT COUNT(*) FROM DEPOSITO)
--ORDER BY p.prod_detalle

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
	   COUNT(DISTINCT f.fact_cliente) AS 'Cantidad de clientes que lo compraron',
	   AVG(i.item_precio) AS 'Importe promedio pagado por el producto',
	   (SELECT COUNT(s.stoc_deposito)
	   FROM STOCK s 
	   WHERE s.stoc_producto = p.prod_codigo AND s.stoc_cantidad > 0) AS 'Cantidad de dep�sitos en los cuales hay stock del producto',
	   (SELECT SUM(ISNULL(s.stoc_cantidad, 0))
	   FROM STOCK s
	   WHERE s.stoc_producto = p.prod_codigo) AS 'Cantidad de stock actual en todos los dep�sitos'
FROM Producto p
JOIN Item_Factura i ON p.prod_codigo = i.item_producto
JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2012
GROUP BY p.prod_detalle, p.prod_codigo
ORDER BY AVG(i.item_precio) DESC

--Cantidad de dep�sitos en los cuales cada producto vendido tiene stock
SELECT p.prod_codigo AS 'C�digo de producto',
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

--La resoluci�n final es:
SELECT c.clie_codigo AS 'C�digo de cliente',
       COUNT(DISTINCT (f.fact_numero + f.fact_sucursal + f.fact_tipo)) AS 'Cantidad de veces que compr� en el �ltimo a�o', --OBS. 14 a
	   ISNULL(AVG(ISNULL(f.fact_total, 0)), 0) AS 'Promedio por compra en el �ltimo a�o',
	   COUNT(DISTINCT i.item_producto) AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
	   ISNULL(MAX(f.fact_total), 0) AS 'Monto de la mayor compra que realiz� en el �ltimo a�o'
FROM Cliente c
LEFT JOIN Factura f ON c.clie_codigo = f.fact_cliente
LEFT JOIN Item_Factura i ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura) OR YEAR(f.fact_fecha) IS NULL
GROUP BY c.clie_codigo
ORDER BY 2 DESC

--Esta fue una primera resoluci�n:
SELECT c.clie_codigo AS 'C�digo de cliente',
       COUNT(DISTINCT (f.fact_numero + f.fact_sucursal + f.fact_tipo)) AS 'Cantidad de veces que compr� en el �ltimo a�o', --OBS. 14 a
	   AVG(ISNULL(f.fact_total, 0)) AS 'Promedio por compra en el �ltimo a�o',
	   COUNT(DISTINCT i.item_producto) AS 'Cantidad de productos diferentes comprados en el �ltimo a�o',
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
       COUNT(f.fact_numero) AS 'Cantidad de veces que compr� en el �ltimo a�o', --OBS.14 b
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

/*OBS. 14 a: no se usa DISTINCT fact_numero, porque como Item_Factura multiplica la atomicidad, si un cliente compr� en distintas sucursales, y el n�mero de 
factura coincidi�, se perder�n facturas. Ahora bien, si no se usa DISTINCT, por la atomicidad de Item_Factura, se contar�n filas de m�s. Entonces se hace 
teniendo en cuenta DISTINCT de la concatenaci�n f.fact_numero + f.fact_sucursal + f.fact_tipo.*/

/*Veamos lo que pasa si no se tiene Item_Factura.
En este caso, no hace falta usar DISTINCT porque est� agrupado por cliente, y s�lo aparecer�n las facturas de cada cliente una sola vez, es decir, no hay 
mayor atomicidad que haga que el c�lculo d� mal. Adem�s, en el caso de que un cliente haya comprado en distintas sucursales, y se le haya hecho una factura 
con el mismo n�mero, al no usar DISTINCT se estar�n contando dichas facturas:*/

SELECT clie_razon_social, COUNT(fact_numero) AS 'Cantidad de facturas'
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
GROUP BY clie_razon_social

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

--Haciendo JOIN con Factura e Item_factura
SELECT clie_razon_social AS 'Raz�n social',
	   SUM(item_cantidad) AS 'Cantidad de unidades vendidas para el cliente',
	   (SELECT TOP 1 item_producto
	   FROM Item_Factura
	   JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	   WHERE fact_cliente = clie_codigo AND YEAR(fact_fecha) = 2012
	   GROUP BY item_producto
	   ORDER BY COUNT(item_cantidad) DESC, item_producto ASC) AS 'Producto con mayor venta en 2012 para el cliente' --Esto hace que se tenga que tener un subselect
FROM Cliente
JOIN Factura ON clie_codigo = fact_cliente
JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
WHERE YEAR(fact_fecha) = 2012
GROUP BY clie_codigo, clie_razon_social
HAVING (SELECT SUM(fact_total) FROM Factura WHERE fact_cliente = clie_codigo) < ((SELECT TOP 1 AVG(i.item_cantidad * i.item_precio) AS 'Promedio de ventas'
					     FROM Item_Factura i
                         JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
                         WHERE YEAR(f.fact_fecha) = 2012
                         GROUP BY i.item_producto
                         ORDER BY SUM(item_cantidad) DESC, item_producto ASC) / 3)

/*La consulta devuelve NULL en el �ltimo campo porque esos clientes no tuvieron compras en el a�o 2012. Esta consulta no es del todo buena porque se podr�a 
haber resuetlo de una manera m�s f�cil, evitando un subselect, como en el caso anterior.*/

SELECT clie_razon_social AS 'Raz�n social',
	   (SELECT SUM(item_cantidad)
       FROM Factura
	   JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
	   WHERE fact_cliente = clie_codigo AND YEAR(fact_fecha) = 2012
       ) AS 'Cantidad de unidades vendidas para el cliente',
	   (SELECT TOP 1 item_producto
	   FROM Item_Factura
	   JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	   WHERE fact_cliente = clie_codigo AND YEAR(fact_fecha) = 2012
	   GROUP BY item_producto
	   ORDER BY COUNT(item_cantidad) DESC, item_producto ASC) AS 'Producto con mayor venta en 2012 para el cliente'
FROM Cliente
GROUP BY clie_codigo, clie_razon_social
HAVING (SELECT SUM(fact_total) FROM Factura WHERE fact_cliente = clie_codigo) < ((SELECT TOP 1 AVG(i.item_cantidad * i.item_precio) AS 'Promedio de vetnas'
					     FROM Item_Factura i
                         JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
                         WHERE YEAR(f.fact_fecha) = 2012
                         GROUP BY i.item_producto
                         ORDER BY SUM(item_cantidad) DESC, item_producto ASC) / 3)


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

SELECT STR(YEAR(fact_fecha)) + '/' + LTRIM(STR(MONTH(fact_fecha))) AS 'PERIODO',
	   prod_codigo AS 'PROD',
	   prod_detalle AS 'DETALLE',
	   SUM(item_cantidad) AS 'CANTIDAD_VENDIDA',
	   (SELECT ISNULL(SUM(item_cantidad), 0)
	   FROM Item_Factura
	   JOIN Factura f1 ON item_numero = f1.fact_numero AND item_sucursal = f1.fact_sucursal AND item_tipo = f1.fact_tipo
	   WHERE item_producto = prod_codigo AND
			 YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) - 1 AND
			 MONTH(f1.fact_fecha) = CASE WHEN (MONTH(f.fact_fecha) - 1) = 0 THEN 12 ELSE MONTH(f.fact_fecha) - 1 END) AS 'VENTAS_A�O_ANT',
	   COUNT(DISTINCT (f.fact_numero + f.fact_sucursal + f.fact_tipo)) AS 'CANT_FACTURAS' --OBS. 17 
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
GROUP BY prod_codigo, prod_detalle, YEAR(f.fact_fecha), MONTH(f.fact_fecha)
ORDER BY YEAR(f.fact_fecha), MONTH(f.fact_fecha), prod_codigo

/*OBS. 17: misma observaci�n que OBS. 14.*/

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

--Resoluci�n final:
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

--Por m�s que no se muestre el rubr_id, debe agruparse por dicho campo para hacer el subselect
SELECT rubr_detalle AS 'DETALLE_RUBRO',
	   SUM(item_cantidad * item_precio) AS 'VENTAS',
	   ISNULL((SELECT prod_codigo FROM (SELECT prod_codigo, ROW_NUMBER() OVER (ORDER BY SUM(item_cantidad) DESC) AS 'NroFila'
	                                   FROM Producto
	                                   JOIN Item_Factura ON prod_codigo = item_producto
	                                   WHERE rubr_id = prod_rubro
	                                   GROUP BY prod_codigo) AS Tabla
	                                   WHERE NroFila = 1), 'No existe') AS 'PROD1',
	   ISNULL((SELECT prod_codigo FROM (SELECT prod_codigo, ROW_NUMBER() OVER (ORDER BY SUM(item_cantidad) DESC) AS 'NroFila'
	                                   FROM Producto
	                                   JOIN Item_Factura ON prod_codigo = item_producto
	                                   WHERE rubr_id = prod_rubro
	                                   GROUP BY prod_codigo) AS Tabla
	                                   WHERE NroFila = 2), 'No existe') AS 'PROD2',
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

--Cliente que compr� m�s cantidad de productos de un rubro en los �ltimos 30 d�as
SELECT TOP 1 fact_cliente
FROM Factura
JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
JOIN Producto ON item_producto = prod_codigo
WHERE prod_rubro = '0001' AND fact_fecha BETWEEN (SELECT MAX(fact_fecha) - 30 FROM Factura) AND (SELECT MAX(fact_fecha) FROM Factura)
GROUP BY fact_cliente
ORDER BY SUM(item_cantidad) DESC

/*Ejercicio 19: en virtud de una recategorizacion de productos referida a la familia de los mismos se
solicita que desarrolle una consulta sql que retorne para todos los productos:
- Codigo de producto
- Detalle del producto
- Codigo de la familia del producto
- Detalle de la familia actual del producto
- Codigo de la familia sugerido para el producto
- Detalla de la familia sugerido para el producto
La familia sugerida para un producto es la que poseen la mayoria de los productos cuyos
detalles coinciden en los primeros 5 caracteres.
En caso que 2 o mas familias pudieran ser sugeridas se debera seleccionar la de menor
codigo. Solo se deben mostrar los productos para los cuales la familia actual sea
diferente a la sugerida
Los resultados deben ser ordenados por detalle de producto de manera ascendente*/

SELECT prod_codigo AS 'C�digo del producto',
	   prod_detalle AS 'Detalle del producto', 
	   prod_familia AS 'C�digo de la familia actual',
	   fami_detalle AS 'Detalle de la familia actual',
	   1 AS 'C�digo de la familia sugerida',
	   2 AS 'Detalle de la familia sugerida'
FROM Producto
JOIN Familia ON prod_familia = fami_id
ORDER BY prod_detalle ASC

/*Ejercicio 20: escriba una consulta sql que retorne un ranking de los mejores 3 empleados del 2012
Se debera retornar legajo, nombre y apellido, anio de ingreso, puntaje 2011, puntaje
2012. El puntaje de cada empleado se calculara de la siguiente manera: para los que
hayan vendido al menos 50 facturas el puntaje se calculara como la cantidad de facturas
que superen los 100 pesos que haya vendido en el a�o, para los que tengan menos de 50
facturas en el a�o el calculo del puntaje sera el 50% de cantidad de facturas realizadas
por sus subordinados directos en dicho a�o.*/

SELECT TOP 3 e.empl_codigo,
       e.empl_nombre,
	   e.empl_apellido,
	   YEAR(e.empl_ingreso) AS 'A�o de ingreso' ,
	   (CASE WHEN COUNT(*) >= 50 THEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = e.empl_codigo AND fact_total > 100 AND YEAR(fact_fecha) = 2011)
			 ELSE 0.5 * (SELECT COUNT(*) FROM Factura
			             WHERE fact_vendedor IN (SELECT e1.empl_codigo FROM Empleado e1 WHERE e1.empl_jefe = e.empl_codigo)
						 AND YEAR(fact_fecha) = 2011)
		END) AS 'Puntaje 2011',
	    (CASE WHEN COUNT(*) >= 50 THEN (SELECT COUNT(*) FROM Factura WHERE fact_vendedor = e.empl_codigo AND fact_total > 100 AND YEAR(fact_fecha) = 2012)
			 ELSE 0.5 * (SELECT COUNT(*) FROM Factura
			             WHERE fact_vendedor IN (SELECT e1.empl_codigo FROM Empleado e1 WHERE e1.empl_jefe = e.empl_codigo)
						 AND YEAR(fact_fecha) = 2012)
		END) AS 'Puntaje 2012'
FROM Empleado e
JOIN Factura ON e.empl_codigo = fact_vendedor
GROUP BY e.empl_codigo, e.empl_nombre, e.empl_apellido, YEAR(e.empl_ingreso)
ORDER BY 5 DESC

/*Ejercicio 21: escriba una consulta sql que retorne para todos los a�os, en los cuales se haya hecho al
menos una factura, la cantidad de clientes a los que se les facturo de manera incorrecta al menos una factura
y que cantidad de facturas se realizaron de manera incorrecta. Se considera que una factura es incorrecta cuando
la diferencia entre el total de la factura menos el total de impuesto tiene una diferencia mayor a $ 1 respecto
a la sumatoria de los costos de cada uno de los items de dicha factura. Las columnas que se deben mostrar son:
- A�o
- Clientes a los que se les facturo mal en ese a�o
- Facturas mal realizadas en ese a�o
*/

SELECT YEAR(fact_fecha) AS 'A�o',
       COUNT(DISTINCT fact_cliente) AS 'Cantidad de clientes con facturas incorrectas',
	   COUNT(fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas incorrectas'
FROM Factura 
WHERE (fact_total - fact_total_impuestos) - (SELECT SUM(item_cantidad * item_precio)
                                            FROM Item_Factura WHERE item_numero = fact_numero
											AND item_sucursal = fact_sucursal
											AND item_tipo = fact_tipo) > 1
GROUP BY YEAR(fact_fecha)

/*Ejercicio 22: escriba una consulta sql que retorne una estadistica de venta para todos los rubros por
trimestre contabilizando todos los a�os. Se mostraran como maximo 4 filas por rubro (1
por cada trimestre).
Se deben mostrar 4 columnas:
- Detalle del rubro
- Numero de trimestre del a�o (1 a 4)
- Cantidad de facturas emitidas en el trimestre en las que se haya vendido al
menos un producto del rubro
- Cantidad de productos diferentes del rubro vendidos en el trimestre
El resultado debe ser ordenado alfabeticamente por el detalle del rubro y dentro de cada
rubro primero el trimestre en el que mas facturas se emitieron.
No se deberan mostrar aquellos rubros y trimestres para los cuales las facturas emitiadas
no superen las 100.
En ningun momento se tendran en cuenta los productos compuestos para esta
estadistica.*/

SELECT rubr_detalle AS 'Detalle del rubro',
	   CASE WHEN MONTH(fact_fecha) BETWEEN 1 AND 3 THEN 1
	        WHEN MONTH(fact_fecha) BETWEEN 4 AND 6 THEN 2
		    WHEN MONTH(fact_fecha) BETWEEN 7 AND 9 THEN 3
			WHEN MONTH(fact_fecha) BETWEEN 10 AND 12 THEN 4
	   END AS 'Trimestre',
	   COUNT(DISTINCT fact_numero + fact_sucursal + fact_tipo) AS 'Cantidad de facturas emitidas',
	   COUNT(DISTINCT prod_codigo) AS 'Cantidad de productos diferentes vendidos'
FROM Rubro
JOIN Producto ON rubr_id = prod_rubro
LEFT JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
WHERE prod_codigo NOT IN (SELECT DISTINCT comp_producto FROM Composicion)
GROUP BY rubr_detalle,
         (CASE WHEN MONTH(fact_fecha) BETWEEN 1 AND 3 THEN 1
	     WHEN MONTH(fact_fecha) BETWEEN 4 AND 6 THEN 2
		 WHEN MONTH(fact_fecha) BETWEEN 7 AND 9 THEN 3
		 WHEN MONTH(fact_fecha) BETWEEN 10 AND 12 THEN 4 END)
HAVING COUNT(DISTINCT fact_numero + fact_sucursal + fact_tipo) >= 100
ORDER BY 1 ASC, 3 DESC

/*Ejercicio 23: realizar una consulta SQL que para cada a�o muestre :
- A�o
- El producto con composici�n m�s vendido para ese a�o.
- Cantidad de productos que componen directamente al producto m�s vendido
- La cantidad de facturas en las cuales aparece ese producto.
- El c�digo de cliente que m�s compro ese producto.
- El porcentaje que representa la venta de ese producto respecto al total de venta
del a�o.
El resultado deber� ser ordenado por el total vendido por a�o en forma descendente.*/

SELECT YEAR(fact_fecha) AS 'A�o',
       comp_producto AS 'Producto con composici�n m�s vendido',
	   COUNT(DISTINCT comp_componente) AS 'Cantidad de productos que componen al producto directamente',
	   COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas en las cuales aparece el producto',
	   (SELECT TOP 1 fact_cliente FROM Factura f1
       JOIN Item_Factura ON f1.fact_numero = item_numero AND f1.fact_sucursal = item_sucursal AND f1.fact_tipo = item_tipo
       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND item_producto = comp_producto
       GROUP BY fact_cliente
       ORDER BY COUNT(DISTINCT f1.fact_numero+f1.fact_sucursal+f1.fact_tipo) DESC) AS 'C�digo de cliente que m�s compr� el producto',
	   SUM(item_cantidad * item_precio) * 100 / (SELECT SUM(fact_total)
	                                            FROM Factura f1
												WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)) AS 'Porcentaje de venta del producto respecto de las ventas del a�o'
FROM Factura f
JOIN Item_Factura on f.fact_numero = item_numero AND f.fact_sucursal = item_sucursal AND f.fact_tipo = item_tipo
JOIN Composicion ON item_producto = comp_producto
WHERE comp_producto = (SELECT TOP 1 item_producto
                      FROM Item_Factura
					  JOIN Factura f1 ON item_numero = f1.fact_numero AND item_sucursal = f1.fact_sucursal AND item_tipo = f1.fact_tipo
                      WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND item_producto IN (SELECT comp_producto FROM Composicion)
					  GROUP BY item_producto
					  ORDER BY COUNT(item_numero+item_sucursal+item_tipo))
GROUP BY YEAR(fact_fecha), comp_producto
ORDER BY (SELECT SUM(fact_total) FROM Factura f1 WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha))

--Cantidad de veces que fue vendido un producto en un a�o
SELECT TOP 1 comp_producto AS 'C�digo de producto', COUNT(item_numero+item_sucursal+item_tipo) AS 'Cantidad de veces vendido' FROM Composicion
JOIN Item_Factura ON comp_producto = item_producto
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
WHERE YEAR(fact_fecha) = 2012
GROUP BY YEAR(fact_fecha), comp_producto
ORDER BY COUNT(item_numero+item_sucursal+item_tipo) DESC

/*Ejercicio 24: escriba una consulta que considerando solamente las facturas correspondientes a los
dos vendedores con mayores comisiones, retorne los productos con composici�n
facturados al menos en cinco facturas,
La consulta debe retornar las siguientes columnas:
- C�digo de Producto
- Nombre del Producto
- Unidades facturadas
El resultado deber� ser ordenado por las unidades facturadas descendente.*/

SELECT prod_codigo AS 'C�digo del producto',
       prod_detalle AS 'Nombre del producto',
	   SUM(item_cantidad) AS 'Unidades facturadas'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
WHERE fact_vendedor IN (SELECT TOP 2 empl_codigo FROM Empleado ORDER BY empl_comision DESC) AND prod_codigo IN (SELECT comp_producto FROM Composicion)
GROUP BY prod_codigo, prod_detalle
HAVING COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) >= 5
ORDER BY 3 DESC


/*Ejercicio 25: realizar una consulta SQL que para cada a�o y familia muestre :
a. A�o
b. El c�digo de la familia m�s vendida en ese a�o.
c. Cantidad de Rubros que componen esa familia.
d. Cantidad de productos que componen directamente al producto m�s vendido de
esa familia.
e. La cantidad de facturas en las cuales aparecen productos pertenecientes a esa
familia.
f. El c�digo de cliente que m�s compro productos de esa familia.
g. El porcentaje que representa la venta de esa familia respecto al total de venta
del a�o.
El resultado deber� ser ordenado por el total vendido por a�o y familia en forma
descendente.*/

SELECT YEAR(fact_fecha) AS 'A�o',
       fami_id AS 'C�digo de familia m�s vendida',
	   COUNT(DISTINCT prod_rubro) AS 'Cantidad de rubros que componen la familia',
	   (SELECT COUNT(comp_componente)
       FROM Composicion
       WHERE comp_producto = (SELECT TOP 1 item_producto 
	                         FROM Item_Factura
                             JOIN Factura f1 ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
                             WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
                             GROUP BY item_producto
                             ORDER BY SUM(item_cantidad) DESC)) AS 'Cantidad de productos que componen al producto m�s vendido de esa familia',
	   COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas con productos de la familia',
	   (SELECT TOP 1 fact_cliente
       FROM Factura
       JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
       JOIN Producto ON item_producto = prod_codigo AND prod_familia = fami_id
       WHERE YEAR(fact_fecha) = YEAR(f.fact_fecha)
       GROUP BY fact_cliente
       ORDER BY SUM(item_cantidad) DESC) AS 'C�digo de cliente que m�s productos compr� de la familia',
	   SUM(item_cantidad * item_precio) * 100 / (SELECT SUM(f1.fact_total)
	                                            FROM Factura f1
                                                WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)) AS 'Porcentaje de venta de la familia respecto a las ventas del a�o'
FROM Familia
JOIN Producto ON fami_id = prod_familia
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
WHERE fami_id = (SELECT TOP 1 fam.fami_id
                FROM Familia fam
				JOIN Producto ON fam.fami_id = prod_familia
				JOIN Item_Factura ON prod_codigo = item_producto
				JOIN Factura fac ON item_numero = fac.fact_numero AND item_sucursal = fac.fact_sucursal AND item_tipo = fac.fact_tipo
				WHERE YEAR(fac.fact_fecha) = YEAR(f.fact_fecha)
				GROUP BY fam.fami_id
				ORDER BY SUM(item_cantidad) DESC)
GROUP BY YEAR(f.fact_fecha), fami_id
ORDER BY 1, 2 --me dio paja, recien me di cuenta ah

/*Ejercicio 26: escriba una consulta sql que retorne un ranking de empleados devolviendo las
siguientes columnas:
- Empleado
- Dep�sitos que tiene a cargo
- Monto total facturado en el a�o corriente
- Codigo de Cliente al que mas le vendi�
- Producto m�s vendido
- Porcentaje de la venta de ese empleado sobre el total vendido ese a�o.
Los datos deberan ser ordenados por venta del empleado de mayor a menor.*/

--Se considera un ranking en un a�o espec�fico
SELECT empl_codigo AS 'C�digo de empleado',
	   (SELECT COUNT(*) FROM DEPOSITO WHERE depo_encargado = empl_codigo) AS 'Dep�sitos a cargo',
	   SUM(ISNULL(fact_total, 0)) AS 'Monto total facturado en el a�o corriente',
	   (SELECT TOP 1 fact_cliente
	   FROM Factura f1
	   WHERE f1.fact_vendedor = empl_codigo
	   GROUP BY fact_cliente
	   ORDER BY SUM(fact_total) DESC) AS 'C�digo de cliente al que m�s le vendi�',
	   (SELECT TOP 1 item_producto
       FROM Item_Factura
       JOIN Factura f1 ON item_numero = f1.fact_numero AND item_sucursal = f1.fact_sucursal AND item_tipo = f1.fact_tipo
       WHERE f1.fact_vendedor = empl_codigo
       GROUP BY item_producto
       ORDER BY SUM(item_cantidad) DESC) AS 'Producto m�s vendido',
	   (SELECT ISNULL(SUM(f1.fact_total), 0)
	   FROM Factura f1
	   WHERE f1.fact_vendedor = empl_codigo) * 100 /
	   (SELECT SUM(fact_total)
	   FROM Factura
	   WHERE YEAR(fact_fecha) = YEAR(GETDATE()) /*2010*/) AS 'Porcentaje de la venta sobre el total vendido del a�o'
FROM Empleado
LEFT JOIN Factura f ON empl_codigo = f.fact_vendedor
WHERE YEAR(f.fact_fecha) = YEAR(GETDATE()) --2010
GROUP BY empl_codigo
ORDER BY (SELECT SUM(f1.fact_total) FROM Factura f1 WHERE f1.fact_vendedor = empl_codigo) DESC

/*Ejercicio 27: escriba una consulta sql que retorne una estad�stica basada en la facturacion por a�o y
envase devolviendo las siguientes columnas:
- A�o
- Codigo de envase
- Detalle del envase
- Cantidad de productos que tienen ese envase
- Cantidad de productos facturados de ese envase
- Producto mas vendido de ese envase
- Monto total de venta de ese envase en ese a�o
- Porcentaje de la venta de ese envase respecto al total vendido de ese a�o
Los datos deberan ser ordenados por a�o y dentro del a�o por el envase con m�s
facturaci�n de mayor a menor.*/

SELECT YEAR(fact_fecha) AS 'A�o',
       enva_codigo AS 'C�digo de envase',
	   enva_detalle AS 'Detalle del envase',
	   (SELECT COUNT(prod_codigo) FROM Producto WHERE prod_envase = enva_codigo) AS 'Cantidad de productos con el envase', -- PROBAR CON LE FT JONI
	   COUNT(DISTINCT prod_codigo) AS 'Cantidad de productos facturados con el envase',
	   (SELECT TOP 1 prod_codigo
	   FROM Producto 
	   JOIN Item_Factura ON prod_codigo = item_producto
	   WHERE prod_envase = enva_codigo
	   GROUP BY prod_codigo
	   ORDER BY SUM(item_cantidad)) AS 'Producto mas vendido con el envase',
	   SUM(item_cantidad * item_precio) AS 'Monto total de venta de productos con el envase',
	   SUM(item_cantidad * item_precio) * 100 / (SELECT SUM(f1.fact_total)
	              FROM Factura f1
	              WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)) AS 'Porcentaje de ventas del envase respecto de las ventas totales del a�o'
FROM Envases
JOIN Producto ON enva_codigo = prod_envase
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
GROUP BY YEAR(f.fact_fecha), enva_codigo, enva_detalle
ORDER BY YEAR(f.fact_fecha), 6 DESC

/*Ejercicio 28: Escriba una consulta sql que retorne una estad�stica por A�o y Vendedor que retorne las
siguientes columnas:
- A�o.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realiz� en ese a�o
- Cantidad de clientes a los cuales les vendi� en ese a�o.
- Cantidad de productos facturados con composici�n en ese a�o
- Cantidad de productos facturados sin composicion en ese a�o.
- Monto total vendido por ese vendedor en ese a�o
Los datos deberan ser ordenados por a�o y dentro del a�o por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(fact_fecha) AS 'A�o',
       empl_codigo AS 'C�odigo de vendedor',
	   RTRIM(empl_nombre) + ' ' + empl_apellido AS 'Nombre y apellido del vendedor',
	   COUNT(fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas realizadas',
	   COUNT(DISTINCT fact_cliente) AS 'Cantidad de clientes atendidos',
	   (SELECT COUNT(DISTINCT item_producto) 
       FROM Item_Factura
       JOIN Factura f1 ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	   JOIN Composicion on item_producto = comp_producto
       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND f1.fact_vendedor = empl_codigo) AS 'Cantidad de productos con composicion facturados',
	   (SELECT COUNT(item_producto) 
       FROM Item_Factura
       JOIN Factura f1 ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND f1.fact_vendedor = empl_codigo AND item_producto NOT IN (SELECT comp_producto FROM Composicion)) AS 'Cantidad de productos sin composicion facturados',
	   SUM(fact_total) AS 'Monto total vendido por el vendedor'
FROM Empleado
JOIN Factura f ON empl_codigo = f.fact_vendedor
GROUP BY YEAR(f.fact_fecha), empl_codigo, empl_nombre, empl_apellido
ORDER BY YEAR(f.fact_fecha), (SELECT COUNT(DISTINCT item_producto)
                             FROM Item_Factura
							 JOIN Factura f1 ON item_numero = f1.fact_numero AND item_sucursal = f1.fact_sucursal AND item_tipo = f1.fact_tipo
							 WHERE f1.fact_vendedor = empl_codigo)

/*Ejercicio 29: se solicita que realice una estad�stica de venta por producto para el a�o 2011, solo para
los productos que pertenezcan a las familias que tengan m�s de 20 productos asignados
a ellas, la cual deber� devolver las siguientes columnas:
a. C�digo de producto
b. Descripci�n del producto
c. Cantidad vendida
d. Cantidad de facturas en la que esta ese producto
e. Monto total facturado de ese producto
Solo se deber� mostrar un producto por fila en funci�n a los considerandos establecidos
antes. El resultado deber� ser ordenado por el la cantidad vendida de mayor a menor.*/

SELECT prod_codigo AS 'C�digo del producto',
       prod_detalle AS 'Descripci�n del producto',
	   SUM(ISNULL(item_cantidad, 0)) AS 'Cantidad vendida',
	   COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas en las que est� el producto',
	   SUM(item_cantidad * item_precio) AS 'Monto total facturado'
FROM Producto
LEFT JOIN Item_Factura ON prod_codigo = item_producto
LEFT JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
WHERE YEAR(fact_fecha) = 2011 AND prod_familia IN (SELECT fami_id
                      FROM Familia
                      JOIN Producto ON fami_id = prod_familia
                      GROUP BY fami_id
                      HAVING COUNT(prod_codigo) > 20)
GROUP BY prod_codigo, prod_detalle
ORDER BY 3 DESC

/*Ejercicio 30: se desea obtener una estadistica de ventas del a�o 2012, para los empleados que sean
jefes, o sea, que tengan empleados a su cargo, para ello se requiere que realice la
consulta que retorne las siguientes columnas:
- Nombre del Jefe
- Cantidad de empleados a cargo
- Monto total vendido de los empleados a cargo
- Cantidad de facturas realizadas por los empleados a cargo
- Nombre del empleado con mejor ventas de ese jefe
Debido a la perfomance requerida, solo se permite el uso de una subconsulta si fuese
necesario.
Los datos deberan ser ordenados por de mayor a menor por el Total vendido y solo se
deben mostrarse los jefes cuyos subordinados hayan realizado m�s de 10 facturas.*/

SELECT jefe.empl_nombre AS 'Nombre del jefe',
       COUNT(DISTINCT subordinado.empl_codigo) AS 'Cantidad de empleados a cargo',
	   SUM(fact_total) AS 'Monto total vendido de los empleados a cargo',
	   COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas realizadas por los empleados a cargo',
	   (SELECT TOP 1 empl_nombre
	   FROM Empleado sub
	   JOIN Factura ON sub.empl_codigo = fact_vendedor
	   WHERE sub.empl_jefe = jefe.empl_codigo AND YEAR(fact_fecha) = 2012
	   GROUP BY sub.empl_codigo, sub.empl_nombre 
	   ORDER BY SUM(fact_total) DESC) AS 'Nombre del empleado con mejor venta'
FROM Empleado jefe
JOIN Empleado subordinado ON jefe.empl_codigo = subordinado.empl_jefe
LEFT JOIN Factura ON subordinado.empl_codigo = fact_vendedor
WHERE YEAR (fact_fecha) = 2012
GROUP BY jefe.empl_codigo, jefe.empl_nombre
HAVING COUNT(DISTINCT fact_numero+fact_sucursal+fact_tipo) > 10
ORDER BY 2 DESC

/*Falta el empleado Pedro, que tiene un solo empleado a cargo, y esto no es consecuencia del filtro de grupo (HAVING), ya que sin �l tampoco lo muestra. Es
consecuencia del filtro WHERE, igual que en el ejercicio 14 y el 29.*/

/*Ejercicio 31: escriba una consulta sql que retorne una estad�stica por A�o y Vendedor que retorne las
siguientes columnas:
- A�o.
- Codigo de Vendedor
- Detalle del Vendedor
- Cantidad de facturas que realiz� en ese a�o
- Cantidad de clientes a los cuales les vendi� en ese a�o.
- Cantidad de productos facturados con composici�n en ese a�o
- Cantidad de productos facturados sin composicion en ese a�o.
- Monto total vendido por ese vendedor en ese a�o
Los datos deberan ser ordenados por a�o y dentro del a�o por el vendedor que haya
vendido mas productos diferentes de mayor a menor.*/

SELECT YEAR(fact_fecha) AS 'A�o',
       empl_codigo AS 'C�odigo de vendedor',
	   RTRIM(empl_nombre) + ' ' + empl_apellido AS 'Nombre y apellido del vendedor',
	   COUNT(fact_numero+fact_sucursal+fact_tipo) AS 'Cantidad de facturas realizadas',
	   COUNT(DISTINCT fact_cliente) AS 'Cantidad de clientes atendidos',
	   (SELECT COUNT(DISTINCT item_producto) 
       FROM Item_Factura
       JOIN Factura f1 ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	   JOIN Composicion on item_producto = comp_producto
       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND f1.fact_vendedor = empl_codigo) AS 'Cantidad de productos con composicion facturados',
	   (SELECT COUNT(item_producto) 
       FROM Item_Factura
       JOIN Factura f1 ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha) AND f1.fact_vendedor = empl_codigo AND item_producto NOT IN (SELECT comp_producto FROM Composicion)) AS 'Cantidad de productos sin composicion facturados',
	   SUM(fact_total) AS 'Monto total vendido por el vendedor'
FROM Empleado
JOIN Factura f ON empl_codigo = f.fact_vendedor
GROUP BY YEAR(f.fact_fecha), empl_codigo, empl_nombre, empl_apellido
ORDER BY YEAR(f.fact_fecha), (SELECT COUNT(DISTINCT item_producto)
                             FROM Item_Factura
							 JOIN Factura f1 ON item_numero = f1.fact_numero AND item_sucursal = f1.fact_sucursal AND item_tipo = f1.fact_tipo
							 WHERE f1.fact_vendedor = empl_codigo)

/*Ejercicio 32: Se desea conocer las familias que sus productos se facturaron juntos en las mismas
facturas para ello se solicita que escriba una consulta sql que retorne los pares de
familias que tienen productos que se facturaron juntos. Para ellos deber� devolver las
siguientes columnas:
- C�digo de familia
- Detalle de familia
- C�digo de familia
- Detalle de familia
- Cantidad de facturas
- Total vendido
Los datos deberan ser ordenados por Total vendido y solo se deben mostrar las familias
que se vendieron juntas m�s de 10 veces.*/

SELECT fam1.fami_id AS 'C�digo de familia',
       fam1.fami_detalle AS 'Detalle de familia',
	   fam2.fami_id AS 'C�digo de familia',
	   fam2.fami_detalle AS 'Detalle de familia',
	   COUNT(DISTINCT fac.fact_numero+fac.fact_sucursal+fac.fact_tipo) AS 'Cantidad de facturas',
	   SUM(i1.item_cantidad * i1.item_precio) + SUM(i2.item_cantidad * i2.item_precio) AS 'Total vendido'
FROM Familia fam1
JOIN Producto p1 ON fam1.fami_id = prod_familia
JOIN Item_Factura i1 ON prod_codigo = i1.item_producto
JOIN Factura fac ON i1.item_numero = fac.fact_numero AND i1.item_sucursal = fac.fact_sucursal AND i1.item_tipo = fac.fact_tipo
JOIN Item_Factura i2 ON i2.item_numero = fac.fact_numero AND i2.item_sucursal = fac.fact_sucursal AND i2.item_tipo = fac.fact_tipo
JOIN Producto p2 ON i2.item_producto = p2.prod_codigo
JOIN Familia fam2 ON p2.prod_familia = fam2.fami_id
WHERE p1.prod_codigo < p2.prod_codigo AND fam1.fami_id < fam2.fami_id
GROUP BY fam1.fami_id, fam1.fami_detalle,fam2.fami_id, fam2.fami_detalle
HAVING  COUNT(DISTINCT fac.fact_numero+fac.fact_sucursal+fac.fact_tipo) > 10
ORDER BY 6 DESC

/*Ejercicio 33: se requiere obtener una estad�stica de venta de productos que sean componentes. Para
ello se solicita que realiza la siguiente consulta que retorne la venta de los
componentes del producto m�s vendido del a�o 2012. Se deber� mostrar:
a. C�digo de producto
b. Nombre del producto
c. Cantidad de unidades vendidas
d. Cantidad de facturas en la cual se facturo
e. Precio promedio facturado de ese producto.
f. Total facturado para ese producto
*/

SELECT prod_codigo AS 'C�digo de producto',
       prod_detalle AS 'Nombre del producto',
	   SUM(item_cantidad) AS 'Cantidad de unidades vendidas',
	   COUNT(DISTINCT (fact_numero + fact_sucursal + fact_tipo)) AS 'Cantidad de facturas en las cuales se factur�',
	   AVG(item_precio) AS 'Precio promedio facturado',
	   SUM(item_precio * item_cantidad) AS 'Total facturado'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
WHERE prod_codigo IN (SELECT comp_componente
				     FROM Composicion
					 WHERE comp_producto = (SELECT TOP 1 item_producto
					                        FROM Item_Factura
											JOIN Factura ON
											item_numero = fact_numero AND
											item_sucursal = fact_sucursal AND
											item_tipo = fact_tipo
                                            JOIN Composicion ON
   				                            item_producto = comp_producto
											WHERE YEAR(fact_fecha) = 2012
											GROUP BY item_producto
										    ORDER BY SUM(item_cantidad)))
GROUP BY prod_codigo, prod_detalle

--Otra forma de hacerlo:
SELECT prod_codigo AS 'C�digo de producto',
       prod_detalle AS 'Nombre del producto',
	   SUM(item_cantidad) AS 'Cantidad de unidades vendidas',
	   COUNT(DISTINCT (fact_numero + fact_sucursal + fact_tipo)) AS 'Cantidad de facturas en las cuales se factur�',
	   AVG(item_precio) AS 'Precio promedio facturado',
	   SUM(item_precio * item_cantidad) AS 'Total facturado'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
JOIN Composicion ON prod_codigo = comp_componente
WHERE comp_producto = (SELECT TOP 1 item_producto
					                        FROM Item_Factura
											JOIN Factura ON
											item_numero = fact_numero AND
											item_sucursal = fact_sucursal AND
											item_tipo = fact_tipo
                                            JOIN Composicion ON
   				                            item_producto = comp_producto
											WHERE YEAR(fact_fecha) = 2012
											GROUP BY item_producto
										    ORDER BY SUM(item_cantidad))
GROUP BY prod_codigo, prod_detalle

/*Ejercicio 34: escriba una consulta sql que retorne para todos los rubros la cantidad de facturas mal
facturadas por cada mes del a�o 2011 Se considera que una factura es incorrecta cuando
en la misma factura se factutan productos de dos rubros diferentes. Si no hay facturas
mal hechas se debe retornar 0. Las columnas que se deben mostrar son:
1- Codigo de Rubro
2- Mes
3- Cantidad de facturas mal realizadas.*/

SELECT p.prod_rubro AS 'C�digo de rubro',
       MONTH(f.fact_fecha) AS 'Mes',
	   COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) AS 'Cantidad de facturas mal realizadas'
FROM Producto p
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
WHERE YEAR(f.fact_fecha) = 2011
      AND f.fact_numero+f.fact_sucursal+f.fact_tipo IN (SELECT f1.fact_numero+f1.fact_sucursal+f1.fact_tipo
                                                       FROM Factura f1
                                                       JOIN Item_Factura ON f1.fact_numero = item_numero
												                        AND f1.fact_sucursal = item_sucursal
																	    AND f1.fact_tipo = item_tipo
                                                       JOIN Producto p1 ON item_producto = p1.prod_codigo
                                                       WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha)
												         AND MONTH(f1.fact_fecha) = MONTH(f.fact_fecha)
													     AND p1.prod_rubro = p.prod_rubro
                                                      GROUP BY f1.fact_numero+f1.fact_sucursal+f1.fact_tipo
                                                      HAVING COUNT(p1.prod_rubro) = 2)
GROUP BY MONTH(f.fact_fecha), p.prod_rubro

/*Ejercicio 35: se requiere realizar una estad�stica de ventas por a�o y producto, para ello se solicita
que escriba una consulta sql que retorne las siguientes columnas:
- A�o
- Codigo de producto
- Detalle del producto
- Cantidad de facturas emitidas a ese producto ese a�o
- Cantidad de vendedores diferentes que compraron ese producto ese a�o.
- Cantidad de productos a los cuales compone ese producto, si no compone a ninguno
se debera retornar 0.
- Porcentaje de la venta de ese producto respecto a la venta total de ese a�o.
Los datos deberan ser ordenados por a�o y por producto con mayor cantidad vendida.*/

SELECT YEAR(f.fact_fecha) AS 'A�o',
       prod_codigo AS 'C�digo del producto',
	   prod_detalle AS 'Detalle del producto',
	   COUNT(DISTINCT f.fact_numero+f.fact_sucursal+f.fact_tipo) AS 'Cantidad de facturas emitidas',
	   COUNT(DISTINCT f.fact_cliente) AS 'Cantidad de compradores diferentes que lo compraron',
	   (SELECT COUNT(*) FROM Composicion WHERE comp_componente = prod_codigo) AS 'Cantidad de productos a los cuales compone',
	   SUM(item_cantidad * item_precio) * 100 / (SELECT SUM(f1.fact_total)
	                                            FROM Factura f1
												WHERE YEAR(f1.fact_fecha) = YEAR(f.fact_fecha))
												AS 'Porcentaje de la venta del producto respecto a la venta total'
FROM Producto
JOIN Item_Factura ON prod_codigo = item_producto
JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
GROUP BY YEAR(fact_fecha), prod_codigo, prod_detalle
ORDER BY 1 ASC, SUM(item_cantidad) DESC
