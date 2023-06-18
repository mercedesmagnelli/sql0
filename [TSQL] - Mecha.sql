/*
1. Hacer una función que dado un artículo y un deposito devuelva un string que
indique el estado del depósito según el artículo. Si la cantidad almacenada es
menor al límite retornar “OCUPACION DEL DEPOSITO XX %” siendo XX el
% de ocupación. Si la cantidad almacenada es mayor o igual al límite retornar
“DEPOSITO COMPLETO”.
*/



CREATE FUNCTION obtener_estado_deposito(@cod_articulo VARCHAR(50), @cod_deposito VARCHAR(50))
RETURNS VARCHAR(100)
AS
BEGIN

	DECLARE @cantidad_almacenada int
	-- voy a tomar como limite al punto de reposicion
	DECLARE @limite int
	DECLARE @mensaje varchar(100)

	

	-- obtengo la cantidad almacenada y el limite 
	SELECT @limite = s.stoc_punto_reposicion, @cantidad_almacenada = s.stoc_cantidad from STOCK s
	where s.stoc_producto = @cod_articulo and @cod_deposito = s.stoc_deposito


	DECLARE @ocupacion DECIMAL(5, 2);
    SET @ocupacion = (@cantidad_almacenada / CAST(@limite AS DECIMAL)) * 100;

	IF (@cantidad_almacenada <= @limite)
		SET @mensaje = 'OCUPACION DEL DEPOSITO AL ' + CAST(@ocupacion AS VARCHAR(10)) + '%'
	ELSE 
		SET @mensaje = 'DEPOSITO COMPLETO'

RETURN @mensaje
END
GO

SELECT dbo.obtener_estado_deposito ('00001707','03');

select * from stock
where stoc_cantidad < stoc_punto_reposicion

SELECT * FROM sys.objects WHERE type = 'FN';



/*Realizar una función que dado un artículo y una fecha, retorne el stock que
existía a esa fecha*/







