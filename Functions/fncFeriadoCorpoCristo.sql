CREATE FUNCTION fncFeriadoCorpoCristo (@ANO int)
 RETURNS datetime
 AS
 BEGIN
	DECLARE @DATA AS DATETIME
	SET @DATA = dbo.fncPascoa(@ANO)
	SET @DATA = DATEADD(DAY, 60, @DATA)
	RETURN(@DATA)
 END;
 GO
