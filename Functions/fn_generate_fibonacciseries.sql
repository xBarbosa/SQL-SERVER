--drop function fn_generate_fibonacciseries
create function fn_generate_fibonacciseries(@number int)
returns @returntable table (rownum int,fibonum int)
as
begin

;with fibonacciseries as (
   select 1 as rownum, cast(0 as float) as start, cast(1 as float) as [next]
   union all
   select rownum+1, [next], start+[next]
   from fibonacciseries
   where rownum<=@number)
Insert into @returntable(rownum,fibonum)
	select rownum,convert(numeric(38,0),cast(start AS float)) 
		from fibonacciseries

return
end
go

select * from dbo.fn_generate_fibonacciseries(10)