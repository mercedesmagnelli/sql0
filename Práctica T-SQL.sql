-- GUÍA DE EJERCICIOS DE T-SQL

USE GD2015C1
GO

/*Ejercicio 1: hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.*/

CREATE FUNCTION dbo.estado_deposito(@codigo_articulo char(8), @codigo_deposito char(2))
RETURNS varchar(30)
AS
BEGIN

	DECLARE @cantidad_almacenada decimal(12,2)
	DECLARE @maximo_stock decimal(12,2)
	DECLARE @estado varchar(30)

	SELECT @cantidad_almacenada = stoc_cantidad, @maximo_stock = stoc_stock_maximo
	FROM Producto p
	JOIN STOCK s ON p.prod_codigo = s.stoc_producto
	JOIN DEPOSITO d ON s.stoc_deposito = d.depo_codigo
	WHERE p.prod_codigo = @codigo_articulo AND d.depo_codigo = @codigo_deposito

	IF(@cantidad_almacenada < @maximo_stock)
	BEGIN

		DECLARE @porcentaje_ocupacion decimal(3,2)

		SELECT @porcentaje_ocupacion = @cantidad_almacenada * 100 / @maximo_stock

		SET @estado = 'OCUPACION DEL DEPOSITO ' + @porcentaje_ocupacion --Puede utilizarse SELECT en lugar de SET
	END

	ELSE
	BEGIN
		SET @estado = 'DEPOSITO COMPLETO'
	END

	RETURN @estado --Muy importante retornar, y no usar PRINT

END
GO

--Modos de uso:
PRINT DBO.estado_deposito('000041', '10')
SELECT DBO.estado_deposito('000041', '10')

DROP FUNCTION dbo.estado_deposito
GO

CREATE FUNCTION estado_deposito_v1(@codigo_articulo char(8), @codigo_deposito char(2))
RETURNS varchar(60)
AS
BEGIN
	RETURN(SELECT CASE WHEN ISNULL(s.stoc_cantidad, 0) >= ISNULL(s.stoc_stock_maximo, 1) THEN 'DEPÓSITO COMPLETO'
	ELSE 'OCUPACIÓN DEL DEPÓSITO ' + s.stoc_deposito + ': ' + STR(ISNULL(s.stoc_cantidad, 0) * 100 / ISNULL(s.stoc_stock_maximo, 1), 12, 2) + '%' END
	FROM STOCK s
	WHERE s.stoc_producto = @codigo_articulo AND s.stoc_deposito = @codigo_deposito
	)
END
GO

--Modo de uso:
SELECT DBO.estado_deposito_v1(stoc_producto, stoc_deposito) FROM STOCK

DROP FUNCTION dbo.estado_deposito_v1
GO

/*Ejercicio 2: realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha.*/

CREATE FUNCTION dbo.stock_a_la_fecha(@codigo_articulo char(8), @fecha smalldatetime)
RETURNS decimal(12,2)
AS
BEGIN
	RETURN (SELECT SUM(ISNULL(s.stoc_cantidad, 0)) + (SELECT SUM(ISNULL(i.item_cantidad, 0)) FROM Item_Factura i
	JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
	WHERE i.item_producto = @codigo_articulo AND f.fact_fecha >= @fecha
	) FROM STOCK s
	WHERE s.stoc_producto = @codigo_articulo
	)
END
GO

--Una forma menos compacta:
CREATE FUNCTION dbo.stock_a_la_fecha_v1(@codigo_articulo char(8), @fecha smalldatetime)
RETURNS decimal(12,2)
AS
BEGIN
	RETURN (SELECT SUM(ISNULL(s.stoc_cantidad, 0)) FROM STOCK s
	WHERE s.stoc_producto = @codigo_articulo)
	+
	(SELECT SUM(ISNULL(i.item_cantidad, 0)) FROM Item_Factura i
	JOIN Factura f ON i.item_numero = f.fact_numero AND i.item_sucursal = f.fact_sucursal AND i.item_tipo = f.fact_tipo
	WHERE i.item_producto = @codigo_articulo AND f.fact_fecha >= @fecha)
	
END
GO

--Modo de uso:
SELECT dbo.stock_a_la_fecha('00001415', '2012-01-01')
SELECT SUM(ISNULL(s.stoc_cantidad, 0)) FROM STOCK s WHERE s.stoc_producto = '00001415' --Este es el stock actual, y se observa que es menor al de la fecha anteriormente probada

DROP FUNCTION dbo.stock_a_la_fecha
GO

DROP FUNCTION dbo.stock_a_la_fecha_v1
GO

/*Ejercicio 3: cree el/los objetos de base de datos necesarios para corregir la tabla empleado
en caso que sea necesario. Se sabe que debería existir un único gerente general
(debería ser el único empleado sin jefe). Si detecta que hay más de un empleado
sin jefe deberá elegir entre ellos el gerente general, el cual será seleccionado por
mayor salario. Si hay más de uno se seleccionara el de mayor antigüedad en la
empresa. Al finalizar la ejecución del objeto la tabla deberá cumplir con la regla
de un único empleado sin jefe (el gerente general) y deberá retornar la cantidad
de empleados que había sin jefe antes de la ejecución.*/

CREATE PROCEDURE comprobacion_y_correccion_gerente_general(@cantidadDeEmpleadosSinJefe int OUTPUT)
AS
BEGIN

	SELECT @cantidadDeEmpleadosSinJefe = COUNT(*) FROM Empleado WHERE empl_jefe IS NULL

	IF(@cantidadDeEmpleadosSinJefe > 1)
	BEGIN
		DECLARE @gerenteGeneral numeric(6)

		SELECT TOP 1 @gerenteGeneral = empl_codigo
		FROM Empleado
		WHERE empl_jefe IS NULL
		ORDER BY empl_salario DESC, empl_ingreso ASC

		UPDATE Empleado
		SET empl_jefe = @gerenteGeneral
		WHERE empl_jefe IS NULL AND empl_codigo != @gerenteGeneral

		print @cantidadDeEmpleadosSinJefe
	END

END
GO

CREATE PROCEDURE comprobacion_y_correccion_gerente_general_v1(@cantidadDeEmpleadosSinJefe int OUTPUT)
AS
BEGIN

	SELECT @cantidadDeEmpleadosSinJefe = COUNT(*) FROM Empleado WHERE empl_jefe IS NULL

	IF(@cantidadDeEmpleadosSinJefe > 1)
	BEGIN
		UPDATE Empleado
		SET empl_jefe = (SELECT TOP 1 empl_codigo
		FROM Empleado
		WHERE empl_jefe IS NULL
		ORDER BY empl_salario DESC, empl_ingreso ASC)
		WHERE empl_jefe IS NULL AND empl_codigo != (SELECT TOP 1 empl_codigo
		FROM Empleado
		WHERE empl_jefe IS NULL
		ORDER BY empl_salario DESC, empl_ingreso ASC)

		print @cantidadDeEmpleadosSinJefe
	END

END
GO

BEGIN
	DECLARE @cant_empleados_sin_jefe int
	SELECT @cant_empleados_sin_jefe = COUNT(*) FROM Empleado WHERE empl_jefe IS NULL
	PRINT 'La cantidad de empleados sin jefe antes de la ejecución del procedure es: ' + STR(@cant_empleados_sin_jefe)
	EXEC comprobacion_y_correccion_gerente_general @cant_empleados_sin_jefe
	PRINT 'La cantidad de empleados sin jefe luego de la ejecución del procedure es: ' + STR(@cant_empleados_sin_jefe)
END
GO

SELECT * FROM Empleado

DROP PROCEDURE comprobacion_y_correccion_gerente_general
GO

DROP PROCEDURE comprobacion_y_correccion_gerente_general_v1
GO

/*Ejercicio 4: cree el/los objetos de base de datos necesarios para actualizar la columna de
empleado empl_comision con la sumatoria del total de lo vendido por ese
empleado a lo largo del último año. Se deberá retornar el código del vendedor
que más vendió (en monto) a lo largo del último año.*/

CREATE PROCEDURE actualizacion_comisiones(@empleado_que_mas_vendio_en_el_ultimo_anio numeric(6) OUTPUT)
AS
BEGIN
	UPDATE Empleado SET empl_comision = (SELECT SUM(ISNULL(fact_total, 0)) 
										FROM Factura
										WHERE YEAR(fact_fecha) = (SELECT MAX(YEAR(fact_fecha)) FROM Factura)
										AND empl_codigo = fact_vendedor)
	
	SET @empleado_que_mas_vendio_en_el_ultimo_anio = (SELECT TOP 1 empl_codigo FROM Empleado ORDER BY empl_comision DESC)
END
GO

DROP PROCEDURE actualizacion_comisiones
GO

/*Ejercicio 5: realizar un procedimiento que complete con los datos existentes en el modelo
provisto la tabla de hechos denominada Fact_table tiene las siguiente definición: 
Create table Fact_table
(anio char(4),
mes char(2),
familia char(3),
rubro char(4),
zona char(3),
cliente char(6),
producto char(8),
cantidad decimal(12,2),
monto decimal(12,2)
)
Alter table Fact_table
Add constraint primary key(anio,mes,familia,rubro,zona,cliente,producto)*/

CREATE TABLE Fact_table
(Anio char(4) NOT NULL,
Mes char(2) NOT NULL,
Familia char(3) NOT NULL,
Rubro char(4) NOT NULL,
Zona char(3) NOT NULL,
Cliente char(6) NOT NULL,
Producto char(8) NOT NULL,
Cantidad decimal(12,2),
Monto decimal(12,2))
GO

ALTER TABLE Fact_table ADD CONSTRAINT PK_Fact_table PRIMARY KEY (Anio, Mes, Familia, Rubro, Zona, Cliente, Producto)
GO

CREATE PROCEDURE completar_tabla_Fact_table
AS
BEGIN
	INSERT INTO Fact_table (Anio, Mes, Familia, Rubro, Zona, Cliente, Producto, Cantidad, Monto)
	SELECT YEAR(fact_fecha), MONTH(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo, SUM(item_cantidad), SUM(item_precio)--Si no se hace la suma, el motor arroja error de clave duplicada, debido a que se tienen idénticas filas, excepto por número de factura (campo no contemplado en esta tabla)
	FROM Factura
	JOIN Item_Factura ON fact_numero = item_numero AND fact_sucursal = item_sucursal AND fact_tipo = item_tipo
	JOIN Producto ON item_producto = prod_codigo
	JOIN Empleado ON fact_vendedor = empl_codigo
	JOIN Departamento ON empl_departamento = depa_codigo
	GROUP BY YEAR(fact_fecha), MONTH(fact_fecha), prod_familia, prod_rubro, depa_zona, fact_cliente, prod_codigo
	ORDER BY 1, 2, 3, 4, 5, 6, 7
END
GO

EXEC completar_tabla_Fact_table
GO

SELECT * FROM Fact_table

DROP PROCEDURE completar_tabla_Fact_table
GO

DROP TABLE Fact_table
GO

/*Ejercicio 6: Realizar un procedimiento que si en alguna factura se facturaron componentes
que conforman un combo determinado (o sea que juntos componen otro
producto de mayor nivel), en cuyo caso deberá reemplazar las filas
correspondientes a dichos productos por una sola fila con el producto que
componen con la cantidad de dicho producto que corresponda.*/



/*Ejercicio 7: hacer un procedimiento que dadas dos fechas complete la tabla Ventas. Debe
insertar una línea por cada artículo con los movimientos de stock generados por
las ventas entre esas fechas. La tabla se encuentra creada y vacía.
*/

CREATE TABLE Ventas
(Codigo char(8),
Detalle char(50),
Cant_mov int,
Precio_de_venta decimal(12,2),
Renglon int,
Ganancia decimal(12,2)
)
GO

CREATE PROCEDURE completar_tabla_Ventas(@fecha_inicio smalldatetime, @fecha_fin smalldatetime)
AS
BEGIN
	DECLARE @codigo_producto AS char(8), @detalle_producto AS char(50), @cantidad_de_movimientos AS int,
	@precio_de_venta AS decimal (12,2), @renglon AS int, @ganancia AS decimal(12,2)

	DECLARE cursor_datos_tabla_ventas CURSOR FOR (SELECT prod_codigo, prod_detalle, COUNT(item_producto), AVG(item_precio),
	                                             (SUM(item_cantidad * item_precio) - SUM(item_cantidad * prod_precio))
	                                             FROM Producto
	                                             JOIN Item_Factura ON prod_codigo = item_producto
	                                             JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	                                             WHERE fact_fecha BETWEEN @fecha_inicio AND @fecha_fin
	                                             GROUP BY prod_codigo, prod_detalle)
	OPEN cursor_datos_tabla_ventas

	SET @renglon = 0

	FETCH cursor_datos_tabla_ventas INTO @codigo_producto, @detalle_producto, @cantidad_de_movimientos, @precio_de_venta, @ganancia

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SET @renglon = @renglon + 1
		
		INSERT INTO Ventas(Codigo, Detalle, Cant_mov, Precio_de_venta, Renglon, Ganancia)
		VALUES(@codigo_producto, @detalle_producto, @cantidad_de_movimientos, @precio_de_venta, @ganancia)

		FETCH cursor_datos_tabla_ventas INTO @codigo_producto, @detalle_producto, @cantidad_de_movimientos, @precio_de_venta, @ganancia
	END

	CLOSE cursor_datos_tabla_ventas

	DEALLOCATE cursor_datos_tabla_ventas
	
END
GO

--Planteo inicial, sin cursor:
CREATE PROCEDURE completar_tabla_Ventas_v1(@fecha_inicio smalldatetime, @fecha_fin smalldatetime)
AS
BEGIN
	INSERT INTO Ventas(Codigo, Detalle, Cant_mov, Precio_de_venta, Renglon, Ganancia)
	SELECT prod_codigo, prod_detalle, COUNT(item_producto), AVG(item_precio), ROW_NUMBER() OVER(ORDER BY prod_codigo), (SUM(item_cantidad * item_precio) - SUM(item_cantidad * prod_precio))
	FROM Producto
	JOIN Item_Factura ON prod_codigo = item_producto
	JOIN Factura ON item_numero = fact_numero AND item_sucursal = fact_sucursal AND item_tipo = fact_tipo
	WHERE fact_fecha BETWEEN @fecha_inicio AND @fecha_fin
	GROUP BY prod_codigo, prod_detalle
END
GO

EXEC completar_tabla_Ventas '2012-01-01', '2012-08-10'
GO

SELECT * FROM Ventas

DROP PROCEDURE completar_tabla_Ventas
GO

DROP PROCEDURE completar_tabla_Ventas_v1
GO

DROP TABLE Ventas
GO

/*Ejercicio 8: Realizar un procedimiento que complete la tabla Diferencias de precios, para los
productos facturados que tengan composición y en los cuales el precio de
facturación sea diferente al precio del cálculo de los precios unitarios por
cantidad de sus componentes, se aclara que un producto que compone a otro,
también puede estar compuesto por otros y así sucesivamente, la tabla se debe
crear y está formada por las siguientes columnas: Codigo, Detalle, Cantidad, Precio_generado, Precio_facturado.*/

CREATE TABLE Diferencias
(Codigo char(8) NOT NULL,
Detalle char(50) NOT NULL,
Cantidad int NOT NULL,
Precio_generado decimal(12,2),
Precio_facturado decimal(12,2) NOT NULL
)
GO

ALTER TABLE Diferencias ADD CONSTRAINT PK_Diferencias PRIMARY KEY(Codigo, Detalle, Cantidad, Precio_facturado)
GO

/*Preguntarse por qué no da error si se crea un cursor con el mismo nombre dentro de cada llamada a la función. Quizás es (se me ocurre) porque son scopes 
distintos. Es decir, cada cursor se va creando dentro de otro cursor "padre" con el mismo nombre*/

CREATE FUNCTION dbo.calcular_precio_generado(@producto_codigo char(8))
RETURNS decimal(12,2)
AS
BEGIN
	DECLARE @precio_generado AS decimal(12,2)

	IF(NOT EXISTS (SELECT comp_producto FROM Composicion WHERE comp_producto = @producto_codigo))
		BEGIN
			SET @precio_generado = (SELECT prod_precio FROM Producto WHERE prod_codigo = @producto_codigo)
		END

	ELSE
		BEGIN
			DECLARE @codigo_componente AS char(8)
			DECLARE @cantidad_componente AS decimal(12,2)

			SET @precio_generado = 0
			
			DECLARE calculador_precio_generado CURSOR FOR
			SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @producto_codigo

			OPEN calculador_precio_generado

			FETCH NEXT FROM calculador_precio_generado INTO @codigo_componente, @cantidad_componente

			WHILE(@@FETCH_STATUS = 0)
			BEGIN
				SET @precio_generado = @precio_generado + dbo.calcular_precio_generado(@codigo_componente) * @cantidad_componente

				FETCH calculador_precio_generado INTO @codigo_componente, @cantidad_componente --FETCH es lo mismo que FETCH NEXT, ya que NEXT es la opción por default
			END

			CLOSE calculador_precio_generado

			DEALLOCATE calculador_precio_generado
		END

	RETURN @precio_generado
END
GO

CREATE PROCEDURE diferencia_de_precios
AS
BEGIN
	INSERT INTO Diferencias(Codigo, Detalle, Cantidad, Precio_generado, Precio_facturado)
	SELECT prod_codigo, prod_detalle, COUNT(DISTINCT comp_componente), dbo.calcular_precio_generado(prod_codigo), item_precio
	FROM Composicion
	JOIN Producto ON comp_producto = prod_codigo
	JOIN Item_Factura ON prod_codigo = item_producto
	WHERE item_precio != dbo.calcular_precio_generado(prod_codigo)
	GROUP BY prod_codigo, prod_detalle, item_precio
END
GO

EXEC diferencia_de_precios
GO

SELECT * FROM Diferencias

DROP FUNCTION dbo.calcular_precio_generado
GO

DROP PROCEDURE diferencia_de_precios
GO

DROP TABLE Diferencias
GO

/*Ejercicio 9: crear el/los objetos de base de datos que ante alguna modificación de un ítem de
factura de un artículo con composición realice el movimiento de sus
correspondientes componentes.*/

CREATE TRIGGER actualizacion_stock_para_productos_composicion ON Item_factura FOR UPDATE
AS
BEGIN
	DECLARE @componente char(8), @cantidad int, @codigo_deposito char(2)

	DECLARE cursor_componente CURSOR FOR (SELECT comp_componente, (i.item_cantidad - d.item_cantidad) * comp_cantidad
								         FROM Composicion
								         JOIN inserted i ON comp_producto = i.item_producto
								         JOIN deleted d ON comp_producto = d.item_producto
								         WHERE i.item_cantidad != d.item_cantidad)
	
	OPEN cursor_componente
	
	FETCH cursor_componente INTO @componente, @cantidad

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad > 0) --Se produjo una actualización de stock negativa porque se vendieron unidades, es decir, se quitaron unidades
			BEGIN
				SET @codigo_deposito = (SELECT TOP 1 stoc_deposito FROM STOCK WHERE stoc_producto = @componente ORDER BY stoc_cantidad ASC)
			END
		ELSE --Se sumaron unidades
			BEGIN
				SET @codigo_deposito = (SELECT TOP 1 stoc_deposito FROM STOCK WHERE stoc_producto = @componente ORDER BY stoc_cantidad DESC)
			END

		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad
		WHERE stoc_producto = @componente
		AND stoc_deposito = @codigo_deposito
	END

	CLOSE cursor_componente

	DEALLOCATE cursor_componente
END
GO

DROP TRIGGER actualizacion_stock_para_productos_composicion
GO

/*Ejercicio 10: crear el/los objetos de base de datos que ante el intento de borrar un artículo
verifique que no exista stock y si es así lo borre en caso contrario que emita un
mensaje de error.*/

--Esta variante hace el análisis por cada uno de los productos a borrar en un borrado masivo
CREATE TRIGGER borrado_de_producto ON Producto INSTEAD OF DELETE
AS
BEGIN
	DECLARE @codigo_producto_a_borrar char(8), @stock_total_producto_a_borrar decimal(12,2)

	DECLARE cursor_verificador_stock CURSOR FOR (SELECT d.prod_codigo, SUM(stoc_cantidad)
											    FROM deleted d 
											    JOIN STOCK ON d.prod_codigo = stoc_producto
											    GROUP BY d.prod_codigo)
	OPEN cursor_verificador_stock

	FETCH cursor_verificador_stock INTO @codigo_producto_a_borrar, @stock_total_producto_a_borrar

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@stock_total_producto_a_borrar = 0)
		BEGIN
			DELETE FROM Producto WHERE prod_codigo = @codigo_producto_a_borrar
		END

		ELSE
		BEGIN
			PRINT 'No se puede borrar el artículo con código ' + @codigo_producto_a_borrar + ' , pues todavía hay unidades en Stock.'
		END

		FETCH cursor_verificador_stock INTO @codigo_producto_a_borrar, @stock_total
	END

	CLOSE cursor_verificador_stock

	DEALLOCATE cursor_verificador_stock
END
GO

DROP TRIGGER borrado_de_producto
GO

--Esta variante analiza el borrado en forma global, es decir, si un borrado falla, no se podrá realiazr ninguno de los restantes borrados
CREATE TRIGGER borrado_de_producto_v1 ON Producto FOR DELETE
AS
BEGIN
	IF(EXISTS (SELECT * FROM STOCK JOIN deleted ON stoc_producto = prod_codigo WHERE stoc_cantidad > 0))
	BEGIN
		PRINT 'No se puede realizar el borrado de artículos, ya que hay artículos con stock.'
		ROLLBACK
	END
END
GO

DROP TRIGGER borrado_de_producto_v1
GO

/*Ejercicio 11: cree el/los objetos de base de datos necesarios para que dado un código de
empleado se retorne la cantidad de empleados que este tiene a su cargo (directa o
indirectamente). Solo contar aquellos empleados (directos o indirectos) que
tengan un código mayor que su jefe directo.*/

CREATE FUNCTION dbo.cantidad_de_empleados_a_cargo(@codigo_empleado numeric(6))
RETURNS int
AS
BEGIN
RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0
                         ELSE (SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @codigo_empleado) + 
	                          (SELECT SUM(dbo.cantidad_de_empleados_a_cargo(empl_codigo))
							  FROM Empleado WHERE empl_jefe = @codigo_empleado) END
       FROM Empleado WHERE empl_jefe = @codigo_empleado)
END
GO

--Una forma menos compacta (planteada inicialmente):
CREATE FUNCTION dbo.cantidad_de_empleados_a_cargo_v1(@codigo_empleado numeric(6))
RETURNS int
AS
BEGIN
	DECLARE @cantidad_de_empleados_a_cargo AS int

	IF(SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @codigo_empleado) = 0
	BEGIN
	SET @cantidad_de_empleados_a_cargo = 0
	END

	ELSE
	BEGIN
	SET @cantidad_de_empleados_a_cargo = (SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @codigo_empleado) + 
	                                     (SELECT SUM(dbo.cantidad_de_empleados_a_cargo_v1(empl_codigo))
										 FROM Empleado WHERE empl_jefe = @codigo_empleado)
	END

RETURN @cantidad_de_empleados_a_cargo
END
GO

--Modo de uso:
SELECT empl_codigo AS 'Código de empleado',
       empl_nombre AS 'Nombre',
	   empl_apellido AS 'Apellido',
	   dbo.cantidad_de_empleados_a_cargo(empl_codigo) AS 'Cantidad de empleados a cargo' FROM Empleado

SELECT empl_codigo AS 'Código de empleado',
       empl_nombre AS 'Nombre',
	   empl_apellido AS 'Apellido',
	   dbo.cantidad_de_empleados_a_cargo_v1(empl_codigo) AS 'Cantidad de empleados a cargo' FROM Empleado

DROP FUNCTION dbo.cantidad_de_empleados_a_cargo
GO

DROP FUNCTION dbo.cantidad_de_empleados_a_cargo_v1
GO

/*Ejercicio 12: cree el/los objetos de base de datos necesarios para que nunca un producto
pueda ser compuesto por sí mismo. Se sabe que en la actualidad dicha regla se
cumple y que la base de datos es accedida por n aplicaciones de diferentes tipos
y tecnologías. No se conoce la cantidad de niveles de composición existentes.*/

/*Con esta resolución, lo único que no se permite es insertar componentes que sean o estén compeustos por el producto en cuestión. No se borra el producto 
composición ya insertado, que es lo se quizás se debería hacer.*/

CREATE FUNCTION dbo.verificacion_componente_valido(@codigo_de_producto char(8), @codigo_de_componente char(8))
RETURNS BIT
AS
BEGIN
	DECLARE @valor_verificacion AS bit

	IF(@codigo_de_producto = @codigo_de_componente) SET @valor_verificacion = 0
	ELSE
	BEGIN
		IF((SELECT COUNT(comp_componente) FROM Composicion WHERE comp_producto = @codigo_de_componente) = 0) SET @valor_verificacion = 1 --El componente no es compuesto
		ELSE 
			BEGIN
				IF(EXISTS (SELECT comp_componente FROM Composicion WHERE comp_producto = @codigo_de_componente AND dbo.verificar_componente_valido(@codigo_de_producto, comp_componente) = 0)) SET @valor_verificacion = 0
				ELSE SET @valor_verificacion = 1
			END
	END

	RETURN @valor_verificacion
END
GO

CREATE TRIGGER verificacion_producto_con_composicion_valido ON Composicion INSTEAD OF INSERT
AS
BEGIN
	DECLARE @codigo_de_producto AS char(8)
	DECLARE @codigo_de_componente AS char(8)
	DECLARE @cantidad_de_componente AS decimal (12, 2)

	DECLARE cursor_productos_insertados CURSOR FOR (SELECT comp_producto, comp_componente, comp_cantidad FROM inserted)

	OPEN cursor_productos_composicion_insertados

	FETCH NEXT FROM cursor_productos_composicion_insertados INTO @codigo_de_producto, @codigo_de_componente, @cantidad_de_componente

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(dbo.verificacion_componente_valido(@codigo_de_producto, @codigo_de_componente) = 0)
		BEGIN
			PRINT 'El producto ' + @codigo_de_componente + ' no se puede insertar debido a que se compone directa o indirectamente a sí mismo.' 
	
			/*Para contemplar lo dicho anteriormente, se podrían agregar las siguientes dos líneas, para dejar el modelo consistente: */
			/*DELETE FROM Composicion WHERE comp_producto = @codigo_de_producto
			DELETE FROM Producto WHERE prod_codigo = @codigo_de_producto*/
		END

		ELSE
		BEGIN
			INSERT INTO Composicion(comp_producto, comp_componente, comp_cantidad)
			VALUES (@codigo_de_producto, @codigo_de_componente, @cantidad_de_componente)
		END

	FETCH NEXT FROM cursor_productos_composicion_insertados INTO @codigo_de_producto, @codigo_de_componente, @cantidad_de_componente
	END

	CLOSE cursor_productos_composicion_insertados

	DEALLOCATE cursor_productos_composicion_insertados
END
GO

DROP FUNCTION dbo.verificacion_componente_valido
GO

DROP TRIGGER verificacion_producto_con_composicion_valido
GO

/*Ejercicio 13: cree el/los objetos de base de datos necesarios para implantar la siguiente regla
“Ningún jefe puede tener un salario mayor al 20% de las suma de los salarios de
sus empleados totales (directos + indirectos)”. Se sabe que en la actualidad dicha
regla se cumple y que la base de datos es accedida por n aplicaciones de
diferentes tipos y tecnologías*/

CREATE FUNCTION dbo.suma_de_salarios_de_subordinados(@codigo_jefe numeric(6))
RETURNS decimal(12, 2)
AS
BEGIN
	RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0
		                ELSE SUM(empl_salario + dbo.suma_de_salarios_de_subordinados(empl_codigo)) END
		   FROM Empleado WHERE empl_jefe = @codigo_jefe)
END
GO

--Con un cursor:
CREATE FUNCTION dbo.suma_de_salarios_de_subordinados_v1(@codigo_jefe numeric(6))
RETURNS decimal(12, 2)
AS
BEGIN
	DECLARE @salario_de_subordinados AS decimal(12,2), @codigo_empleado AS numeric(6)
	
	SET @salario_de_subordinados = (SELECT ISNULL(SUM(empl_salario), 0) FROM Empleado WHERE empl_jefe = @codigo_jefe)

	DECLARE salarios_de_subordinados_de_subordinados CURSOR FOR (SELECT empl_codigo FROM Empleado WHERE empl_jefe = @codigo_jefe)
	
	OPEN salarios_de_subordinados_de_subordinados

	FETCH salarios_de_subordinados_de_subordinados INTO @codigo_empleado

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		SET @salario_de_subordinados = @salario_de_subordinados + dbo.suma_de_salarios_de_subordinados_v1(@codigo_empleado)
		FETCH salarios_de_subordinados_de_subordinados INTO @codigo_empleado
	END

	CLOSE salarios_de_subordinados_de_subordinados

	DEALLOCATE salarios_de_subordinados_de_subordinados
	
	RETURN @salario_de_subordinados
END
GO

CREATE TRIGGER validacion_salario_jefe ON Empleado INSTEAD OF UPDATE
AS
BEGIN
	DECLARE @codigo_jefe AS numeric(6), @salario_jefe AS decimal (12, 2)
	DECLARE cursor_salario_jefe CURSOR FOR (SELECT d.empl_codigo, i.empl_salario
	                                        FROM deleted d
										    JOIN inserted i ON d.empl_codigo = i.empl_codigo
										    WHERE d.empl_codigo IN (SELECT empl_jefe FROM Empleado)
											AND d.empl_salario = i.empl_salario)

	OPEN cursor_salario_jefe
	
	FETCH cursor_salario_jefe INTO @codigo_jefe, @salario_jefe

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		IF(@salario_jefe > 0.2 * dbo.suma_de_salarios_de_subordinados(@codigo_jefe))
		BEGIN
			PRINT 'El salario del jefe ' + STR(@codigo_jefe, 6, 0) + ' no puede modificarse debido a que supera el 20% de la suma de los salarios de sus subordinados.'
		END

		ELSE
		BEGIN
			UPDATE Empleado SET empl_salario = @salario_jefe WHERE empl_codigo = @codigo_jefe
		END

		FETCH cursor_salario_jefe INTO @codigo_jefe, @salario_jefe
	END

	CLOSE cursor_salario_jefe

	DEALLOCATE cursor_salario_jefe
END
GO

DROP FUNCTION dbo.suma_de_salarios_de_subordinados
GO

DROP FUNCTION dbo.suma_de_salarios_de_subordinados_v1
GO

DROP TRIGGER validacion_salario_jefe
GO

/*Ejercicio 14: agregar el/los objetos necesarios para que si un cliente compra un producto
compuesto a un precio menor que la suma de los precios de sus componentes
que imprima la fecha, que cliente, que productos y a qué precio se realizó la
compra. No se deberá permitir que dicho precio sea menor a la mitad de la suma
de los componentes.*/

CREATE TRIGGER verificacion_compra_de_productos_compuestos ON Item_Factura INSTEAD OF INSERT
AS
BEGIN
	DECLARE @cantidad_item AS decimal(12,2),
	        @numero_item AS char(8),
	        @precio_item AS decimal(12,2),
			@producto_item AS char(8),
			@sucursal_item AS char(4),
			@tipo_item AS char(1),
			@cliente_fact AS char(6),
			@fecha_fact AS smalldatetime

	DECLARE cursor_items_compuestos_facturados CURSOR FOR (SELECT i.item_cantidad,
	                                                              i.item_numero,
													              i.item_precio,
													              i.item_producto,
													              i.item_sucursal,
													              i.item_tipo,
																  fact_cliente,
													              fact_fecha
													              FROM inserted i
													              JOIN Factura ON i.item_numero = fact_numero
													              AND i.item_sucursal = fact_sucursal
													              AND i.item_tipo = fact_tipo
																  JOIN Composicion ON i.item_producto = comp_producto)
	 
	OPEN cursor_items_compuestos_facturados

	FETCH cursor_items_compuestos_facturados INTO @cantidad_item,
	                                              @numero_item,
												  @precio_item,
												  @producto_item,
												  @sucursal_item,
											      @tipo_item,
												  @cliente_fact,
												  @fecha_fact
	
	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @suma_de_precios_de_componentes AS decimal(12,2)

		SET @suma_de_precios_de_componentes = (SELECT SUM(prod_precio)
		                                      FROM Producto
						                      JOIN Composicion ON prod_codigo = comp_componente
						                      WHERE prod_codigo = @producto_item)
		IF(@precio_item < 0.5 * @suma_de_precios_de_componentes)
		BEGIN
			PRINT'El cliente ' + @cliente_fact + ' no puede comprar el producto ' + @producto_item + ' porque su precio es inferior a la mitad del precio de la suma de sus componentes.' 
		END
		
		ELSE
		BEGIN
			IF(@precio_item < @suma_de_precios_de_componentes)
			PRINT'El cliente ' + @cliente_fact + ' compró el producto ' + @producto_item + ' el día ' + STR(@fecha_fact, 15, 0) + ' por un precio menor al de la suma de sus componentes.'
			INSERT INTO Item_Factura(item_cantidad, item_numero, item_precio, item_producto, item_sucursal, item_tipo)
			VALUES (@cantidad_item, @numero_item, @precio_item, @producto_item, @sucursal_item, @tipo_item)
		END

		FETCH cursor_items_compuestos_facturados INTO @cantidad_item,
	                                               @numero_item,
												   @precio_item,
												   @producto_item,
												   @sucursal_item,
												   @tipo_item,
												   @cliente_fact,
												   @fecha_fact
	END
END
GO

DROP TRIGGER verificacion_compra_de_productos_compuestos
GO

/*Ejercicio 15: cree el/los objetos de base de datos necesarios para que el objeto principal
reciba un producto como parametro y retorne el precio del mismo.
Se debe prever que el precio de los productos compuestos sera la sumatoria de
los componentes del mismo multiplicado por sus respectivas cantidades. No se
conocen los nivles de anidamiento posibles de los productos. Se asegura que
nunca un producto esta compuesto por si mismo a ningun nivel. El objeto
principal debe poder ser utilizado como filtro en el where de una sentencia
select.*/

CREATE FUNCTION dbo.es_producto_compuesto(@codigo_de_producto char(8))
RETURNS BIT
AS
BEGIN
	RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END FROM Composicion WHERE comp_producto = @codigo_de_producto)
END
GO

CREATE FUNCTION dbo.precio_de_producto(@codigo_de_producto char(8))
RETURNS decimal(12,2)
AS
BEGIN
	DECLARE @precio AS decimal(12,2)
	IF(dbo.es_producto_compuesto(@codigo_de_producto) = 0)
	BEGIN
		SET @precio = (SELECT prod_precio FROM Producto WHERE prod_codigo = @codigo_de_producto)
	END

	ELSE
	BEGIN
		SET @precio = (SELECT SUM(comp_cantidad * dbo.precio_de_producto(comp_componente)) FROM Composicion WHERE comp_producto = @codigo_de_producto)
	END

	RETURN @precio
END
GO

--Modo de uso:
SELECT DISTINCT comp_producto AS 'Código de producto', dbo.precio_de_producto(comp_producto) AS 'Precio' FROM Composicion

DROP FUNCTION dbo.es_producto_compuesto
GO

DROP FUNCTION dbo.precio_de_producto
GO

/*Ejercicio 16: desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se descuenten del stock los articulos vendidos. Se descontaran
del deposito que mas producto poseea y se supone que el stock se almacena
tanto de productos simples como compuestos (si se acaba el stock de los
compuestos no se arman combos)
En caso que no alcance el stock de un deposito se descontara del siguiente y asi
hasta agotar los depositos posibles. En ultima instancia se dejara stock negativo
en el ultimo deposito que se desconto.*/

CREATE FUNCTION dbo.es_producto_compuesto(@codigo_de_producto char(8))
RETURNS BIT
AS
BEGIN
	RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0 ELSE 1 END FROM Composicion WHERE comp_producto = @codigo_de_producto)
END
GO

CREATE PROCEDURE descontar_stock(@codigo_de_producto char(8), @cantidad decimal(12,2))
AS
BEGIN
	IF(EXISTS(SELECT stoc_deposito FROM STOCK WHERE stoc_producto = @codigo_de_producto AND stoc_cantidad >= @cantidad))
	BEGIN
		UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad
		WHERE stoc_deposito = (SELECT TOP 1 stoc_deposito FROM STOCK
		                      WHERE stoc_producto = @codigo_de_producto
							  ORDER BY stoc_cantidad DESC)
	END

	ELSE
	BEGIN
		DECLARE @codigo_de_deposito_a_descontar AS char(2), @cantidad_a_descontar AS decimal(12,2)
		SET @cantidad_a_descontar = @cantidad

		IF(@cantidad_a_descontar > 0)
		BEGIN
			SET @codigo_de_deposito_a_descontar = (SELECT stoc_deposito FROM STOCK
												  WHERE stoc_producto = @codigo_de_producto
												  ORDER BY stoc_cantidad DESC)
			
			DECLARE @stoc_de_deposito AS decimal(12,2)
			SET @stoc_de_deposito = (SELECT stoc_cantidad FROM STOCK WHERE stoc_deposito = @codigo_de_deposito_a_descontar)
		
			IF(@stoc_de_deposito > 0)
			BEGIN
				UPDATE STOCK SET stoc_cantidad = 0 WHERE stoc_deposito = @codigo_de_deposito_a_descontar AND stoc_producto = @codigo_de_producto
				SET @cantidad_a_descontar = @cantidad_a_descontar - @stoc_de_deposito
			END

			ELSE
			BEGIN
				UPDATE STOCK SET stoc_cantidad = stoc_cantidad - @cantidad_a_descontar WHERE stoc_deposito = @codigo_de_deposito_a_descontar AND stoc_producto = @codigo_de_producto
				SET @cantidad_a_descontar = 0
			END

			EXEC descontar_stock @codigo_de_producto, @cantidad_a_descontar
		END
	END
END
GO

CREATE PROCEDURE descontar_stock_de_producto(@codigo_de_producto char(8), @cantidad decimal(12,2))
AS
BEGIN
	IF(dbo.es_producto_compuesto(@codigo_de_producto) = 1)
	BEGIN
		DECLARE @codigo_componente AS char(8), @cantidad_componente AS decimal(12,2)
		DECLARE cursor_componentes CURSOR FOR (SELECT comp_componente, comp_cantidad FROM Composicion WHERE comp_producto = @codigo_de_producto)

		OPEN cursor_componentes

		FETCH cursor_componentes INTO @codigo_componente, @cantidad_componente

		WHILE(@@FETCH_STATUS = 0)
		BEGIN
			DECLARE @cantidad_a_descontar AS decimal(12,2)
			SET @cantidad_a_descontar = @cantidad * @cantidad_componente
			EXEC descontar_stock @codigo_componente, @cantidad_a_descontar
			FETCH cursor_componentes INTO @codigo_componente, @cantidad_componente
		END

		CLOSE cursor_componentes
		DEALLOCATE cursor_componentes
	END

	ELSE
	BEGIN
		EXEC descontar_stock @codigo_de_producto, @cantidad
	END
END
GO

CREATE TRIGGER descuento_stock ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @codigo_de_producto AS char(8), @cantidad AS decimal(12,2)
	DECLARE cursor_items_vendidos CURSOR FOR (SELECT i.item_producto, i.item_cantidad FROM inserted i)

	OPEN cursor_items_vendidos

	FETCH cursor_items_vendidos INTO @codigo_de_producto, @cantidad

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		EXEC descontar_stock_de_producto @codigo_de_producto, @cantidad
		FETCH cursor_items_vendidos INTO @codigo_de_producto, @cantidad
	END

	CLOSE cursor_items_vendidos

	DEALLOCATE cursor_items_vendidos
END
GO

DROP FUNCTION dbo.es_producto_compuesto
GO

DROP PROCEDURE descontar_stock
GO

DROP PROCEDURE descontar_stock_de_producto
GO

DROP TRIGGER descuento_stock
GO

/*Ejercicio 17: sabiendo que el punto de reposicion del stock es la menor cantidad de ese objeto
que se debe almacenar en el deposito y que el stock maximo es la maxima
cantidad de ese producto en ese deposito, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio se cumpla automaticamente. No se
conoce la forma de acceso a los datos ni el procedimiento por el cual se
incrementa o descuenta stock*/

--Considerando una actualización masiva:

CREATE TRIGGER validacion_actualizacion_stock ON STOCK FOR UPDATE
AS
BEGIN
	IF(EXISTS(SELECT i.stoc_deposito FROM inserted i
	         JOIN deleted d ON i.stoc_deposito = d.stoc_deposito AND i.stoc_producto = d.stoc_producto
			 WHERE (i.stoc_cantidad < d.stoc_stock_maximo OR i.stoc_cantidad > d.stoc_stock_maximo) AND i.stoc_cantidad != d.stoc_cantidad))
	PRINT 'No se puede modificar el stock debido a que existe al menos un producto para el cual su stock es inferior al mínimo, o bien un producto con stock superior al máximo.'
	ROLLBACK
END
GO

--Discriminando ente actualizaciones correctas e incorrectas:
CREATE TRIGGER validacion_actualizacion_stock_v1 ON STOCK INSTEAD OF UPDATE
AS
BEGIN
	DECLARE	@deposito_stock AS char(2), @producto_stock AS char(6), @cantidad_stock AS decimal(12,2),
	        @maximo_stock AS decimal(12,2), @minimo_stock AS decimal(12,2)
	DECLARE cursor_modificaciones_stock CURSOR FOR (SELECT i.stoc_deposito, i.stoc_producto, i.stoc_cantidad, d.stoc_stock_maximo, d.stoc_punto_reposicion
	                                               FROM inserted i
												   JOIN deleted d ON i.stoc_deposito = d.stoc_deposito AND i.stoc_producto = d.stoc_producto
												   WHERE i.stoc_cantidad != d.stoc_cantidad)

	OPEN cursor_modificaciones_stock

	FETCH cursor_modificaciones_stock INTO @deposito_stock, @producto_stock, @cantidad_stock, @maximo_stock, @minimo_stock

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad_stock BETWEEN @minimo_stock AND @maximo_stock)
		BEGIN
			UPDATE STOCK SET stoc_cantidad = @cantidad_stock WHERE stoc_deposito = @deposito_stock AND stoc_producto = @producto_stock
		END

		ELSE
		BEGIN
			IF(@cantidad_stock < @minimo_stock)
			BEGIN
				PRINT 'No se pede modificar el stock para el producto ' + @producto_stock + ' en el depósito ' + @deposito_stock + ' debido a que la cantidad de stock es inferior al punto de reposición.'
			END
			
			ELSE
			BEGIN
				PRINT 'No se pede modificar el stock para el producto ' + @producto_stock + ' en el depósito ' + @deposito_stock + ' debido a que la cantidad de stock supera a la máxima permitida.'
			END
		END

		FETCH cursor_modificaciones_stock INTO @deposito_stock, @producto_stock, @cantidad_stock
	END

	CLOSE cursor_modificaciones_stock
	DEALLOCATE cursor_modificaciones_stock
END
GO

DROP TRIGGER validacion_actualizacion_stock
GO

DROP TRIGGER validacion_actualizacion_stock_v1
GO

/*Ejercicio 18: sabiendo que el limite de credito de un cliente es el monto maximo que se le
puede facturar mensualmente, cree el/los objetos de base de datos necesarios
para que dicha regla de negocio se cumpla automaticamente. No se conoce la
forma de acceso a los datos ni el procedimiento por el cual se emiten las facturas.*/

CREATE TRIGGER verificacion_limite_de_credito ON Factura FOR INSERT
AS
BEGIN
	DECLARE @cliente_factura AS char(6), @fecha_factura AS smalldatetime, @numero_factura AS char(8), @sucursal_factura AS char(4), @tipo_factura AS char(1), 
	@total_factura AS decimal(12,2)
	DECLARE cursor_facturas_insertadas CURSOR FOR (SELECT i.fact_cliente, i.fact_fecha, i.fact_numero, i.fact_sucursal, i.fact_tipo, i.fact_total
	                                              FROM inserted i)
	
	OPEN cursor_facturas_insertadas

	FETCH cursor_facturas_insertadas INTO @cliente_factura, @fecha_factura, @numero_factura, @sucursal_factura, @tipo_factura, @total_factura

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @credito_restante AS decimal(12,2)
		SET @credito_restante = (SELECT clie_limite_credito - SUM(fact_total)
		                        FROM Factura
								JOIN Cliente ON fact_cliente = clie_codigo
								WHERE fact_cliente = @cliente_factura
		                        AND MONTH(fact_fecha) = MONTH(@fecha_factura)
								AND YEAR(fact_fecha) = YEAR(@fecha_factura)
								GROUP BY clie_limite_credito)
		
		IF(@total_factura > @credito_restante)
		BEGIN
			PRINT 'No se pudo completar la operación debido a que el cliente ' + TRIM(@cliente_factura) + ' ha superado el límite de crédito mensual de ' + STR(@credito_restante, 12, 2) + '.'
			ROLLBACK 
		END

		ELSE
		BEGIN
			UPDATE Cliente SET clie_limite_credito = clie_limite_credito - @total_factura WHERE clie_codigo = @cliente_factura
		END
	END

	CLOSE cursor_facturas_insertadas
	DEALLOCATE cursor_facturas_insertadas
END
GO

DROP TRIGGER verificacion_limite_de_credito
GO

/*Ejercicio 19: cree el/los objetos de base de datos necesarios para que se cumpla la siguiente
regla de negocio automáticamente “Ningún jefe puede tener menos de 5 años de
antigüedad y tampoco puede tener más del 50% del personal a su cargo
(contando directos e indirectos) a excepción del gerente general”. Se sabe que en
la actualidad la regla se cumple y existe un único gerente general.*/

CREATE FUNCTION dbo.cantidad_de_empleados_a_cargo(@codigo_empleado numeric(6))
RETURNS int
AS
BEGIN
RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0
                         ELSE (SELECT COUNT(*) FROM Empleado WHERE empl_jefe = @codigo_empleado) + 
	                          (SELECT SUM(dbo.cantidad_de_empleados_a_cargo(empl_codigo))
							  FROM Empleado WHERE empl_jefe = @codigo_empleado) END
       FROM Empleado WHERE empl_jefe = @codigo_empleado)
END
GO

CREATE FUNCTION dbo.es_gerente_general(@codigo_jefe numeric(6))
RETURNS bit
AS
BEGIN
	RETURN (SELECT CASE WHEN @codigo_jefe = (SELECT TOP 1 empl_codigo
		                                    FROM Empleado
		                                    WHERE empl_jefe IS NULL
		                                    ORDER BY empl_salario DESC, empl_ingreso ASC)
						THEN 1
						ELSE 0
						END)
END
GO

CREATE TRIGGER validacion_antiguedad_y_empleados_a_cargo_para_jefe ON Empleado FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @codigo_jefe AS numeric(6), @dias_antiguedad AS int, @cantidad_de_empleados_a_cargo AS int
	DECLARE cursor_jefes CURSOR FOR (SELECT i.empl_jefe,
	                                DATEDIFF(day, e.empl_ingreso, GETDATE()),
									dbo.cantidad_de_empleados_a_cargo(e.empl_codigo)
									FROM inserted i
	                                JOIN Empleado e ON i.empl_jefe = e.empl_codigo)
	
	FETCH cursor_jefes INTO @codigo_jefe, @dias_antiguedad, @cantidad_de_empleados_a_cargo

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF((@dias_antiguedad/365 < 5
		  OR @cantidad_de_empleados_a_cargo > 0.5 * (SELECT COUNT(*) FROM Empleado WHERE empl_codigo != @codigo_jefe))
		  AND dbo.es_gerente_general(@codigo_jefe) = 0)
		BEGIN
			PRINT 'No se pudo completar la operación, ya que el empleado ' + STR(@codigo_jefe, 6, 0) + ' no cumple con los requisitos necesarios para ser jefe.'
			ROLLBACK
		END

		FETCH cursor_jefes INTO @codigo_jefe, @dias_antiguedad, @cantidad_de_empleados_a_cargo
	END

	CLOSE cursor_jefes
	DEALLOCATE cursor_jefes
END
GO

DROP FUNCTION dbo.cantidad_de_empleados_a_cargo
GO

DROP FUNCTION dbo.es_gerente_general
GO

DROP TRIGGER validacion_antiguedad_y_empleados_a_cargo_para_jefe
GO

/*Ejercicio 20: crear el/los objeto/s necesarios para mantener actualizadas las comisiones del
vendedor.
El cálculo de la comisión está dado por el 5% de la venta total efectuada por ese
vendedor en ese mes, más un 3% adicional en caso de que ese vendedor haya
vendido por lo menos 50 productos distintos en el mes.*/

CREATE TRIGGER actualizacion_comision_vendedores ON Factura FOR INSERT
AS
BEGIN
	DECLARE @vendedor_codigo AS numeric(6), @ventas_del_mes AS decimal(12,2), @cantidad_de_productos_vendidos_en_el_mes AS int
	DECLARE cursor_vendedores CURSOR FOR (SELECT i.fact_vendedor,
	                                     SUM(f.fact_total),
										 (SELECT COUNT(DISTINCT item_producto) FROM Item_Factura
										 JOIN Factura f ON item_numero = f.fact_numero AND item_sucursal = f.fact_sucursal AND item_tipo = f.fact_tipo
										 WHERE f.fact_vendedor = i.fact_vendedor
										 AND MONTH(i.fact_fecha) = MONTH(f.fact_fecha)
										 AND YEAR(i.fact_fecha) = YEAR(f.fact_fecha))
	                                     FROM inserted i
										 JOIN Factura f ON i.fact_vendedor = f.fact_vendedor
										 WHERE MONTH(i.fact_fecha) = MONTH(f.fact_fecha) AND YEAR(i.fact_fecha) = YEAR(i.fact_fecha)
										 GROUP BY i.fact_vendedor)

	OPEN cursor_vendedores
	FETCH cursor_vendedores INTO @vendedor_codigo, @ventas_del_mes, @cantidad_de_productos_vendidos_en_el_mes

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @comision AS decimal(12,2)
		SET @comision = 0.05 * @ventas_del_mes

		IF(@cantidad_de_productos_vendidos_en_el_mes >= 50)
		BEGIN
			SET @comision = @comision + 0.03 * @ventas_del_mes
		END

		UPDATE Empleado SET empl_comision = @comision WHERE empl_codigo = @vendedor_codigo

		FETCH cursor_vendedores INTO @vendedor_codigo, @ventas_del_mes, @cantidad_de_productos_vendidos_en_el_mes
	END

	CLOSE cursor_vendedores
	DEALLOCATE cursor_vendedores
END
GO

DROP TRIGGER acualizacion_comision_vendedores
GO

/*Ejercicio 21: desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que en una factura no puede contener productos de
diferentes familias. En caso de que esto ocurra no debe grabarse esa factura y
debe emitirse un error en pantalla.*/

CREATE TRIGGER validacion_facturas_con_productos_de_distintas_familias ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @factura AS char(13), @cantidad_de_familias AS int
	DECLARE cursor_items CURSOR FOR (SELECT i.item_numero+i.item_sucursal+i.item_tipo, COUNT(DISTINCT p.prod_familia)
	                                FROM inserted i
									JOIN Producto p ON i.item_producto = p.prod_codigo
									GROUP BY i.item_numero+i.item_sucursal+i.item_tipo)

	OPEN cursor_items
	FETCH cursor_items INTO @factura, @cantidad_de_familias

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad_de_familias > 1)
		BEGIN
			
			PRINT 'La operación no pudo completarse debido a que la factura número '
			+ SUBSTRING(@factura, 0, 7) + ' de tipo ' + SUBSTRING(@factura, 12, 1)
			+ ' de la sucursal ' + SUBSTRING(@factura, 8, 4)
			+ ' posee productos que no pertenecen a una misma familia.'
			ROLLBACK
			DELETE FROM Factura WHERE fact_numero+fact_sucursal+fact_tipo = @factura
		END

		FETCH cursor_items INTO @factura, @cantidad_de_familias
	END

	CLOSE cursor_items
	DEALLOCATE cursor_items
END
GO

DROP TRIGGER validacion_facturas_con_productos_de_distintas_familias
GO

/*Ejercicio 22: se requiere recategorizar los rubros de productos, de forma tal que nigun rubro
tenga más de 20 productos asignados, si un rubro tiene más de 20 productos
asignados se deberan distribuir en otros rubros que no tengan mas de 20
productos y si no entran se debra crear un nuevo rubro en la misma familia con
la descirpción “RUBRO REASIGNADO”, cree el/los objetos de base de datos
necesarios para que dicha regla de negocio quede implementada.*/

CREATE PROCEDURE recategorizar_rubros
AS
BEGIN
	PRINT 'TODO'
END
GO

DROP PROCEDURE recategorizar_rubros
GO

/*Ejercicio 23: desarrolle el/los elementos de base de datos necesarios para que ante una venta
automaticamante se controle que en una misma factura no puedan venderse más
de dos productos con composición. Si esto ocurre debera rechazarse la factura.*/

CREATE TRIGGER validacion_productos_con_composicion_en_factura ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @numero_item AS char(8), @sucursal_item AS char(4), @tipo_item AS char(1), @cantidad_productos_con_composicion AS int

	DECLARE cursor_items CURSOR FOR (SELECT item_numero, item_sucursal, item_tipo, COUNT(item_producto)
	                          FROM inserted
							  JOIN Producto ON item_producto = prod_codigo
							  WHERE item_producto IN (SELECT comp_producto FROM Composicion)
							  GROUP BY item_numero, item_sucursal, item_tipo)
	
	OPEN cursor_items

	FETCH cursor_items INTO @numero_item, @sucursal_item, @tipo_item, @cantidad_productos_con_composicion

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad_productos_con_composicion > 2)
		BEGIN
			PRINT 'La operación no pudo completarse debido a que la factura número '
			+ @item_numero + ' de tipo ' + @item_tipo
			+ ' de la sucursal ' + @item_sucursal
			+ ' posee más de un producto con composición.'

			ROLLBACK

			DELETE FROM Item_Factura WHERE item_numero = @numero_item AND item_sucursal = @sucursal_item AND item_tipo = @tipo_item

			DELETE FROM Factura WHERE fact_numero = @numero_item AND fact_sucursal = @sucursal_item AND fact_tipo = @tipo_item
			
		END
	END

	CLOSE curosr_items
	DEALLOCATE curosr_items
END
GO

DROP TRIGGER validacion_productos_con_composicion_en_factura
GO

/*Ejercicio 24: se requiere recategorizar los encargados asignados a los depositos. Para ello
cree el o los objetos de bases de datos necesarios que lo resueva, teniendo en
cuenta que un deposito no puede tener como encargado un empleado que
pertenezca a un departamento que no sea de la misma zona que el deposito, si
esto ocurre a dicho deposito debera asignársele el empleado con menos
depositos asignados que pertenezca a un departamento de esa zona.*/

CREATE PROCEDURE recategorizar_encargados_de_depositos
AS
BEGIN
	DECLARE @codigo_deposito AS char(2), @zona_deposito AS char(3), @zona_encargado AS char(3)
	
	DECLARE cursor_encargados_depositos CURSOR FOR (SELECT depo_codigo, depo_zona, zona_codigo AS encargado_zona FROM DEPOSITO
	                                               JOIN Empleado ON depo_encargado = empl_codigo
												   JOIN Departamento ON empl_departamento = depa_codigo
												   JOIN Zona ON depa_zona = zona_codigo)
	
	FETCH cursor_encargados_depositos INTO @codigo_deposito, @zona_deposito, @zona_encargado

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@zona_deposito != @zona_encargado)
		BEGIN
			DECLARE @nuevo_encargado AS numeric(6)

			SET @nuevo_encargado = (SELECT TOP 1 empl_codigo
			                       FROM Empleado
								   JOIN DEPOSITO ON empl_codigo = depo_encargado
								   JOIN Departamento ON empl_departamento = depa_codigo
								   WHERE depo_zona = depa_zona
								   ORDER BY COUNT(depo_codigo) DESC)

			UPDATE DEPOSITO SET depo_encargado = @nuevo_encargado WHERE depo_codigo = @codigo_deposito
		END

		FETCH cursor_encargados_depositos INTO @codigo_deposito, @zona_deposito, @zona_encargado
	END

	CLOSE cursor_encargados_depositos
	DEALLOCATE cursor_encargados_depositos
END
GO

DROP PROCEDURE recategorizar_encargados_de_depositos
GO

/*Ejercicio 25: desarrolle el/los elementos de base de datos necesarios para que no se permita
que la composición de los productos sea recursiva, o sea, que si el producto A
compone al producto B, dicho producto B no pueda ser compuesto por el
producto A, hoy la regla se cumple.*/

CREATE FUNCTION dbo.es_producto_compuesto_recursivamente_por_si_mismo(@codigo_de_producto_composicion AS char(8), @codigo_de_componente AS char(8))
RETURNS BIT
AS
BEGIN
	DECLARE @valor_verificacion AS bit

	IF(@codigo_de_producto_composicion = @codigo_de_componente) SET @valor_verificacion = 1
	ELSE
	BEGIN
		IF((SELECT COUNT(comp_componente) FROM Composicion WHERE comp_producto = @codigo_de_componente) = 0) SET @valor_verificacion = 0 --Si el componente no es compuesto
		ELSE --EL componente es compuesto
		BEGIN
			IF(EXISTS(SELECT comp_componente FROM Composicion WHERE comp_producto = @codigo_de_componente AND dbo.es_producto_compuesto_recursivamente_por_si_mismo(comp_producto, comp_componente) = 1)) SET @valor_verificacion = 1
			ELSE SET @valor_verificacion = 0
		END 
	END

	RETURN @valor_verificacion
END
GO

CREATE TRIGGER verificacion_producto_con_composicion_valido_v1 ON Composicion FOR INSERT
AS
BEGIN
	DECLARE @producto_composicion AS char(8), @producto_componente AS char(8)

	DECLARE cursor_productos_composicion_insertados CURSOR FOR(SELECT comp_producto, comp_cantidad FROM inserted)

	OPEN cursor_productos_composicion_insertados

	FETCH cursor_productos_composicion_insertados INTO @producto_composicion, @producto_componente

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(dbo.es_producto_compuesto_recursivamente_por_si_mismo(@producto_composicion, @producto_componente) = 1)
		BEGIN
			PRINT 'La operación no pudo realizarse debido a que el producto con composición '
			+ @producto_composicion + ' se compone recursivamente a través del componente ' + @producto_componente + '.'
			
			ROLLBACK

			DELETE FROM Composicion WHERE comp_producto = @producto_composicion --Se deja consistente el modelo
			DELETE FROM Producto WHERE prod_codigo = @producto_composicion
		END

		FETCH cursor_productos_composicion_insertados INTO @producto_composicion, @producto_componente
	END
	
	CLOSE cursor_productos_composicion_insertados
	DEALLOCATE cursor_productos_composicion_insertados
END
GO

DROP TRIGGER verificacion_producto_con_composicion_valido
GO

DROP FUNCTION es_producto_compuesto_recursivamente_por_si_mismo
GO

/*Ejercicio 26: esarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de otros productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/

CREATE TRIGGER validacion_factura_sin_productos_componentes ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @numero_item AS char(8), @sucursal_item AS char(4), @tipo_item AS char(1), @producto_item AS char(8)

	DECLARE cursor_items_insertados CURSOR FOR (SELECT item_numero, item_sucursal, item_tipo, item_producto
	                                           FROM inserted)
	
	OPEN validacion_factura_sin_productos_componentes

	FETCH validacion_factura_sin_productos_componentes INTO @numero_item, @sucursal_item, @tipo_item, @producto_item

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(EXISTS(SELECT comp_producto FROM Composicion WHERE comp_componente = @producto_item))
		BEGIN
			PRINT 'La operación no pudo completarse debido a que el producto ' + @producto_item + ' es componente de algún producto compuesto.'

			ROLLBACK

			DELETE FROM Item_Factura WHERE item_numero = @numero_item AND item_sucursal = @sucursal_item AND item_tipo = @tipo_item

			DELETE FROM Factura WHERE fact_numero = @numero_item AND fact_sucursal = @sucursal_item AND fact_tipo = @tipo_item
		END

		FETCH validacion_factura_sin_productos_componentes INTO @numero_item, @sucursal_item, @tipo_item, @producto_item
	END

	CLOSE validacion_factura_sin_productos_componentes

	DEALLOCATE validacion_factura_sin_productos_componentes

END
GO

DROP TRIGGER validacion_factura_sin_productos_componentes
GO

/*Ejercicio 27: se requiere reasignar los encargados de stock de los diferentes depósitos. Para
ello se solicita que realice el o los objetos de base de datos necesarios para
asignar a cada uno de los depósitos el encargado que le corresponda,
entendiendo que el encargado que le corresponde es cualquier empleado que no
es jefe y que no es vendedor, o sea, que no está asignado a ningun cliente, se
deberán ir asignando tratando de que un empleado solo tenga un deposito
asignado, en caso de no poder se irán aumentando la cantidad de depósitos
progresivamente para cada empleado.*/

/*Con esta resolución se considera que más allá de que el encargado actual cumpla con la condición, se le reasignará el encargado a cada depósito. Esto 
es, en primer lugar se seteará en NULL en el campo depo_encargado para cada depósito y luego se hará la reasignación pedida.*/

CREATE PROCEDURE reasignar_encargado_de_stock_para_depositos
AS
BEGIN
	DECLARE @codigo_deposito AS char(2)

	DECLARE cursor_depositos CURSOR FOR (SELECT depo_codigo FROM DEPOSITO)

	UPDATE DEPOSITO SET depo_encargado = NULL

	OPEN cursor_depositos

	FETCH cursor_depositos INTO @codigo_deposito

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @codigo_nuevo_encargado AS numeric(6)

		--Esta parte puede abstraerse con dos funciones: dbo.es_jefe y dbo.esta_asignado_a_algun_cliente
		SET @codigo_nuevo_encargado = (SELECT TOP 1 encargado.empl_codigo
		                              FROM Empleado encargado
									  LEFT JOIN Empleado subordinado ON encargado.empl_codigo = subordinado.empl_jefe
									  WHERE NOT EXISTS (SELECT clie_vendedor FROM Cliente WHERE clie_vendedor = encargado.empl_codigo)
									  GROUP BY encargado.empl_codigo
									  HAVING COUNT(subordinado.empl_jefe) = 0
									  ORDER BY (SELECT COUNT(depo_codigo) FROM DEPOSITO
									           RIGHT JOIN Empleado on depo_encargado = encargado.empl_codigo) ASC)
		
		UPDATE DEPOSITO SET depo_encargado = @codigo_nuevo_encargado

		FETCH cursor_depositos INTO @codigo_deposito
	END

	CLOSE cursor_depositos

	DEALLOCATE cursor_depositos
END
GO

DROP PROCEDURE reasignar_encargado_de_stock_para_depositos
GO

/*Ejercicio 28: se requiere reasignar los vendedores a los clientes. Para ello se solicita que
realice el o los objetos de base de datos necesarios para asignar a cada uno de los
clientes el vendedor que le corresponda, entendiendo que el vendedor que le
corresponde es aquel que le vendió más facturas a ese cliente, si en particular un
cliente no tiene facturas compradas se le deberá asignar el vendedor con más
venta de la empresa, o sea, el que en monto haya vendido más.*/

CREATE PROCEDURE reasignar_vendedores_a_clientes
AS
BEGIN
	
	DECLARE @codigo_cliente AS char(6), @codigo_vendedor AS numeric(6)

	DECLARE cursor_clientes_vendedores CURSOR FOR (SELECT clie_codigo, clie_vendedor FROM Cliente)

	OPEN cursor_clientes_vendedores

	FETCH cursor_clientes_vendedores INTO @codigo_cliente, @codigo_vendedor

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		DECLARE @codigo_nuevo_vendedor AS numeric(6)

		SET @codigo_nuevo_vendedor = (SELECT CASE WHEN COUNT(fact_cliente) = 0
		                             THEN (SELECT TOP 1 fact_vendedor
									      FROM Factura
									      GROUP BY fact_vendedor
										  ORDER BY SUM (fact_total) DESC)
		                             ELSE (SELECT fact_vendedor
									      FROM Factura
										  WHERE fact_cliente = @codigo_cliente
										  GROUP BY fact_vendedor
										  ORDER BY COUNT(*) DESC) END
		                             FROM Cliente
									 LEFT JOIN Factura ON clie_codigo = fact_cliente
									 GROUP BY clie_codigo)

		IF(@codigo_vendedor != @codigo_nuevo_vendedor)
		BEGIN
			UPDATE Cliente SET clie_vendedor = @codigo_nuevo_vendedor WHERE clie_codigo = @codigo_cliente
		END

		FETCH cursor_clientes_vendedores INTO @codigo_cliente, @codigo_vendedor
	END

	CLOSE cursor_clientes_vendedores

	DEALLOCATE cursor_clientes_vendedores
END
GO

DROP PROCEDURE reasignar_vendedores_a_clientes
GO

/*Ejercicio 29: desarrolle el/los elementos de base de datos necesarios para que se cumpla
automaticamente la regla de que una factura no puede contener productos que
sean componentes de diferentes productos. En caso de que esto ocurra no debe
grabarse esa factura y debe emitirse un error en pantalla.*/

CREATE TRIGGER validacion_factura_sin_productos_componentes_de_diferentes_productos ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @numero_item AS char(8), @sucursal_item AS char(4), @tipo_item AS char(1), @componente AS char(8), @cantidad_de_productos_composicion_distintos AS int

	DECLARE cursor_items_composicion CURSOR FOR (SELECT item_numero, item_sucursal, item_tipo, comp_componente, COUNT(DISTINCT comp_producto)
                                                 FROM Item_Factura
                                                 JOIN Composicion ON item_producto = comp_componente
												 WHERE item_numero+item_sucursal+item_tipo IN (SELECT item_numero+item_sucursal+item_tipo FROM inserted)
                                                 GROUP BY item_numero, item_sucursal, item_tipo, comp_componente)

	OPEN cursor_items_composicion

	FETCH cursor_items_composicion INTO @numero_item, @sucursal_item, @tipo_item, @componente, @cantidad_de_productos_composicion_distintos

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad_de_productos_composicion_distintos > 1)
		BEGIN
			PRINT 'No puede completarse la operación debido a que la factura número '
			+ RTRIM(STR(@numero_item, 10,0)) + ' de la sucursal '
			+ RTRIM(STR(@sucursal_item, 10, 0)) + ' de tipo '
			+ RTRIM(STR(@tipo_item, 10, 0)) + ' posee items que son componentes de distintos productos compuestos.'

			ROLLBACK

			DELETE FROM Item_Factura WHERE item_numero = @numero_item AND item_sucursal = @sucursal_item AND item_tipo = @tipo_item

			DELETE FROM Factura WHERE fact_numero = @numero_item AND fact_sucursal = @sucursal_item AND fact_tipo = @tipo_item

		END

		FETCH cursor_items_composicion INTO @numero_item, @sucursal_item, @tipo_item, @componente, @cantidad_de_productos_composicion_distintos
	END

	CLOSE cursor_items_composicion

	DEALLOCATE cursor_items_composicion
END
GO

DROP TRIGGER validacion_factura_sin_productos_componentes_de_diferentes_productos
GO

/*Ejercicio 30: agregar el/los objetos necesarios para crear una regla por la cual un cliente no
pueda comprar más de 100 unidades en el mes de ningún producto, si esto
ocurre no se deberá ingresar la operación y se deberá emitir un mensaje “Se ha
superado el límite máximo de compra de un producto”. Se sabe que esta regla se
cumple y que las facturas no pueden ser modificadas.*/

CREATE TRIGGER validacion_cantidad_de_undiades_compradas_en_el_mes ON Item_Factura FOR INSERT
AS
BEGIN
	DECLARE @numero_item AS char(8), @sucursal_item AS char(4), @tipo_item AS char(1), @cantidad_item AS decimal(12,2), @cantidad_del_mismo_producto_comprada_en_el_mes AS int

	DECLARE cursor_items_insertados CURSOR FOR (SELECT ins.item_numero, ins.item_sucursal, ins.item_tipo, ins.item_cantidad, SUM(it.item_cantidad)
	                                           FROM Item_Factura ins
											   JOIN Factura f ON ins.item_numero = f.fact_numero AND ins.item_sucursal = f.fact_sucursal AND ins.item_tipo = f.fact_tipo
											   JOIN Factura f1 ON f.fact_cliente = f1.fact_cliente
											   JOIN Item_Factura it ON f1.fact_numero = it.item_numero AND f1.fact_sucursal = it.item_sucursal AND f1.fact_tipo = it.item_tipo
											   WHERE YEAR(f.fact_fecha) = YEAR(f1.fact_fecha) AND MONTH(f.fact_fecha) = MONTH(f1.fact_fecha) AND ins.item_producto = it.item_producto
											   GROUP BY ins.item_numero, ins.item_sucursal, ins.item_tipo, ins.item_cantidad)

	OPEN cursor_items_insertados

	FETCH cursor_items_insertados INTO @numero_item, @sucursal_item, @tipo_item, @cantidad_item, @cantidad_del_mismo_producto_comprada_en_el_mes

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@cantidad_del_mismo_producto_comprada_en_el_mes + @cantidad_item >= 100)
		BEGIN
			PRINT 'Se ha superado el límite máximo de compra de un producto.'

			ROLLBACK

			DELETE FROM Item_Factura WHERE item_numero = @numero_item AND item_sucursal = @sucursal_item AND item_tipo = @tipo_item

			DELETE FROM Factura WHERE fact_numero = @numero_item AND fact_sucursal = @sucursal_item AND fact_tipo = @tipo_item
		END

		FETCH cursor_items_insertados INTO @numero_item, @sucursal_item, @tipo_item, @cantidad_del_mismo_producto_comprada_en_el_mes
	END

	CLOSE cursor_items_insertados

	DEALLOCATE cursor_items_insertados
END
GO

DROP TRIGGER validacion_cantidad_de_undiades_compradas_en_el_mes
GO

/*Ejercicio 31: desarrolle el o los objetos de base de datos necesarios, para que un jefe no pueda
tener más de 20 empleados a cargo, directa o indirectamente, si esto ocurre
debera asignarsele un jefe que cumpla esa condición, si no existe un jefe para
asignarle se le deberá colocar como jefe al gerente general que es aquel que no
tiene jefe.*/

CREATE FUNCTION dbo.cantidad_de_subordinados(@jefe_codigo numeric(6))
RETURNS int
AS
BEGIN
	RETURN (SELECT CASE WHEN COUNT(*) = 0 THEN 0
	                    ELSE COUNT(*) + SUM(dbo.cantidad_de_subordinados(empl_codigo)) END
		   FROM Empleado
		   WHERE empl_jefe = @jefe_codigo)
END
GO

CREATE TRIGGER validacion_jefe_correcto ON Empleado FOR INSERT, UPDATE
AS
BEGIN
	DECLARE @codigo_empleado AS numeric(6), @codigo_jefe AS numeric(6), @cantidad_de_subordinados_del_jefe AS int

	DECLARE cursor_empeados CURSOR FOR (SELECT i.empl_codigo, i.empl_jefe, dbo.cantidad_de_subordinados(jefe.empl_codigo)
	                                    FROM inserted i
										JOIN Empleado jefe ON i.empl_jefe = jefe.empl_codigo)

	OPEN cursor_empeados

	FETCH cursor_empeados INTO @codigo_empleado, @codigo_jefe, @cantidad_de_subordinados_del_jefe

	WHILE(@@FETCH_STATUS = 0)
	BEGIN
		IF(@codigo_jefe IS NOT NULL AND @cantidad_de_subordinados_del_jefe <= 20)
		BEGIN
			DECLARE @codigo_nuevo_jefe AS numeric(6)

			IF(EXISTS (SELECT empl_codigo FROM Empleado WHERE dbo.cantidad_de_subordinados(empl_codigo) < 20))
			BEGIN
				SET @codigo_nuevo_jefe = (SELECT TOP 1 empl_codigo
				                          FROM Empleado
										  WHERE dbo.cantidad_de_subordinados(empl_codigo) < 20
				                          ORDER BY dbo.cantidad_de_subordinados(empl_codigo) ASC)
			END

			ELSE
			BEGIN
				SET @codigo_nuevo_jefe = (SELECT empl_codigo FROM Empleado WHERE empl_jefe IS NULL) --El código del gerente general
			END
			
			UPDATE Empleado SET empl_jefe = @codigo_nuevo_jefe WHERE empl_codigo = @codigo_empleado
		END
	END

	CLOSE cursor_empeados

	DEALLOCATE cursor_empeados

END
GO

DROP FUNCTION dbo.cantidad_de_subordinados
GO

DROP TRIGGER validacion_jefe_correcto
GO

--Cantidad de subordinados directos
SELECT i.empl_codigo AS 'EMPLEADO',
       i.empl_jefe AS 'JEFE',
	   COUNT(subordinado.empl_codigo) AS 'CANTIDAD DE SUBORDINADOS'
FROM Empleado i
JOIN Empleado jefe ON i.empl_jefe = jefe.empl_codigo
JOIN Empleado subordinado ON jefe.empl_codigo = subordinado.empl_jefe
GROUP BY i.empl_codigo, i.empl_jefe
