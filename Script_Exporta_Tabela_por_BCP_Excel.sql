exec xp_cmdshell 'bcp "select [UF],[DATA] from [db_MySQL_OCC].[dbo].[temp_tb_TempTB]" queryout "c:\teste21.xls" -c -T -S' 
go