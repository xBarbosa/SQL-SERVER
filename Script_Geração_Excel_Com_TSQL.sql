-- Create XLS script DAL - 04/24/2003
-- Designed for Agent scheduling, turn on "Append output for step history"
-- Search for %%% to find adjustable constants and other options
-- Uses OLE for ADO and OLE DB to create the XLS file if it does not exist
--   Linked server requires the XLS to exist before creation
-- Uses OLE ADO to Create the XLS Worksheet for use as a table by T-SQL
-- Uses Linked Server to allow T-SQL access to XLS table
-- Uses T-SQL to populate te XLS worksheet, very fast
--

PRINT 'Begin CreateXLS script at '+RTRIM(CONVERT(varchar(24),GETDATE(),121))+' '
PRINT ''
GO

SET NOCOUNT ON

DECLARE @Conn int					-- ADO Connection object to create XLS
      , @hr int						-- OLE return value
      , @src varchar(255)			-- OLE Error Source
      , @desc varchar(255)			-- OLE Error Description
      , @Path varchar(255)			-- Drive or UNC path for XLS
      , @Connect varchar(255)		-- OLE DB Connection string for Jet 4 Excel ISAM
      , @WKS_Created bit			-- Whether the XLS Worksheet exists
      , @WKS_Name varchar(128)		-- Name of the XLS Worksheet (table)
      , @ServerName nvarchar(128)	-- Linked Server name for XLS
      , @DDL varchar(8000)			-- Jet4 DDL for the XLS WKS table creation
      , @SQL varchar(8000)			-- INSERT INTO XLS T-SQL
      , @Recs int					-- Number of records added to XLS
      , @Log bit					-- Whether to log process detail

-- Init variables

SELECT @Recs = 0
	-- %%% 1 = Verbose output detail, helps find problems, 0 = minimal output detail
	, @Log = 1

-- %%% assign the UNC or path and name for the XLS file, requires Read/Write access
--   must be accessable from server via SQL Server service account
--   & SQL Server Agent service account, if scheduled

SET @Path = '\\192.168.10.111\C$\Test_'+CONVERT(varchar(10),GETDATE(),112)+'.xls'

-- assign the ADO connection string for the XLS creation
SET @Connect = 'Provider=Microsoft.Jet.OLEDB.4.0;Data Source='+@Path+';Extended Properties=Excel 8.0'

-- %%% assign the Linked Server name for the XLS population
SET @ServerName = 'EXCEL_TEST'

-- %%% Rename Table as required, this will also be the XLS Worksheet name
SET @WKS_Name = 'People_1'

-- %%% Table creation DDL, uses Jet4 syntax,
--   Text data type = varchar(255) when accessed from T-SQL

SET @DDL = 'CREATE TABLE '+@WKS_Name+' (Name Text, Phone Text)'

-- %%% T-SQL for table population, note the 4 part naming required by Jet4 OLE DB
--   INSERT INTO SELECT, INSERT INTO VALUES, and EXEC sp types are supported
--   Linked Server does not support SELECT INTO types

SET @SQL = 'INSERT INTO '+@ServerName+'...'+@WKS_Name+' (Name, Phone) '
SET @SQL = @SQL+'SELECT top 5000'
SET @SQL = @SQL+' LTRIM(RTRIM(ISNULL(DESCRICAO,'''')+'' ''+ISNULL(DESCRICAO,''''))) AS Name'
SET @SQL = @SQL+', FAMILIA AS Phone '
SET @SQL = @SQL+'FROM [master].[dbo].[TEMP_DE_PARA_FAMILIA_POSITIVOS]'

IF @Log = 1 PRINT 'Created OLE ADODB.Connection object'

-- Create the Conn object

EXEC @hr = sp_OACreate 'ADODB.Connection', @Conn OUT

IF @hr <> 0 -- have to use <> as OLE / ADO can return negative error numbers
BEGIN
      -- Return OLE error
      EXEC sp_OAGetErrorInfo @Conn, @src OUT, @desc OUT
      SELECT Error=convert(varbinary(4),@hr), Source=@src, Description=@desc
      RETURN
END

 

IF @Log = 1 PRINT char(9)+'Assigned ConnectionString property'

-- Set a the Conn object's ConnectionString property
--   Work-around for error using a variable parameter on the Open method

EXEC @hr = sp_OASetProperty @Conn, 'ConnectionString', @Connect

IF @hr <> 0
BEGIN
      -- Return OLE error
      EXEC sp_OAGetErrorInfo @Conn, @src OUT, @desc OUT
      SELECT Error=convert(varbinary(4),@hr), Source=@src, Description=@desc
      RETURN
END
 

IF @Log = 1 PRINT char(9)+'Open Connection to XLS, for file Create or Append'

-- Call the Open method to create the XLS if it does not exist, can't use parameters

EXEC @hr = sp_OAMethod @Conn, 'Open'

IF @hr <> 0
BEGIN
      -- Return OLE error
      EXEC sp_OAGetErrorInfo @Conn, @src OUT, @desc OUT
      SELECT Error=convert(varbinary(4),@hr), Source=@src, Description=@desc
      RETURN
END

-- %%% This section could be repeated for multiple Worksheets (Tables)

IF @Log = 1 PRINT char(9)+'Execute DDL to create '''+@WKS_Name+''' worksheet'

-- Call the Execute method to Create the work sheet with the @WKS_Name caption,
--   which is also used as a Table reference in T-SQL
-- Neat way to define column data types in Excel worksheet
--   Sometimes converting to text is the only work-around for Excel's General
--   Cell formatting, even though the Cell contains Text, Excel tries to format
--   it in a "Smart" way, I have even had to use the single quote appended as the
--   1st character in T-SQL to force Excel to leave it alone

EXEC @hr = sp_OAMethod @Conn, 'Execute', NULL, @DDL, NULL, 129 -- adCmdText + adExecuteNoRecords

-- 0x80040E14 for table exists in ADO

IF @hr = 0x80040E14
      -- kludge, skip 0x80042732 for ADO Optional parameters (NULL) in SQL7
      OR @hr = 0x80042732
BEGIN
      -- Trap these OLE Errors
      IF @hr = 0x80040E14
      BEGIN
            PRINT char(9)+''''+@WKS_Name+''' Worksheet exists for append'
            SET @WKS_Created = 0
      END

      SET @hr = 0 -- ignore these errors
END

IF @hr <> 0
BEGIN
      -- Return OLE error
      EXEC sp_OAGetErrorInfo @Conn, @src OUT, @desc OUT
      SELECT Error=convert(varbinary(4),@hr), Source=@src, Description=@desc
      RETURN
END

IF @Log = 1 PRINT 'Destroyed OLE ADODB.Connection object'

-- Destroy the Conn object, +++ important to not leak memory +++

EXEC @hr = sp_OADestroy @Conn

IF @hr <> 0
BEGIN
      -- Return OLE error

      EXEC sp_OAGetErrorInfo @Conn, @src OUT, @desc OUT
      SELECT Error=convert(varbinary(4),@hr), Source=@src, Description=@desc
      RETURN
END

 

-- Linked Server allows T-SQL to access the XLS worksheet (Table)
--   This must be performed after the ADO stuff as the XLS must exist
--   and contain the schema for the table, or worksheet

IF NOT EXISTS(SELECT srvname from master.dbo.sysservers where srvname = @ServerName)
BEGIN
      IF @Log = 1 PRINT 'Created Linked Server '''+@ServerName+''' and Login'
      EXEC sp_addlinkedserver @server = @ServerName
            , @srvproduct = 'Microsoft Excel Workbook'
            , @provider = 'Microsoft.Jet.OLEDB.4.0'
            , @datasrc = @Path
            , @provstr = 'Excel 8.0'

      -- no login name or password are required to connect to the Jet4 ISAM linked server
      EXEC sp_addlinkedsrvlogin @ServerName, 'false'
END

-- Have to EXEC the SQL, otherwise the SQL is evaluated
--   for the linked server before it exists

EXEC (@SQL)

PRINT char(9)+'Populated '''+@WKS_Name+''' table with '+CONVERT(varchar,@@ROWCOUNT)+' Rows'

-- %%% Optional you may leave the Linked Server for other XLS operations
--   Remember that the Linked Server will not create the XLS, so remove it
--   When you are done with it, especially if you delete or move the file

IF EXISTS(SELECT srvname from master.dbo.sysservers where srvname = @ServerName)
BEGIN
      IF @Log = 1 PRINT 'Deleted Linked Server '''+@ServerName+''' and Login'
      EXEC sp_dropserver @ServerName, 'droplogins'
END
GO
 

SET NOCOUNT OFF

PRINT ''
PRINT 'Finished CreateXLS script at '+RTRIM(CONVERT(varchar(24),GETDATE(),121))+' '
GO