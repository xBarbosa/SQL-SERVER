-- ================================================

-- Template generated from Template Explorer using:

-- Create Scalar Function (New Menu).SQL

--

-- Use the Specify Values for Template Parameters

-- command (Ctrl-Shift-M) to fill in the parameter

-- values below.

--

-- This block of comments will not be included in

-- the definition of the function.

-- ================================================

SET ANSI_NULLS ON

GO

SET QUOTED_IDENTIFIER ON

GO

-- =============================================

-- Author: Emerson Tadeu

-- Create date:

-- Description: Retorna Verdadeiro ou Falso apos verificar se CPF é válido

-- =============================================

CREATE FUNCTION isCPF

(

@pCPF varchar(15)

)

RETURNS BIT

AS

BEGIN

DECLARE @RETURN BIT

DECLARE @INDICE INT

DECLARE @SOMA INT

DECLARE @DIG1 INT

DECLARE @DIG2 INT

DECLARE @CPF varchar(15)

SET @CPF = RTRIM(LTRIM(@pCPF))

/* Calculo do digito 1 */

SET @INDICE = 1

SET @SOMA = 0

WHILE (@INDICE <= 9)

BEGIN

IF ISNUMERIC(SUBSTRING(@CPF, @INDICE, 1)) = 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CPF, @INDICE, 1) AS INT) * (11 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

SET @DIG1 = 11 - (@SOMA % 11)

IF @DIG1 > 9

SET @DIG1 = 0

/* Calculo do digito 2 */

SET @INDICE = 1

SET @SOMA = 0

WHILE (@INDICE <= 10)

BEGIN

IF ISNUMERIC(SUBSTRING(@CPF, @INDICE, 1)) = 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CPF, @INDICE, 1) AS INT) * (12 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

SET @DIG2 = 11 - (@SOMA % 11)

IF @DIG2 > 9

SET @DIG2 = 0

/* Validando */

IF ((@DIG1 = SUBSTRING(@CPF, LEN(@CPF)-1, 1)) AND (@DIG2 = SUBSTRING(@CPF, LEN(@CPF), 1))

AND NOT((@CPF = '11111111111')

OR (@CPF = '22222222222')

OR (@CPF = '33333333333')

OR (@CPF = '44444444444')

OR (@CPF = '55555555555')

OR (@CPF = '66666666666')

OR (@CPF = '77777777777')

OR (@CPF = '88888888888')

OR (@CPF = '99999999999')

OR (@CPF = '00000000000'))

)

SET @RETURN = 1

ELSE

SET @RETURN = 0

RETURN @RETURN

END

GO

    