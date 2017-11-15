USE db_ProjetoOCC_Fase2
GO

DECLARE @BASE VARCHAR(128)	 = DB_NAME()
DECLARE @TABELA VARCHAR(100) = 'dbo.tb_Faturamento'

SELECT a.index_id as [Index ID], name as [Index Name], avg_fragmentation_in_percent as Fragmentation
FROM sys.dm_db_index_physical_stats(DB_ID(@BASE),OBJECT_ID(@TABELA),NULL,NULL,NULL) AS a
INNER JOIN sys.indexes AS b
ON a.object_id = b.object_id AND a.index_id = b.index_id
ORDER BY Fragmentation