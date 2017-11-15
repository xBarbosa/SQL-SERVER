-- Zera os contadores ************************
--DBCC FREEPROCCACHE;
-- *******************************************
SELECT 
	DB_NAME(database_id)								as DBName, 
	OBJECT_NAME(object_id)								as SPName,
	datediff(second, last_execution_time, getdate())	as SecondsAgo, 
	last_execution_time									as LastExecDate,
	CASE WHEN execution_count = 0 THEN '--' ELSE
	RIGHT('0'+convert(varchar(5),(total_elapsed_time/(1000000*execution_count))/3600),2)+':'+ 
	RIGHT('0'+convert(varchar(5),(total_elapsed_time/(1000000*execution_count))%3600/60),2)+':'+ 
	RIGHT('0'+convert(varchar(5),((total_elapsed_time/(1000000*execution_count))%60)),2) END 
														as ReadableTime, 
	CASE WHEN execution_count= 0 THEN 0 ELSE total_elapsed_time/(1000*execution_count) END 
														as AvgTimeMS,
	CASE WHEN execution_count= 0 THEN 0 ELSE total_worker_time/(1000*execution_count) END 
														as AvgTimeCPU,
	last_elapsed_time/1000								as LastTimeMS,
	min_elapsed_time/1000								as MinTimeMS,
	total_elapsed_time/1000								as TotalTimeMS,
	CASE WHEN DATEDIFF(second, s.cached_time, GETDATE()) < 1 THEN 0 ELSE
	cast(execution_count as decimal) / cast(DATEDIFF(second, s.cached_time, GETDATE()) as decimal) END 
														as ExecPerSecond,
	execution_count										as TotalExecCount, 
	last_worker_time/1000								as LastWorkerCPU,
	last_physical_reads									as LastPReads,
	max_physical_reads									as MaxPReads,
	last_logical_writes									as LastLWrites,
	last_logical_reads									as LastLReads 
FROM sys.dm_exec_procedure_stats s 
WHERE 
	database_id = DB_ID() 
AND last_execution_time > dateadd(day, -7, getdate())
ORDER BY 6 desc, 3
