USE GD2015C1
GO

-- AFTER / FOR: no se usa un Delete porque se pierde la consistencia del Motor; se usa ROLLBACK (deshace lo que ha ingresado/actualizado)
-- INSTEAD OF: (en vez de) NUNCA se usa un Rollback(deshace lo que se hizo), siempre se usa un DELETE

-- Ejercico T-SQL
/* Para estimar que STOCK se necesita comprar de cada producto, se toma como estimación las ventas de unidades promedio de los últimos 3 meses anteriores a una fecha. 
Se solicita que se guarde en una tabla (producto, cantidad a reponer) en función del criterio antes mencionado. */

IF OBJECT_ID('dbo.stocTabla') IS NOT NULL
	DROP TABLE dbo.stocTabla
GO

IF OBJECT_ID('dbo.ejercicio1') IS NOT NULL
	DROP PROCEDURE dbo.ejercicio1 
GO

CREATE TABLE stocTabla (
	producto CHAR(8) PRIMARY KEY, 
	cantidad_a_reponer INT NOT NULL
);
GO

CREATE PROCEDURE dbo.ejercicio1 (@FECHA smalldatetime)
AS
BEGIN
	INSERT INTO stocTabla
	SELECT item_producto, SUM(item_cantidad)/3 FROM Item_Factura
		JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
	WHERE YEAR(fact_fecha) = YEAR(@FECHA)
		AND MONTH(fact_fecha) BETWEEN MONTH(@FECHA) AND MONTH(@FECHA) - 3 
	GROUP BY item_producto
END
GO


--------------------------------------------------------------------------------------------------------------------


/* Recalcular precios de prods con composicion
Nuevo precio: suma de precio compontentes * 0,8 */

IF OBJECT_ID('dbo.ejercicio2') IS NOT NULL
	DROP PROCEDURE dbo.ejercicio2
GO

CREATE FUNCTION dbo.precioCombo(@PRODUCTO CHAR(8))
RETURNS DECIMAL(12,2)
AS
BEGIN
	
	DECLARE @PRECIO_TOTAL DECIMAL(12,2) = 0
	
	IF NOT EXISTS (SELECT * FROM Composicion
				WHERE comp_producto = @PRODUCTO)
		BEGIN
			SET @PRECIO_TOTAL = (SELECT prod_precio FROM Producto WHERE prod_codigo = @PRODUCTO)
			RETURN @PRECIO_TOTAL
		END
	ELSE
		BEGIN
			DECLARE @COMPONENTE CHAR(8), @CANTIDAD INT
			DECLARE cursorComp CURSOR FOR
				SELECT comp_componente, comp_cantidad FROM Composicion
					WHERE comp_producto = @PRODUCTO

			OPEN cursorComp
			FETCH NEXT FROM cursorComp INTO @COMPONENTE, @CANTIDAD
			WHILE @@FETCH_STATUS = 0
				BEGIN

					SET @PRECIO_TOTAL = @PRECIO_TOTAL + dbo.precioCombo(@COMPONENTE) * @CANTIDAD * 0.80

					FETCH NEXT FROM cursorComp INTO @COMPONENTE, @CANTIDAD
				END
				CLOSE cursorComp
				DEALLOCATE cursorComp
		END
		RETURN @PRECIO_TOTAL
END
GO

CREATE PROCEDURE dbo.ejercicio2
AS
BEGIN
	DECLARE @PRODUCTO CHAR(8)
	DECLARE @NUEVO_PRECIO DECIMAL(12,2)
	
	DECLARE cursorProd CURSOR FOR
		SELECT prod_codigo FROM Producto

	OPEN cursorProd
	FETCH NEXT FROM cursorProd INTO @PRODUCTO
	WHILE @@FETCH_STATUS = 0
		BEGIN
			
			UPDATE Producto SET prod_precio = dbo.precioCombo(@PRODUCTO) WHERE prod_codigo = @PRODUCTO

			FETCH NEXT FROM cursorProd INTO @PRODUCTO
		END
		CLOSE cursorProd
		DEALLOCATE cursorProd
END
GO


--------------------------------------------------------------------------------------------------------------------


/* Implementar el/los objetos necesarios para controlar que nunca se pueda facturar un
producto si no hay stock suficiente del producto en el depósito '00'.
NOTA: En caso de que se facture un producto compuesto, deberá controlar que exista Stock en el 
depósito '00' de cada uno de sus componentes. */


SELECT * FROM STOCK
WHERE stoc_deposito = '00'
GO

CREATE FUNCTION dbo.tieneStockSuficiente (@PRODUCTO CHAR(8), @CANTIDAD INT)
RETURNS INT
AS
BEGIN
	DECLARE @DISPONIBILIDAD INT = 1
	
	IF NOT EXISTS (SELECT * FROM STOCK
				   WHERE stoc_producto = @PRODUCTO
					  AND stoc_deposito = '00'
					  AND stoc_cantidad > @CANTIDAD)
		BEGIN
			SET @DISPONIBILIDAD = 0
			RETURN @DISPONIBILIDAD
		END
	ELSE 
		BEGIN
			DECLARE @COMPONENTE CHAR(8), @CANTIDAD_COMP INT
			
			DECLARE cursorComp CURSOR FOR 
				SELECT comp_componente, comp_cantidad FROM Composicion
				WHERE comp_producto = @PRODUCTO

			OPEN cursorComp
			FETCH NEXT FROM cursorComp INTO @COMPONENTE, @CANTIDAD_COMP
			WHILE @@FETCH_STATUS = 0
				BEGIN
					
					IF(dbo.tieneStockSuficiente(@COMPONENTE, @CANTIDAD_COMP * @CANTIDAD) = 0)
						SET @DISPONIBILIDAD = 0
						RETURN @DISPONIBILIDAD

					FETCH NEXT FROM cursorComp INTO @COMPONENTE, @CANTIDAD_COMP
				END
				CLOSE cursorComp
				DEALLOCATE cursorComp
		END

	RETURN @DISPONIBILIDAD
END
GO

CREATE TRIGGER dbo.ejercicio3 ON Item_Factura FOR INSERT
AS
BEGIN
	IF EXISTS (SELECT I.item_producto, I.item_cantidad FROM inserted I WHERE dbo.tieneStockSuficiente(I.item_producto, I.item_cantidad) = 0)
		BEGIN
			ROLLBACK
			RETURN
		END
END
GO



--------------------------------------------------------------------------------------------------------------------


/* Dada una tabla llamada TOP_Cliente, en la cual esta el cliente que más unidades compro
de todos los productos en todos los tiempos se le pide que implemente el/los objetos
necesarios para que la misma esté siempre actualizada. La estructura de la tabla es
TOP_CLIENTE( ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA) y actualmente tiene datos
y cumplen con la condición. */

IF OBJECT_ID('dbo.TOP_Cliente') IS NOT NULL
	DROP TABLE dbo.TOP_Cliente
GO

CREATE TABLE dbo.TOP_Cliente (
	ID_CLIENTE CHAR(8) PRIMARY KEY,
	CANTIDAD_TOTAL_COMPRADA INT NOT NULL
);
GO

CREATE TRIGGER dbo.ejercicio4 ON Item_Factura FOR INSERT, UPDATE, DELETE
AS
BEGIN
	INSERT INTO TOP_Cliente (ID_CLIENTE, CANTIDAD_TOTAL_COMPRADA)
		SELECT TOP 1 fact_cliente, SUM(item_cantidad) FROM Item_Factura
			JOIN Factura ON fact_numero+fact_sucursal+fact_tipo = item_numero+item_sucursal+item_tipo
		GROUP BY fact_cliente, item_producto
		ORDER BY SUM(item_cantidad) DESC
END
GO


/* Implementar el/los objetos y aislamientos necesarios para poder implementar
el concepto de UNIQUE CONSTRAINT sobre la tabla Clientes, campo razon_social. 
Tomar en consideración que pueden existir valores nulos y estos sí pueden estar repetidos.
Cada vez que se quiera ingresar un valor duplicado además de no permitirlo, se deberá guardar en
una estructura adicional el valor a insertar y fecha_hora de intento. También, tomar
las medidas necesarias dado que actualmente se sabe que esta restricción no esta implementada.
NOTA: No se puede usar la UNIQUE CONSTRAINT ni cambiar la PRIMARY KEY para resolver este ejercicio.*/

/*UNIQUE: controla una clave por unicidad, es decir, controla que ese valor NO se repita en la misma columna, puede tener un NULL pero solamente 1.*/


create table tabla_auxiliar (
	clie_codigo char(6) primary key,
	razon_social char(100) null,
	fecha_hora smalldatetime null
);
go

create trigger ejercicio on Cliente instead of insert
as
begin
	declare @cliente char(6), @razon_social char(100), @telefono char(100), @domicilio char(100), @limite_credito decimal(12,2), @vendedor numeric(6)


	declare c1 cursor for
		select * from inserted i
	
	open c1
	fetch next from c1 into @cliente, @razon_social, @telefono, @domicilio, @limite_credito, @vendedor
	while @@FETCH_STATUS = 0
		begin
			
			if exists (select * from Cliente where clie_codigo = @cliente and clie_razon_social = @razon_social)
				or 
			exists (select * from Cliente where clie_codigo = @cliente and @razon_social is null and clie_razon_social is null)
				begin
					print('EL VALOR YA EXISTE EN LA TABLA. SE PROCEDE A GUARDARLO EN LA TABLA AUXILIAR.')
					insert into tabla_auxiliar values (@cliente, @razon_social, GETDATE())
				end
			else
				begin
					insert into Cliente values (@cliente, @razon_social, @telefono, @domicilio, @limite_credito, @vendedor)
				end

			fetch next from c1 into @cliente, @razon_social, @telefono, @domicilio, @limite_credito, @vendedor
		end
		close c1
		deallocate c1
end
go


select * from Cliente