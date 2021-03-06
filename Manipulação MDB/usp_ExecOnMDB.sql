USE [db_ProjetoOCC]
GO
/****** Object:  StoredProcedure [dbo].[usp_ExecOnMDB]    Script Date: 02/28/2009 22:09:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================  
-- Author:  glauco.basilio
-- Create date: 20090120  
-- Description: Executa um sql em um mdb existente
-- =============================================  
/*
 Exemplo:
		Exec usp_ExecOnMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb',
		'Create table teste3 ( 
			teste varchar(20)	
		)'
*/
ALTER Proc [dbo].[usp_ExecOnMDB]
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