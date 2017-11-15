--initialize transaction
set transaction isolation level read uncommitted
set nocount on

--initial declarations
declare @rowID int, @maxRowID int
declare @sql nvarchar(4000)
declare @searchValue varchar(100)
declare @statements table (rowID int, SQL varchar(8000))
create table #results (tableName varchar(250), tableSchema varchar(250), columnName varchar(250))

set @rowID = 1
set @searchValue = 'numero'

--create CTE table holding metadata
;with MyInfo (tableName, tableSchema, columnName) as (
select table_name, table_schema, column_name from information_schema.columns where data_type not in ('image','text','timestamp','binary','uniqueidentifier')
)

--create search strings
insert into @statements
select row_number() over (order by tableName, columnName) as rowID, 'insert into #results select distinct '''+tableName+''', '''+tableSchema+''', '''+columnName+''' from ['+tableSchema+'].['+tableName+'] where convert(varchar,['+columnName+']) like ''%'+@searchValue+'%''' from myInfo

--initialize while components and process search strings
select @maxRowID = max(rowID) from @statements
while @rowID <= @maxRowID
 begin
 select @sql = sql from @statements where rowID = @rowID
 exec sp_executeSQL @sql
 set @rowID = @rowID + 1
 end

--view results and cleanup
select * from #results
drop table #results





