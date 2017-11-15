use AdventureWorks;
go

if exists 
(
    select * 
        from sys.objects 
        where 
            [object_id] = object_id(N'[dbo].[usp_generate_inserts]') 
            and type in (N'P', N'PC')
)
    drop proc [dbo].[usp_generate_inserts];
go

create proc dbo.usp_generate_inserts
(
    @table nvarchar(255)
)
as
begin
    set nocount on
    declare @is_identity bit; 
    declare @columns nvarchar(max);
    declare @values nvarchar(max);
    declare @script nvarchar(max);
    if isnull(charindex('.', @table), 0) = 0
    begin
        print 'Procedure dbo.usp_generate_inserts expects a table_name parameter in the form of schema_name.table_name';
    end
    else
    begin
        -- initialize variables as otherwise the padding will fail (return nulls for nvarchar(max) types)
        set @is_identity = 0;
        set @columns = '';
        set @values = '';
        set @script = '';
        /*
            The following select makes an assumption that the identity column should be included in
            the insert statements. Such inserts still work when coupled with identity_insert toggle, 
            which is typically used when there is a need to "plug the holes" in the identity values.
            Please note the special handling of the text data type. The type should never be present
            in SQL Server 2005 tables because it will not be supported in future versions, but there
            are unfortunately plenty of tables with text columns out there, patiently waiting for 
            someone to upgrade them to varchar(max).
        */
        select 
            @is_identity = @is_identity | columnproperty(object_id(@table), column_name, 'IsIdentity'),
            @columns = @columns + ', ' + '['+ column_name + ']',
            @values = 
                @values + ' + '', '' + isnull(master.dbo.fn_varbintohexstr(cast(' + 
                case data_type 
                    when 'text' then 'cast([' + column_name + '] as varchar(max))'
                    else '[' + column_name + ']' 
                end + ' as varbinary(max))), ''null'')' 
            from 
                information_schema.columns 
            where 
                table_name = substring(@table, charindex('.', @table) + 1, len(@table)) 
                and data_type != 'timestamp'
            order by ordinal_position;
        set @script = 
            'select ''insert into ' + @table + ' (' + substring(@columns, 3, len(@columns)) + 
            ') values ('' + ' + substring(@values, 11, len(@values)) + ' + '');'' from ' + @table + ';';
        if @is_identity = 1 
            print ('set identity_insert ' + @table + ' on');
        /* 
            generate insert statements. If the results to text option is set and the query results are
            completely fit then the prints are a part of the batch, but if the results to grid is set
            then the prints (identity insert related) can be gathered from the messages window.
        */ 
        exec sp_executesql @script;
        if @is_identity = 1 
            print ('set identity_insert ' + @table + ' off');
    end
    set nocount off
end
go
-- test the proc
--exec dbo.usp_generate_inserts 'Production.BillOfMaterials'
/*
 Here is the paste from few of the 2679 returned records:
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID] /* abridged */) values (0x0000037d, null, /* abridged */);
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID], /* abridged */) values (0x0000010f, null,/* abridged */);
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID], /* abridged */) values (0x00000022, null,/* abridged */);
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID], /* abridged */) values (0x0000033e, null,/* abridged */);
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID], /* abridged */) values (0x0000081a, null,/* abridged */);
 insert into Production.BillOfMaterials ([BillOfMaterialsID], [ProductAssemblyID], /* abridged */) values (0x0000079e, null,/* abridged */);

*/