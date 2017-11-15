CREATE FUNCTION GEN_FN_StripCharacters
(
    @strInputString NVARCHAR(MAX), 
    @strMatchExpression VARCHAR(255)
)

/*
---Created By : Ram    
--Date : 15-Feb-2013
--- Purpose : To remove the specified Characters in the Given String
Alphabetic only: SELECT dbo.fn_StripCharacters('a1!s2@d3#f4$', '^a-z')
Numeric only: SELECT dbo.fn_StripCharacters('a1!s2@d3#f4$', '^0-9+-/')
Alphanumeric only: SELECT dbo.fn_StripCharacters('a1!s2@d3#f4$', '^a-z0-9')
Non-alphanumeric: SELECT dbo.fn_StripCharacters('a1!s2@d3#f4$', 'a-z0-9')
*/


RETURNS NVARCHAR(MAX)
AS
BEGIN
    SET @strMatchExpression =  '%['+@strMatchExpression+']%'

    WHILE PatIndex(@strMatchExpression, @strInputString) > 0
        SET @strInputString = Stuff(@strInputString, PatIndex(@strMatchExpression, @strInputString), 1, '')

    RETURN @strInputString
END