--http://www.patrickkeisler.com/2013/01/how-to-remove-undo-table-partitioning.html

SELECT
     SCHEMA_NAME(t.schema_id) AS SchemaName
    ,OBJECT_NAME(i.object_id) AS ObjectName
    ,p.partition_number AS PartitionNumber
    ,fg.name AS Filegroup_Name
    ,rows AS 'Rows'
    ,au.total_pages AS 'TotalDataPages'
    ,CASE boundary_value_on_right
        WHEN 1 THEN 'less than'
        ELSE 'less than or equal to'
     END AS 'Comparison'
    ,value AS 'ComparisonValue'
    ,p.data_compression_desc AS 'DataCompression'
    ,p.partition_id
FROM sys.partitions p
    JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
    JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
    JOIN sys.partition_functions f ON f.function_id = ps.function_id
    LEFT JOIN sys.partition_range_values rv ON f.function_id = rv.function_id AND p.partition_number = rv.boundary_id
    JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND dds.destination_id = p.partition_number
    JOIN sys.filegroups fg ON dds.data_space_id = fg.data_space_id
    JOIN (SELECT container_id, sum(total_pages) as total_pages
            FROM sys.allocation_units
            GROUP BY container_id) AS au ON au.container_id = p.partition_id  
    JOIN sys.tables t ON p.object_id = t.object_id
WHERE i.index_id < 2
ORDER BY ObjectName,p.partition_number;
GO