USE [db_ProjetoOCC]
GO
/****** Object:  StoredProcedure [dbo].[usp_geraCreateTabelaMDB]    Script Date: 03/11/2009 12:11:14 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Rodrigo Barbosa
-- Create date: 27/02/2009
-- =============================================
ALTER PROCEDURE [dbo].[usp_geraCreateTabelaMDB]
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
								when charindex(type_name(system_type_id), @numtypes) > 0 then convert(char(5),OdbcScale(system_type_id,scale))
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
			
		set @sqlColunas	= @sqlColunas + @colName 
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
				when @colType = 'numeric' then @sqlColunas + '(' + LTRIM(RTRIM(@colPrec)) + ',' + LTRIM(RTRIM(@colScale)) + ')'
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
	
	/*
	--CRIAÇÃO DO MDB NO CAMINHO ESPECIFICADO *********************************************************************************************
	exec usp_CreateMDB @MDBPathName = @caminhoMDB, @OverrideBit = 1
	
	--CRIANDO TABELA NO MDB **************************************************************************************************************
	exec usp_ExecOnMDB @MDBPathName = @caminhoMDB, @sql = @sqlColunas

	--PREENCHENDO TABELA COM OS REGISTROS ************************************************************************************************
	exec('
		insert into openrowset(''Microsoft.Jet.OLEDB.4.0'','''+ @caminhoMDB +''';''Admin'';'''','+ @nameTabelaMDB +')
		select * from kcserver4.db_projetoocc.dbo.temp_tb
	') At KCSERVERBKP01
	*/
	
	set @returnScript = @sqlColunas
	
	BEGIN TRY
		EXECUTE('drop table temp_tb')
	END TRY
	BEGIN CATCH
	END CATCH
	
	
END
