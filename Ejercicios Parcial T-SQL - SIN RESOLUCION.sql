USE GD2015C1
GO
/*****EJERCICIO 1 ****/
-- AFTER / FOR: no se usa un Delete porque se pierde la consistencia del Motor; se usa ROLLBACK (deshace lo que ha ingresado/actualizado)
-- INSTEAD OF: (en vez de) NUNCA se usa un Rollback(deshace lo que se hizo), siempre se usa un DELETE

-- Ejercico T-SQL
/* Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las ventas de unidades promedio de los últimos 3 meses anteriores a una fecha. 
Se solicita que se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado. */


--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 2 ****/

/* Recalcular precios de prods con composicion
Nuevo precio: suma de precio compontentes * 0,8 */



--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 3 ****/

/* Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un
producto si no hay stock suficiente del producto en el depósito '00'.
NOTA: En caso de que se facture un producto compuesto, deberá controlar que exista Stock en el 
depósito '00' de cada uno de sus componentes. */


--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 4 ****/

/* Dada una tabla llamada TOP_Cliente, en la cual esta el cliente que más unidades compro
de todos los productos en todos los tiempos se le pide que implemente el/los objetos
necesarios para que la misma esté siempre actualizada. La estructura de la tabla es
TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos
y cumplen con la condición. */


/*****EJERCICIO 5 ****/

/* Implementar el/los objetos y aislamientos necesarios para poder implementar
el concepto de UNIQUE CONSTRAINT sobre la tabla Clientes, campo razon_social. 
Tomar en consideración que pueden existir valores nulos y estos sí pueden estar repetidos.
Cada vez que se quiera ingresar un valor duplicado además de no permitirlo, se deberá guardar en
una estructura adicional el valor a insertar y fecha_hora de intento. También, tomar
las medidas necesarias dado que actualmente se sabe que esta restricción no esta implementada.
NOTA: No se puede usar la UNIQUE CONSTRAINT ni cambiar la PRIMARY KEY para resolver este ejercicio.*/

/*UNIQUE: controla una clave por unicidad, es decir, controla que ese valor NO se repita en la misma columna, puede tener un NULL pero solamente 1.*/


/*****EJERCICIO 6 ****/


/*

Implementar el/los objetos necesarios para implementar la sigueinte restricción en línea:

Cuando se inserta en una venta un combo, nuca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes. 
NOTA: Se sabe que actualmente todos los art{iculos guardados de ventas están decompuestos en sus componentes. 



*/

/*EJERCICIO  7*/

/*

Crear un procedimiento que reciba un número de orden de compra por parámetro
y realice la eliminación de la misma junto con sus ítems.
Deberá manejar una transacción y deberá manejar excepciones ante algún error
que ocurra.
El procedimiento deberá guardar en una tabla de auditoria AUDIT_OC los
siguientes datos: order_num, order_date, customer_num, cantidad_items,
total_orden y cant_productos.
Ante un error deberá almacenar en una tabla erroresOC (order_num,
error_ocurrido VARCHAR(50)) y deshacer toda la operación.

*/

/*Ejercicio 8*/

/*
Dada la tabla CURRENT_STOCK
create table CURRENT_STOCK (
stock_num smallint not null,
manu_code char(3) not null,
Current_Amount integer default 0,
created_date datetime not null, -- fecha de creación del registro
updated_date datetime not null, -- última fecha de actualización del registro
PRIMARY KEY (stock_num, manu_code) );

Realizar un trigger que ante un insert o delete de la tabla Items actualice la cantidad
CURRENT_AMOUNT de forma tal que siempre contenga el stock actual del par (stock_num,
manu_code).
Si la operación es un INSERT se restará la cantidad QUANTITY al CURRENT_AMOUNT.
Si la operación es un DELETE se sumará la cantidad QUANTITY al CURRENT_AMOUNT.
Si no existe el par (stock_num, manu_code) en la tabla CURRENT_STOCK debe insertarlo en la tabla
CURRENT_STOCK con el valor inicial de 0 (cero) mas/menos la operación a realizar.
Tener en cuenta que las operaciones (INSERTs, DELETEs) pueden ser masivas.

*/

/*Ejercicio 9*/


/*
Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un producto si no hay stock suficiente del producto en el 
depósito 00. 

NOTA: En caso de que se facture un producto compuesto, por ejemplo, combo 1, se deberá controlar que exista stock en el deposito de cada uno de sus componentes.

*/


/*Ejercicio 10*/

/*
Se necesita realizar una migración de los códigos de productos a una nueva codificación 
que va a ser A + substring(prodcodigo,2,7). Implemente el/los objetos para llevar a cabo la migración.


*/