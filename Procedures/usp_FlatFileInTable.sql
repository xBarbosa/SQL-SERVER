USE [master]
GO

IF OBJECT_ID('[dbo].[usp_FlatFileInTable]') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].[usp_FlatFileInTable]
END
GO

SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[usp_FlatFileInTable]
(
	@pathFile		NVARCHAR(4000),
	@delimeter		NCHAR(1),
	@qtdColumns		INT,
	@nameTableEndResult varchar(100) = ''
)
AS
BEGIN
	SET NOCOUNT ON

	--Declara as variaveis de erros
	DECLARE @sErrDesc VARCHAR(2000)
	DECLARE @sErrSource VARCHAR(2000) 
	DECLARE @ERROR_SEVERITY INT
	DECLARE @ERROR_STATE INT

	DECLARE @sTxt varchar(8000)
	DECLARE @sPathOrig VARCHAR(8000)
	DECLARE @sPathFMT varchar(2000)
	DECLARE @sPathFileErr varchar(800)
	DECLARE @sNameFile varchar(800)
	DECLARE @sNameErrFile varchar(800)
	DECLARE @ID_LINHA BIGINT
	DECLARE @LINHA VARCHAR(8000)
	DECLARE @LINHA_SELECT VARCHAR(8000)
	DECLARE @nQtdColumnsSelect INT
	DECLARE @sComand VARCHAR(MAX)
	DECLARE @tmp TABLE (ID INT IDENTITY (1, 1), Data Varchar(4000))
	DECLARE @FSO INT, @RES int, @FID int, @Exist BIT
	DECLARE @FSO2 INT, @RES2 int, @FID2 int, @Exist2 BIT, @cmdDel VARCHAR(200)
	DECLARE @FLG_ARQ_ERRO BIT
	DECLARE @LOOP INT
	----------------------------------------------------------------------------------------------------------------------------------------------
	SELECT 
		@sNameFile	  = REVERSE(LEFT(REVERSE(@pathFile),CHARINDEX('\',REVERSE(@pathFile))-1)),
		@sNameErrFile = '_err_'+@sNameFile,
		@sPathOrig    = REVERSE(SUBSTRING(REVERSE(@pathFile), CHARINDEX('\',REVERSE(@pathFile)), LEN(@pathFile))),
		--@sPathFileErr = REVERSE(REPLACE(REVERSE(@pathFile),LEFT(REVERSE(@pathFile),CHARINDEX('\',REVERSE(@pathFile))-1),REVERSE(@sNameFile+'.ErroLog'))),
		@sPathFileErr = '\\192.168.10.104\f\ARQUIVOS_RECEBIDOS\EMBRATEL\FORMATO\'+@sNameErrFile,
		@sPathFMT	  = '\\192.168.10.104\f\ARQUIVOS_RECEBIDOS\EMBRATEL\FORMATO\LINHA.fmt',
		@LOOP		  = 1,
		@FLG_ARQ_ERRO = 0
		
	IF @nameTableEndResult = '' SET @nameTableEndResult = 'TB_'+SUBSTRING(@sNameFile,1,(CHARINDEX('.',@sNameFile)-1))
		
	BEGIN TRY
		DROP TABLE ##TEMP_LINHAS_BOAS
	END TRY
	BEGIN CATCH
	END CATCH
	BEGIN TRY
		SET @sComand = 'CREATE TABLE ##TEMP_LINHAS_BOAS'
		--SET @sComand = @sComand + '(ID BIGINT IDENTITY(1,1) PRIMARY KEY NOT NULL'
		SET @sComand = @sComand + '(ID BIGINT PRIMARY KEY NOT NULL'
		WHILE @LOOP <= @QtdColumns BEGIN
			SET @sComand = @sComand + ',CAMPO_'+RIGHT('00'+CAST(@LOOP AS VARCHAR),2)+' VARCHAR(8000) NULL'
			SET @LOOP = @LOOP + 1
		END
		SET @sComand = @sComand + ')'
		EXEC(@sComand)
	END TRY
	BEGIN CATCH
		SET @sErrDesc		= ERROR_MESSAGE();
		SET @ERROR_SEVERITY = ERROR_SEVERITY();
		SET @ERROR_STATE	= ERROR_STATE();
		RAISERROR(@sErrDesc, @ERROR_SEVERITY, @ERROR_STATE);
		RETURN
	END CATCH
	----------------------------------------------------------------------------------------------------------------------------------------------

	--Cria o Objeto de manipulação de arquivo texto
	EXECUTE @RES = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT
	--Verifica se metodo falhou ao criar o objeto
	IF @RES <> 0 BEGIN
		EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT
		PRINT @RES
		PRINT @sErrDesc
		PRINT @sErrSource
		RETURN
	END

	--Verifica se existe o arquivo para deletar e cria-lo novamente
	EXECUTE @RES = sp_OAMethod @FSO, 'FileExists', @Exist OUT, @sPathFMT
	--Verifica se o metodo falhou ao verificar se a pasta existe 
	IF @RES <> 0 BEGIN
		EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT
		PRINT @RES
		PRINT @sErrDesc
		PRINT @sErrSource
		RETURN
	END

	IF @Exist = 0 BEGIN 
		-- Abertura do Arquivo
		EXECUTE @RES = sp_OAMethod @FSO, 'OpenTextFile', @FID OUT, @sPathFMT, 8, 1
		-- Verifica se o metodo de abertura falhou
		IF @RES <> 0 BEGIN
			EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT
			PRINT @RES
			PRINT @sErrDesc
			PRINT @sErrSource
			RETURN
		END
		
		set @sTxt = '9.0'+char(10)+char(13)
		EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, @sTxt
		set @sTxt = '1'+char(10)+char(13)
		EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, @sTxt
		set @sTxt = '1      SQLCHAR        0       25500     "\n"  1    Linha                SQL_Latin1_General_CP1_CI_AS'+char(10)+char(13)
		EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, @sTxt
			
		EXECUTE @RES = sp_OAMethod @FID, 'close', NULL
		EXECUTE @RES = sp_OADestroy @FID
	END
	EXECUTE @RES = sp_OADestroy @FSO	
	-----------------------------------
	--Cria o Objeto de manipulação de arquivo texto
	EXECUTE @RES2 = sp_OACreate 'Scripting.FileSystemObject', @FSO2 OUT
	EXECUTE @RES2 = sp_OAMethod @FSO2, 'FileExists', @Exist2 OUT, @sPathFileErr
	IF @Exist2 = 0 BEGIN 
		EXECUTE @RES2 = sp_OAMethod @FSO2, 'OpenTextFile', @FID2 OUT, @sPathFileErr, 8, 1
		SET @sTxt = 'ID			LINHA'
		EXECUTE @RES2 = sp_OAMethod @FID2, 'WriteLine', NULL, @sTxt
		EXECUTE @RES2 = sp_OAMethod @FID2, 'close', NULL
		EXECUTE @RES2 = sp_OADestroy @FID2
		EXECUTE @RES2 = sp_OADestroy @FSO2	
	END
	---------------------------------------------------------------------------------------------------------------------------------------------- 
	 
	BEGIN TRY
		DROP TABLE ##TEMP_COLUMNS_ROWS_FILETXT
	END TRY
	BEGIN CATCH
	END CATCH
	BEGIN TRY
		SET @LOOP = 1
		SET @sComand = 'ID'
		WHILE @LOOP <= @QtdColumns BEGIN
			SET @sComand = @sComand + ',CAMPO_'+RIGHT('00'+CAST(@LOOP AS VARCHAR),2)
			SET @LOOP = @LOOP + 1
		END

		EXEC('
		CREATE TABLE ##TEMP_COLUMNS_ROWS_FILETXT
		(
			ID_LINHA BIGINT PRIMARY KEY CLUSTERED NOT NULL,
			LINHA VARCHAR(8000) NOT NULL
		)
		
		INSERT INTO ##TEMP_COLUMNS_ROWS_FILETXT (ID_LINHA, LINHA)
		SELECT ROW_NUMBER() OVER(ORDER BY LINHA) ID_LINHA, A.LINHA FROM 
		OPENROWSET(BULK '''+@pathFile+''', 
			FORMATFILE='''+@sPathFMT+''') A	
		WHERE LINHA IS NOT NULL
		')
	END TRY
	BEGIN CATCH
		SET @sErrDesc		= ERROR_MESSAGE();
		SET @ERROR_SEVERITY = ERROR_SEVERITY();
		SET @ERROR_STATE	= ERROR_STATE();
		RAISERROR(@sErrDesc, @ERROR_SEVERITY, @ERROR_STATE);
		RETURN
	END CATCH

	WHILE (SELECT TOP 1 1 FROM ##TEMP_COLUMNS_ROWS_FILETXT) > 0 BEGIN
		SELECT TOP 1 @ID_LINHA = ID_LINHA, @LINHA = LINHA FROM ##TEMP_COLUMNS_ROWS_FILETXT
		
		;WITH
		L0   AS(SELECT 1 AS c UNION ALL SELECT 1),
		L1   AS(SELECT 1 AS c FROM L0 AS A, L0 AS B),
		L2   AS(SELECT 1 AS c FROM L1 AS A, L1 AS B),
		L3   AS(SELECT 1 AS c FROM L2 AS A, L2 AS B),
		L4   AS(SELECT 1 AS c FROM L3 AS A, L3 AS B),
		Numbers AS(SELECT ROW_NUMBER() OVER(ORDER BY c) AS Number FROM L4
		)
		--INSERT INTO @tmp (Data)
		SELECT @nQtdColumnsSelect = COUNT(LTRIM(RTRIM(CONVERT(NVARCHAR(4000),
				SUBSTRING(@LINHA, Number,CHARINDEX(@delimeter, @LINHA + @delimeter, Number) - Number)
		))))
		FROM   Numbers
		WHERE  Number <= CONVERT(INT, LEN(@LINHA))
			AND  SUBSTRING(@delimeter + @LINHA, Number, 1) = @delimeter	
		
		IF @nQtdColumnsSelect = @qtdColumns BEGIN
			IF RIGHT(RTRIM(@LINHA),1) = ';' BEGIN
				SET @LINHA_SELECT	= REPLACE(CAST(@ID_LINHA AS VARCHAR)+@delimeter+SUBSTRING(RTRIM(@LINHA),1,LEN(@LINHA)-1),@delimeter, ''',''')
			END
			ELSE BEGIN 
				SET @LINHA_SELECT	= REPLACE(CAST(@ID_LINHA AS VARCHAR)+@delimeter+@LINHA,@delimeter, ''',''')
			END
			
			BEGIN TRY
				INSERT INTO ##TEMP_LINHAS_BOAS
				EXEC('SELECT * FROM (VALUES ('''+@LINHA_SELECT+''')) AS MyTable('+@sComand+')')
			END TRY
			BEGIN CATCH
				if @Exist2 = 0 begin
					SET @FLG_ARQ_ERRO = 1
					EXECUTE @RES2 = sp_OACreate 'Scripting.FileSystemObject', @FSO2 OUT
					EXECUTE @RES2 = sp_OAMethod @FSO2, 'OpenTextFile', @FID2 OUT, @sPathFileErr, 8, 1
					set @sTxt = RIGHT('0000'+CAST(@ID_LINHA as varchar),4)+'		'+@LINHA
					EXECUTE @RES2 = sp_OAMethod @FID2, 'WriteLine', NULL, @sTxt
					EXECUTE @RES2 = sp_OAMethod @FID2, 'close', NULL
					EXECUTE @RES2 = sp_OADestroy @FID2
					EXECUTE @RES2 = sp_OADestroy @FSO2
				end
			END CATCH
		END
		ELSE BEGIN
			if @Exist2 = 0 begin
				SET @FLG_ARQ_ERRO = 1
				EXECUTE @RES2 = sp_OACreate 'Scripting.FileSystemObject', @FSO2 OUT
				EXECUTE @RES2 = sp_OAMethod @FSO2, 'OpenTextFile', @FID2 OUT, @sPathFileErr, 8, 1
				set @sTxt = RIGHT('0000'+CAST(@ID_LINHA as varchar),4)+'		'+@LINHA
				EXECUTE @RES2 = sp_OAMethod @FID2, 'WriteLine', NULL, @sTxt
				EXECUTE @RES2 = sp_OAMethod @FID2, 'close', NULL
				EXECUTE @RES2 = sp_OADestroy @FID2
				EXECUTE @RES2 = sp_OADestroy @FSO2
			end
		END
		
		DELETE FROM ##TEMP_COLUMNS_ROWS_FILETXT WHERE ID_LINHA = @ID_LINHA
	END
	
	BEGIN TRY
		EXECUTE @RES2 = sp_OADestroy @FID2
		EXECUTE @RES2 = sp_OADestroy @FSO2
	END TRY
	BEGIN CATCH
		SET @sErrDesc		= ERROR_MESSAGE();
		SET @ERROR_SEVERITY = ERROR_SEVERITY();
		SET @ERROR_STATE	= ERROR_STATE();
		RAISERROR(@sErrDesc, @ERROR_SEVERITY, @ERROR_STATE);
	END CATCH

	BEGIN TRY
		IF @FLG_ARQ_ERRO = 1 BEGIN
			set @sComand = 'EXEC master..xp_cmdshell ''MOVE "' + @sPathFileErr + '" "' + @sPathOrig +'"'''    
			exec(@sComand)
		END
		ELSE BEGIN
			SET @sComand = 'EXEC master..xp_cmdshell ''DEL /F /Q ' + @sPathFileErr+''''
			exec(@sComand)
		END
	END TRY
	BEGIN CATCH
		SET @sErrDesc		= ERROR_MESSAGE();
		SET @ERROR_SEVERITY = ERROR_SEVERITY();
		SET @ERROR_STATE	= ERROR_STATE();
		RAISERROR(@sErrDesc, @ERROR_SEVERITY, @ERROR_STATE);
	END CATCH
	
	BEGIN TRY
		SET @sComand = '
		IF OBJECT_ID('''+@nameTableEndResult+''',''U'') IS NOT NULL DROP TABLE '+@nameTableEndResult+'
		SELECT * INTO ##'+@nameTableEndResult+' FROM ##TEMP_LINHAS_BOAS'
		EXEC(@sComand)
		
		DROP TABLE ##TEMP_LINHAS_BOAS
	END TRY
	BEGIN CATCH
		SET @sErrDesc		= ERROR_MESSAGE();
		SET @ERROR_SEVERITY = ERROR_SEVERITY();
		SET @ERROR_STATE	= ERROR_STATE();
		RAISERROR(@sErrDesc, @ERROR_SEVERITY, @ERROR_STATE);
	END CATCH
	
	BEGIN TRY
		DROP TABLE ##TEMP_COLUMNS_ROWS_FILETXT
	END TRY
	BEGIN CATCH
	END CATCH
	
	SELECT '------------------ RESULTADO DAS LINHAS INSERIDAS NA TABELA : ##'+@nameTableEndResult +' ------------------'
	PRINT '##'+@nameTableEndResult
END