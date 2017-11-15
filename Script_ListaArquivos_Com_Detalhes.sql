use master 
go
DECLARE @g cursor;
DECLARE @path varchar(8000), @name varchar(8000);
DECLARE @CaminhoCompleto varchar(8000);

IF OBJECT_ID('tempdb..#ARQUIVOS') IS NOT NULL
	DROP TABLE #ARQUIVOS;
	
CREATE TABLE #ARQUIVOS(
	Path				varchar(100)
	,ShortPath			varchar(100)
	,Type				varchar(100)
	,DateCreated		datetime
	,DateLastAccessed	datetime
	,DateLastModified	datetime
	,Attributes			int
	,size				NUMERIC(30,0)
)

EXEC master.dbo.usp_ListaArquivos @dir = '\\192.168.10.112\d$\Log_Files', @pattern = '.' , @saida = @g OUTPUT
FETCH NEXT FROM @g INTO @path, @name
WHILE @@fetch_status = 0 BEGIN
	PRINT @path + ' -- ' + @name;
	
	SET @CaminhoCompleto = @path + '\' + @name
	
	INSERT INTO #ARQUIVOS
	select * from fn_getfiledetails(@CaminhoCompleto)
	
	FETCH NEXT FROM @g INTO @path, @name
END
CLOSE @g
DEALLOCATE @g

SELECT *
FROM #ARQUIVOS
GO