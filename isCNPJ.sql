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

-- Description:

-- =============================================

CREATE FUNCTION isCNPJ

(

-- Add the parameters for the function here

@pCNPJ VARCHAR(15)

)

RETURNS BIT

AS

BEGIN

-- Declare the return variable here

DECLARE @RESULT BIT

DECLARE @INDICE INT

DECLARE @SOMA INT

DECLARE @DIG1 INT

DECLARE @DIG2 INT

DECLARE @CNPJ VARCHAR(15)

SET @CNPJ = RTRIM(LTRIM(@pCNPJ))

/* Calculo do digito 1 */

SET @INDICE = 1

SET @SOMA = 0

WHILE (@INDICE <= 12)

BEGIN

IF (@INDICE <= 4)

BEGIN

IF ISNUMERIC(SUBSTRING(@CNPJ, @INDICE, 1))= 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CNPJ, @INDICE, 1) AS INT) * (6 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

ELSE

BEGIN

IF ISNUMERIC(SUBSTRING(@CNPJ, @INDICE, 1))= 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CNPJ, @INDICE, 1) AS INT) * (14 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

END

SET @DIG1 = 11 - (@SOMA % 11)

IF @DIG1 > 9

SET @DIG1 = 0

/* Calculo do digito 2 */

SET @INDICE = 1

SET @SOMA = 0

WHILE (@INDICE <= 13)

BEGIN

IF (@INDICE <= 5)

BEGIN

IF ISNUMERIC(SUBSTRING(@CNPJ, @INDICE, 1))= 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CNPJ, @INDICE, 1) AS INT) * (7 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

ELSE

BEGIN

IF ISNUMERIC(SUBSTRING(@CNPJ, @INDICE, 1)) = 1

BEGIN

SET @SOMA = @SOMA + CAST(SUBSTRING(@CNPJ, @INDICE, 1) AS INT) * (15 - @INDICE)

SET @INDICE = @INDICE + 1

END

ELSE

RETURN 0

END

END

SET @DIG2 = 11 - (@SOMA % 11)

IF @DIG2 > 9

SET @DIG2 = 0

/* Validando */

IF ((@DIG1 = SUBSTRING(@CNPJ, LEN(@CNPJ)-1, 1)) AND (@DIG2 = SUBSTRING(@CNPJ, LEN(@CNPJ), 1)))

SET @RESULT = 1

ELSE

SET @RESULT = 0

-- Return the result of the function

RETURN @RESULT

END

GO