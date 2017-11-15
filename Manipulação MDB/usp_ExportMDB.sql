SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Rodrigo Barbosa da Silva
-- Create date: 02/03/2009
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE usp_ExportMDB
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
		exec(@cmd) At KCSERVERBKP01
		
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
