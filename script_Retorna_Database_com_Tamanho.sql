USE master
GO
declare @base varchar(100)
declare @tb_bases table(bases varchar(100))
declare @tb_resultado table(database_name varchar(100), total_size_mb numeric(18,2))

insert into @tb_bases
			select D.name
			from master.sys.databases D
			where D.name not like '%report%'
			and D.name not like '%temp%'
			and D.name not like '%master%'
			and D.name not like '%model%'
			and D.name not like '%msdb%'

while(select top 1 1 from @tb_bases) > 0
begin
	select top 1 @base = bases from @tb_bases
	
	--print('
	insert into @tb_resultado
	exec
	('
	SELECT
	 '''+@base+''' AS database_name
	,REVERSE (SUBSTRING (REVERSE (CONVERT (VARCHAR (15), CONVERT (NUMERIC(18,2), ROUND ((A.total_size*CONVERT (BIGINT, 8192))/1048576.0, 0)), 1)), 4, 15))  AS total_size_mb
	FROM
	(
		SELECT
			 SUM (CASE
					WHEN DBF.type = 0 THEN DBF.size
					ELSE 0
					END) AS database_size
			,SUM (DBF.size) AS total_size
		FROM '+@base+'.[sys].[database_files] AS DBF
		WHERE DBF.type IN (0,1)
	) A
	CROSS JOIN
	(
		SELECT
			 SUM (AU.total_pages) AS total_pages
			,SUM (AU.used_pages) AS used_pages
			,SUM (CASE
					WHEN IT.internal_type IN (202,204) THEN 0
					WHEN AU.type <> 1 THEN AU.used_pages
					WHEN P.index_id <= 1 THEN AU.data_pages
					ELSE 0
					END) AS pages
		FROM '+@base+'.[sys].[partitions] P
		INNER JOIN '+@base+'.[sys].[allocation_units] AU ON AU.container_id = P.partition_id
		LEFT JOIN '+@base+'.[sys].[internal_tables] IT ON IT.[object_id] = P.[object_id]
	) B')
	--')
	delete from @tb_bases where bases = @base
end

select * from @tb_resultado order by total_size_mb desc