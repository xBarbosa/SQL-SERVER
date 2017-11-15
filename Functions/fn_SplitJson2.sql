/*
http://weblogs.asp.net/bleroy/archive/2008/01/18/dates-and-json.aspx
http://www.sqlservercentral.com/articles/JSON/68128/

Options
The @Option parameter is used to change default settings when the function is run. They are passed into the function using the JSON object format.

-------------------------------------------------------------------------------------------------------------------------------------------------
|NAME			|DATATYPE	|DEFAULT	|DESCRIPTION																							|
-------------------------------------------------------------------------------------------------------------------------------------------------
|dateStyle		|int		|121		|The style number used by the T_SQL CONVERT function. 121 =yyyy-mm-dd hh:mi:ss.mmm(24h).				|
|				|			|			|This is used when decoding \/DATE(n)\/.																|
-------------------------------------------------------------------------------------------------------------------------------------------------
|idStart		|int		|1			|The starting value for the id column.																	|
-------------------------------------------------------------------------------------------------------------------------------------------------
|idStep			|int		|1			|The integer value to add to the last value inserted into the id column.								|
-------------------------------------------------------------------------------------------------------------------------------------------------
|debug			|bit		|0			|If 1 then the option settings are inserted into the returned table.									|
|				|			|			|The id values are negative offset from the idStart value.												|
-------------------------------------------------------------------------------------------------------------------------------------------------
|removeQuotes	|bit		|1			|If removeQuotes =1 and surrounding double quotes are detected, then the surrounding double quotes are	|
|				|			|			|removed and the control pattern \" is replaced with a ".												|
-------------------------------------------------------------------------------------------------------------------------------------------------
|splitChar		|nchar(1)	|,(comma)	|The JSON format uses a comma for the character to split on. The splitChar option allows you to specify |
|				|			|			|a different character to split on.																		|
-------------------------------------------------------------------------------------------------------------------------------------------------
|verbose		|int		|1			|Sets the level of messages displayed.																	|
|				|			|			|0 = no messages																						|
|				|			|			|1 = error messages																						|
-------------------------------------------------------------------------------------------------------------------------------------------------

#################################################################################################################################################
Exemplo:
SELECT id, name, value FROM dbo.fn_SplitJson2('{Apples:20000,Oranges:400,Apricots:507}',NULL)
#################################################################################################################################################
Exemplo:
idStart and idStep Settings
In this example the start value for the id column is set to 10 and each following id value increments by 3.

SELECT id, value FROM dbo.fnSplitJson2('[Apples,Oranges,Apricots,Grapes]', '{idStart:10,idStep:3}')
#################################################################################################################################################
*/


IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.fn_SplitJson2') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION dbo.fn_SplitJson2
GO

SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION dbo.fn_SplitJson2 
( @InputString nvarchar(max)
, @Options nvarchar(1023) = NULL
)  
RETURNS @tbl TABLE
( id int, name nvarchar(255), value nvarchar(max), offset int, length int
, colon int, nested int, errcnt int, msg varchar(8000)
)
AS
/*-------------------------------------------------------------------------------------------------
author: Ric Vander Ark 2007-2009
released under Microsoft Public License (Ms-PL) in August 2009
-------------------------------------------------------------------------------------------------*/
BEGIN 
DECLARE 
  @NestedObjectCount int = 0
, @NestedArrayCount int = 0
, @LENInputString as int
, @removeQuotes bit = 1
, @NestedObject int = 0
, @NestedArray int = 0
, @ValueFlag bit = 0
, @splitChar nchar(1) = ','
, @LTrimFlag bit = 0
, @trimchars nvarchar(20) = NCHAR(9) + NCHAR(10) + NCHAR(13) + NCHAR(32)
, @JsonType int
, @dateStyle int = 121
, @instring bit = 0
, @InObject bit = 0
, @errcount int = 0
, @verbose int = 1
, @InArray bit = 0
, @idStart int = 1
, @idStep int = 1
, @msgcnt int = 0
, @nested int = 0
, @dbase datetime2 = '1970-01-01'
, @debug bit = 0
, @value nvarchar(max) = ''
, @colon int
, @name nvarchar(255)
, @btmp varbinary(255)
, @crlf nchar(2) = NCHAR(13) + NCHAR(10)
, @etx nchar(1) = NCHAR(3)
, @tmp nvarchar(255)
, @msg varchar(8000) = ''
, @sec int
, @c2i int
, @c2 nchar(1)
, @ms int
, @p0 int
, @p1 int
, @p2 int
, @c nchar(1)
, @d datetime2(3) 
, @w int
IF(@Options IS NOT NULL)
BEGIN
	SELECT @dateStyle = CASE WHEN name = 'dateStyle' AND ISNUMERIC(value) = 1 THEN value ELSE @dateStyle END
	, @debug = CASE WHEN name = 'debug' AND ISNUMERIC(value) = 1 THEN value ELSE @debug END
	, @idStart = CASE WHEN name = 'idStart' AND ISNUMERIC(value) = 1 THEN value ELSE @idStart END
	, @idStep = CASE WHEN name = 'idStep' AND ISNUMERIC(value) = 1 THEN value ELSE @idStep END
	, @RemoveQuotes = CASE WHEN name = 'removeQuotes' AND ISNUMERIC(value) = 1 THEN value ELSE @RemoveQuotes END
	, @splitChar = CASE WHEN name = 'splitChar' THEN value ELSE @splitChar END
 	, @verbose = CASE WHEN name = 'verbose' AND ISNUMERIC(value) = 1 THEN value ELSE @verbose END
	FROM dbo.fn_SplitJson2(@Options, NULL);
END
IF(@debug= 1)
BEGIN
	INSERT @tbl(id, name, value, offset, length, colon, nested, errcnt, msg)
	VALUES	( ( @idStart - 10), 'version', 'SS2008 V1.0  Aug 2009', -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 9), 'author', 'Ric Vander Ark', -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 8), 'license', 'Microsoft Public License (Ms-PL)', -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 7), 'verbose', CAST(@verbose AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 6), 'splitChar', @splitChar , -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 5), 'removeQuotes', CAST(@removeQuotes AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 4), 'idStep', CAST(@idStep AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 3), 'idStart', CAST(@idStart AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 2), 'debug', CAST(@debug AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
	, ((@idStart - 1), 'dateStyle', CAST(@dateStyle AS varchar(11)), -1, -1, -1, 0, 0, 'Option Debug')
END

SELECT @InputString = REVERSE(STUFF(@InputString, 1, PATINDEX('%[^' + @trimchars + ']%', @InputString)-1,''))
, @InputString = REVERSE(STUFF(@InputString, 1, PATINDEX('%[^' + @trimchars + ']%', @InputString)-1,''));

IF(@InputString IS NULL OR LEN(@InputString) = 0) RETURN;

SELECT @JsonType = CASE WHEN ('{' = LEFT(@InputString, 1) AND '}' = RIGHT(@InputString, 1)) THEN 1
WHEN ('[' = LEFT(@InputString, 1) AND ']' = RIGHT(@InputString, 1)) THEN 2
ELSE 0 END

IF(@JsonType NOT IN (1,2))
BEGIN
	INSERT @tbl(id, name, value, offset, length, colon, nested, errcnt, msg)
	SELECT @idStart, @name, @InputString, -1, -1, -1, 0, 1, 'JSON type could not be determined'
	RETURN;
END
SELECT @InputString = LTRIM(RTRIM(SUBSTRING(@InputString, 2, LEN(@InputString)-2)))
SELECT @InputString = REVERSE(STUFF(@InputString, 1, PATINDEX('%[^' + @trimchars + ']%', @InputString)-1,''))
SELECT @InputString = REVERSE(STUFF(@InputString, 1, PATINDEX('%[^' + @trimchars + ']%', @InputString)-1,''))  + @etx
, @w = 0, @p0 = 1, @p1 = 1, @p2 = 0
, @LENInputString = LEN(@InputString)

WHILE (@p2 <= @LENInputString)
BEGIN
    SELECT @p2 += 1
    SELECT @c = SUBSTRING(@InputString, @p2, 1)
    IF(@LTrimFlag = 1)
    BEGIN
		IF(CHARINDEX(@c, @trimchars) > 0) 
		BEGIN
			SELECT @p0 += 1, @p1 += 1
			CONTINUE;
		END
		SET @LTrimFlag = 0;
    END
    
    IF(@c = '"' AND @NestedArray = 0 AND @NestedObject = 0)
    BEGIN
        IF(@instring = 1)
        BEGIN   
            IF(SUBSTRING(@InputString, @p2 - 1, 1) = '\')
			BEGIN   
				CONTINUE;-- move on to the next
			END
            SELECT @instring = 0;
        END
        ELSE
        BEGIN
            SELECT @instring = 1, @LTrimFlag = 0;
        END
        CONTINUE;
    END
    
    IF(@InString = 0)
	BEGIN
		SELECT @NestedObject += CASE @c WHEN '{' THEN 1 WHEN '}' THEN CASE @NestedObject WHEN 0 THEN 0 ELSE -1 END ELSE 0 END
		, @NestedObjectCount += CASE @c WHEN '{' THEN 1 ELSE 0 END
		, @NestedArray += CASE @c WHEN '[' THEN 1 WHEN ']' THEN CASE @NestedArray WHEN 0 THEN 0 ELSE -1 END ELSE 0 END
		, @NestedArrayCount += CASE @c WHEN '[' THEN 1 ELSE 0 END
	END
    IF(@instring != 0 OR @NestedArray > 0 OR @NestedObject > 0) CONTINUE;

    
    
    IF(@c = '{' AND @InObject = 0)
    BEGIN
        IF(SUBSTRING(@InputString, @p2 - 1, 1) <> '\')
        BEGIN   
             SELECT @InObject = 1, @LTrimFlag = 0;
        END
        CONTINUE;
    END
    IF(@InObject = 1) 
    BEGIN
        IF(@c = '}' AND SUBSTRING(@InputString, @p2 - 1, 1) <> '\')
        BEGIN
            SELECT @InObject = 0;
        END
        CONTINUE;
    END
            
    IF(@c = '[' AND @InArray = 0)
    BEGIN
		IF(SUBSTRING(@InputString, @p2 - 1, 1) <> '\')
		BEGIN   
			SELECT @InArray = 1, @LTrimFlag = 0;
		END
		CONTINUE;
    END
    IF(@InArray = 1) 
    BEGIN
        IF(@c = ']' AND SUBSTRING(@InputString, @p2 - 1, 1) <> '\')
        BEGIN
			SELECT @InArray = 0;
        END
        CONTINUE;
    END
    
    IF(@c = '\')
    BEGIN
		SELECT @c2 = SUBSTRING(@InputString, @p2 + 1, 1), @c2i = ASCII(@c2);
	
		IF(@c2i IN (34,92,98,102,110,114,116)) 
		BEGIN 
			SELECT @value += SUBSTRING(@InputString, @p1, @p2 - @p1)
			+ CASE @c2i 
			WHEN 98 THEN CHAR(8)--  8 'b' backspace 
			WHEN 102 THEN CHAR(12)-- 12 'f' formfeed
			WHEN 110 THEN CHAR(10)-- 10 'n' newline		
			WHEN 114 THEN CHAR(13)-- 13 'r' carriage return
			WHEN 116 THEN CHAR(9)--  9 't' tab (horizontal)
			ELSE @c2 END  -- 34 '"'  92 '\'
			, @p2 += 2 
			, @p1 = @p2;
			CONTINUE; 
		END 

		IF(@c2i = 117) -- 'u' 4 digit hex follows
		BEGIN
 			SELECT @btmp = CONVERT(varbinary(8), SUBSTRING(@InputString, @p2 + 2, 4), 0) -- get hex value
			SELECT @value += SUBSTRING(@InputString, @p1, @p2 - @p1)
			+ NCHAR(
			(CAST( SUBSTRING(@btmp, 1,1) AS int) - 
			CASE WHEN (SUBSTRING(@btmp, 1,1)) <= 0x39 THEN 48 
			WHEN (SUBSTRING(@btmp, 1,1)) <= 0x5A THEN 55 
			ELSE 87 END) * 4096

			+ (CAST( SUBSTRING(@btmp, 3,1) AS int) - 
			CASE WHEN (SUBSTRING(@btmp, 3,1)) <= 0x39 THEN 48 
			WHEN (SUBSTRING(@btmp, 3,1)) <= 0x5A THEN 55 
			ELSE 87 END) * 256
			
			+ (CAST( SUBSTRING(@btmp, 5,1) AS int) - 
			CASE WHEN (SUBSTRING(@btmp, 5,1)) <= 0x39 THEN 48 
			WHEN (SUBSTRING(@btmp, 5,1)) <= 0x5A THEN 55 
			ELSE 87 END)* 16
			
			+ (CAST( SUBSTRING(@btmp, 7,1) AS int) - 
			CASE WHEN (SUBSTRING(@btmp, 7,1)) <= 0x39 THEN 48 
			WHEN (SUBSTRING(@btmp, 7,1)) <= 0x5A THEN 55 
			ELSE 87 END) 
			)
 			SELECT @p2 += 5, @p1 = @p2 + 1; 

			CONTINUE; 
		END 
		
		IF(@c2i = 47) -- '/' interpret \/
		BEGIN 
			IF(SUBSTRING(@InputString, @p2, 7) = '\/DATE(')
			BEGIN
				IF(SUBSTRING(@InputString, @p2 + 20, 3) != ')\/')
				BEGIN
					IF(@verbose > 0)
					BEGIN
						SELECT @w = CHARINDEX(')\/', SUBSTRING(@InputString, @p2, 30), 1) 
						SELECT @msgcnt += 1
						, @msg += @crlf + CAST(@msgcnt as varchar(11)) + ') '
						+ CASE WHEN @w = 0 THEN ' "\/DATE(" found at position ' + CAST(@p2 - @p1 + 1 as varchar(11)) + ' but closing ")\/" was not found.'
						ELSE ' "\/DATE(" found at position' + CAST(@p2 - @p1 + 1 as varchar(11)) + ' but the date is not 13 numeric characters.'
						END
					END
					SELECT @value += SUBSTRING(@InputString, @p1, @p2 - @p1) 
					+ '\/DATE(', @p2 += 7, @p1 = @p2, @errcount += 1 ;
					CONTINUE; 
				END 
				SELECT @tmp = SUBSTRING(@InputString, @p2 + 7, 13)
				IF(ISNUMERIC(@tmp) = 0 )
				BEGIN
					IF(@verbose > 0)
					BEGIN
						SELECT @msgcnt += 1
						, @msg += @crlf + CAST(@msgcnt as varchar(11)) + ') "\/DATE(" found at position ' + CAST(@p2 - @p1 + 1 as varchar(11)) 
						+ '  but the date is not 13 numeric characters.'
						END
					SELECT @value += CASE WHEN @p2=@p1 THEN '' ELSE SUBSTRING(@InputString, @p1, @p2 - @p1) END
					+ '\/DATE(', @p2 += 7, @p1 = @p2, @errcount += 1 ;
					CONTINUE; 
				END
				
				SELECT @sec = CAST(LEFT(@tmp, 10) AS int)
				, @ms = CAST(RIGHT(@tmp, 3) AS int)
				, @tmp = '';
				SELECT @d = DATEADD(millisecond, @ms, DATEADD(second, @sec, @dbase) )
				SET @value += CASE WHEN @p2=@p1 THEN '' ELSE SUBSTRING(@InputString, @p1, @p2 - @p1) END 
				SET @value += CONVERT(nvarchar(50), @d, @dateStyle)
				SELECT @p2 += 22, @p1 = @p2 + 1; 
				
				CONTINUE; 
			END
			
			SELECT @p2 += 2 ; CONTINUE; 	
		END --  @c2i = 47 = '/' interpret \/
		
		IF(@verbose > 0)
		BEGIN
			SELECT @msgcnt += 1, @msg += @crlf 
			+ CAST(@msgcnt as varchar(11)) + ') Unresolved ' + @c + @c2 + ' at position ' + CAST((@p2 - @p1 + 1) as varchar(11))
		END
		SELECT @errcount += 1, @p2 += 2 ; CONTINUE; 
    END -- '\'
    
    IF(@c = @splitChar OR @c = @etx)
    BEGIN
    	IF @NestedObjectCount != 0 AND @verbose > 1
		BEGIN 
			SELECT @msgcnt += 1
			, @msg += @crlf 
			+ CAST(@msgcnt as varchar(11)) + ') ' + CAST(@NestedObjectCount as varchar(11)) + ' nested Object' 
			+ CASE WHEN @NestedObjectCount > 1 then 's' ELSE '' END  + ' found.'
		END
		
		IF @NestedArray != 0
		BEGIN 
			SELECT @errcount += 1
			IF @verbose > 0
			BEGIN
				SELECT @msgcnt += 1
				, @msg += @crlf 
				+ CAST(@msgcnt as varchar(11)) + ') ' + CAST(@NestedArray as varchar(11)) + ' nested Array missing closing ]' 
			END			
		END
		
		IF @NestedObjectCount != 0 AND @verbose > 1
		BEGIN 
			SELECT @msgcnt += 1
			, @msg += @crlf 
			+ CAST(@msgcnt as varchar(11)) + ') ' + CAST(@NestedObjectCount as varchar(11)) + ' nested Object' 
			+ CASE WHEN @NestedObjectCount > 1 then 's' ELSE '' END  + ' found.'
		END

		IF @NestedObject != 0
		BEGIN 
			SELECT @errcount += 1
			IF @verbose > 0
			BEGIN
				SELECT @msgcnt += 1
				, @msg += @crlf 
				+ CAST(@msgcnt as varchar(11)) + ') ' + CAST(@NestedObject as varchar(11)) + ' nested Object missing closing ]' 
			END
		END
    
		SELECT @w = @p2 - @p1 -- this removes blank entries
		, @nested = @NestedObjectCount + @NestedArrayCount
		, @msg = CASE WHEN @msgcnt = 0 THEN @msg ELSE CAST(@msgcnt AS varchar(11)) + ' messages. ' + @msg END
		
		IF(@w > 0 OR @name IS NOT NULL)
		BEGIN
			IF(@JsonType = 1 AND @name IS NULL)
			BEGIN
				SELECT @name = SUBSTRING(@InputString, @p1, @w )
				, @value = '' 
			END
			ELSE 
			BEGIN
				SELECT @value += SUBSTRING(@InputString, @p1, @w )
			END
		END
		SELECT @value = REVERSE(STUFF(@value, 1, PATINDEX('%[^' + @trimchars + ']%', @value)-1,''))
		SELECT @value = REVERSE(STUFF(@value, 1, PATINDEX('%[^' + @trimchars + ']%', @value)-1,'')) 
		
		IF(@RemoveQuotes <> 0)
		BEGIN
			IF(LEFT(@name, 1) = '"' AND RIGHT(@name, 1) = '"')
			BEGIN
				SELECT @name = REPLACE(SUBSTRING(@name, 2, LEN(@name) - 2), '\"', '"')
			END
			IF(LEFT(@value, 1) = '"' AND RIGHT(@value, 1) = '"')
			BEGIN
				SELECT @value = REPLACE(SUBSTRING(@value, 2, LEN(@value) - 2), '\"', '"')
			END
		
		END
		
		INSERT @tbl(id, name, value, offset, length, colon, nested, errcnt, msg)
		SELECT @idStart, @name, @value, @p0, (@p2 - @p0), @colon, @nested, @errcount, @msg
		SELECT @idStart += @idStep
		, @p1 = @p2 + 1, @p0 = @p1, @name = NULL, @value = '' , @ValueFlag = 0, @InArray = 0, @InObject = 0
		, @LTrimFlag = 1, @colon = null, @nested = 0, @errcount = 0, @msg = '', @msgcnt = 0
	, @NestedObjectCount = 0, @NestedArrayCount = 0
	, @NestedObject = 0, @NestedArray = 0;

		CONTINUE;       
    END
    
    IF(@c = ':' AND @JsonType = 1 AND @ValueFlag = 0)
    BEGIN
        SELECT @name = SUBSTRING(@InputString, @p1, @p2-@p1)
		SELECT @name = REVERSE(STUFF(@name, 1, PATINDEX('%[^' + @trimchars + ']%', @name)-1,''))
		SELECT @name = REVERSE(STUFF(@name, 1, PATINDEX('%[^' + @trimchars + ']%', @name)-1,'')) 
        SELECT @colon = @p2 - @p0 + 1, @ValueFlag = 1
        , @LTrimFlag = 1, @p1 = @p2 + 1;
        CONTINUE;
    END
END

RETURN 
END

GO

