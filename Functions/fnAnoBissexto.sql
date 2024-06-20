CREATE FUNCTION fncAnoBissexto (@ANO int)
RETURNS BIT
AS
BEGIN

	DECLARE @return BIT
	DECLARE @regra1 AS INT
	DECLARE @regra2 AS INT
	DECLARE @regra3 AS INT

	SET @return = 0

	SET @regra1 = ( @ANO % 4 )
	SET @regra2 = ( @ANO % 100 )
	SET @regra3 = ( @ANO % 400 )

	SET @return = CASE
					WHEN @regra1 = 0 and @regra2 > 0 then 1
					WHEN @regra1 = 0 and @regra2 = 0 and @regra3 = 0 then 1
					ELSE 0
				END
	RETURN (@return)
END
GO


