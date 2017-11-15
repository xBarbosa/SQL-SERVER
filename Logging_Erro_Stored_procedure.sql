/*
Fonte SQL Server Central

http://www.sqlservercentral.com/articles/Error+Handling/105909/
*/
CREATE TABLE ProcessLogs
(
    JobStepID       BIGINT          IDENTITY PRIMARY KEY
    ,JobName        VARCHAR(128)    NOT NULL
    ,JobStartDT     DATETIME        NOT NULL
    ,StepStartDT    DATETIME        NOT NULL
    ,StepEndDT      DATETIME        NOT NULL
    ,StepName       VARCHAR(50)     NOT NULL
    ,Row_Count      INT             NOT NULL
    ,[ERROR_NUMBER] INT             NULL
    ,ERROR_MSG      NVARCHAR(4000)  NULL
    ,[ERROR_LINE]   INT             NULL
    ,ERROR_PROC     NVARCHAR(128)   NULL
    ,ERROR_SEV      INT             NULL
    ,[ERROR_STATE]  INT             NULL
    ,Specifics1     SQL_VARIANT     NULL
    ,Specifics2     SQL_VARIANT     NULL
    ,Specifics3     SQL_VARIANT     NULL
    ,Specifics4     SQL_VARIANT     NULL
    ,Spid           INT             NOT NULL
    ,Kpid           INT             NOT NULL
    ,[Status]       VARCHAR(50)     NOT NULL
    ,Hostname       VARCHAR(50)     NOT NULL
    ,[Dbid]         INT             NOT NULL
    ,Cmd            VARCHAR(50)     NOT NULL
);
GO

CREATE TYPE Process_Log AS TABLE
(
    JobName         VARCHAR(128)    NOT NULL
    ,JobStartDT     DATETIME        NOT NULL
    ,StepStartDT    DATETIME        NOT NULL
    ,StepEndDT      DATETIME        NOT NULL
    ,StepName       VARCHAR(50)     NOT NULL
    ,Row_Count      INT             NOT NULL
    ,[ERROR_NUMBER] INT             NULL
    ,ERROR_MSG      NVARCHAR(4000)  NULL
    ,[ERROR_LINE]   INT             NULL
    ,ERROR_PROC     NVARCHAR(128)   NULL
    ,ERROR_SEV      INT             NULL
    ,[ERROR_STATE]  INT             NULL
    ,Specifics1     SQL_VARIANT     NULL
    ,Specifics2     SQL_VARIANT     NULL
    ,Specifics3     SQL_VARIANT     NULL
    ,Specifics4     SQL_VARIANT     NULL
    ,Spid           INT             NOT NULL
    ,Kpid           INT             NOT NULL
    ,[Status]       VARCHAR(50)     NOT NULL
    ,Hostname       VARCHAR(50)     NOT NULL
    ,[Dbid]         INT             NOT NULL
    ,Cmd            VARCHAR(50)     NOT NULL
);
GO
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT TableTypeName=CASE rn WHEN 1 THEN TableTypeName ELSE '' END
    ,ColumnName, ColumnType, max_length
    ,[precision], scale, collation_name
    ,[Nulls Allowed]=CASE is_nullable WHEN 1 THEN 'YES' ELSE 'NO' END
    ,[Is Identity]=CASE is_identity WHEN 1 THEN 'YES' ELSE 'NO' END
    ,[Is In Primary Key]=CASE WHEN index_column_id IS NULL THEN 'NO' ELSE 'YES' END
    ,[Primary Key Constraint Name]=CASE rn WHEN 1 THEN ISNULL(PKName, '') ELSE '' END
FROM
(
    SELECT TableTypeName=a.name, ColumnName=b.name, ColumnType=UPPER(c.name)
        ,b.max_length, b.[precision], b.scale
        ,collation_name=COALESCE(b.collation_name, a.collation_name, '')
        ,rn=ROW_NUMBER() OVER (PARTITION BY a.name ORDER BY b.column_id)
        ,b.column_id
        ,b.is_nullable
        ,b.is_identity
        ,e.index_column_id
        ,PKName = d.name
    FROM sys.table_types a
    JOIN sys.columns b ON b.[object_id] = a.type_table_object_id
    JOIN sys.types c
        ON c.system_type_id = b.system_type_id
    LEFT JOIN sys.key_constraints d ON b.[object_id] = d.parent_object_id
    LEFT JOIN sys.index_columns e
        ON b.[object_id] = e.[object_id] AND e.index_column_id = b.column_id
    WHERE c.system_type_id = c.user_type_id
) a
--WHERE a.TableTypeName = 'Process_Log'
ORDER BY a.TableTypeName, column_id;
GO;
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE MyBatchJobProcess
AS
BEGIN

    DECLARE @ProcessLog         dbo.Process_Log;
   
    DECLARE @JobName            VARCHAR(128)    = 'MyBatchJobProcess'
        ,@JobStartDT            DATETIME        = GETDATE()
        ,@StepStartDT           DATETIME
        ,@StepEndDT             DATETIME    
        ,@Row_Count             INT
        ,@ERROR_NUMBER          INT             = NULL            
        ,@ERROR_MSG             NVARCHAR(4000)  = NULL 
        ,@ERROR_LINE            INT             = NULL            
        ,@ERROR_PROC            NVARCHAR(128)   = NULL  
        ,@ERROR_SEV             INT             = NULL
        ,@ERROR_STATE           INT             = NULL
        ,@Specifics1            SQL_VARIANT     = NULL
        ,@Specifics2            SQL_VARIANT     = NULL
        ,@Specifics3            SQL_VARIANT     = NULL
        ,@Specifics4            SQL_VARIANT     = NULL
        ,@Spid                  INT             = @@SPID            
        ,@Kpid                  INT            
        ,@Status                VARCHAR(50)   
        ,@Hostname              VARCHAR(50)    
        ,@Dbid                  INT          
        ,@Cmd                   VARCHAR(50);    

    -- Some system process variables that we will include with each log record
    SELECT TOP 1 @Kpid=kpid, @Status=[status], @Hostname=hostname, @Dbid=[dbid], @Cmd=cmd
    FROM master..sysprocesses
    WHERE spid = @Spid;

    -- Other initializations required to handle your SP's functional requirements go here
    WAITFOR DELAY '00:00:01';   -- Remove this once you convert the template to a real SP.

END
GO;
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
SELECT @StepStartDT = @JobStartDT, @StepEndDT = GETDATE(), @Row_Count = 0;
INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'JOB INITIALIZATION COMPLETE'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;
    
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
-- First job step (outside of a transaction)

-- Do the work, SELECT ... INTO ... FROM ... (replace the WAITFOR)
SELECT @StepStartDT = GETDATE();
WAITFOR DELAY '00:00:02';   -- Remove this once you convert the template to a real SP.
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
-- Capture any specifics about the step now.

INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepNameh
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 1: DESC OF STEP 1'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

BEGIN TRANSACTION T1;

-- Second job step (inside of a transaction)

-- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
SELECT @StepStartDT = GETDATE();
WAITFOR DELAY '00:00:03';   -- Remove this once you convert the template to a real SP.
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
-- Capture any specifics about the step now.

INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 2: DESC OF STEP 2'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;

-- Third job step (inside of a transaction)

-- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
SELECT @StepStartDT = GETDATE();
WAITFOR DELAY '00:00:04';   -- Remove this once you convert the template to a real SP.
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
-- Capture any specifics about the step now.

INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 3: DESC OF STEP 3'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;

COMMIT TRANSACTION T1;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------

-- Penultimate job step (purge the log)
SELECT @StepStartDT = GETDATE();

DELETE dbo.ProcessLogs
WHERE JobName = @JobName AND JobStartDT < DATEADD(day, -30, @JobStartDT);
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();

INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP x: PURGE LOG'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

-- Final step to note job complete
INSERT INTO dbo.ProcessLogs
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, GETDATE(), GETDATE(), 'JOB COMPLETE'
    ,0
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------    
    
CREATE PROCEDURE dbo.MyBatchJobProcess
AS
BEGIN

    DECLARE @ProcessLog         dbo.Process_Log;
   
    DECLARE @JobName            VARCHAR(128)    = 'MyBatchJobProcess'
        ,@JobStartDT            DATETIME        = GETDATE()
        ,@StepStartDT           DATETIME
        ,@StepEndDT             DATETIME    
        ,@Row_Count             INT
        ,@ERROR_NUMBER          INT             = NULL            
        ,@ERROR_MSG             NVARCHAR(4000)  = NULL 
        ,@ERROR_LINE            INT             = NULL            
        ,@ERROR_PROC            NVARCHAR(128)   = NULL  
        ,@ERROR_SEV             INT             = NULL
        ,@ERROR_STATE           INT             = NULL
        ,@Specifics1            SQL_VARIANT     = NULL
        ,@Specifics2            SQL_VARIANT     = NULL
        ,@Specifics3            SQL_VARIANT     = NULL
        ,@Specifics4            SQL_VARIANT     = NULL
        ,@Spid                  INT             = @@SPID            
        ,@Kpid                  INT            
        ,@Status                VARCHAR(50)   
        ,@Hostname              VARCHAR(50)    
        ,@Dbid                  INT          
        ,@Cmd                   VARCHAR(50);    

    -- Some system process variables that we will include with each log record
    SELECT TOP 1 @Kpid=kpid, @Status=[status], @Hostname=hostname, @Dbid=[dbid], @Cmd=cmd
    FROM master..sysprocesses
    WHERE spid = @Spid;

    -- Other initializations required to handle your SP's functional requirements go here
    WAITFOR DELAY '00:00:01';   -- Remove this once you convert the template to a real SP.

    SELECT @StepStartDT = @JobStartDT, @StepEndDT = GETDATE(), @Row_Count = 0;
    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'JOB INITIALIZATION COMPLETE'
        ,@Row_Count
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

    -- First job step (outside of a transaction)

    -- Do the work, SELECT ... INTO ... FROM ... (replace the WAITFOR)
    SELECT @StepStartDT = GETDATE();
    WAITFOR DELAY '00:00:02';   -- Remove this once you convert the template to a real SP.
    SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
    -- Capture any specifics about the step now.

    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 1: DESC OF STEP 1'
        ,@Row_Count
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

    SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;
   
    BEGIN TRANSACTION T1;

    -- Second job step (inside of a transaction)

    -- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
    SELECT @StepStartDT = GETDATE();
    WAITFOR DELAY '00:00:03';   -- Remove this once you convert the template to a real SP.
    SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
    -- Capture any specifics about the step now.

    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 2: DESC OF STEP 2'
        ,@Row_Count
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

    SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;

    -- Third job step (inside of a transaction)

    -- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
    SELECT @StepStartDT = GETDATE();
    WAITFOR DELAY '00:00:04';   -- Remove this once you convert the template to a real SP.
    SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
    -- Capture any specifics about the step now.

    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 3: DESC OF STEP 3'
        ,@Row_Count
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

    SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL;

    COMMIT TRANSACTION T1;
   
    -- Penultimate job step (purge the log)
    SELECT @StepStartDT = GETDATE();

    DELETE dbo.ProcessLogs
    WHERE JobName = @JobName AND JobStartDT < DATEADD(day, -30, @JobStartDT);
    SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();

    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP x: PURGE LOG'
        ,@Row_Count
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

    -- Final step to note job complete
    INSERT INTO dbo.ProcessLogs
    (
        JobName, JobStartDT, StepStartDT, StepEndDT, StepName
        ,Row_Count
        ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
        ,Specifics1, Specifics2, Specifics3, Specifics4
        ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
    )
    SELECT @JobName, @JobStartDT, GETDATE(), GETDATE(), 'JOB COMPLETE'
        ,0
        ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
        ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
        ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

END

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------    

BEGIN TRANSACTION T1;

-- Second job step (inside of a transaction)

-- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
SELECT @StepStartDT = GETDATE();
BEGIN TRY
    WAITFOR DELAY '00:00:03';   -- Remove this once you convert the template to a real SP.
    SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
    -- Capture any specifics about the step now (within the TRY).
END TRY
BEGIN CATCH
    SELECT @ERROR_NUMBER    = ERROR_NUMBER()
        ,@ERROR_PROC        = ERROR_PROCEDURE()
        ,@ERROR_SEV         = ERROR_SEVERITY()
        ,@ERROR_STATE       = ERROR_STATE()
        ,@ERROR_LINE        = ERROR_LINE()
        ,@ERROR_MSG         = ERROR_MESSAGE()
        ,@Error_Count       = @Error_Count + 1
        ,@Row_Count         = 0
        ,@StepEndDT         = GETDATE();
END CATCH

-- Within the transaction we want to capture logging to the TABLE variable
-- so it can be used upon ROLLBACK
INSERT INTO @ProcessLog
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 2: DESC OF STEP 2'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

SELECT @Specifics1=CASE WHEN @Error_Count <> 0 THEN 'STEP SKIPPED DUE TO PRIOR ERRORS' END
    ,@Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL
    ,@ERROR_NUMBER=NULL, @ERROR_MSG=NULL, @ERROR_LINE=NULL
    ,@ERROR_PROC=NULL, @ERROR_SEV=NULL, @ERROR_STATE=NULL;

-- Third job step (inside of a transaction)
IF @Error_Count = 0
BEGIN       
    -- Do the work, INSERT/UPDATE/DELETE/MERGE or whatever (replace the WAITFOR)
    SELECT @StepStartDT = GETDATE();
    BEGIN TRY
        WAITFOR DELAY '00:00:04';   -- Remove this once you convert the template to a real SP.
        SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
        -- Capture any specifics about the step now.
    END TRY
    BEGIN CATCH
        SELECT @ERROR_NUMBER    = ERROR_NUMBER()
            ,@ERROR_PROC        = ERROR_PROCEDURE()
            ,@ERROR_SEV         = ERROR_SEVERITY()
            ,@ERROR_STATE       = ERROR_STATE()
            ,@ERROR_LINE        = ERROR_LINE()
            ,@ERROR_MSG         = ERROR_MESSAGE()
            ,@Error_Count       = @Error_Count + 1
            ,@Row_Count         = 0
            ,@StepEndDT         = GETDATE();
    END CATCH
END

INSERT INTO @ProcessLog
(
    JobName, JobStartDT, StepStartDT, StepEndDT, StepName
    ,Row_Count
    ,[ERROR_NUMBER], ERROR_MSG, [ERROR_LINE], ERROR_PROC, ERROR_SEV, [ERROR_STATE]
    ,Specifics1, Specifics2, Specifics3, Specifics4
    ,Spid, Kpid, [Status], Hostname, [Dbid], Cmd  
)
SELECT @JobName, @JobStartDT, @StepStartDT, @StepEndDT, 'STEP 3: DESC OF STEP 3'
    ,@Row_Count
    ,@ERROR_NUMBER, @ERROR_MSG, @ERROR_LINE, @ERROR_PROC, @ERROR_SEV, @ERROR_STATE
    ,@Specifics1, @Specifics2, @Specifics3, @Specifics4
    ,@Spid, @Kpid, @Status, @Hostname, @Dbid, @Cmd;

-- Set @Specifics1 here like shown after step 2 if > 2 steps in the trans
SELECT @Specifics1=NULL, @Specifics2=NULL, @Specifics3=NULL, @Specifics4=NULL
    ,@ERROR_NUMBER=NULL, @ERROR_MSG=NULL, @ERROR_LINE=NULL
    ,@ERROR_PROC=NULL, @ERROR_SEV=NULL, @ERROR_STATE=NULL;

IF @Error_Count = 0 AND XACT_STATE() = 1 COMMIT TRANSACTION T1;
ELSE IF XACT_STATE() <> 0 ROLLBACK TRANSACTION T1;
   
INSERT INTO ProcessLogs
SELECT * FROM @ProcessLog;

---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------    

-- Other initializations required to handle your SP's functional requirements go here
--WAITFOR DELAY '00:00:01';
SELECT TOP 5000 @Error_Count = 0 * ROW_NUMBER() OVER (ORDER BY (SELECT NULL))
FROM sys.all_columns a CROSS JOIN sys.all_columns b;

-- First job step (outside of a transaction)
--WAITFOR DELAY '00:00:02';
SELECT *
INTO #Temp
FROM dbo.ProcessLogs;
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();
DROP TABLE #Temp;

-- Second job step (inside of a transaction)
--WAITFOR DELAY '00:00:03';  
UPDATE dbo.ProcessLogs
SET JobStartDT = DATEADD(millisecond, 3, JobStartDT);
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();

-- Third job step (inside of a transaction)
--WAITFOR DELAY '00:00:04';
SELECT 1/0;
SELECT @Row_Count = @@ROWCOUNT, @StepEndDT = GETDATE();