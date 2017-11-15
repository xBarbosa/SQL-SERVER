set nocount on

declare @db_name varchar(500), 
		@cmd varchar(max)

declare c_databases cursor for 
	select name from sys.databases where database_id > 4 --and right(name,2) in ('PR','RS') 

open c_databases

fetch next from c_databases into @db_name

while @@fetch_status = 0 begin
	print '/*' + @db_name + '*/'
	set @cmd = 'select  ''"'' + filename + ''"'' from ' + @db_name+ '.dbo.sysfiles'
	exec( @cmd )

	print 'EXEC sp_detach_db @dbname = '''+@db_name+''''

	fetch next from c_databases into @db_name
End

close c_databases
deallocate c_databases

set nocount off
