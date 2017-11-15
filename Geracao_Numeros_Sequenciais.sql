WITH Number
     AS (SELECT 1 AS n
         UNION ALL
         SELECT n + 1
         FROM   Number
         WHERE  n < 10000)
         
SELECT n
FROM   Number
OPTION ( MAXRECURSION 10000 ); 