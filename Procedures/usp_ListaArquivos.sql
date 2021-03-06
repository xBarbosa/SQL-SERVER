USE [master]
GO

IF OBJECT_ID('[dbo].[usp_ListaArquivos]') IS NOT NULL 
BEGIN
	DROP PROCEDURE [dbo].[usp_ListaArquivos]
END

/****** Object:  StoredProcedure [dbo].[usp_ListaArquivos]    Script Date: 11/06/2009 16:40:31 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Author:		glauco.basilio
-- Create date: 20081219
-- Description:	Retorna um cursor contendo os arquivos do diretório @dir
--				que se enquadram dentro da definição da do padrão @pattern
--
-- Obs:			@pattern é uma expressão regular ECMA
--				depende deste arquivo \\10.1.1.110\Projeto Oi\ePrata\Scripts\ListaArquivos.vbs
--				estar no local correto
-- =============================================
/*
	Exemplo:
			declare @g cursor
			declare @path varchar(7000), @name varchar(7000)
			exec usp_ListaArquivos @dir = '\\192.168.10.108\F$\BRT - RELATORIO ESPECIAL DE AC\2007', 
			@pattern = '\.001$' , @saida = @g OUTPUT
			fetch next from @g into @path, @name
			while @@fetch_status = 0 Begin
				print @path + ' -- ' + @name
				fetch next from @g into @path, @name
			End
			close @g
			deallocate @g
*/
CREATE proc [dbo].[usp_ListaArquivos]
	@dir varchar(500),
	@pattern varchar(100) = '.',
	@saida cursor VARYING output
As Begin
	declare @cmd varchar(1000)
	declare @count int
	Set @cmd = 'cscript //NoLogo "\\192.168.10.105\publico\TI\ListaArquivos.vbs" "' + @dir + '" "' + @pattern + '"'
	declare @ret table ( arquivo VARCHAR(7000))
	insert @ret exec xp_cmdshell @cmd
	select @count = count(*) from @ret
	if @count <> 0 begin
		set @saida = cursor static for 
			select top(@count-1) left(arquivo,charindex(';',arquivo)-1) path, right(arquivo,len(arquivo)-charindex(';',arquivo)) filename from @ret
		open @saida
	end
End




