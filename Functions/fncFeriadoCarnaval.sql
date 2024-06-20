CREATE FUNCTION fncFeriadoCarnaval (@ANO int)
 RETURNS datetime
 AS
 BEGIN
  
	DECLARE @DATA AS DATETIME
	SET @DATA = dbo.fncPascoa(@ANO)
	SET @DATA = DATEADD(DAY, -47, @DATA)
	RETURN(@DATA)
 END;
 GO

