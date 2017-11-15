USE [db_ProjetoOCC]
GO

/****** Object:  StoredProcedure [dbo].[usp_CreateFile]    Script Date: 02/28/2009 22:00:59 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

-- =============================================  
-- Author:  desconhecido(http://www.dalago.com/2008/12/10/gerar-arquivo-dinamicamente-pelo-sqlserver/)
-- Create date: 20090120  
-- Description: Cria um arquivo de texto
-- =============================================  
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


