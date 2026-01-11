USE TechHealthDb;
GO

/* 
STRING FUNCTION EXERCISE #1 — Product Name Cleanup
Scenario:
Your Products table contains product names entered by different employees. 
Some names have inconsistent casing, extra spaces, and mixed formatting.

Task:
Write a T?SQL query that returns a cleaned version of each product name with the following rules:
1. Remove leading and trailing spaces
2. Replace multiple spaces between words with a single space
3. Convert the entire name to Title Case (first letter uppercase, rest lowercase)
4. Remove any digits that appear inside the product name
5. Return both the original and cleaned name

Input column:
    product_name (NVARCHAR)

Output columns:
    OriginalName
    CleanedName
*/

CREATE FUNCTION dbo.TitleCase(@input NVARCHAR(4000))
RETURNS NVARCHAR(4000)
AS
BEGIN
    DECLARE @output NVARCHAR(4000) = '';
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@input);
    DECLARE @char NCHAR(1);
    DECLARE @prev NCHAR(1) = ' ';

    WHILE @i <= @len
    BEGIN
        SET @char = SUBSTRING(@input, @i, 1);

        IF @prev = ' '
            SET @output += UPPER(@char);
        ELSE
            SET @output += LOWER(@char);

        SET @prev = @char;
        SET @i += 1;
    END

    RETURN @output;
END;


SELECT 
    product_name AS OriginalName,
    dbo.TitleCase(
        LTRIM(RTRIM(
            REPLACE(
                REPLACE(
                    REPLACE(
                        TRANSLATE(product_name, '0123456789', '          '),
                        '  ', ' '
                    ),
                    '  ', ' '
                ),
                '  ', ' '
            )
        ))
    ) AS CleanedName
FROM Products;



-- checking what functions I have created
SELECT 
    s.name AS SchemaName,
    o.name AS FunctionName,
    o.type_desc AS FunctionType
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('FN', 'IF', 'TF')
ORDER BY s.name, o.name;

-- delete function
DROP FUNCTION dbo.TitleCase;

