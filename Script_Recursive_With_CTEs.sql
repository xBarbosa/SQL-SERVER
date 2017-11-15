WITH
cteCounter AS
(--==== Counter rCTE counts from 0 to 11
	SELECT 0 AS N      --This provides the starting point (anchor) of zero
	UNION ALL 
	SELECT N + 1       --This is the recursive part
	FROM cteCounter
	WHERE N < 60
)--==== Add the counter value to a start date and you get multiple dates

--SELECT StartOfMonth = DATEADD(mm,N,'2011')
--FROM cteCounter;

SELECT StartOfMonth = DATEADD(DD,N,'2011')--DATEADD(mm,N,'2011')
FROM cteCounter;
go
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
--===== Declare and preset some obviously named variables
DECLARE @StartYear  DATETIME,
        @Years      INT,
        @Days       INT
;
 SELECT @StartYear = '2011',
        @Years     = 1,
        @Days      = DATEDIFF(dd,@StartYear,DATEADD(yy,@Years+1,@StartYear))
;
select @StartYear as StartYear, @Years as Years, @Days as Days
--=======================================================================================
--      Demonstrate the Recursive CTE.  Don't ever use this method in production.
--      It's just too bloody slow compared to simpler methods.        
--=======================================================================================
;WITH --===== Recursive CTE
cteTally AS  --("Tally" is another name for counting things)
( --=== Counter rCTE counts from 0 to the number of days needed
 SELECT 0 AS N      --This provides the starting point (anchor) of zero
  UNION ALL 
 SELECT N + 1       --This is the recursive part
   FROM cteTally
  WHERE N < @Days - 1
) --=== Add the counter value to a start date and you get multiple dates
 SELECT WholeDate = DATEADD(dd,N  ,@StartYear),
        NextDate  = DATEADD(dd,N+1,@StartYear)
   FROM cteTally
  ORDER BY N
 OPTION (MAXRECURSION 11000) --Needed more than the default of 100
;
--=======================================================================================
--      Demonstrate the Classic Cross Join method.
--=======================================================================================
;WITH --===== Classic Cross Join method
cteTally AS
( --=== Pseudo Cursor counts from 0 to the number of days needed
 SELECT TOP (@Days)
        N = ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) -1
   FROM sys.all_columns st1
  CROSS JOIN sys.all_columns st2
)--==== Add the counter value to a start date and you get multiple dates
 SELECT WholeDate = DATEADD(dd,N  ,@StartYear),
        NextDate  = DATEADD(dd,N+1,@StartYear)
   FROM cteTally
;

--=======================================================================================
--      Demonstrate the Itzik-Style CROSS JOIN method.
--      The code is a bit complex but you could turn the CTE's into an iTVF
--      ("iTVF" = "Inline Table Valued Function")
--=======================================================================================
;WITH --===== Itzik-Style CROSS JOIN counts from 1 to the number of days needed
      E1(N) AS (
                SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
                SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL 
                SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1 UNION ALL SELECT 1
               ),                          -- 1*10^1 or 10 rows
      E2(N) AS (SELECT 1 FROM E1 a, E1 b), -- 1*10^2 or 100 rows
      E4(N) AS (SELECT 1 FROM E2 a, E2 b), -- 1*10^4 or 10,000 rows
      E8(N) AS (SELECT 1 FROM E4 a, E4 b), -- 1*10^8 or 100,000,000 rows
cteTally(N) AS (SELECT TOP (@Days) ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) FROM E8)
 SELECT WholeDate = DATEADD(dd,N-1,@StartYear),
        NextDate  = DATEADD(dd,N  ,@StartYear)
   FROM cteTally
;


