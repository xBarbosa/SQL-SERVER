
SELECT referencing_schema_name, referencing_entity_name, 
 referencing_id, referencing_class_desc
FROM sys.dm_sql_referencing_entities ('dbo.hist_segurado', 'OBJECT')
GO

