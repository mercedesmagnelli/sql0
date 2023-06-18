USE GD2015C1
GO
/*****EJERCICIO 1 ****/
-- AFTER / FOR: no se usa un Delete porque se pierde la consistencia del Motor; se usa ROLLBACK (deshace lo que ha ingresado/actualizado)
-- INSTEAD OF: (en vez de) NUNCA se usa un Rollback(deshace lo que se hizo), siempre se usa un DELETE

-- Ejercico T-SQL
/* Para estimar que STOCK se necesita comprar de cada producto, se toma como estimaci�n las ventas de unidades promedio de los �ltimos 3 meses anteriores a una fecha. 
Se solicita que se guarde en una tabla (producto, cantidad a reponer) en funci�n del criterio antes mencionado. */


--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 2 ****/

/* Recalcular precios de prods con composicion
Nuevo precio: suma de precio compontentes * 0,8 */



--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 3 ****/

/* Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un
producto si no hay stock suficiente del producto en el dep�sito '00'.
NOTA: En caso de que se facture un producto compuesto, deber� controlar que exista Stock en el 
dep�sito '00' de cada uno de sus componentes. */


--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 4 ****/

/* Dada una tabla llamada TOP_Cliente, en la cual esta el cliente que m�s unidades compro
de todos los productos en todos los tiempos se le pide que implemente el/los objetos
necesarios para que la misma est� siempre actualizada. La estructura de la tabla es
TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos
y cumplen con la condici�n. */


/*****EJERCICIO 5 ****/

/* Implementar el/los objetos y aislamientos necesarios para poder implementar
el concepto de UNIQUE CONSTRAINT sobre la tabla Clientes, campo razon_social. 
Tomar en consideraci�n que pueden existir valores nulos y estos s� pueden estar repetidos.
Cada vez que se quiera ingresar un valor duplicado adem�s de no permitirlo, se deber� guardar en
una estructura adicional el valor a insertar y fecha_hora de intento. Tambi�n, tomar
las medidas necesarias dado que actualmente se sabe que esta restricci�n no esta implementada.
NOTA: No se puede usar la UNIQUE CONSTRAINT ni cambiar la PRIMARY KEY para resolver este ejercicio.*/

/*UNIQUE: controla una clave por unicidad, es decir, controla que ese valor NO se repita en la misma columna, puede tener un NULL pero solamente 1.*/


/*****EJERCICIO 6 ****/


/*

Implementar el/los objetos necesarios para implementar la sigueinte restricci�n en l�nea:

Cuando se inserta en una venta un combo, nuca se deber� guardar el producto COMBO, sino, la descomposici�n de sus componentes. 
NOTA: Se sabe que actualmente todos los art{iculos guardados de ventas est�n decompuestos en sus componentes. 



*/

/*EJERCICIO  7*/

/*

Crear un procedimiento que reciba un n�mero de orden de compra por par�metro
y realice la eliminaci�n de la misma junto con sus �tems.
Deber� manejar una transacci�n y deber� manejar excepciones ante alg�n error
que ocurra.
El procedimiento deber� guardar en una tabla de auditoria AUDIT_OC los
siguientes datos: order_num, order_date, customer_num, cantidad_items,
total_orden y cant_productos.
Ante un error deber� almacenar en una tabla erroresOC (order_num,
error_ocurrido VARCHAR(50)) y deshacer toda la operaci�n.

*/

/*Ejercicio 8*/

/*
Dada la tabla CURRENT_STOCK
create table CURRENT_STOCK (
stock_num smallint not null,
manu_code char(3) not null,
Current_Amount integer default 0,
created_date datetime not null, -- fecha de creaci�n del registro
updated_date datetime not null, -- �ltima fecha de actualizaci�n del registro
PRIMARY KEY (stock_num, manu_code) );

Realizar un trigger que ante un insert o delete de la tabla Items actualice la cantidad
CURRENT_AMOUNT de forma tal que siempre contenga el stock actual del par (stock_num,
manu_code).
Si la operaci�n es un INSERT se restar� la cantidad QUANTITY al CURRENT_AMOUNT.
Si la operaci�n es un DELETE se sumar� la cantidad QUANTITY al CURRENT_AMOUNT.
Si no existe el par (stock_num, manu_code) en la tabla CURRENT_STOCK debe insertarlo en la tabla
CURRENT_STOCK con el valor inicial de 0 (cero) mas/menos la operaci�n a realizar.
Tener en cuenta que las operaciones (INSERTs, DELETEs) pueden ser masivas.

*/

/*Ejercicio 9*/


/*
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock suficiente del producto en el 
dep�sito 00. 

NOTA: En caso de que se facture un producto compuesto, por ejemplo, combo 1, se deber� controlar que exista stock en el deposito de cada uno de sus componentes.

*/


/*Ejercicio 10*/

/*
Se necesita realizar una migraci�n de los c�digos de productos a una nueva codificaci�n 
que va a ser A + substring(prodcodigo,2,7). Implemente el/los objetos para llevar a cabo la migraci�n.


*/