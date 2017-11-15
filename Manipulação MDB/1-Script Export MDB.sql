USE db_MySql_RMCA

DECLARE @path varchar(400)
DECLARE @Tabela1 varchar(100)
DECLARE @TabelaMDB varchar(100)
DECLARE @cmd1 varchar(max)
declare @filial varchar(2)

select name, 0 aux into #temp from sys.tables where name like 'tb_Convenio%_Reprecessado' order by name

set @TabelaMDB = 'tb_convenio'

while (select top 1 1 from #temp where aux = 0) > 0 begin
	select top 1 @Tabela1 = name from #temp where aux = 0
	
	set @filial = SUBSTRING(@Tabela1,12,2)	
	
	PRINT '######################'
	PRINT @filial
	PRINT '######################'
	
	SELECT 
		@path	 = '\\192.168.10.105\publico\BIBLIOTECA_TIM\Projeto STDF Legado\2ª Fase\Operacional\MDB\MDBs STDF final\mdb_convenio_'+@filial+'.mdb',
		@cmd1	 = 'select * from db_MySql_RMCA.dbo.'+@Tabela1

	EXEC [db_ProjetoOCC].[dbo].[usp_ExportMDB] @path, 1, @TabelaMDB, @cmd1

	update #temp set aux = 1 where name = @Tabela1	
end

drop table #temp
go