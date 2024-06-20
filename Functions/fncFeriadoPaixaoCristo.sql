CREATE FUNCTION fncFeriadoPaixaoCristo (@ANO int)
 RETURNS datetime
 AS
 BEGIN
	DECLARE @DATA AS DATETIME
	SET @DATA = dbo.fncPascoa(@ANO)
	SET @DATA = DATEADD(DAY, -2, @DATA)
	RETURN(@DATA)
 END;
 GO

