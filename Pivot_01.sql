/*
USE master

IF OBJECT_ID('Tempdb.dbo.#NOMES ') IS NOT NULL DROP TABLE #NOMES 
GO

CREATE TABLE #NOMES  (ID INT,NOME VARCHAR(20))
GO

INSERT INTO #NOMES  (ID,NOME)
VALUES
(1,'ROGERIO')
,(1,'PRATA')
,(1,'GUSTAVO')
,(2,'EDUARDO')
,(2,'TIAGO')
,(2,'LUCI')

--DROP TABLE NOMES
SELECT * FROM #NOMES 

SELECT MAIN.ID, 
       LEFT(MAIN.STUDENTS,LEN(MAIN.STUDENTS)-1) AS "STUDENTS" 
FROM (

	SELECT DISTINCT ST2.ID,  
			-- coluna student
           (SELECT ST1.NOME + ',' AS [text()] 
            FROM #NOMES  ST1 
            WHERE ST1.ID = ST2.ID
            ORDER BY ST1.ID 
            FOR XML PATH ('')) [STUDENTS] 
            -- coluna student
      FROM #NOMES  ST2

) [MAIN] 