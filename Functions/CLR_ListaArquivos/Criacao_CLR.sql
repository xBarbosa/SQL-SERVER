USE MASTER
GO
---------------------------------------------------------------------------------------------
exec sp_configure 'clr enabled', 1
reconfigure
GO
-----------------------------------------------------------------------------------------------------
/*
use master;
-- Replace SQL_Server_logon with your SQL Server user credentials.
GRANT EXTERNAL ACCESS ASSEMBLY TO [DEV]; 
-- Modify the following line to specify a different database.
ALTER DATABASE master SET TRUSTWORTHY ON;
*/
-----------------------------------------------------------------------------------------------------
IF EXISTS (SELECT name FROM sysobjects WHERE name = 'UFN_LISTA_ARQUIVOS')
   DROP FUNCTION UFN_LISTA_ARQUIVOS;
GO
IF EXISTS (SELECT name FROM sys.assemblies WHERE name = 'AssemblyListarArquivos')
   DROP ASSEMBLY AssemblyListarArquivos;
GO
---------------------------------------------------------------------------------------------
CREATE ASSEMBLY AssemblyListarArquivos
FROM 'C:\.net Assembly\ListFiles.dll'
WITH PERMISSION_SET = EXTERNAL_ACCESS; /* SAFE | UNSAFE | EXTERNAL_ACCESS */
GO
---------------------------------------------------------------------------------------------
CREATE FUNCTION [dbo].[UFN_LISTA_ARQUIVOS] (@PATH nvarchar(4000), @EXPRESSAO nvarchar(2000))
RETURNS TABLE 
	(
	Diretorio NVARCHAR(4000), 
	Arquivo NVARCHAR(400), 
	TamanhoBytes BIGINT
	)
AS EXTERNAL NAME AssemblyListarArquivos.[ListFiles.UserDefinedFunctions].Folders;
GO
---------------------------------------------------------------------------------------------
select *
from [dbo].[UFN_LISTA_ARQUIVOS]('E:\CTBC', '.NM')


select *
from [dbo].[UFN_LISTA_ARQUIVOS]('\\192.168.10.111\e\CTBC', '.NM')



