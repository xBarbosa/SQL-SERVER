
							
							
							
		exec usp_CreateMDB @MDBPathName = '\\192.168.10.108\c$\teste.mdb', @OverrideBit = 1

		exec usp_ExecOnMDB @MDBPathName = '\\192.168.10.108\c$\teste.mdb', @sql = 
		'
		CREATE TABLE tb_Importacao(
			id_Arquivo long  NOT NULL,
			Tipo_Arquivo varchar(80) NULL,
			Nome_Arquivo varchar(80) NOT NULL,
			dt_Importacao datetime NULL,
			dt_Inicio datetime NULL,
			dt_Fim datetime NULL,
			id_Status int NULL,
			Filial varchar(2) NULL,
			Diretorio varchar(255) NULL
		)'

		exec('
			insert into openrowset(''Microsoft.Jet.OLEDB.4.0'',''c:\teste.mdb'';''Admin'';'''',tb_Importacao)
			select * from kcserver10.db_Oi_Config.dbo.tb_Importacao
		') At KCSERVERBKP01