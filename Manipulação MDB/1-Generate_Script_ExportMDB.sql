/****** Object:  StoredProcedure [dbo].[usp_ExportMDB]    Script Date: 10/27/2009 12:21:31 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ExportMDB]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_ExportMDB]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExportMDB]    Script Date: 10/27/2009 12:21:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_ExportMDB]
	-- Add the parameters for the stored procedure here
	@fullPathNameMDB sysname, 
	@OverrideMDB bit = 0,
	@nameTableMDB varchar(100) = 'TABELA_01',
	@comand varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Declaração de variáveis ***************************************************************************************************************
	Declare @servername sysname = @@SERVERNAME;
	Declare @dbName sysname = DB_NAME();
	Declare @ErrorMessage NVARCHAR(4000);
	Declare @ErrorSeverity INT;
	Declare @ErrorState INT;
	Declare @return varchar(max);
	Declare @cmd varchar(max);
	Declare @FSO INT, @RES int, @FID int;
	Declare @temp_tb_ExportMDB varchar(max);
	Declare @name_temp_tb varchar(30) = 'TEMP_ExportMDB';
	Declare @Exist bit;
		
	Set @Exist = 0;
	
	BEGIN TRY
		Print '-- Validando variáveis ***********************************************************************.'
		--RAISERROR ( <Message text> , <Severity> , <State> );
		IF (LTRIM(RTRIM(@fullPathNameMDB)) = '' Or @fullPathNameMDB Is Null) RAISERROR ('Error: Caminho do MDB não foi informado.', 16, 1);
		IF (LTRIM(RTRIM(@nameTableMDB))='' Or @nameTableMDB Is Null) RAISERROR ('Error: Nome da não foi informada.', 16, 1); 
		IF (LTRIM(RTRIM(@comand)) = '' Or @comand is null) RAISERROR ('Error: Query sql não foi informada.', 16, 1); 

		IF OBJECT_ID(@name_temp_tb) IS NOT NULL BEGIN
			Set @cmd = 'DROP TABLE '+ @dbName +'.dbo.'+ @name_temp_tb
			exec(@cmd)
		END	

		Set @temp_tb_ExportMDB = REPLACE(LOWER(@comand),'from','into '+  @name_temp_tb +' from')
		EXEC(@temp_tb_ExportMDB)
				
		IF @OverrideMDB = 0 BEGIN
			Print '-- Verificando se existe o mdb ***************************************************************.'
			Declare @sErrDesc VARCHAR(2000);
			Declare @sErrSource VARCHAR(2000);
						
			--Inicializa o obleto "Scripting.FileSystemObject" ***************************************************************************************
			EXECUTE @RES = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT;
			--Verifica se metodo falhou ao criar o objeto
			IF @RES <> 0 BEGIN
				EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT;
				RAISERROR (@sErrDesc, 16, 1); 
			END;
			
			--Verifica se existe o arquivo para deletar e cria-lo novamente **************************************************************************
			EXECUTE @RES = sp_OAMethod @FSO, 'FileExists', @Exist OUT, @fullPathNameMDB;
			--Verifica se o metodo falhou ao verificar se a pasta existe 
			IF @RES <> 0 BEGIN
				EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT;
				RAISERROR (@sErrDesc, 16, 1);
			END;
		END;
		
		-----------------------------------------------------------------------------------------
		-- "@Exist" está inicializado com 0(zero), mas "@OverrideMDB" esiver igual a 0(zero),
		-- será testado se existe o MDB; caso exista o MDB a variavel "@Exist" será igual a 1 
		-----------------------------------------------------------------------------------------
		IF @Exist = 1 BEGIN
			BEGIN TRY
				Set @cmd = 'DROP TABLE ' + @nameTableMDB;
				-- Executa o drop table detro do MDB *****************************************************************************************************
				Print '-- Exclui a tabela caso ela exista no mdb ****************************************************.'
				exec usp_ExecOnMDB @MDBPathName = @fullPathNameMDB, @sql = @cmd;
			END TRY
			BEGIN CATCH
			END CATCH
		END;
		ELSE BEGIN 
			-- Criação do MDB ************************************************************************************************************************
			Print '-- Gerando o mdb no caminho especificado *****************************************************.'
			EXEC usp_CreateMDB @MDBPathName = @fullPathNameMDB, @OverrideBit = 1;
		END;

		-- Executa a procrdure de criação do create da tabela no MDB *****************************************************************************
		Print '-- Gerando o script da tabela do mdb *********************************************************.'
		Set @cmd = 'select * from ' + @name_temp_tb;
		
		EXEC usp_geraCreateTabelaMDB @nameTabelaMDB = @nameTableMDB, @query = @cmd, @returnScript = @return output;
		
		IF LTRIM(RTRIM(@return)) = '' Or @return Is Null RAISERROR ('Error inesperável na criação do create table MDB.', 16, 1);
		
		-- Criando a tabela no MDB ***************************************************************************************************************
		Print '-- Criando a tabela no mdb *******************************************************************.'
		EXEC usp_ExecOnMDB @MDBPathName = @fullPathNameMDB, @sql = @return;
		
		-- Insere os registros na tabela criada no MDB *******************************************************************************************
		Print '-- Carregando os registro na tabela do mdb ***************************************************.'
		Set @cmd = 
		'insert into openrowset(''Microsoft.Jet.OLEDB.4.0'','''+ @fullPathNameMDB +''';''Admin'';'''','+ @nameTableMDB +')
		select * from '+ @servername +'.'+ @dbName +'.dbo.'+ @name_temp_tb
		--exec(@cmd) At KCSERVERBKP01
		--exec(@cmd) At [KCSERVER8\SQLSERVER2008]
		exec(@cmd) At KCSERVER8
		
		Print '-- Excluido tabela temporária ****************************************************************.'
		Set @cmd = 'DROP TABLE '+ @dbName +'.dbo.'+ @name_temp_tb
		exec(@cmd)
		
		Print ''
		Print '-- Processo finalizado com sucesso !'
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage	= ERROR_MESSAGE(),
			   @ErrorSeverity	= ERROR_SEVERITY(),
			   @ErrorState		= ERROR_STATE();
		
		IF OBJECT_ID(@name_temp_tb) IS NOT NULL BEGIN
			Set @cmd = 'DROP TABLE '+ @dbName +'.dbo.'+ @name_temp_tb
			exec(@cmd)
		END	
		
					-- Message text. -- Severity.	-- State.
		RAISERROR ( @ErrorMessage	, @ErrorSeverity, @ErrorState );
	END CATCH;
	
END
GO

/****** Object:  StoredProcedure [dbo].[usp_ExecOnMDB]    Script Date: 10/27/2009 12:22:45 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_ExecOnMDB]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_ExecOnMDB]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExecOnMDB]    Script Date: 10/27/2009 12:22:45 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 Exemplo:
		Exec usp_ExecOnMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb',
		'Create table teste3 ( 
			teste varchar(20)	
		)'
*/
Create Proc [dbo].[usp_ExecOnMDB]
	@MDBPathName varchar(8000),
	@sql varchar(max)
As Begin
	Declare @dependencia varchar(100),
			@cmd varchar(max),
			@ret int /* retorno de usp_RunVbs */
	Set @dependencia = 'usp_RunVbs'
	If Not Exists(select 1 from sys.procedures where name = @dependencia) Begin
		RAISERROR
			(N'Dependência não encontrada: %s',
			15, -- Severity.
			1, -- State.
			@dependencia)
		Return 1
	End
	Set @sql = REPLACE(@sql,char(10),' ')
	Set @sql = REPLACE(@sql,char(13),' ')
	
	Set @cmd = 
	'
		Dim con,sql
		Set con = CreateObject("ADODB.Connection")
		con.Open "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' + @MDBPathName + '"
		con.Execute "' + @sql + '" 
		con.Close
		Set con = Nothing
	'
	Exec @ret = usp_RunVbs @cmd
	If @ret <> 0  Begin
		RAISERROR
		(N'Erro ao executar sql no mdb: 
	mdb: %s
	sql: %s',
			15, -- Severity.
			1, -- State.
			@MDBPathName,
			@sql)
		Return 1
	End
	Return 0
End
GO

/****** Object:  StoredProcedure [dbo].[usp_CreateMDB]    Script Date: 10/27/2009 12:23:53 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_CreateMDB]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_CreateMDB]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateMDB]    Script Date: 10/27/2009 12:23:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*
 Exemplo:
	1) Sem sobrescrever
		Exec usp_CreateMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb'
	2) Mandando sobrescerever o mdb
		Exec usp_CreateMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb',1
*/
Create Proc [dbo].[usp_CreateMDB]
	@MDBPathName SYSNAME,
	@OverrideBit Bit = 0
As Begin
	Declare @dependencia varchar(100),
			@cmd varchar(max),
			@ret int /* retorno de usp_RunVbs */
	Set @dependencia = 'usp_RunVbs'
	If Not Exists(select 1 from sys.procedures where name = @dependencia) Begin
		RAISERROR
			(N'Dependência não encontrada: %s',
			15, -- Severity.
			1, -- State.
			@dependencia)
		Return 1
	End
		
	If @OverrideBit = 1 Begin
		Set @cmd = 
		'
			Dim fso
			Set fso = CreateObject("Scripting.FileSystemObject")
			If (fso.FileExists("' +@MDBPathName + '")) Then
				fso.DeleteFile "' +@MDBPathName + '", true
			End If
			Set fso = Nothing
		'
		Exec @ret = usp_RunVbs @cmd, '', 0
		If @ret <> 0  begin
			RAISERROR
			(N'Erro ao tentar deletar o mdb: %s',
			15, -- Severity.
			1, -- State.
			@MDBPathName)
			Return 1
		End
	End
	
	Set @cmd = 
	'
		Dim cat
		Set cat = CreateObject("ADOX.Catalog")
		cat.Create "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=' + @MDBPathName + '"
		Set Cat = Nothing
	'
	Exec @ret = usp_RunVbs @cmd
	If @ret <> 0  Begin
		RAISERROR
		(N'Erro ao tentar criar o mdb: %s',
			15, -- Severity.
			1, -- State.
			@MDBPathName)
		Return 1
	End
	Return 0
End
GO

/****** Object:  StoredProcedure [dbo].[usp_CreateFile]    Script Date: 10/27/2009 12:25:14 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_CreateFile]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_CreateFile]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateFile]    Script Date: 10/27/2009 12:25:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*  
 Exemplo:  
   Exec sp_CreateFile @fileName, @texto
   select * from sys.configurations where value = 1 
*/
CREATE PROCEDURE [dbo].[usp_CreateFile]
	@Caminho SYSNAME,
	--@TXT VARCHAR(8000)
	@TXT VARCHAR(max) --para sqlserver 2005,2008
AS
BEGIN
	 
	DECLARE @FSO INT, @RES int, @FID int
	If Not Exists(select * from sys.configurations where name = 'Ole Automation Procedures' And value = 1) Begin
		Print 'Essa procedure depende da opção "Ole Automation Procedures" habilitada'
		Print 'Execute: '
		Print '	sp_configure ''Ole Automation Procedures'',1'
		Print '	go'
		Print '	Reconfigure'
		Return 0
	End
	EXECUTE @RES = sp_OACreate 'Scripting.FileSystemObject', @FSO OUT
	-- EXECUTE @RES = sp_OACreate 'Excel.Application ', @FSO OUT
	 
	-- Abertura do Arquivo
	EXECUTE @RES = sp_OAMethod @FSO, 'OpenTextFile', @FID OUT, @Caminho, 8, 1

	-- Escrita para o arquivo
	EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, @TXT
	EXECUTE @RES = sp_OAMethod @FID, 'close', NULL
	EXECUTE @RES = sp_OADestroy @FID
	EXECUTE @RES = sp_OADestroy @FSO
END
GO

/****** Object:  StoredProcedure [dbo].[usp_geraCreateTabelaMDB]    Script Date: 10/27/2009 12:26:13 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_geraCreateTabelaMDB]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_geraCreateTabelaMDB]
GO
/****** Object:  StoredProcedure [dbo].[usp_geraCreateTabelaMDB]    Script Date: 10/27/2009 12:26:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[usp_geraCreateTabelaMDB]
	-- Add the parameters for the stored procedure here
	--@fullPathMDB varchar(max)='', 
	@nameTabelaMDB varchar(50), 
	@query varchar(max),
	@returnScript nvarchar(max) out
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @ErrorMessage NVARCHAR(4000);
	DECLARE @ErrorSeverity INT;
	DECLARE @ErrorState INT;
	
	BEGIN TRY
		--RAISERROR ( <Message text> , <Severity> , <State> );
		--IF LTRIM(RTRIM(@fullPathMDB)) = '' RAISERROR ('Error: Caminho do MDB não foi informado.', 16, 1);
		IF (LTRIM(RTRIM(@query)) = '' Or @query is null) RAISERROR ('Error: Query sql não foi informada.', 16, 1); 
		IF (LTRIM(RTRIM(@nameTabelaMDB))='' Or @nameTabelaMDB Is Null) Set @nameTabelaMDB = 'TABELA_01';
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage	= ERROR_MESSAGE(),
			   @ErrorSeverity	= ERROR_SEVERITY(),
			   @ErrorState		= ERROR_STATE();
		
					-- Message text. -- Severity.	-- State.
		RAISERROR ( @ErrorMessage	, @ErrorSeverity, @ErrorState );
		RETURN;
	END CATCH;

   --DECLARA AS VARIAVEIS ******************************************************************************************************************
	declare @sqlPrinc varchar(max), @sqlColunas varchar(max)=''

	declare @objName as varchar(50)
	declare	@dbname	sysname,@no varchar(35), @yes varchar(35), @none varchar(35)

	declare @objid INT
	declare @sysobj_type char(2)

	declare @colName sysname, @colType sysname, @colLength sysname, @colPrec sysname, @colScale sysname, @colNullable sysname 
	declare @dblist table (colName sysname, colType sysname, colLength sysname, colPrec sysname, colScale sysname, colNullable sysname)

	set @objName = 'temp_tb'
	
	select @no = 'no', @yes = 'yes', @none = 'none'

	declare @numtypes nvarchar(80)
	select @numtypes = N'tinyint,smallint,decimal,int,real,money,float,numeric,smallmoney'

	declare @primeiraVez bit = 0

	--declare @caminhoMDB varchar(max) = @fullPathMDB
	--**************************************************************************************************************************************

	--set @sqlPrinc =	'select a.* from db_projetoocc..tb_occ_2 a inner join db_projetoocc..tb_original b on b.cod_uf = a.cod_uf and b.marcado = origem_fat where a.cod_uf = ''AC'' and b.flag_marcacao is not null'
	BEGIN TRY
		EXECUTE('drop table temp_tb')
	END TRY
	BEGIN CATCH
	END CATCH
	
	BEGIN TRY
		set @sqlPrinc = REPLACE(@query,' from ',' into '+ @objName +' from ')
		set @sqlPrinc = REPLACE(REPLACE(@sqlPrinc,'top 1',''),'select ','select top 1 ')
		
		exec(@sqlPrinc)
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage	= ERROR_MESSAGE(),
			   @ErrorSeverity	= ERROR_SEVERITY(),
			   @ErrorState		= ERROR_STATE();
		
					-- Message text. -- Severity.	-- State.
		RAISERROR ( @ErrorMessage	, @ErrorSeverity, @ErrorState );
		RETURN;
	END CATCH
		
	BEGIN TRY
		select @objid = object_id, @sysobj_type = type from sys.all_objects where object_id = object_id(@objName)

		--CRIANDO TABELA PARA LOOP DE COLUNAS *************************************************************************************************
		insert into @dblist(colName, colType, colLength, colPrec, colScale, colNullable)
			select
			'Column_name'	= name,
			'Type'			= type_name(user_type_id),
			'Length'		= convert(int, max_length),
			'Prec'			= case 
								when charindex(type_name(system_type_id), @numtypes) > 0 then convert(char(5),ColumnProperty(object_id, name, 'precision'))
								else '     ' 
							  end,
			'Scale'			= case 
								when charindex(type_name(system_type_id), @numtypes) > 0 and ISNULL(convert(char(5),OdbcScale(system_type_id,scale)),0) <> 0 then convert(char(5),OdbcScale(system_type_id,scale))
								when ISNULL(convert(char(5),OdbcScale(system_type_id,scale)),0) = 0 then 0
								else '     ' 
							  end,
			'Nullable'		= case when is_nullable = 0 then @no else @yes end
			from sys.all_columns where object_id = @objid
	END TRY
	BEGIN CATCH
		SELECT @ErrorMessage	= ERROR_MESSAGE(),
			   @ErrorSeverity	= ERROR_SEVERITY(),
			   @ErrorState		= ERROR_STATE();
		
		BEGIN TRY
			declare @dropTempTB varchar(100) = 'DROP TABLE ' + @objName
			EXEC(@dropTempTB)
		END TRY
		BEGIN CATCH
		END CATCH
		
					-- Message text. -- Severity.	-- State.
		RAISERROR ( @ErrorMessage	, @ErrorSeverity, @ErrorState );
		RETURN;
	END CATCH
	
	--GERAÇÃO DO CREATE TABLE DO MDB *****************************************************************************************************
	set @sqlColunas = 'CREATE TABLE '+ @nameTabelaMDB +' ('
	while (select count(*) from @dblist) > 0
	begin
		select top 1 @colName = colName, @colType = colType, @colLength = colLength, @colPrec = colPrec, @colScale = colScale, @colNullable = colNullable  from @dblist
		
		set @sqlColunas	= @sqlColunas + CHAR(13) + CHAR(10)
		
		if @primeiraVez = 0 
			set @primeiraVez = 1
		else 
			set @sqlColunas = @sqlColunas + ',' 
			
		set @sqlColunas	= @sqlColunas + '[' + @colName + ']'
		set @sqlColunas	= @sqlColunas + ' '
		set @sqlColunas =
			case
				when (@colType = 'varchar' Or @colType = 'nvarchar') And @colLength < 255 then @sqlColunas + 'varchar'
				when ((@colType = 'varchar' Or @colType = 'nvarchar') And @colLength > 255) Or ((@colType = 'varchar' Or @colType = 'nvarchar') And @colLength <= 0) Or @colType = 'text' then @sqlColunas + 'LongText'
				when @colType = 'int' then @sqlColunas + 'Long'
				when @colType = 'numeric' then @sqlColunas + 'Decimal'
				when @colType = 'date' then @sqlColunas + 'varchar'
				when @colType = 'timestamp' then @sqlColunas + 'VarBinary'
				when @colType = 'bigint' then @sqlColunas + 'Decimal'
				when @colType = 'float' then @sqlColunas + 'Double'
				when @colType = 'smalldatetime' then @sqlColunas + 'DateTime'
				when @colType = 'smallint' then @sqlColunas + 'Short'
				when @colType = 'uniqueidentifier' then @sqlColunas + 'GUID'
				else @sqlColunas + @colType
			end
		set @sqlColunas	= 
			case
				when (@colType = 'varchar' Or @colType = 'nvarchar') And @colLength > 0 And @colLength < 255 then @sqlColunas + '(' + @colLength + ')'
				--when @colType = 'numeric' then @sqlColunas + '(' + LTRIM(RTRIM(@colPrec)) + ',' + LTRIM(RTRIM(@colScale)) + ')'
				when @colType = 'numeric' then @sqlColunas + '(' + LTRIM(RTRIM(@colLength)) + ',' + LTRIM(RTRIM(@colScale)) + ')'
				when @colType = 'date' then @sqlColunas + '(10)'
				when @colType = 'timestamp' then @sqlColunas + '(8)'
				when @colType = 'bigint' then @sqlColunas + '(19, 0)'
				else @sqlColunas + ''
			end
			
		if @colNullable = 'no' 
			set @sqlColunas	= @sqlColunas + ' NOT NULL'
		else
			set @sqlColunas	= @sqlColunas + ' NULL'
			
		delete from @dblist where colName = @colName
	end
	
	set @sqlColunas = @sqlColunas + ')'
	
	set @returnScript = @sqlColunas
	
	BEGIN TRY
		EXECUTE('drop table temp_tb')
	END TRY
	BEGIN CATCH
	END CATCH
END
GO

/****** Object:  StoredProcedure [dbo].[usp_RunVbs]    Script Date: 10/27/2009 12:27:19 ******/
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[usp_RunVbs]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[usp_RunVbs]
GO
/****** Object:  StoredProcedure [dbo].[usp_RunVbs]    Script Date: 10/27/2009 12:27:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  glauco.basilio  
-- Create date: 20090120  
-- Description: Executa a string(@texto) 
--				contendo vbscript no contexto do WindowsScriptHost
--  
-- Obs:   @pattern é uma expressão regular ECMA  
--    depende deste arquivo \\10.1.1.110\Projeto Oi\ePrata\Scripts\ListaArquivos.vbs  
--    estar no local correto  
-- =============================================  
/*  
 Exemplo:  
   usp_RunVbs '
	Dim cat , mdb
	mdb = WScript.Arguments(0)
	Set cat = CreateObject("ADOX.Catalog")
	cat.Create "Provider=Microsoft.Jet.OLEDB.4.0;Data Source=C:\Users\glauco.basilio\Documents\" & mdb 
	Set Cat = Nothing
   ', 'MDBTESTE.MDB'
*/
create proc [dbo].[usp_RunVbs] 
	@texto varchar(max) = '', 
	@params varchar(1000) = '',
	@32BitFlag bit = 1 /*força a execução em ambiente 32 bits(é o padrão)*/,
	@ForcarResumeNext bit = 1 /*força a adição das strings de tratamento de erro*/
As Begin
	Set nocount on
	Declare @cmd varchar(8000)
	Declare @fileName SYSNAME
	Declare @ret int 
	If @ForcarResumeNext = 1 Begin
		Set @texto = 
		'
			On Error Resume Next ''Adicionado automáticamente pelo "usp_RunVbs"
		' + @texto + '
			If Err.Number <> 0 Then				''Adicionado automáticamente pelo "usp_RunVbs"
				WScript.Echo Err.Description	''Adicionado automáticamente pelo "usp_RunVbs"
				Wscript.Quit 1					''Adicionado automáticamente pelo "usp_RunVbs"
			End If								''Adicionado automáticamente pelo "usp_RunVbs"
		'
		
	End
	If Not Exists(select * from sys.configurations where name = 'xp_cmdshell' And value = 1) Begin
		Print 'Essa procedure depende da opção "xp_cmdshell" habilitada'
		Print 'Execute: '
		Print '	sp_configure ''xp_cmdshell'',1'
		Print '	go'
		Print '	Reconfigure'
		Set nocount off
		Return 1
	End
	
	If Not Exists(select * from sys.configurations where name = 'Ole Automation Procedures' And value = 1) Begin
		Print 'Essa procedure depende da opção "Ole Automation Procedures" habilitada'
		Print 'Execute: '
		Print '	sp_configure ''Ole Automation Procedures'',1'
		Print '	go'
		Print '	Reconfigure'
		Set nocount off
		Return 1
	End
	DECLARE @CMDSHELL INT, @RES INT, @VAREXPANDIDA SYSNAME
	
	--Expandindo o diretório %TEMP% para @VAREXPANDIDA
	EXECUTE @RES = sp_OACreate 'WScript.Shell', @CMDSHELL OUT
	
	EXECUTE @RES = sp_OAMethod @CMDSHELL, 'ExpandEnvironmentStrings', @VAREXPANDIDA OUT, '%temp%'
	EXECUTE @RES = sp_OADestroy @CMDSHELL

	Set @fileName = @VAREXPANDIDA + '\TempVBS' + CAST(@@SPID as varchar) + '.VBS'
	
	-- deletendo resquicios
	Set @cmd  = 'del /F "' + @fileName + '" '
	Exec @ret = xp_CmdShell  @cmd, no_output
		
	-- criando o vbs
	Exec usp_CreateFile @fileName, @texto
	
	-- Executando o script
	Set @cmd  = 'cscript //E:VBSCRIPT //H:CSCRIPT //NOLOGO "' + 
				@fileName + '" ' + @params
				
	if @32BitFlag = 1
		Set @cmd  = '%windir%\SysWOW64\cmd.exe /C ' + @cmd
	
	Exec @ret = xp_CmdShell  @cmd
	--Exec xp_CmdShell  @cmd
	If @ret <> 0 begin
		RAISERROR
			(N'
Ouve um erro ao executar o script: 
	Comando Executado: %s
	
	Script: %s',
			15, -- Severity.
			1, -- State.
			@cmd,
			@texto)
		-- Deletando o arquivo
		Set nocount off
		Return 1
	End
	Set @cmd  = 'del /F "' + @fileName + '" '
	Exec xp_CmdShell  @cmd, no_output
	Set nocount off	
End
GO

