--###########################################################################################################################
--create bat file
--###########################################################################################################################
USE db_ProjetoOCC
GO 
SET NOCOUNT ON;

DECLARE @Path SYSNAME = '\\192.168.10.104\c$\temp\Relatorio'
DECLARE @Exist BIT
DECLARE @SQL VARCHAR(MAX) 
--Declara as variaveis de erros
DECLARE @sErrDesc VARCHAR(2000)
DECLARE @sErrSource VARCHAR(2000) 
 
DECLARE @FSO INT, @RES int, @FID int

DECLARE @PathBatFull varchar(300) = @Path + '\Relatorio.bat'

DECLARE @dbId sysname
DECLARE @dblist table (dbId sysname)

DECLARE @CAMINHO varchar(max)


PRINT 'Verificação de criação do objeto "Scripting.FileSystemObject" para arquivo bat ************************************************************'
Print ''
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
EXECUTE @RES = sp_OAMethod @FSO, 'FileExists', @Exist OUT, @PathBatFull
--Verifica se o metodo falhou ao verificar se a pasta existe 
IF @RES <> 0 BEGIN
	EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT
	PRINT @RES
	PRINT @sErrDesc
	PRINT @sErrSource
	RETURN
END

IF @Exist = 1 BEGIN
	DECLARE @CMD SYSNAME
	Set @CMD = 'DEL ' + @PathBatFull
	EXEC XP_CMDSHELL @CMD
END 

-- Abertura do Arquivo
EXECUTE @RES = sp_OAMethod @FSO, 'OpenTextFile', @FID OUT, @PathBatFull, 8, 1
-- Verifica se o metodo de abertura falhou
IF @RES <> 0 BEGIN
	EXEC sp_OAGetErrorInfo @RES, @sErrSource OUT, @sErrDesc OUT
	PRINT @RES
	PRINT @sErrDesc
	PRINT @sErrSource
	RETURN
END

INSERT INTO @dblist(dbId) SELECT COD_UF
							FROM dbo.TB_OCC_2
							WHERE COD_UF not in ('RJ')
							GROUP BY COD_UF
							ORDER BY COUNT(COD_UF)
	
EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, 'cd\'
EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, 'cls'

while (select count(*) from @dblist) > 0 begin
	select top 1 @dbId = dbId from @dblist

	Set @CAMINHO = 'bcp "SELECT * FROM db_projetoocc..tb_temp_relatorio where cod_uf = ''' + @dbId + '''" queryout \\192.168.10.104\c$\temp\Relatorio\relatorio_'+ @dbId +'.txt -c -t ; -S KCSERVER4 -U sa -P kcc -c;'
	Print @CAMINHO
	
	EXEC @RES = sp_OAMethod @FID, 'WriteLine', NULL, @CAMINHO

	delete from @dblist where dbId = @dbId
end	

EXECUTE @RES = sp_OAMethod @FID, 'WriteLine', NULL, 'Exit;'
	
EXECUTE @RES = sp_OAMethod @FID, 'close', NULL
EXECUTE @RES = sp_OADestroy @FID


EXECUTE @RES = sp_OADestroy @FSO	


--Execute bat file
PRINT 'Executando o arquivo .bat ****************************************************************************************************************'
--EXECUTE XP_CMDSHELL @PathBatFull 

SET NOCOUNT OFF;
