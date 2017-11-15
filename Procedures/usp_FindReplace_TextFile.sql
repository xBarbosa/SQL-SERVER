SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:Gene Hunter DBA ,BBQ Master 
-- Create date: 12/15/2011
-- fart = Find and Replace Text
-- Description:????exec DBA_DR_fart @batchfilename = 'c:\downloads\fart.bat' , @servername = 'SERVERNAME',
-- @newservername = 'NEWSERVERNAME', @sqlfiletoparse = 'c:\downloads\script.sql', 
-- @filetocreate = 'c:\downloads\newscript.sql'
-- 
-- =============================================
-- fart = Find and Replace Text

-- exec DBA_DR_fart @batchfilename = 'c:\downloads\fart.bat' , @servername = 'SERVERNAME',
-- @newservername = 'NEWSERVERNAME', @sqlfiletoparse = 'c:\downloads\script.sql',
-- @filetocreate = 'c:\downloads\newscript.sql'
-- @batchfilename is temp batch file you will create
-- @servername is actually the TEXT you want to find
-- @newservername is teh TEXT you want to replace with
-- @sqlfiletoparse is the file you want to read
-- @filetocreate is the file you parsed with changes.

-- will not delete orginal file, but you can change that 
-- =============================================
CREATE PROCEDURE [dbo].[DBA_DR_fart] 


@batchfilename varchar(300),
@servername varchar(100), 
@newservername varchar(100),
@sqlfiletoparse varchar(300),
@sqlfiletocreate varchar(300)

AS

BEGIN

SET NOCOUNT ON;
declare @sql varchar(200)
declare @sql2 varchar(200)

set @sql = ' echo @echo off > ' + @batchfilename 
exec xp_cmdshell @sql

set @sql ='SETLOCAL ENABLEEXTENSIONS' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2

set @sql ='SETLOCAL DISABLEDELAYEDEXPANSION' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2

set @sql ='if "%~1"=="" findstr "^::" "%~f0"' + CHAR(94) + CHAR(38) + CHAR(71) + CHAR(79) + CHAR(84) + CHAR(79) + CHAR(58) + CHAR(69) + CHAR(79) + CHAR(70) 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2

select @sql2
set @sql ='for /f "tokens=1,* delims=]" %%A in (''"type %3|find /n /v """'') do (' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename

exec xp_cmdshell @sql2
set @sql =' set "line=%%B"' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2


set @sql =' if defined line (' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2


set @sql =' call set "line=echo.%%line:%~1=%~2%%"' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2


set @sql =' for /f "delims=" %%X in (''"echo."%%line%%""'') do %%~X' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2


set @sql =' ) ELSE echo.' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2

set @sql =')' 
set @sql2 = ' echo ' + @sql + ' >> ' + @batchfilename
exec xp_cmdshell @sql2

--execute the find and replace

set @sql = @batchfilename + ' ' + @servername + ' ' + @newservername + ' ' + @sqlfiletoparse + ' > ' + @sqlfiletocreate
exec xp_cmdshell @sql
END
GO









