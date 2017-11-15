USE DB_TESTE;
GO
CREATE TRIGGER safety 
ON DATABASE 
FOR CREATE_TABLE 
AS 
    PRINT 'CREATE TABLE Issued.'
    SELECT EVENTDATA().value
        ('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]','nvarchar(max)')
   RAISERROR ('New tables cannot be created in this database.', 16, 1) 
   ROLLBACK
;
GO
--Test the trigger.
CREATE TABLE NewTable (Column1 int);
GO
--Drop the trigger.
DROP TRIGGER safety
ON DATABASE
GO
