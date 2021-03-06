USE [db_ProjetoOCC]
GO
/****** Object:  StoredProcedure [dbo].[usp_CreateMDB]    Script Date: 02/28/2009 22:09:37 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================  
-- Author:  desconhecido(http://www.dalago.com/2008/12/10/gerar-arquivo-dinamicamente-pelo-sqlserver/)
-- Create date: 20090120  
-- Description: Cria um mdb
-- =============================================  
/*
 Exemplo:
	1) Sem sobrescrever
		Exec usp_CreateMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb'
	2) Mandando sobrescerever o mdb
		Exec usp_CreateMDB 'C:\Users\glauco.basilio\Documents\Teste2.mdb',1
*/
ALTER Proc [dbo].[usp_CreateMDB]
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
