use AdventureWorksDW2012
go
set nocount on;
go

declare @obj_name varchar(100),
		@obj_id	bigint;

IF (OBJECT_ID('tempdb..#MSdependencies') is not null)
	DROP TABLE #MSdependencies;
CREATE TABLE #MSdependencies (	
	oType		varchar(1000)	NULL,
	oObjName	varchar(1000)	NULL,
	oOwner		varchar(1000)	NULL,
	oSequence	varchar(1000)	NULL 
);

if (OBJECT_ID(N'tempdb..#Tabelas') is not null)
	drop table #Tabelas;
create table #Tabelas (
	IdTab bigint not null,
	[schema] varchar(30) not null,
	tabela varchar(100) not null,
	TemDependente bit not null default 0,
	TemDependecia bit not null default 0,
	Ordenacao int not null default -1,
	constraint pk_#tabelas primary key clustered (IdTab)
);

if (OBJECT_ID(N'tempdb..#TabelasDependentes') is not null)
	drop table #TabelasDependentes;
create table #TabelasDependentes (
	IdTabPrincipal bigint not null,
	IdTabDependente bigint not null,
	constraint pk_#TabelasDependentes primary key clustered (IdTabPrincipal, IdTabDependente)
);

IF (OBJECT_ID('tempdb..#DependeDe') is not null)
	DROP TABLE #DependeDe;
CREATE TABLE #DependeDe (	
	TableName		varchar(1000)	NULL,
	TableNameDep	varchar(1000)	NULL );

IF (OBJECT_ID(N'tempdb..#Ordenacao') is not null)
	DROP TABLE #Ordenacao;
CREATE TABLE #Ordenacao (
	TableName		varchar(100),
	OrderNo			int);

insert into #Tabelas (IdTab, [schema], tabela)
select t.object_id, SCHEMA_NAME(t.schema_id), t.name
from sys.tables t with(nolock)
where t.type = 'U';

declare cur cursor for
	select IdTab, ([schema]+'.'+tabela) as tabela
	from #Tabelas;

open cur
fetch next from cur into @obj_id, @obj_name;

while @@FETCH_STATUS = 0
begin
	truncate table #MSdependencies;

	insert into #MSdependencies
	EXEC sp_MSdependencies @obj_name, null, 1315327	-- tabelas que dependam da <tabela>
	
	insert into #TabelasDependentes (IdTabPrincipal, IdTabDependente) 
	select @obj_id, t.IdTab
	from #MSdependencies d
	join #Tabelas t
	on d.oObjName = t.tabela
	where oType = 8

	fetch next from cur into @obj_id, @obj_name;
end

close cur
deallocate cur

insert into #DependeDe (TableName, TableNameDep)
select OBJECT_NAME(t.IdTabDependente), OBJECT_NAME(t.IdTabPrincipal)
from #TabelasDependentes t

update t set t.TemDependente = 1
from #Tabelas t
where exists(
	select * from #TabelasDependentes td
	where td.IdTabPrincipal = t.IdTab
)

update t set t.TemDependecia = 1
from #Tabelas t
where exists(
	select * from #TabelasDependentes td
	where td.IdTabDependente = t.IdTab
)

insert into #Ordenacao (TableName, OrderNo)
select OBJECT_NAME(t.IdTab), 1
from #Tabelas t
where not exists( select * from #TabelasDependentes td where td.IdTabDependente = t.IdTab )


DECLARE @X INT
SET @X = 1

WHILE EXISTS ( SELECT * FROM #DependeDe )
BEGIN

	SET @X = @X + 1
	
	INSERT INTO #Ordenacao
	
	SELECT TableName, @X
	FROM #DependeDe A
	WHERE EXISTS ( SELECT * 
					 FROM #Ordenacao B
					WHERE A.TableNameDep = B.TableName )
	  
	  AND NOT EXISTS ( SELECT *
						 FROM #Ordenacao C 
						WHERE A.TableName = C.TableName )
						
	GROUP BY TableName
	HAVING COUNT(*) = ( SELECT COUNT(*) FROM #DependeDe D WHERE D.TableName = A.TableName )

	DELETE FROM #DependeDe WHERE TableName IN ( SELECT TableName FROM #Ordenacao )

END 

update t set t.Ordenacao = o.OrderNo
from #Tabelas t
join #Ordenacao o
on t.tabela = o.TableName

drop table #Ordenacao;
drop table #DependeDe;
drop table #MSdependencies;

select * 
from #Tabelas t 
order by Ordenacao

select 
	t.IdTabPrincipal, OBJECT_NAME(t.IdTabPrincipal) as Tabela, 
	t.IdTabDependente, OBJECT_NAME(t.IdTabDependente)  as TabelaDependente
from #TabelasDependentes t 
order by 1, 3
