/*
Get FirstDate and LastDate of Every month from two Dates

Get FirstDate and LastDate of Every month from two Dates.
Like IF we have @date1='05/02/2015' and @date2= '11/25/2015' then we will get list of first date and last date from month 5 to 11.
SELECT ID,FirstDate,LastDate,Month,Year FROM [GetFLDatelist](@date1,@date2)

http://www.sqlservercentral.com/scripts/132664/
*/

CREATE FUNCTION [dbo].[GetFLDatelist]
(@StartDate DATE,
 @EndDate   DATE)
RETURNS @DateTable TABLE (
  ID        INT IDENTITY,
  FirstDate DATETIME,
  LastDate  DATETIME,
  [Month]   INT,
  [Year]    INT)
AS
  BEGIN
      DECLARE @EndDate1   DATE,
              @StartDate1 DATE,
              @EndDate2   DATE
      SET @StartDate1 = ( SELECT DATEADD(month, DATEDIFF(month, 1, @StartDate), 0) )
      SET @EndDate1 = ( SELECT DATEADD(s, -1, DATEADD(mm, DATEDIFF(m, 0, @StartDate) + 1, 0)) )
      SET @EndDate2 = ( SELECT DATEADD(s, -1, DATEADD(mm, DATEDIFF(m, 0, @EndDate) + 2, 0)) );
      WITH Numbers (Number) AS ( SELECT row_number()
                                          OVER (
                                            ORDER BY object_id)
                                 FROM   sys.all_objects )
      INSERT INTO @DateTable
      SELECT dateadd(month, Number - 1, @StartDate1),
             dateadd(month, Number - 1, @EndDate1),
             MONTH(dateadd(month, Number - 1, @StartDate1)),
             YEAR(dateadd(month, Number - 1, @StartDate1))
      FROM   Numbers
      WHERE  number <= datediff(month, @StartDate, @EndDate2)
      RETURN
  END
GO 
