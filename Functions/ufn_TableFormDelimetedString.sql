USE [master]
GO

/****** Object:  UserDefinedFunction [dbo].[fnTableFormDelimetedString]    Script Date: 11/10/2010 10:10:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/*
++++++++
EXEMPLO:
++++++++
SELECT * 
FROM [db_Importacao].[dbo].[fnTableFormDelimetedString] ('a,b,c,d,e,f,d', ',')
GO
*/

CREATE FUNCTION [dbo].[fnTableFormDelimetedString]
(
	@param      NVARCHAR(MAX),
	@delimeter  NCHAR(1)
) RETURNS @tmp TABLE (ID INT IDENTITY (1, 1), Data Varchar(MAX))
BEGIN
	 
	;WITH
	L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
	L1   AS(SELECT 1 AS c FROM L0 AS A, L0 AS B),
	L2   AS(SELECT 1 AS c FROM L1 AS A, L1 AS B),
	L3   AS(SELECT 1 AS c FROM L2 AS A, L2 AS B),
	L4   AS(SELECT 1 AS c FROM L3 AS A, L3 AS B),
	Numbers AS(SELECT ROW_NUMBER() OVER(ORDER BY c) AS Number FROM L4
	)
	INSERT INTO @tmp (Data)
	SELECT LTRIM(RTRIM(CONVERT(NVARCHAR(4000),
	SUBSTRING(@param, Number,
	CHARINDEX(@delimeter, @param + @delimeter, Number) - Number
	)
	))) AS Value
	FROM   Numbers
	WHERE  Number <= CONVERT(INT, LEN(@param))
		AND  SUBSTRING(@delimeter + @param, Number, 1) = @delimeter
	
	RETURN
END
GO


