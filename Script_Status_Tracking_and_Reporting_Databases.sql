USE master
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
       Dateandtime from dbinformation
where filesizemb > 0
group by servername,databasename, Status, RecoveryMode, dateandtime
GO