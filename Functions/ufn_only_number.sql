USE [Integracao_gemco_sap]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE FUNCTION [dbo].[UFN_ONLY_NUMBER]
(
  @pCol varchar(255)
)
RETURNS varchar(255)
AS
Begin

    Declare @KeepValues as varchar(50)
    Set @KeepValues = '%[^0-9]%'
    While PatIndex(@KeepValues, @pCol) > 0
        Set @pCol = Stuff(@pCol, PatIndex(@KeepValues, @pCol), 1, '')

    Return case when @pCol = '' then '0' else @pCol end
End
GO


