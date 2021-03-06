--delete from [SOFTTEK_CONTROLE_MODELADO].[dbo].[sysssislog]

select 
	MIN(id) as id
	,[event], [sourceid], [source], min([starttime]) [starttime], max([endtime]) [endtime]
	,Col01, Col02, Col03, Col04, Col05, Col06, Col07, Col08
	,sum(cast(Col09 as bigint)) as Col09
from (
	select 
	ID, [event], [sourceid], [source], [starttime], [endtime],
	xmlname.value('/Names[1]/name[1]','varchar(200)') AS Col01,    
	 xmlname.value('/Names[1]/name[2]','varchar(200)') AS Col02,
	 xmlname.value('/Names[1]/name[3]','varchar(200)') AS Col03,
	 xmlname.value('/Names[1]/name[4]','varchar(200)') AS Col04,
	 xmlname.value('/Names[1]/name[5]','varchar(200)') AS Col05,
	 xmlname.value('/Names[1]/name[6]','varchar(200)') AS Col06,
	 xmlname.value('/Names[1]/name[7]','varchar(200)') AS Col07,
	 xmlname.value('/Names[1]/name[8]','varchar(200)') AS Col08,
	xmlname.value('/Names[1]/name[9]','varchar(200)')  AS Col09
	from (
		SELECT [id]
			  ,[event]
			  ,[source]
			  ,[sourceid]
			  ,[starttime]
			  ,[endtime]
			  ,[message]
			  ,case 
				when [event] = 'OnPipelineRowsSent' then CONVERT(XML,'<Names><name>' + REPLACE([message],':', '</name><name>') + '</name></Names>') 
				else ''
				end
			  AS xmlname
			  --delete 
		  FROM [SOFTTEK_CONTROLE_MODELADO].[dbo].[sysssislog]
	) xx
) qq  
group by 
[event], [sourceid], [source]
,Col01, Col02, Col03, Col04, Col05, Col06, Col07, Col08
order by id
  
--DECLARE @VAR VARCHAR(8000) = 'Rows were provided to a data flow component as input. :  : 133 : Flat File Source Output : 62 : Data Conversion : 63 : Data Conversion Input : 213'
--select @VAR


-- SELECT --Value,      
-- xmlname.value('/Names[1]/name[1]','varchar(200)') AS Col01,    
-- xmlname.value('/Names[1]/name[2]','varchar(200)') AS Col02,
-- xmlname.value('/Names[1]/name[3]','varchar(200)') AS Col03,
-- xmlname.value('/Names[1]/name[4]','varchar(200)') AS Col04,
-- xmlname.value('/Names[1]/name[5]','varchar(200)') AS Col05,
-- xmlname.value('/Names[1]/name[6]','varchar(200)') AS Col06,
-- xmlname.value('/Names[1]/name[7]','varchar(200)') AS Col07,
-- xmlname.value('/Names[1]/name[8]','varchar(200)') AS Col08,
-- xmlname.value('/Names[1]/name[9]','varchar(200)') AS Col09
-- FROM (
--	SELECT CONVERT(XML,'<Names><name>' + REPLACE(@VAR,':', '</name><name>') + '</name></Names>') AS xmlname
-- ) as XX