-- Get all columns & data types for a table
USE SPED_ESTUDO
GO
DECLARE @TABELA VARCHAR(200) = 'TS_USUARIOS'

SELECT distinct 
sysobjects.name as 'Table',
syscolumns.colid ,
'[' + syscolumns.name + ']' as 'ColumnName',
'@'+syscolumns.name  as 'ColumnVariable',
systypes.name +	Case  
				When  systypes.xusertype in (165,167,175,231,239 ) 
				Then '(' + Convert(varchar(10),syscolumns.length) +')' 
				Else '' 
				end   as 'DataType' ,
'@'+syscolumns.name  + '  ' + systypes.name + Case  
												When  systypes.xusertype in (165,167,175,231,239 )
												Then '(' + Convert(varchar(10),syscolumns.length) +')' 
												Else '' 
												end as 'ColumnParameter'
From    sysobjects , syscolumns ,  systypes
Where   1=1
and sysobjects.id        = syscolumns.id
and syscolumns.xusertype = systypes.xusertype
and sysobjects.xtype     = 'u'
and sysobjects.name      = @TABELA
Order by syscolumns.colid