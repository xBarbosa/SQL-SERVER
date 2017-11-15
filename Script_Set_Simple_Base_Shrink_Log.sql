USE master
GO
SET NOCOUNT ON 
GO

IF OBJECT_ID('DBINFORMATION',N'U') IS NULL BEGIN
	CREATE TABLE DBINFORMATION
	(	ServerName VARCHAR(100)Not Null,
		DatabaseName VARCHAR(100)Not Null,
		LogicalFileName sysname Not Null,
		PhysicalFileName NVARCHAR(520),
		FileSizeMB INT,
		Status sysname,
		RecoveryMode sysname,
		FreeSpaceMB INT,
		FreeSpacePct INT,
		Dateandtime varchar(10) not null
	)
	Alter table DBINFORMATION ADD CONSTRAINT Comb_SNDNDT2 UNIQUE(ServerName, DatabaseName, Dateandtime,LogicalFileName)
	Alter table DBINFORMATION ADD CONSTRAINT Pk_SNDNDT2 PRIMARY KEY (ServerName, DatabaseName, Dateandtime,LogicalFileName)
END
ELSE BEGIN 
	TRUNCATE TABLE DBINFORMATION
END
GO

DECLARE @command VARCHAR(5000)
SELECT @command = 'Use [' + '?' + '] SELECT
@@servername as ServerName,
' + '''' + '?' + '''' + ' AS DatabaseName,
Cast (sysfiles.size/128.0 AS int) AS FileSizeMB,
sysfiles.name AS LogicalFileName, sysfiles.filename AS PhysicalFileName,
CONVERT(sysname,DatabasePropertyEx(''?'',''Status'')) AS Status,
CONVERT(sysname,DatabasePropertyEx(''?'',''Recovery'')) AS RecoveryMode,
CAST(sysfiles.size/128.0 - CAST(FILEPROPERTY(sysfiles.name, ' + '''' +
 'SpaceUsed' + '''' + ' ) AS int)/128.0 AS int) AS FreeSpaceMB,
CAST(100 * (CAST (((sysfiles.size/128.0 -CAST(FILEPROPERTY(sysfiles.name,
' + '''' + 'SpaceUsed' + '''' + ' ) AS int)/128.0)/(sysfiles.size/128.0))
AS decimal(4,2))) as Int) AS FreeSpacePct, CONVERT(VARCHAR(10),GETDATE(),111) as dateandtime
FROM dbo.sysfiles'
INSERT INTO DBINFORMATION
 (ServerName,
 DatabaseName,
 FileSizeMB,
 LogicalFileName,
 PhysicalFileName,
 Status,
 RecoveryMode,
 FreeSpaceMB,
 FreeSpacePct,
 dateandtime
 )
EXEC sp_MSForEachDB @command
GO

select servername,
       databasename,
       sum(filesizemb) as FilesizeMB,
       Status,
       RecoveryMode,
       sum(FreeSpaceMB)as FreeSpaceMB,
       sum(freespacemb)*100/sum(filesizemb) as FreeSpacePct,
       Dateandtime 
from dbinformation
where filesizemb > 0
AND RecoveryMode = 'FULL'
group by servername,databasename, Status, RecoveryMode, dateandtime
GO
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------
SET NOCOUNT ON;
GO

DECLARE @BASE_FULL VARCHAR(100);
DECLARE @TB_BASES TABLE(BASE VARCHAR(100));
DECLARE @ID_ARQUIVO INT;
DECLARE @NOME_ARQUIVO VARCHAR(200);
DECLARE @TB_FILES TABLE(ID INT, NOME_ARQUIVO VARCHAR(200));
DECLARE @CMD_SQL VARCHAR(2000);

INSERT INTO @TB_BASES
				select DISTINCT databasename
				from dbinformation
				where 
				filesizemb > 0
				AND RecoveryMode = 'FULL'
				AND databasename NOT IN('model','master','msdb','tempdb', 'ReportServer')


WHILE (SELECT TOP 1 1 FROM @TB_BASES) > 0
BEGIN
	SELECT TOP 1 @BASE_FULL = BASE FROM @TB_BASES;
	------------------------------------------------------------------------------
	SET @CMD_SQL = 'select fileid, name from '+@BASE_FULL+'.sys.sysfiles A WHERE A.filename LIKE ''%.ldf'''
	
	DELETE FROM @TB_FILES;
	INSERT INTO @TB_FILES EXEC(@CMD_SQL);

	PRINT ('
	USE [master]
	GO
	ALTER DATABASE ['+@BASE_FULL+'] SET RECOVERY SIMPLE WITH NO_WAIT
	GO
	')
	
	WHILE (SELECT TOP 1 1 FROM @TB_FILES) > 0
	BEGIN
		SELECT TOP 1 @ID_ARQUIVO = ID, @NOME_ARQUIVO = NOME_ARQUIVO FROM @TB_FILES;
		--------------------------------------------------------------------------
		PRINT ('
		USE ['+@BASE_FULL+']
		GO
		DBCC SHRINKFILE (N'''+@NOME_ARQUIVO+''' , 0)
		GO
		');
		--------------------------------------------------------------------------
		DELETE FROM @TB_FILES WHERE ID = @ID_ARQUIVO;
	END;
	
	------------------------------------------------------------------------------
	DELETE FROM @TB_BASES WHERE BASE = @BASE_FULL;
END;
GO
