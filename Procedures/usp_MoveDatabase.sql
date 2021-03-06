/*
Exemplo de execução:
---------------------

	EXECUTE MASTER.[dbo].[uspMoveDatabase]
		@NewArrayDataFolder	= 'E:\Data_file;G:\Data_file',	-- Array contendo um ou mais caminhos separados por ";" contendo os caminhos nos quais se quer mover os arquivos de dados.
		@NewArrayLogFolder	= 'D:\Log_file;F:\Log_file',	-- Array contendo um ou mais caminhos separados por ";" contendo os caminhos nos quais se quer mover os arquivos de log.
		@ArrayDB			= 'TESTE_CLARO',				-- Array contendo um ou mais caminhos separados por ";" contendo as bases de dados que queira mover para os caminhos informados acima.
		@MoveSecundaryData	= 1								-- Informar "0" - Para não mover os arquivos secundarios(.ndf) e "1" - Para mover os arquivos secundarios (.ndf).
	
*/

USE [master]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 
IF OBJECT_ID ('[dbo].[uspMoveDatabase]') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].[uspMoveDatabase]
END
GO

CREATE procedure [dbo].[uspMoveDatabase]
	@NewArrayDataFolder varchar(8000),
	@NewArrayLogFolder varchar(8000),
	@ArrayDB varchar(4000),
	@MoveSecundaryData bit=0
AS
BEGIN
	SET NOCOUNT ON;
	
	------------------------------------------------------------------------------------------------------------------------------
	-- DECLARAÇÃO DE VARIAVEIS ---------------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	DECLARE @DbBases		table (lkey int identity (1,1) primary key, dbname nvarchar(100))
	DECLARE @DbDrives		table (lkey int identity (1,1) primary key, drivename nvarchar(100), freespace bigint)
	DECLARE @FileTable		table (lkey int identity (1,1) primary key, [name]nvarchar(100), physical_name nvarchar(1000), [type] int )
	DECLARE @FreeFileSpace	table (lkey int identity (1,1) primary key, fileid int, filegroup int, totalextents int, usedextents int, dbname varchar(256), filename varchar(2000))
	DECLARE @Tb_Path		table (idTb int identity (1,1), id int, pathData varchar(3000), tipo char(1));
	
	DECLARE @sql nvarchar(4000)
	DECLARE @count int,	@RowNum int
	DECLARE @DbName nvarchar(100)
	DECLARE @OldPath nvarchar(1000)
	DECLARE @Type int
	DECLARE @LogicalName nvarchar(100)
	DECLARE @FileName nvarchar(100)
	DECLARE @NewPath nvarchar(1000)
	DECLARE @Id int	
	DECLARE @ExistFolder BIT
	DECLARE @Delimiter NVARCHAR(1)

	DECLARE @ERROR_MESSAGE	VARCHAR(2000)
	DECLARE @ERROR_SOURCE	VARCHAR(2000) 	
	DECLARE @SEVERITY		INT				

	DECLARE @FSO INT 
	DECLARE @RES INT 
	DECLARE @FID INT
	
	DECLARE @SizeFile bigint
	DECLARE @FreeSpaceDisk bigint

	DECLARE @CountData int, @CountLog int, @CountLoopData int, @CountLoopLog int;

	------------------------------------------------------------------------------------------------------------------------------
	-- INICIALIZAÇÃO DAS VARIAVEIS -----------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	SET @Delimiter = ';'
	
	INSERT INTO @Tb_Path (id, pathData, tipo)
				SELECT *
				FROM (
					SELECT ID, Data, 'D' TIPO
					FROM master.[dbo].[fnTableFormDelimetedString] (@NewArrayDataFolder, @Delimiter)
					UNION ALL
					SELECT ID, Data, 'L' TIPO
					FROM master.[dbo].[fnTableFormDelimetedString] (@NewArrayLogFolder, @Delimiter)
				)X;
	
	SET @CountData = (SELECT COUNT(1) FROM @Tb_Path WHERE tipo = 'D');
	SET @CountLog  = (SELECT COUNT(1) FROM @Tb_Path WHERE tipo = 'L');
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	
	------------------------------------------------------------------------------------------------------------------------------		
	-- CRIAÇÃO DO OBJETO DE MANIPULAÇÃO DE OBJETO TEXTO --------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	EXECUTE @RES = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT
	IF @RES <> 0 BEGIN
		EXEC sp_OAGetErrorInfo @RES, @ERROR_SOURCE OUT, @ERROR_MESSAGE OUT
		PRINT @RES
		PRINT @ERROR_MESSAGE
		PRINT @ERROR_SOURCE
		RETURN
	END
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

	------------------------------------------------------------------------------------------------------------------------------		
	-- VERIFICA SE OS CAMINHO INFORMADOS PARA MOVER OS ARQUIVOS, EXISTAM ---------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	SET @ExistFolder = 1
	SET @RowNum = 1
	WHILE @RowNum <= (SELECT COUNT(1) FROM @Tb_Path)
	BEGIN
		SELECT @NewPath = pathData FROM @Tb_Path WHERE idTb = @RowNum
		
		EXECUTE @RES = sp_OAMethod @FSO, 'folderexists', @ExistFolder OUT, @NewPath
		IF @RES <> 0 BEGIN
			EXEC sp_OAGetErrorInfo @RES, @ERROR_SOURCE OUT, @ERROR_MESSAGE OUT
			PRINT @RES
			PRINT @ERROR_MESSAGE
			PRINT @ERROR_SOURCE
			RETURN
		END

		IF @ExistFolder = 0 
		BEGIN
			RAISERROR	(
						N'Caminhos informados invalido. %s', -- Message text.
						16, -- Severity.
						1, -- State.
						@NewPath
						);
			RETURN;
		END
		
		SET @RowNum = @RowNum + 1
	END
	IF @ExistFolder = 0 RETURN
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
		
	------------------------------------------------------------------------------------------------------------------------------
	-- CRIA TABELA COM AS BASES À MOVER ------------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @DbBases (dbname)
						SELECT Data
						FROM master.[dbo].[fnTableFormDelimetedString] (@ArrayDB, @Delimiter);
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx 
		
	------------------------------------------------------------------------------------------------------------------------------ 
	-- EXCLUI BASES INFORMADAS QUE NÃO EXISTAM NO BANCO DE DADOS -----------------------------------------------------------------
	------------------------------------------------------------------------------------------------------------------------------ 
	DELETE FROM @DbBases WHERE NOT EXISTS( SELECT name FROM sys.databases WHERE [state] = 0 AND name = dbname )
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	
	------------------------------------------------------------------------------------------------------------------------------
	-- CRIA TABELAS COM AS UNIDADES EXISTENTES NA MAQUINA, E O SEUS ESPAÇOS LIVRES EM MB -----------------------------------------
	------------------------------------------------------------------------------------------------------------------------------
	INSERT INTO @DbDrives (drivename, freespace) EXEC master..xp_fixeddrives
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	 
	------------------------------------------------------------------------------------------------------------------------------
	-- HABILITA OS SERVIÇOS NECESSARIOS NO SQL PARA O FUNCIONAMENTO DA PROCEDURE, CASO ESTEJAM DESABILITADOS ---------------------
	------------------------------------------------------------------------------------------------------------------------------
	EXEC sp_configure 'show advanced option', '1'
	RECONFIGURE
	 
	EXEC sp_configure 'xp_cmdshell' , '1'
	RECONFIGURE
	--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
	 
	PRINT 'NewMdfFolder is ' + REPLACE ( @NewArrayDataFolder, @Delimiter, ' <||> ' )
	PRINT 'NewLdfFolder is ' + REPLACE ( @NewArrayLogFolder	, @Delimiter, ' <||> ' )
		 
	SET @RowNum			= 1
	SET @count			= (select count(*) from @DbBases)

	WHILE @RowNum <= @count
	BEGIN
		SELECT @DbName = dbname FROM @DbBases WHERE lKey = @RowNum ORDER BY dbname
		
		SET @CountLoopData	= 1
		SET @CountLoopLog	= 1
		
		EXEC('
		USE '+@DbName+'
		
		CREATE TABLE ##FreeFileSpace
			(lkey int identity (1,1) primary key, 
			fileid int, 
			filegroup int, 
			totalextents int, 
			usedextents int, 
			dbname varchar(256), 
			filename varchar(2000))
		
		insert into ##FreeFileSpace (fileid, filegroup, totalextents, usedextents, dbname, filename)
		exec (''dbcc showfilestats'')
		')
		
		BEGIN TRY
			insert into @FreeFileSpace (fileid, filegroup, totalextents, usedextents, dbname, filename)
			SELECT fileid, filegroup, totalextents, usedextents, dbname, filename FROM ##FreeFileSpace
			DROP TABLE ##FreeFileSpace
		END TRY
		BEGIN CATCH
		--SELECT ERROR_SEVERITY
			SET @ERROR_MESSAGE	= ERROR_MESSAGE()
			SET @SEVERITY		= ERROR_SEVERITY()
			RAISERROR (@ERROR_MESSAGE, @SEVERITY, 6);
			RETURN
		END CATCH			
				
		SET @sql = 'SELECT name, physical_name, type FROM  ' + @DbName + '.sys.database_files'
		--Caso não esteja marcada a opção de mover os arquivos secudarios, ele só retornara o arquivo principal e o LOG.
		IF @MoveSecundaryData = 0 SET @sql = @sql + ' WHERE (type = 0 and file_id =1) or type = 1'
		SET @sql = @sql + ' ORDER BY file_id'
		
		INSERT INTO @FileTable
					EXEc sp_executesql @sql
	 
		-- kill all user connections by setting to single user with immediate
		SET @sql=  'ALTER DATABASE [' + @DbName  + '] SET SINGLE_USER WITH ROLLBACK IMMEDIATE'
		PRINT ''
		PRINT 'Executing line  -' + @sql
		EXEC sp_executesql @sql

		-- set db off line
		SET @sql = 'ALTER DATABASE [' + @DbName + '] SET OFFLINE;'
		PRINT ''
		PRINT 'Executing line - ' + @sql
		EXEC sp_executesql @sql
		
		BEGIN TRY
			SELECT lkey FROM @FileTable
			WHIle @@rowcount > 0   
			BEGin
				select top 1 
					@Id				= lkey, 
					@OldPath		= physical_name, 
					@Type			= [type], 
					@LogicalName	= [name]
				from @FileTable
				
				SET @FileName	= (SELECT REVERSE(SUBSTRING(REVERSE(@OldPath), 0, CHARINDEX('\', REVERSE(@OldPath), 1))))
				IF @type = 0
				BEGIN
					SET @CountLoopData	= (CASE WHEN @CountLoopData > @CountData THEN 1 ELSE @CountLoopData END);
					SET @NewPath		= (SELECT pathData FROM @Tb_Path WHERE id = @CountLoopData AND tipo = 'D');
					SET @CountLoopData	= (@CountLoopData + 1);
				END
				ELSE
				BEGIN
					SET @CountLoopLog	= (CASE WHEN @CountLoopLog > @CountLog THEN 1 ELSE @CountLoopLog END);
					SET @NewPath		= (SELECT pathData FROM @Tb_Path WHERE id = @CountLoopLog AND tipo = 'L');
					SET @CountLoopLog	= (@CountLoopLog + 1);
				END

				SET @NewPath	= REPLACE( (@NewPath+'\@/'+@FileName), '\@/', '\' );

				SELECT @SizeFile = (totalextents*64)/1024 
				FROM @FreeFileSpace 
				WHERE dbname = @LogicalName

				SELECT @FreeSpaceDisk = freespace
				FROM @DbDrives
				WHERE drivename = LEFT(@NewPath,1)
				
				IF @SizeFile < @FreeSpaceDisk
				BEGIN
					set @Sql = 'EXEC master..xp_cmdshell ''MOVE "' + @OldPath + '" "' + @NewPath +'"'''    
					PRINT ''
					PRINT 'Executing line  -' + @sql
					exec sp_executesql @sql
			 
					--alter file paths
					SET @sql = 'ALTER DATABASE ' + @DbName + ' MODIFY FILE (NAME = ' + @LogicalName + ', FILENAME = "' + @NewPath   + '")'
					PRINT ''
					PRINT 'Executing line  -' + @sql
					EXEC sp_executesql @sql
					
					DELETE FROM @DbDrives
					INSERT INTO @DbDrives (drivename, freespace) EXEC master..xp_fixeddrives
				END
				
				DELETE FROM @FileTable WHERE [name] = @LogicalName
				
				SELECT * FROM @FileTable
			END --while
		END TRY
		BEGIN CATCH
			SET @ERROR_MESSAGE	= ERROR_MESSAGE()
			SET @SEVERITY		= ERROR_SEVERITY()
			RAISERROR (@ERROR_MESSAGE, @SEVERITY, 6);
		END CATCH
		
		SET @sql = 'ALTER DATABASE [' + @DbName + '] SET ONLINE;'
		PRINT ''
		PRINT 'Executing line  -' + @sql
		EXEC sp_executesql @sql
						 
		SET @sql=  'ALTER DATABASE [' + @DbName  + '] SET MULTI_USER'
		PRINT ''
		PRINT 'Executing line  -' + @sql
		EXEC sp_executesql @sql
		
		SET @RowNum = @RowNum + 1
	END

End --procedure
