--http://www.sqlservercentral.com/scripts/Search+Field+In+Table/104101/

Declare @TableNameParameter Nvarchar(200)='UserInfo' --Nome da tabela que deverá ser pesquisada
Declare @FieldNameParameterTable  Table (FieldsName Nvarchar(200))
Insert into @FieldNameParameterTable(FieldsName) values ('UserName'),('Password') --Nome das colunas a serem pesquisadas



DECLARE @TempDatabases Table 
(
	id int primary key identity(1,1),
	databaseId int,
	DatabaseName nvarchar(100),
	RowNumber int
)


Insert into @TempDatabases(databaseId,DatabaseName,RowNumber)
Select database_id,Name,ROW_NUMBER()over(order by database_id)
	FROM SYS.databases
	WHERE name NOT IN ('master', 'tempdb', 'model', 'msdb','ReportServer','ReportServerTempDB')
	
	Declare @CountDatabase int
	Select @CountDatabase=COUNT(*) from 	@TempDatabases

	Declare @QueryListTableInDatabase nvarchar(max)
	set @QueryListTableInDatabase=''
	Declare @QueryColumns nvarchar(Max)=''
Declare @iteratorDatabase int=1
	while(@iteratorDatabase<=@CountDatabase)
		begin
			Declare @CurrentDatabaseName nvarchar(200)
				Select @CurrentDatabaseName=DatabaseName
					from @TempDatabases
						where RowNumber=@iteratorDatabase
				
				
				Set @QueryListTableInDatabase=@QueryListTableInDatabase+' Select '''+@CurrentDatabaseName+''' ,Name from '+@CurrentDatabaseName+'.sys.tables  Where Type=''U''  Union All  '
				Set @QueryColumns=@QueryColumns+' SELECT TABLE_CATALOG,TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME FROM '+@CurrentDatabaseName+'.INFORMATION_SCHEMA.COLUMNS Where Table_Name='''+@TableNameParameter+'''  Union '
				
				
			Set @iteratorDatabase=@iteratorDatabase+1
		End
	
	Set @QueryColumns=SUBSTRING(@QueryColumns,0,len(@QueryColumns)-5)
	
	
DECLARE @TempTable Table 
(
	RowId int primary key identity(1,1),
	DatabaseName nvarchar(100),
	TABLE_SCHEMA nvarchar(100),
	TABLE_NAME nvarchar(100),
	COLUMN_NAME nvarchar(100),
	Value nvarchar(200)
)
	
	Insert into @TempTable(DatabaseName,TABLE_SCHEMA,TABLE_NAME,COLUMN_NAME)
	exec Sp_Executesql @QueryColumns
	
	Delete from @TempTable
	where COLUMN_NAME Not In (Select * from @FieldNameParameterTable)
	
	
	
	
	Declare @CountRecordTable int
	Declare @Iterator int=1
				
	Select @CountRecordTable=COUNT(*)
		from @TempTable
		
		
		Declare @Query nvarchar(max)=''
		Declare @UpdateQuery nvarchar(max)=''
		while(@Iterator<=@CountRecordTable)
			begin
				
				Declare @CurrentDatabaseName1 nvarchar(100)
				Declare @CurrentTABLE_SCHEMA nvarchar(100)
				Declare @CurrentTABLE_NAME nvarchar(100)
				Declare @CurrentCOLUMN_NAME nvarchar(100)
				Select  @CurrentDatabaseName1=DatabaseName,
						@CurrentTABLE_SCHEMA=TABLE_SCHEMA,
						@CurrentTABLE_NAME=TABLE_NAME,
						@CurrentCOLUMN_NAME=COLUMN_NAME
						From @TempTable
						where RowId=@Iterator
						
					Set @Query='Select '+@CurrentCOLUMN_NAME 
								+' from  '+	@CurrentDatabaseName1+'.'+@CurrentTABLE_SCHEMA+'.'+@CurrentTABLE_NAME 
							
						
						
					
				Declare  @TempValue Table(value nvarchar(200))	
				Delete from @TempValue
				insert into @TempValue(value)
				exec Sp_Executesql @Query
																									
					
					Update  @TempTable 
						Set Value=(Select top(1) value from @TempValue)
						where RowId=@Iterator
					
			Set @Iterator=@Iterator+1
			End
		
		
		Select * from @TempTable
		
	
		

