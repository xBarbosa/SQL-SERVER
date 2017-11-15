/************************************************************************************************* Autor:     Rodrigo Barbosa da Silva Criado em: 09/11/2010     ************************************************************************************************* Objetivo:  Realizar a restauração de backups de forma automatizada Ex.: 	DECLARE @RC int
	DECLARE @PathBackup varchar(8000)		= '\\192.168.10.120\e\backup\kcserver9'
	DECLARE @Pattern varchar(200)			= '(CLARO_PE_*).+(bak|BAK)$'
	DECLARE @PathRestoreData varchar(8000)	= 'D:\Data_Files;E:\Data_Files'
	DECLARE @PatRestoreLog varchar(8000)	= 'D:\Log_Files;E:\Log_Files'
	DECLARE @IsReplace bit					= 1

	EXECUTE @RC = [master].[dbo].[usp_RestauraBackups] 
	@PathBackup
	,@Pattern
	,@PathRestoreData
	,@PatRestoreLog
	,@IsReplace
	GO************************************************************************************************ Changelog:	1.0 - Criação da procedure de restauração dos backups de bases de dados.************************************************************************************************
*/

USE [master]
GO
IF OBJECT_ID ('[dbo].[usp_RestauraBackups]') IS NOT NULL
BEGIN
	DROP PROCEDURE [dbo].usp_RestauraBackups
END
GO

CREATE PROCEDURE usp_RestauraBackups
	@PathBackup			varchar(8000),
	@Pattern			varchar(200),
	@PathRestoreData	varchar(MAX),
	@PatRestoreLog		varchar(MAX),
	@IsReplace			bit = 0
AS
BEGIN
SET NOCOUNT ON

--DECLARE @PathBackup			varchar(8000)	= '\\192.168.10.120\e\backup\kcserver9',
--		@Pattern			varchar(200)	= '(CLARO_PE_*).+(bak|BAK)$',--'CLARO_RN_CONV115_BSE_2006',
--		@PathRestoreData	varchar(MAX)	= 'D:\Data_Files;E:\Data_Files',
--		@PatRestoreLog		varchar(MAX)	= 'D:\Log_Files;E:\Log_Files',
--		@IsReplace			bit				= 1
		
DECLARE @g cursor;
DECLARE @path varchar(8000), @name varchar(8000);
DECLARE @IdData int, @PathData varchar(5000);
DECLARE @IdLog int,  @PathLog  varchar(5000);
DECLARE @PosIni int, @PosMax int;
DECLARE @PathBkp varchar(8000);
DECLARE @DataBaseName varchar(100);
DECLARE @LogicalName varchar(70), @PhysicalName varchar(1000);
DECLARE @RestoreData varchar(1000), @RestoreLog varchar(1000);
DECLARE @CountData int, @CountLog int, @CountLoop int;
DECLARE @SqlData varchar(max),@SqlLog varchar(max);

DECLARE @Tb_PathData table (id int, pathData varchar(5000));
DECLARE @Tb_PathLog  table (id int, pathLog varchar(5000));

insert into @Tb_PathData
			SELECT ID, Data
			FROM master.[dbo].[fnTableFormDelimetedString] (@PathRestoreData, ';');

insert into @Tb_PathLog
			SELECT ID, Data
			FROM master.[dbo].[fnTableFormDelimetedString] (@PatRestoreLog, ';');

SET @CountData = (SELECT COUNT(1) FROM @Tb_PathData);
SET @CountLog  = (SELECT COUNT(1) FROM @Tb_PathLog);

IF OBJECT_ID('tempdb..##TEMP_HEADERONLY') IS NOT NULL
	DROP TABLE ##TEMP_HEADERONLY;
	
CREATE TABLE ##TEMP_HEADERONLY(
BackupName				varchar(80),	BackupDescription		varchar(200),
BackupType				int,			ExpirationDate			datetime,
Compressed				smallint,		Position				int,
DeviceType				smallint,		UserName				varchar(100),
ServerName				varchar(30),	DatabaseName			varchar(100),
DatabaseVersion			int,			DatabaseCreationDate	datetime,
BackupSize				bigint,			FirstLSN				varchar(30),
LastLSN					varchar(30),	CheckpointLSN			varchar(30),
DatabaseBackupLSN		varchar(30),	BackupStartDate			datetime,
BackupFinishDate		datetime,		SortOrder				int,
CodePage				int,			UnicodeLocaleId			int,
UnicodeComparisonStyle	int,			CompatibilityLevel		int,
SoftwareVendorId		int,			SoftwareVersionMajor	int,
SoftwareVersionMinor	int,			SoftwareVersionBuild	int,
MachineName				varchar(60),	Flags					int,
BindingID				varchar(40),	RecoveryForkID			varchar(255),
Collation				varchar(30),	FamilyGUID				varchar(255),
HasBulkLoggedData		bit,			IsSnapshot				bit,
IsReadOnly				bit,			IsSingleUser			bit,
HasBackupChecksums		bit,			IsDamaged				bit,
BeginsLogChain			bit,			HasIncompleteMetaData	bit,
IsForceOffline			bit,			IsCopyOnly				bit,
FirstRecoveryForkID		varchar(255),	ForkPointLSN			varchar(255),
RecoveryModel			varchar(15),	DifferentialBaseLSN		varchar(25),
DifferentialBaseGUID	varchar(255),	BackupTypeDescription	varchar(25),
BackupSetGUID			varchar(255),	CompressedBackupSize	bigint
)
IF OBJECT_ID('tempdb..##TEMP_FILELISTONLY') IS NOT NULL
	DROP TABLE ##TEMP_FILELISTONLY;
	
CREATE TABLE ##TEMP_FILELISTONLY(
LogicalName				varchar(70),	PhysicalName			varchar(3000),
Type					char(1),		FileGroupName			varchar(40),
Size					numeric(30,0),	MaxSize					numeric(30,0),
FileId					int,			CreateLSN				varchar(30),
DropLSN					int,			UniqueId				varchar(255),
ReadOnlyLSN				int,			ReadWriteLSN			int,
BackupSizeInBytes		numeric(20,0),	SourceBlockSize			int,
FileGroupId				int,			LogGroupGUID			varchar(255),
DifferentialBaseLSN		bigint,			DifferentialBaseGUID	varchar(255),
IsReadOnly				bit,			IsPresent				bit,
TDEThumbprint			varchar(255)
)

IF OBJECT_ID('tempdb..#ARQUIVOS') IS NOT NULL
	DROP TABLE #ARQUIVOS;
CREATE TABLE #ARQUIVOS(CAMINHO VARCHAR(8000), ARQUIVO VARCHAR(100));

EXEC master.dbo.usp_ListaArquivos @dir = @PathBackup, @pattern = @Pattern , @saida = @g OUTPUT
FETCH NEXT FROM @g INTO @path, @name
WHILE @@fetch_status = 0 BEGIN
	PRINT 'PRINT ''--'+@path + ' -- ' + @name + ''' ';
	INSERT INTO #ARQUIVOS(CAMINHO,ARQUIVO) VALUES(@path, @name)
	
	SET @PathBkp = @path + '\' + @name;
	
	TRUNCATE TABLE ##TEMP_HEADERONLY;
	TRUNCATE TABLE ##TEMP_FILELISTONLY;
	
	INSERT INTO ##TEMP_HEADERONLY
				EXEC('RESTORE HEADERONLY	FROM DISK ='''+@PathBkp+'''');
	INSERT INTO ##TEMP_FILELISTONLY
				EXEC('RESTORE FILELISTONLY	FROM DISK ='''+@PathBkp+'''');
	
	SET @CountLoop	  = 1
	SET @DataBaseName = (SELECT TOP 1 DataBaseName FROM ##TEMP_HEADERONLY);
	SET @PosIni		  = (SELECT x1.Position FROM (SELECT xx.BackupType, max(xx.Position)Position FROM ##TEMP_HEADERONLY xx GROUP BY xx.BackupType)x1 WHERE x1.BackupType = 1);
	SET @PosMax		  = (SELECT x1.Position FROM (SELECT xx.BackupType, max(xx.Position)Position FROM ##TEMP_HEADERONLY xx GROUP BY xx.BackupType)x1 WHERE BackupType <> 1);
	SET @PosMax		  = CASE WHEN isnull(@PosMax,0) <= @PosIni THEN @PosIni ELSE @PosMax END;
	
	--SELECT @DataBaseName, @PosIni, @PosMax
	--SELECT * FROM ##TEMP_HEADERONLY
	--SELECT * FROM ##TEMP_FILELISTONLY
	
	SET @SqlData = '';
	WHILE (SELECT TOP 1 1 FROM ##TEMP_FILELISTONLY WHERE [Type] = 'D') > 0
	BEGIN 
		SELECT TOP 1 @LogicalName = LogicalName, @PhysicalName = PhysicalName FROM ##TEMP_FILELISTONLY WHERE [Type] = 'D';
		
		SET @CountLoop	 = CASE WHEN @CountLoop > @CountData THEN 1 ELSE @CountLoop END;
		SET @RestoreData = (select pathData from @Tb_PathData WHERE id = @CountLoop);
		SET @RestoreData = @RestoreData+reverse(substring(reverse(@PhysicalName), 1, charindex('\',reverse(@PhysicalName))));
		SET @CountLoop	 = @CountLoop + 1;

		SET @SqlData = @SqlData + ', MOVE N'''+@LogicalName+''' TO N'''+@RestoreData+''' ';
	
		DELETE FROM ##TEMP_FILELISTONLY WHERE LogicalName = @LogicalName;
	END
	SET @SqlLog = '';
	WHILE (SELECT TOP 1 1 FROM ##TEMP_FILELISTONLY WHERE [Type] = 'L') > 0
	BEGIN 
		SELECT TOP 1 @LogicalName = LogicalName, @PhysicalName = PhysicalName FROM ##TEMP_FILELISTONLY WHERE [Type] = 'L';
		
		SET @CountLoop	= CASE WHEN @CountLoop > @CountLog THEN 1 ELSE @CountLoop END;
		SET @RestoreLog = (select pathLog from @Tb_PathLog WHERE id = @CountLoop);
		SET @RestoreLog = @RestoreLog+reverse(substring(reverse(@PhysicalName), 1, charindex('\',reverse(@PhysicalName))));
		SET @CountLoop	= @CountLoop + 1;

		SET @SqlLog = @SqlLog + ', MOVE N'''+@LogicalName+''' TO N'''+@RestoreLog+''' ';
	
		DELETE FROM ##TEMP_FILELISTONLY WHERE LogicalName = @LogicalName;
	END
	
----------------
	WHILE (@PosIni <= @PosMax)
	BEGIN
		PRINT 'RESTORE DATABASE '+@DataBaseName+' FROM ';
		PRINT 'DISK = N'''+@PathBkp+''' WITH  FILE = '+CAST(@PosIni AS VARCHAR)+' ';
		PRINT @SqlData;
		PRINT @SqlLog;
		IF @PosIni < @PosMax
			PRINT ', NORECOVERY, NOUNLOAD, '+ CASE WHEN @IsReplace = 1 THEN 'REPLACE,' ELSE '' END +'  STATS = 10';
		ELSE
			PRINT ', NOUNLOAD, '+ CASE WHEN @IsReplace = 1 THEN 'REPLACE,' ELSE '' END +' STATS = 10';
	
		PRINT 'GO'
		
		SET @PosIni = @PosIni + 1;
	END
----------------
	
	FETCH NEXT FROM @g INTO @path, @name
END
CLOSE @g
DEALLOCATE @g
--GO

SELECT * FROM #ARQUIVOS ORDER BY ARQUIVO
--GO

END


