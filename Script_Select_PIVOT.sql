SET LANGUAGE 'BRAZILIAN'
GO

SELECT *
FROM (
	SELECT 
	FILIAL
	,DATEPART(M, DATAEMISSAO) MESES
	,DATENAME(M, DATAEMISSAO) MESES_EXT
	,DATEPART(YYYY, DATAEMISSAO) ANO
	,SUM(ICMS_AJUSTADO)ICMS_AJUSTADO
	FROM vivo_ba_2006_2009..TAB_CAT_FINAL_ATLYS 
	GROUP BY FILIAL, DATEPART(M, DATAEMISSAO), DATENAME(M, DATAEMISSAO), DATEPART(YYYY, DATAEMISSAO)
) AA
PIVOT ( SUM(AA.ICMS_AJUSTADO) FOR AA.ANO IN ([2006],[2007],[2008],[2009]))P
ORDER BY MESES
GO
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
DECLARE @ANO_CHAR varchar(4) = '2005'

EXEC(
'SELECT CNPJCPF,CODASSINANTE,SERIE,
		ISNULL([' + @ANO_CHAR + '01],0) AS "Jan/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '02],0) AS "Fev/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '03],0) AS "Mar/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '04],0) AS "Abr/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '05],0) AS "Mai/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '06],0) AS "Jun/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '07],0) AS "Jul/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '08],0) AS "Ago/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '09],0) AS "Set/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '10],0) AS "Out/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '11],0) AS "Nov/' + @ANO_CHAR + '",
		ISNULL([' + @ANO_CHAR + '12],0) AS "Dez/' + @ANO_CHAR + '"
	FROM (
			SELECT CNPJCPF, CODASSINANTE, SERIE, MESREF_C115 AS MESREF, CONVERT(MONEY,VALORTOTAL) VALOR
				FROM [CLARO_BA_ANALISE_FRAUDE].[dbo].TB_RESUMO_FINAL
					WHERE 1=1
					AND LEFT(MESREF_C115,4) = ' + @ANO_CHAR + '
					AND CNPJCPF		 = 2716328528
					AND CODASSINANTE = 452107038
					AND SERIE		 = ''B2''
		) AS ZZ
		
		PIVOT
		(
		SUM (VALOR)
		FOR MESREF IN
		( [' + @ANO_CHAR + '01], [' + @ANO_CHAR + '02], [' + @ANO_CHAR + '03], [' + @ANO_CHAR + '04],
		  [' + @ANO_CHAR + '05], [' + @ANO_CHAR + '06], [' + @ANO_CHAR + '07], [' + @ANO_CHAR + '08],
		  [' + @ANO_CHAR + '09], [' + @ANO_CHAR + '10], [' + @ANO_CHAR + '11], [' + @ANO_CHAR + '12] )
		) AS pvt
	
ORDER BY CNPJCPF,CODASSINANTE,SERIE'
)