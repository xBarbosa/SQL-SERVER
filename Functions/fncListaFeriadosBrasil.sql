CREATE FUNCTION dbo.fncListaFeriadosBrasil (@ANO int)
RETURNS TABLE 
AS
RETURN 
(
	--declare @ANO int = 2024
	 select 
		dia, 
		mes, 
		case 
		when @ANO = 0 then YEAR(GETDATE())
		else @ANO
		end as ano,
		CONVERT(DATE, (CAST(case when @ANO = 0 then YEAR(GETDATE()) else @ANO end as varchar)+'-'+CAST(mes as varchar)+'-'+CAST(dia as varchar)),120) as [Data],
		DATEPART(WEEKDAY, CONVERT(DATE, (CAST(case when @ANO = 0 then YEAR(GETDATE()) else @ANO end as varchar)+'-'+CAST(mes as varchar)+'-'+CAST(dia as varchar)),120)) as id_dia_semana,
		CASE 
		DATEPART(WEEKDAY, CONVERT(DATE, (CAST(case when @ANO = 0 then YEAR(GETDATE()) else @ANO end as varchar)+'-'+CAST(mes as varchar)+'-'+CAST(dia as varchar)),120))
		WHEN 1 THEN 'domingo'
		WHEN 2 THEN 'segunda-feira'
		WHEN 3 THEN 'ter�a-feira'
		WHEN 4 THEN 'quarta-feira'
		WHEN 5 THEN 'quinta-feira'
		WHEN 6 THEN 'sexta-feira'
		WHEN 7 THEN 'sabado'
		end as dia_semana,
		dbo.fncAnoBissexto(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as ano_bissexto,
		ambito,
		tipo_feriado,
		uf,
		descricao
	 from (
			  select 
				CAST('NACIONAL' as varchar(8)) collate SQL_Latin1_General_CP1_CI_AS as ambito, 
				CAST('FIXO' as varchar(5)) collate SQL_Latin1_General_CP1_CI_AS as tipo_feriado, 
				CAST('' as varchar(2)) collate SQL_Latin1_General_CP1_CI_AS as uf,	
				CAST(01 as smallint) as dia, 
				CAST(01 as smallint) as mes, 
				CAST('Confraterniza��o Universal' as varchar(200)) collate SQL_Latin1_General_CP1_CI_AS as descricao
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Carnaval' from (select dbo.fncFeriadoCarnaval(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Corpus Christi' from (select dbo.fncFeriadoCorpoCristo(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Paix�o de Cristo' from (select dbo.fncFeriadoPaixaoCristo(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'P�scoa' from (select dbo.fncFeriadoPascoa(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'FIXO', '',	01,	05, 'Dia do Trabalhador'
	union all select 'NACIONAL', 'FIXO', '',	02,	11, 'Finados'
	union all select 'NACIONAL', 'FIXO', '',	07,	09, 'Independ�ncia'
	union all select 'NACIONAL', 'FIXO', '',	12,	10, 'Nossa Senhora Aparecida'
	union all select 'NACIONAL', 'FIXO', '',	15,	11, 'Proclama��o da Rep�blica'
	union all select 'NACIONAL', 'FIXO', '',	21,	04, 'Tiradentes'
	union all select 'NACIONAL', 'FIXO', '',	25,	12, 'Natal'
	union all select 'ESTADUAL', 'FIXO', 'AC',	05,	09, 'Dia da Amaz�nia'
	union all select 'ESTADUAL', 'FIXO', 'AC',	08,	03, 'Alusivo ao Dia Internacional da Mulher'
	union all select 'ESTADUAL', 'FIXO', 'AC',	15,	06, 'Anivers�rio do estado'
	union all select 'ESTADUAL', 'FIXO', 'AC',	17,	11, 'Assinatura do Tratado de Petr�polis'
	union all select 'ESTADUAL', 'FIXO', 'AC',	23,	01, 'Dia do evang�lico'
	union all select 'ESTADUAL', 'FIXO', 'AL',	16,	09, 'Emancipa��o Pol�tica'
	union all select 'ESTADUAL', 'FIXO', 'AL',	20,	11, 'Morte de Zumbi dos Palmares'
	union all select 'ESTADUAL', 'FIXO', 'AL',	24,	06, 'S�o Jo�o'
	union all select 'ESTADUAL', 'FIXO', 'AL',	29,	06, 'S�o Pedro'
	union all select 'ESTADUAL', 'FIXO', 'AM',	05,	09, 'Eleva��o do Amazonas � categoria de prov�ncia'
	union all select 'ESTADUAL', 'FIXO', 'AM',	20,	11, 'Dia da Consci�ncia Negra'
	union all select 'ESTADUAL', 'FIXO', 'AP',	13,	09, 'Cria��o do Territ�rio Federal (Data Magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'AP',	19,	03, 'Dia de S�o Jos�, santo padroeiro do Estado do Amap�'
	union all select 'ESTADUAL', 'FIXO', 'BA',	02,	07, 'Independ�ncia da Bahia (Data magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'CE',	25,	03, 'Data magna do estado (data da aboli��o da escravid�o no Cear�)'
	union all select 'ESTADUAL', 'FIXO', 'DF',	21,	04, 'Funda��o de Bras�lia'
	union all select 'ESTADUAL', 'FIXO', 'DF',	30,	09, 'Dia do evang�lico'
	union all select 'ESTADUAL', 'FIXO', 'MA',	28,	07, 'Ades�o do Maranh�o � independ�ncia do Brasil'
	union all select 'ESTADUAL', 'FIXO', 'MG',	21,	04, 'Data magna do estado'
	union all select 'ESTADUAL', 'FIXO', 'MS',	11,	10, 'Cria��o do estado'
	union all select 'ESTADUAL', 'FIXO', 'MT',	20,	11, 'Dia da Consci�ncia Negra'
	union all select 'ESTADUAL', 'FIXO', 'PA',	15,	08, 'Ades�o do Gr�o-Par� � independ�ncia do Brasil (data magna)'
	union all select 'ESTADUAL', 'FIXO', 'PB',	05,	08, 'Funda��o do Estado em 1585'
	union all select 'ESTADUAL', 'FIXO', 'PB',	26,	07, 'Homenagem � mem�ria do ex-presidente Jo�o Pessoa'
	union all select 'ESTADUAL', 'FIXO', 'PI',	08,	12, 'Santa Imaculada Conceicao'
	union all select 'ESTADUAL', 'FIXO', 'PI',	19,	10, 'Dia do Piau�'
	union all select 'ESTADUAL', 'FIXO', 'PR',	19,	12, 'Emancipa��o pol�tica (emancipa��o do Paran�)'
	union all select 'ESTADUAL', 'FIXO', 'RJ',	20,	11, 'Dia da Consci�ncia Negra'
	union all select 'ESTADUAL', 'FIXO', 'RJ',	23,	04, 'Dia de S�o Jorge'
	union all select 'ESTADUAL', 'FIXO', 'RN',	03,	10, 'M�rtires de Cunha� e Urua�u'
	union all select 'ESTADUAL', 'FIXO', 'RO',	04,	01, 'Cria��o do estado (data magna)'
	union all select 'ESTADUAL', 'FIXO', 'RO',	18,	06, 'Dia do evang�lico'
	union all select 'ESTADUAL', 'FIXO', 'RR',	05,	10, 'Cria��o do estado'
	union all select 'ESTADUAL', 'FIXO', 'RS',	20,	09, 'Proclama��o da Rep�blica Rio-Grandense'
	union all select 'ESTADUAL', 'FIXO', 'SC',	11,	08, 'Dia de Santa Catarina (cria��o da capitania, separando-se de S�o Paulo)'
	union all select 'ESTADUAL', 'FIXO', 'SC',	25,	11, 'Dia de Santa Catarina de Alexandria'
	union all select 'ESTADUAL', 'FIXO', 'SE',	08,	07, 'Autonomia pol�tica de Sergipe'
	union all select 'ESTADUAL', 'FIXO', 'SE',	08,	12, 'Nossa Senhora da Concei��o'
	union all select 'ESTADUAL', 'FIXO', 'SE',	17,	03, 'Anivers�rio de Aracaju'
	union all select 'ESTADUAL', 'FIXO', 'SE',	24,	06, 'S�o Jo�o'
	union all select 'ESTADUAL', 'FIXO', 'SP',	09,	07, 'Revolu��o Constitucionalista de 1932 (Data magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'TO',	05,	10, 'Cria��o do estado'
	union all select 'ESTADUAL', 'FIXO', 'TO',	08,	09, 'Padroeira do Estado (Nossa Senhora da Natividade)'
	union all select 'ESTADUAL', 'FIXO', 'TO',	18,	03, 'Autonomia do Estado (cria��o da Comarca do Norte)'
	) feriados

)



