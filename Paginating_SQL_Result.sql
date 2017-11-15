/****************************************************************
Paginating a Query Result set

Greg Ryan
5/2/2014
http://www.sqlservercentral.com/scripts/T-SQL/110199/
****************************************************************/

DECLARE @pagenumber int = 1; --Page to return
DECLARE @pagesize int = 10;  --number of lines to return per page
DECLARE @total int;
WITH    Query_cte --Do your primary Query and filtering in the inner Common Table Expression
          AS ( SELECT
                    <Column1>
                ,   <Column2>
                ,   <Column3>
                ,   ROW_NUMBER() OVER ( ORDER BY <Column1> ASC ) AS line --This order by Determines your sort order
                ,   _LineCount = COUNT(*) OVER ( )
                FROM
                    dbo.<Table>
                WHERE <Column1> > 99
             )
     SELECT TOP ( @pagesize ) -- Diplay results in outer Query
            <Column1>
        ,   <Column2>
        ,   <Column3>
        ,   _LineCount
        ,   ( _LineCount / @pagesize ) _PgCount
        FROM
            Query_cte
        WHERE
            line > ( @pagenumber - 1 ) * @pagesize
        ORDER BY line --Must have an order by statement to make TOP Deterministic