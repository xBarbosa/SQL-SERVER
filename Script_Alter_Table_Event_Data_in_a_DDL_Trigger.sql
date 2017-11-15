CREATE TRIGGER ColumnChanges
ON DATABASE -- ALL SERVER
FOR ALTER_TABLE
AS
-- Detect whether a column was created/altered/dropped.
SELECT EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'nvarchar(max)')
RAISERROR ('Table schema cannot be modified in this database.', 16, 1);
ROLLBACK;


