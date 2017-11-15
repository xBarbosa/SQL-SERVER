---- query unused space all DBs
USE MASTER 
GO 
SET NOCOUNT ON;
DECLARE @DBFILENAME varchar(255), @DBFILESIZE int, @DBSPACEFREE int, @DBPERCENTFREE DECIMAL(18,2)

GO
CREATE TABLE #TMPCOMMAND ( 
 COMMANDNAME VARCHAR(2048)
) 
GO

CREATE TABLE #TMPFIXEDDRIVES ( 
 DRIVE CHAR(1), 
 MBFREE INT) 

INSERT INTO #TMPFIXEDDRIVES EXEC xp_FIXEDDRIVES 

CREATE TABLE #TMPSPACEUSED ( 
 DBNAME NVARCHAR(255), 
 FILENME VARCHAR(255), 
 SPACEUSED FLOAT) 
GO

CREATE TABLE #DB ( 
 NAME NVARCHAR(255)
 )
GO

DECLARE @dbName sysname, @rc int
DECLARE @cmdSQL varchar(2000)

INSERT INTO #DB (NAME) SELECT NAME FROM master.sys.databases
WHERE 
 name NOT IN ('master', 'model', 'msdb', 'tempdb', 'ADMINDB', 'ReplDistribution') AND
 name NOT LIKE '%ReportServer%' AND
 DATABASEPROPERTYEX([name], 'IsInStandBy') = 0 AND
 DATABASEPROPERTYEX([name], 'Status') = 'ONLINE'

SELECT @rc = 1, @dbName = MIN(name) FROM #DB

WHILE @rc <> 0
BEGIN


SET @cmdSQL = 'USE [' + @dbName + '];' + 'INSERT INTO #TMPSPACEUSED (DBNAME, FILENME, SPACEUSED) SELECT ''' + @dbName + ''', NAME, FILEPROPERTY(NAME, ''SpaceUsed'') FROM [' + @dbName + '].sys.sysfiles'
EXEC(@cmdSQL)


 SELECT TOP 1 @dbName = name
 FROM #db
 WHERE name > @dbName
 ORDER BY name

 SET @rc = @@ROWCOUNT

END

DROP TABLE #DB


INSERT INTO #TMPCOMMAND(COMMANDNAME)
SELECT 'USE [' + A.NAME + '];' + ' DBCC SHRINKFILE(' + 
 B.NAME + ', ' + 
 CAST(
 (
 CAST((B.SIZE * 8 / 1024.0) AS DECIMAL(18,0))
 - 
 CAST((B.SIZE * 8 / 1024.0) - (D.SPACEUSED / 128.0) AS DECIMAL(15,0))
 + 1 )
 AS VARCHAR(20) )+ ')' 
FROM SYS.DATABASES A 
 JOIN SYS.MASTER_FILES B 
 ON A.DATABASE_ID = B.DATABASE_ID 
 JOIN #TMPFIXEDDRIVES C 
 ON LEFT(B.PHYSICAL_NAME,1) = C.DRIVE 
 JOIN #TMPSPACEUSED D 
 ON A.NAME = D.DBNAME 
 AND B.NAME = D.FILENME 
WHERE CAST((B.SIZE * 8 / 1024.0) - (D.SPACEUSED / 128.0) AS DECIMAL(15,2)) / CAST(CAST((B.SIZE * 8 / 1024.0) AS DECIMAL(18,2)) AS VARCHAR(20)) > 0.01


DROP TABLE #TMPFIXEDDRIVES 
DROP TABLE #TMPSPACEUSED 


DECLARE @PrintCommand VARCHAR(8000) 

DECLARE Print_cursor CURSOR 
FOR 
SELECT COMMANDNAME FROM #TMPCOMMAND ORDER BY COMMANDNAME
 
OPEN Print_cursor 
 
FETCH NEXT FROM Print_cursor INTO @PrintCommand 
WHILE (@@FETCH_STATUS <> -1) 
BEGIN 
IF (@@FETCH_STATUS <> -2) 
BEGIN 
PRINT @PrintCommand 
END 
FETCH NEXT FROM Print_cursor INTO @PrintCommand 
END 

DROP TABLE #TMPCOMMAND
CLOSE Print_cursor 
DEALLOCATE Print_cursor 



