-- =============================================
-- Author:	Karl Klingler
-- Create date: 20100507
-- Description:	Based on the code from Phil Factor
-- found on http://www.simple-talk.com/sql/learn-sql-server/building-my-first-sql-server-2005-clr/
--              i had to eliminate the error reporting because that will not work in functions
-- =============================================
USE master
GO
CREATE FUNCTION fn_getfiledetails 
(
@Filename sysname
)
/*
Example: select [DateLastModified] from fn_getfiledetails('c:\autoexec.bat')
*/
RETURNS 
@filedetails TABLE 
(
	[Path] VARCHAR(100),
	[ShortPath] VARCHAR(100),
	[Type] VARCHAR(100),
	[DateCreated] datetime,
	[DateLastAccessed] datetime,
	[DateLastModified] datetime,
	[Attributes] INT,
	[size] INT
)

AS
BEGIN
	DECLARE 
	@hr INT,				-- the HRESULT returned from the FileSystem object
	@objFileSystem INT,			--
	@objFile INT,				-- the File object
	@Path VARCHAR(100),			--
	@ShortPath VARCHAR(100),
	@Type VARCHAR(100),
	@DateCreated datetime,
	@DateLastAccessed datetime,
	@DateLastModified datetime,
	@Attributes INT,
	@size INT

	EXEC @hr = sp_OACreate 'Scripting.FileSystemObject', @objFileSystem OUT

	IF @hr=0 EXEC @hr = sp_OAMethod @objFileSystem, 'GetFile',  @objFile out,@Filename

	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'Path', @path OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'ShortPath', @ShortPath OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'Type', @Type OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'DateCreated', @DateCreated OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'DateLastAccessed', @DateLastAccessed OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'DateLastModified', @DateLastModified OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'Attributes', @Attributes OUT
	IF @hr=0 EXEC @hr = sp_OAGetProperty @objFile, 'size', @size OUT

	EXEC sp_OADestroy @objFileSystem
	EXEC sp_OADestroy @objFile

	INSERT @filedetails
	SELECT [Path]=  @Path,
		   [ShortPath]=    @ShortPath,
		   [Type]= @Type,
		   [DateCreated]=  @DateCreated ,
		   [DateLastAccessed]=     @DateLastAccessed,
		   [DateLastModified]=     @DateLastModified,
		   [Attributes]=   @Attributes,
		   [size]= @size
	RETURN
END       

