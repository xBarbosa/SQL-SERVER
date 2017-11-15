/*
Drop All Temp Tables For Connection
http://www.sqlservercentral.com/scripts/drop+all+temporary+tables/132734/
*/
USE [master]
GO
--select *
--into ##tmp_mes_01
--from TEMPR_DB..MES

--CREATE PROC [dbo].[SP_DropTemp]
declare 
		@IncludeGlobal BIT = 0			--	include global temporary tables
	,	@ShowDrops BIT = 0				--	show tables that were dropped afterwards
--AS

SET NOCOUNT ON;
--
--	using a table variable so we 
--	don't try to drop ourselves.
--
DECLARE @temporaries TABLE 
(
		[ID]			INT					NOT NULL					PRIMARY KEY		IDENTITY(1, 1)
	,	[Name]			VARCHAR(2000)		NOT NULL
	,	[Command]		VARCHAR(2011)		NOT NULL
);


;	WITH [tables] AS (
		--	get all temporary tables, not global-temporary
		SELECT 
			QUOTENAME([O].[name])										AS	[Name]
		FROM 
			[TempDb].[sys].[Objects] [O]
		WHERE 
			[O].[name] LIKE '#[^#]%'
		AND OBJECT_ID('TempDb.dbo.' + [O].[name], 'U') IS NOT NULL
		UNION
		--	get all global-temporary tables
		--	when the switch is set to 1
		SELECT 
			QUOTENAME([O].[name])										AS	[Name]
		FROM 
			[TempDb].[sys].[Objects] [O]
		WHERE 
			@IncludeGlobal = 1
		AND
			[O].[name] LIKE '##%'
), [command] AS (
	SELECT
		[t].[Name]														AS	[Name]
		, 'DROP TABLE ' + [t].[Name]									AS	[Command]
	FROM
		[tables] [t]
)
INSERT INTO @temporaries
(
		[Name]
	,	[Command]
)
SELECT
		[c].[Name]														AS	[Name]
	,	[c].[Command]													AS	[Command]
FROM
	[command] [c];
--
--
-- clean up the temporary tables
--
--
DECLARE @ID INT					= 1;
DECLARE @SQL VARCHAR(2011)		= NULL;

WHILE (@ID IS NOT NULL)
BEGIN
	SELECT 
		@SQL = [t].[Command] 
	FROM 
		@temporaries t 
	WHERE 
		[t].[ID] = @ID;

	EXEC (@SQL);

	SELECT 
		@ID = MIN([t].[ID]) 
	FROM 
		@temporaries [t] 
	WHERE 
		[t].[ID] > @ID;
END
--
-- if specified then display the tables that were dropped
--
IF (@ShowDrops = 1) 
BEGIN
	SELECT 
		[t].[Name] 
	FROM 
		@temporaries [t] 
	ORDER BY 
		[t].[Name]
END
GO


