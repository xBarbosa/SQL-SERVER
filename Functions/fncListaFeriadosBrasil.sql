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
		WHEN 3 THEN 'terça-feira'
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
				CAST('Confraternização Universal' as varchar(200)) collate SQL_Latin1_General_CP1_CI_AS as descricao
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Carnaval' from (select dbo.fncFeriadoCarnaval(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Corpus Christi' from (select dbo.fncFeriadoCorpoCristo(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Paixão de Cristo' from (select dbo.fncFeriadoPaixaoCristo(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'MOVEL', '', DAY([Data]), MONTH([Data]), 'Páscoa' from (select dbo.fncFeriadoPascoa(case when @ANO=0 then YEAR(GETDATE()) else @ANO end) as [Data]) x 
	union all select 'NACIONAL', 'FIXO', '',	01,	05, 'Dia do Trabalhador'
	union all select 'NACIONAL', 'FIXO', '',	02,	11, 'Finados'
	union all select 'NACIONAL', 'FIXO', '',	07,	09, 'Independência'
	union all select 'NACIONAL', 'FIXO', '',	12,	10, 'Nossa Senhora Aparecida'
	union all select 'NACIONAL', 'FIXO', '',	15,	11, 'Proclamação da República'
	union all select 'NACIONAL', 'FIXO', '',	21,	04, 'Tiradentes'
	union all select 'NACIONAL', 'FIXO', '',	25,	12, 'Natal'
	union all select 'ESTADUAL', 'FIXO', 'AC',	05,	09, 'Dia da Amazônia'
	union all select 'ESTADUAL', 'FIXO', 'AC',	08,	03, 'Alusivo ao Dia Internacional da Mulher'
	union all select 'ESTADUAL', 'FIXO', 'AC',	15,	06, 'Aniversário do estado'
	union all select 'ESTADUAL', 'FIXO', 'AC',	17,	11, 'Assinatura do Tratado de Petrópolis'
	union all select 'ESTADUAL', 'FIXO', 'AC',	23,	01, 'Dia do evangélico'
	union all select 'ESTADUAL', 'FIXO', 'AL',	16,	09, 'Emancipação Política'
	union all select 'ESTADUAL', 'FIXO', 'AL',	20,	11, 'Morte de Zumbi dos Palmares'
	union all select 'ESTADUAL', 'FIXO', 'AL',	24,	06, 'São João'
	union all select 'ESTADUAL', 'FIXO', 'AL',	29,	06, 'São Pedro'
	union all select 'ESTADUAL', 'FIXO', 'AM',	05,	09, 'Elevação do Amazonas à categoria de província'
	union all select 'ESTADUAL', 'FIXO', 'AM',	20,	11, 'Dia da Consciência Negra'
	union all select 'ESTADUAL', 'FIXO', 'AP',	13,	09, 'Criação do Território Federal (Data Magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'AP',	19,	03, 'Dia de São José, santo padroeiro do Estado do Amapá'
	union all select 'ESTADUAL', 'FIXO', 'BA',	02,	07, 'Independência da Bahia (Data magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'CE',	25,	03, 'Data magna do estado (data da abolição da escravidão no Ceará)'
	union all select 'ESTADUAL', 'FIXO', 'DF',	21,	04, 'Fundação de Brasília'
	union all select 'ESTADUAL', 'FIXO', 'DF',	30,	09, 'Dia do evangélico'
	union all select 'ESTADUAL', 'FIXO', 'MA',	28,	07, 'Adesão do Maranhão à independência do Brasil'
	union all select 'ESTADUAL', 'FIXO', 'MG',	21,	04, 'Data magna do estado'
	union all select 'ESTADUAL', 'FIXO', 'MS',	11,	10, 'Criação do estado'
	union all select 'ESTADUAL', 'FIXO', 'MT',	20,	11, 'Dia da Consciência Negra'
	union all select 'ESTADUAL', 'FIXO', 'PA',	15,	08, 'Adesão do Grão-Pará à independência do Brasil (data magna)'
	union all select 'ESTADUAL', 'FIXO', 'PB',	05,	08, 'Fundação do Estado em 1585'
	union all select 'ESTADUAL', 'FIXO', 'PB',	26,	07, 'Homenagem à memória do ex-presidente João Pessoa'
	union all select 'ESTADUAL', 'FIXO', 'PI',	08,	12, 'Santa Imaculada Conceicao'
	union all select 'ESTADUAL', 'FIXO', 'PI',	19,	10, 'Dia do Piauí'
	union all select 'ESTADUAL', 'FIXO', 'PR',	19,	12, 'Emancipação política (emancipação do Paraná)'
	union all select 'ESTADUAL', 'FIXO', 'RJ',	20,	11, 'Dia da Consciência Negra'
	union all select 'ESTADUAL', 'FIXO', 'RJ',	23,	04, 'Dia de São Jorge'
	union all select 'ESTADUAL', 'FIXO', 'RN',	03,	10, 'Mártires de Cunhaú e Uruaçu'
	union all select 'ESTADUAL', 'FIXO', 'RO',	04,	01, 'Criação do estado (data magna)'
	union all select 'ESTADUAL', 'FIXO', 'RO',	18,	06, 'Dia do evangélico'
	union all select 'ESTADUAL', 'FIXO', 'RR',	05,	10, 'Criação do estado'
	union all select 'ESTADUAL', 'FIXO', 'RS',	20,	09, 'Proclamação da República Rio-Grandense'
	union all select 'ESTADUAL', 'FIXO', 'SC',	11,	08, 'Dia de Santa Catarina (criação da capitania, separando-se de São Paulo)'
	union all select 'ESTADUAL', 'FIXO', 'SC',	25,	11, 'Dia de Santa Catarina de Alexandria'
	union all select 'ESTADUAL', 'FIXO', 'SE',	08,	07, 'Autonomia política de Sergipe'
	union all select 'ESTADUAL', 'FIXO', 'SE',	08,	12, 'Nossa Senhora da Conceição'
	union all select 'ESTADUAL', 'FIXO', 'SE',	17,	03, 'Aniversário de Aracaju'
	union all select 'ESTADUAL', 'FIXO', 'SE',	24,	06, 'São João'
	union all select 'ESTADUAL', 'FIXO', 'SP',	09,	07, 'Revolução Constitucionalista de 1932 (Data magna do estado)'
	union all select 'ESTADUAL', 'FIXO', 'TO',	05,	10, 'Criação do estado'
	union all select 'ESTADUAL', 'FIXO', 'TO',	08,	09, 'Padroeira do Estado (Nossa Senhora da Natividade)'
	union all select 'ESTADUAL', 'FIXO', 'TO',	18,	03, 'Autonomia do Estado (criação da Comarca do Norte)'
	) feriados

)



