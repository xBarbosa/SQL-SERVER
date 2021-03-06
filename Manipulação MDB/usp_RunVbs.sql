USE [db_ProjetoOCC]
GO
/****** Object:  StoredProcedure [dbo].[usp_RunVbs]    Script Date: 02/28/2009 22:10:03 ******/
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
ALTER proc [dbo].[usp_RunVbs] 
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
	
	-- Caminho e nome do arquivo
	
	

	
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

--sp_configure 'Ole Automation Procedures',1
--reconfigure
