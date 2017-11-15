USE [SGBODS]
GO

/****** Object:  StoredProcedure [dbo].[sp_ReturnDepencencies]    Script Date: 10/07/2015 15:29:53 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


/* ************************************************************************************ */
/* Procedure sp_ReturnDepencencies														*/
/* Retorna a dependência entre as tabelas do banco de dados e sua ordenação de cargas	*/
/*																						*/
/* Autor: Anselmo Guedes																*/
/* Data: 23/06/2015																		*/
/* ************************************************************************************ */

/* ************************************************************************************ */
/* Use of sp_MSdependencies procedure:													*/
/* Value 1315327 shows objects that are dependent on the specified object				*/
/* Value 1053183 shows objects that the specified object is dependent on				*/
/*																						*/
/* EXEC sp_MSdependencies N'SCH_ODS.TB_AreaVenda', null, 1315327						*/
/* EXEC sp_MSdependencies N'SCH_ODS.TB_AreaVenda', null, 1053183						*/
/* ************************************************************************************ */

CREATE PROCEDURE [dbo].[sp_ReturnDepencencies]
AS

SET NOCOUNT ON

------------------------------------------------------------------------------------------
-- CRIA OS OBJETOS
------------------------------------------------------------------------------------------

-- Objetos quais este depende:

CREATE TABLE #MSdependencies (	
	oType		varchar(1000)	NULL,
	oObjName	varchar(1000)	NULL,
	oOwner		varchar(1000)	NULL,
	oSequence	varchar(1000)	NULL )

CREATE TABLE #DependeDe (	
	TableName		varchar(1000)	NULL,
	TableNameDep	varchar(1000)	NULL )

CREATE TABLE #Ordenacao (
	TableName		varchar(1000),
	OrderNo			varchar(5) )

declare
	@obj_name	varchar(1000),
	@sch_name	varchar(1000)

------------------------------------------------------------------------------------------
-- CURSOR PARA OBTER AS DEPENDENCIAS
------------------------------------------------------------------------------------------

declare objects_cur cursor for

	select SCHEMA_NAME(schema_id) + '.' + name, SCHEMA_NAME(schema_id)
	from sys.objects obj
	where type = 'u' and name != 'sysdiagrams'
	
open objects_cur
fetch next from objects_cur into @obj_name, @sch_name

while @@FETCH_STATUS = 0
begin

	truncate table #MSdependencies
		
	INSERT INTO #MSdependencies
	EXEC sp_MSdependencies @obj_name, null, 1053183

	insert into #DependeDe
	select replace(@obj_name,@sch_name + '.', '') ,a.oObjName from #MSdependencies a

	fetch next from objects_cur into @obj_name, @sch_name
	
end

close objects_cur
deallocate objects_cur

select * into #RetDependeDe from #DependeDe 

------------------------------------------------------------------------------------------
-- CARGA DOS OBJETOS DE ORDEM 1
------------------------------------------------------------------------------------------

INSERT INTO #Ordenacao

select name, '1'
from sys.objects obj
where type = 'u' 
  and name != 'sysdiagrams'
  and name not in ( select TableName from #DependeDe )
  

------------------------------------------------------------------------------------------
-- CARGA DOS OBJETOS COM AS DEMAIS ORDENAÇÕES
------------------------------------------------------------------------------------------

DECLARE @X INT
SET @X = 1

WHILE EXISTS ( SELECT * FROM #DependeDe )
BEGIN

	SET @X = @X + 1
	
	INSERT INTO #Ordenacao
	
	SELECT TableName, @X
	FROM #DependeDe A
	WHERE EXISTS ( SELECT * 
					 FROM #Ordenacao B
					WHERE A.TableNameDep = B.TableName )
	  
	  AND NOT EXISTS ( SELECT *
						 FROM #Ordenacao C 
						WHERE A.TableName = C.TableName )
						
	GROUP BY TableName
	HAVING COUNT(*) = ( SELECT COUNT(*) FROM #DependeDe D WHERE D.TableName = A.TableName )

	DELETE FROM #DependeDe WHERE TableName IN ( SELECT TableName FROM #Ordenacao )

END 

------------------------------------------------------------------------------------------
-- RETORNA OS DADOS 
------------------------------------------------------------------------------------------
SELECT * FROM #RetDependeDe
SELECT * FROM #Ordenacao


GO


