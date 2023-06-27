USE GD2015C1
GO
/*****EJERCICIO 1 ****/
-- AFTER / FOR: no se usa un Delete porque se pierde la consistencia del Motor; se usa ROLLBACK (deshace lo que ha ingresado/actualizado)
-- INSTEAD OF: (en vez de) NUNCA se usa un Rollback(deshace lo que se hizo), siempre se usa un DELETE

-- Ejercico T-SQL
/* Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las ventas de unidades promedio de los últimos 3 meses anteriores a una fecha. 
Se solicita que se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado. */



IF OBJECT_ID('calcular_stock') IS NOT NULL
    DROP procedure calcular_stock
GO

IF OBJECT_ID('stock_a_reponer') IS NOT NULL
    DROP table dbo.stock_a_reponer
GO

create table stock_a_reponer (
	cod_prod int, 
	cantidad int
);

-- si vinieran los dos valores por parametro
CREATE PROCEDURE calcular_stock @producto int, @fecha smalldatetime
AS
BEGIN
   DECLARE @stock_calculado int 
   DECLARE @fechaAnterior smalldatetime 
   SET @fechaAnterior = DATEADD(MONTH, -3, @fecha)
   
	select @stock_calculado =  round(avg(it.item_cantidad),0)
	from Item_Factura it join Factura f on f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
	where f.fact_fecha between @fechaAnterior and @fecha
	and @producto = it.item_producto
	group by it.item_producto 

	INSERT INTO stock_a_reponer VALUES (@producto, @stock_calculado)

END;



-- si viene solo la fecha por parametro 
CREATE PROCEDURE calcular_stock  @fecha smalldatetime
AS
BEGIN
   DECLARE @stock_calculado int 
   DECLARE @fechaAnterior smalldatetime 
   SET @fechaAnterior = DATEADD(MONTH, -3, @fecha)
   
	INSERT INTO stock_a_reponer
	select it.item_producto, ceiling(sum(it.item_cantidad)/3)
	from Item_Factura it join Factura f on f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
	where f.fact_fecha between @fechaAnterior and @fecha
	group by it.item_producto
		
END;

-- EXEC NombreDelStoredProc @Parametro1 = Valor1, @Parametro2 = Valor2;
exec calcular_stock @fecha = '2012-08-10 00:00:00'


select * from stock_a_reponer
order by cod_prod


select it.item_producto, ceiling(sum(it.item_cantidad)/3)
	from Item_Factura it join Factura f on f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
	where f.fact_fecha between'2012-05-10 00:00:00' and '2012-08-10 00:00:00'
	group by it.item_producto
	order by 1


select * from stock_a_reponer

SELECT * from Item_Factura it join Factura f on f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal where it.item_numero = '00093385'

select * from stock_a_reponer


-- '2012-08-10 00:00:00'

select round(avg(it.item_cantidad),0)
	from Item_Factura it join Factura f on f.fact_tipo + f.fact_numero + f.fact_sucursal = it.item_tipo + it.item_numero + it.item_sucursal
	where f.fact_fecha between '2012-05-10 00:00:00' and '2012-08-10 00:00:00'
	and '00001416' = it.item_producto
	group by it.item_producto
--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 2 ****/

/* Recalcular precios de prods con composicion
Nuevo precio: suma de precio compontentes * 0,8 */

-- dado que la consigna es re cortita, voy a asumir que hay que actualizar TODOS los precios de TODAS las composiciones, entonces
-- recorro todos los productos y solo actualizo aquellos que pertenezcan a la tabla de composicion

/*
PARA CADA PRODUCTO, ACTUALIZO SU PRECIO. LA LÓGICA DE QUÉ PRECIO AGREGAR, VA A ESTAR DETERMINADA EN LA FUNCIÓN
*/

DROP FUNCTION calcular_precio
DROP PROCEDURE actualizar_precios_combos

CREATE FUNCTION calcular_precio(@PRODUCTO char(8))
RETURNS decimal(12,2)
AS
BEGIN 

	DECLARE @PRECIO_TOTAL decimal(12,2) 

	IF @PRODUCTO NOT IN (SELECT comp_producto FROM Composicion)
		BEGIN -- quiere decir que no lo tengo que acutalizar porque es uno sin composicion
		SET @PRECIO_TOTAL = (SELECT prod_precio FROM Producto WHERE prod_codigo = @PRODUCTO)

		return @PRECIO_TOTAL 
		END
	ELSE -- quiere decir que es un producto con composicion, por lo que tengo que recorrer todos los productos que lo componen con un cursor y sumar al precio total lo que salen 
		BEGIN 
			DECLARE @CANTIDAD int, @COMPONENTE char(8)
			DECLARE cursor_componentes CURSOR FOR -- se genera un cursor para la tabla de componentes del producto con codigo @PRODUCTO
					(SELECT c.comp_cantidad, c.comp_componente FROM Composicion c
					WHERE @PRODUCTO = c.comp_producto)

					-- recalculo el precio
					OPEN cursor_componentes 
					FETCH NEXT FROM cursor_componentes INTO @CANTIDAD, @COMPONENTE
					WHILE @@FETCH_STATUS = 0
						BEGIN
						-- esto me sirve solamente si sé que los productos finales son productos SIN composicion (es el caso de estas tablas del modelo) 
						--SET @PRECIO_TOTAL = @PRECIO_TOTAL + @CANTIDAD * (SELECT prod_precio FROM Producto WHERE prod_codigo = @COMPONENTE)

						-- para hacerlo más abstracto, entonces me conviene hacerla recursiva
						SET @PRECIO_TOTAL = @PRECIO_TOTAL + @CANTIDAD * dbo.calcular_precio(@COMPONENTE)
				
					FETCH NEXT FROM cursor_componentes INTO @CANTIDAD, @COMPONENTE
						END
					close cursor_componentes
					deallocate cursor_componentes
		END
		return @PRECIO_TOTAL 
		END 



CREATE PROCEDURE actualizar_precios_combos
AS
BEGIN
	DECLARE @PRODUCTO char(8)
	DECLARE @PRECIO_NUEVO decimal(12,2) = 0

	-- abro el cursor para ir recorriendo TODOS los productos 

	DECLARE cursor_productos CURSOR FOR 
		SELECT p.prod_codigo FROM Producto p 

		OPEN cursor_productos
			FETCH NEXT FROM cursor_productos INTO @PRODUCTO
			WHILE @@FETCH_STATUS = 0
				BEGIN

					-- actualizo el precio 
					UPDATE Producto SET prod_precio = dbo.calcular_precio(@PRODUCTO) * 0.8 WHERE prod_codigo = @PRODUCTO

					FETCH NEXT FROM cursor_productos INTO @PRODUCTO
				END
				CLOSE cursor_productos
				DEALLOCATE cursor_productos
END
GO


EXEC actualizar_precios_combos








--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 3 ****/

/* Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un
producto si no hay stock suficiente del producto en el depósito '00'.
NOTA: En caso de que se facture un producto compuesto, deberá controlar que exista Stock en el 
depósito '00' de cada uno de sus componentes. */


-- CREO QUE TRIGGER PARA QUE NO SE PUEDAN AGREGAR PRODUCTOS A LA TABLA ITEM FACTURA 


DROP TRIGGER CONTROL_STOCK_NEGATIVO
DROP FUNCTION haystock 

CREATE TRIGGER control_stock_negativo ON ITEM_FACTURA FOR INSERT
AS
BEGIN
    
	-- si no hay stock -> tengo que hacer rollback para que no pase 
	-- me tengo que fijar sobre la tabla de insertados 


	-- tieneStockSuficiente -> 0: no; 1 si
	IF EXISTS (SELECT I.item_producto, I.item_cantidad FROM inserted I WHERE dbo.hayStock(I.item_producto, I.item_cantidad) = 0) -- EL STOCK DE LO QUE SE INSERTO ES 0
	BEGIN
		ROLLBACK
	END
	
END

CREATE FUNCTION hayStock(@producto char(8), @cantidad int)
RETURNS int
BEGIN
	DECLARE @B_STOCK int
	SET @B_STOCK = 1 --  HAY STOCK POR DEFAULT SIEMPRE


	IF @producto not in (select c.comp_producto from Composicion c)
		BEGIN
			DECLARE @CANTIDAD_PROD_FINAL int
			 -- para saber la disponibilidad de un producto en el deposito 00 ->
			SET @CANTIDAD_PROD_FINAL =  (SELECT s.stoc_cantidad FROM STOCK s where @producto = s.stoc_producto and s.stoc_deposito = '00')
			-- hay mas sotck del que solicito
			IF @CANTIDAD_PROD_FINAL <= @cantidad
				BEGIN
					SET @B_STOCK = 0
					return @B_STOCK
				END
		END
	ELSE -- es compuesto
	-- recorro la tabla de composicion
	DECLARE @CANT_COMPONENTES int
	DECLARE @COD_COMPONENTE char(8)
	DECLARE componentes cursor for
		select c.comp_componente, c.comp_cantidad from Composicion c

	OPEN componentes
	FETCH NEXT FROM componentes INTO @COD_COMPONENTE, @CANT_COMPONENTES
	
		WHILE @@FETCH_STATUS = 0 
		BEGIN

			-- tengo que recorrer hasta que alguno NO tenga disponibilidad, entonces 
			-- el corte de control sería si alguno me da que tiene 0

			IF (dbo.hayStock(@COD_COMPONENTE, @CANT_COMPONENTES * @cantidad) = 0)
				BEGIN
					SET @B_STOCK = 0
					RETURN @B_STOCK
				END
			
				FETCH NEXT FROM componentes INTO @COD_COMPONENTE, @CANT_COMPONENTES
		END
		
			CLOSE componentes
			deallocate componentes
	RETURN @B_STOCK -- ME HACE AGREGARLO PARA QUE COMPILE
	END

GO 


select * from STOCK

--------------------------------------------------------------------------------------------------------------------

/*****EJERCICIO 4 ****/

/* Dada una tabla llamada TOP_Cliente, en la cual esta el cliente que más unidades compro
de todos los productos en todos los tiempos se le pide que implemente el/los objetos
necesarios para que la misma esté siempre actualizada. La estructura de la tabla es
TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos
y cumplen con la condición. */


DROP TABLE TOP_CLIENTE

create table TOP_CLIENTE(
	ID_CLIENTE char(8), 
	CANTIDAD_TOTAL_COMPRADA decimal(12,2)
)
DROP TRIGGER dbo.nuevo_top_cliente


CREATE TRIGGER dbo.nuevo_top_cliente ON Item_Factura FOR INSERT
AS
BEGIN
	declare @TIPO char(1), @SUCURSAL char(4), @NUMERO char(8), @CANTIDAD decimal(12,2)
	
	SELECT @TIPO = i.item_tipo, @SUCURSAL = i.item_sucursal,  @NUMERO = i.item_numero, @CANTIDAD = i.item_cantidad from inserted i
	

	-- CODIGO DE CLIENTE QUE INSERTO

	DECLARE @NUEVA_CANTIDAD decimal(12,2), @CLIENTE_NUEVO char(6)
	

	SELECT @CLIENTE_NUEVO = f.fact_cliente FROM Factura f
	where @TIPO = f.fact_tipo 
	and @SUCURSAL = f.fact_sucursal
	AND @NUMERO = f.fact_numero

	-- CALCULO CUANTO ES LO NUEVO COMPRADO POR EL CLIENTE (TODOS LOS PRODUCTOS) 

	SELECT @NUEVA_CANTIDAD = sum(it.item_cantidad) + @CANTIDAD FROM Item_Factura it 
	join Factura f on f.fact_numero + f.fact_sucursal+f.fact_tipo=it.item_numero+it.item_sucursal+it.item_tipo
	where @CLIENTE_NUEVO = f.fact_cliente
	
		/*id_cliente -> ¿cuanto compro en total? -> ES MAS QUE EL TOP CLIENTE? -> REEMPLAZO 
				     						   -> ES MENOS QUE EL TOP CLIENTE? -> MANTENGO AL OTRO */


	IF(@NUEVA_CANTIDAD > (SELECT TOP 1 c.CANTIDAD_TOTAL_COMPRADA from TOP_CLIENTE c))
	BEGIN 
		BEGIN TRANSACTION T 

		DELETE FROM TOP_CLIENTE
		
		INSERT INTO TOP_CLIENTE (ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA)
		VALUES (@CLIENTE_NUEVO, @NUEVA_CANTIDAD)
	
		COMMIT TRANSACTION T
	END 

END
GO




/*****EJERCICIO 5 ****/

/* Implementar el/los objetos y aislamientos necesarios para poder implementar
el concepto de UNIQUE CONSTRAINT sobre la tabla Clientes, campo razon_social. 
Tomar en consideración que pueden existir valores nulos y estos sí pueden estar repetidos.
Cada vez que se quiera ingresar un valor duplicado además de no permitirlo, se deberá guardar en
una estructura adicional el valor a insertar y fecha_hora de intento. También, tomar
las medidas necesarias dado que actualmente se sabe que esta restricción no esta implementada.
NOTA: No se puede usar la UNIQUE CONSTRAINT ni cambiar la PRIMARY KEY para resolver este ejercicio.*/

/*UNIQUE: controla una clave por unicidad, es decir, controla que ese valor NO se repita en la misma columna, puede tener un NULL pero solamente 1.*/


/*TA DIFICIL */

/*****EJERCICIO 6 ****/


/*

Implementar el/los objetos necesarios para implementar la sigueinte restricción en línea:

Cuando se inserta en una venta un combo, nuca se deberá guardar el producto COMBO, sino, la descomposición de sus componentes. 
NOTA: Se sabe que actualmente todos los art{iculos guardados de ventas están decompuestos en sus componentes. 

*/

DROP TRIGGER dbo.guardar_productos_descompuestos

CREATE TRIGGER dbo.guardar_productos_descompuestos ON Item_Factura FOR INSERT
AS
BEGIN
	

	DECLARE @CANTIDAD decimal(12,2), @NUMERO char(8), @PRECIO decimal(12,2), @PRODUCTO char(8), @SUCURSAL char(4), @TIPO char(1)
	DECLARE cursor_inserted CURSOR FOR 
					SELECT i.item_cantidad, i.item_numero, i.item_precio, i.item_producto, i.item_sucursal, i.item_tipo from inserted i 

				OPEN cursor_inserted
				FETCH NEXT FROM cursor_inserted INTO @CANTIDAD, @NUMERO, @PRECIO, @PRODUCTO, @SUCURSAL, @TIPO
				WHILE @@FETCH_STATUS = 0
					BEGIN
								
						EXEC dbo.insertar_producto @CANTIDAD,@NUMERO,@PRECIO, @PRODUCTO, @SUCURSAL, @TIPO					

					FETCH NEXT FROM cursor_inserted INTO @CANTIDAD, @NUMERO, @PRECIO, @PRODUCTO, @SUCURSAL, @TIPO
					END
					CLOSE cursor_inserted
					DEALLOCATE cursor_inserted
			END

END
GO

DROP PROCEDURE dbo.insertar_producto

CREATE PROCEDURE dbo.insertar_producto(@CANTIDAD decimal(12,2), @NUMERO char(8), @PRECIO decimal(12,2), @PRODUCTO char(8), @SUCURSAL char(4), @TIPO char(1))
AS
BEGIN
	
	IF(@PRODUCTO not in (select comp_producto from Composicion)) -- NO EXISTE EN LA TABLA COMPOSICION, INSERTAR DIRECTAMENTE
		BEGIN
		INSERT INTO Item_Factura(item_tipo, item_sucursal, item_numero, item_producto, item_cantidad, item_precio)
		VALUES (@TIPO, @SUCURSAL, @NUMERO, @PRODUCTO, @CANTIDAD, @PRECIO)
			
		END
	ELSE -- ES UNA COMPOSICION
		BEGIN 
			DECLARE @CANTIDAD_COMP int, @COMPONENTE char(8)
			DECLARE cursor_componentes CURSOR FOR -- se genera un cursor para la tabla de componentes del producto con codigo @PRODUCTO
					(SELECT c.comp_cantidad, c.comp_componente FROM Composicion c
					WHERE @PRODUCTO = c.comp_producto)

					OPEN cursor_componentes 
					FETCH NEXT FROM cursor_componentes INTO @CANTIDAD_COMP, @COMPONENTE
					WHILE @@FETCH_STATUS = 0
						BEGIN

						DECLARE @NUEVA_CANTIDAD decimal(12,2)
						SET @NUEVA_CANTIDAD = @CANTIDAD * @CANTIDAD_COMP
						
						DECLARE @NUEVO_PRECIO DECIMAL(12,2)
						SET @NUEVO_PRECIO = (SELECT p.prod_precio from Producto p where p.prod_codigo = @COMPONENTE)
																							
						EXEC dbo.insertar_producto @NUEVA_CANTIDAD,@NUMERO, @NUEVO_PRECIO, @COMPONENTE, @SUCURSAL, @TIPO	

				
					FETCH NEXT FROM cursor_componentes INTO @CANTIDAD_COMP, @COMPONENTE
						END
					close cursor_componentes
					deallocate cursor_componentes

		END

END

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