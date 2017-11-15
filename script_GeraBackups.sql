set nocount on
go
declare @LikeBase varchar(200)			= '%%%'
declare @PathSaveBackup varchar(8000)	= '\\KCSERVER8\G\BACKUPS\KCSERVER4'

create table #fe(fe bit, fd bit, pd bit)

declare @base sysname = '',
		@arquivo varchar(8000) = '',
		@cmd varchar(max),
		@tipo varchar(15),
		@DescTipo varchar(15)
	
select name as Bases_Backups from sys.databases where database_id > 4 And name not like 'ReportServer%' and name like @LikeBase	

declare CBASES Cursor STATIC for
	select name from sys.databases 
	where database_id > 4 And name not like 'ReportServer%'
	and name like @LikeBase
	
open CBASES
fetch next from CBASES into @base

While @@FETCH_STATUS = 0 Begin
	--Set @arquivo = '\\192.168.10.120\E\backup\' + @@SERVERNAME + '\' + @base + '.bak'
	Set @arquivo = @PathSaveBackup + '\' + @base + '.bak'
	
	insert into #fe exec xp_fileexist @arquivo

	declare @fe bit = 0
	select @fe = fe from #fe
	truncate table #fe
	
	if @fe = 1 Begin
		Set @tipo = 'DIFFERENTIAL, '
		Set @DescTipo = 'Diferencial'
	End 
	Else Begin
		Set @tipo = ''
		Set @DescTipo = 'Cheio'
	End
	
	set @cmd = 
		'BACKUP DATABASE ['+@base+'] TO  DISK = N'''+@arquivo+''' 
		WITH '+@tipo+'NOFORMAT, NOINIT,  
		NAME = N''' + @base + '-'+@DescTipo+' Banco de Dados Backup'', 
		SKIP, 
		NOREWIND, 
		NOUNLOAD, 
		STATS = 10'
	--exec(@cmd)
	print(@cmd)
	print('go')
	
fetch next from CBASES into @base
End 

close CBASES
deallocate CBASES
drop table #fe