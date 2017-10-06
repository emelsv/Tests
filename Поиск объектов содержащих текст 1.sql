SET NOCOUNT ON

DECLARE 
    @search_string varchar(8000)        = 'pc_proc_card_data',--'pc_dwh_cashback_turnover',--'login_active',--'',--'in_query', --'Сведения об оформлении, переводе и закрытии паспорта сделки',
    @search_object_type varchar(2)      =  'P'                       -- NULL - любой, V - представление, P - хранимая процедура и т.п.

SELECT  
        r.object_name,
        r.object_type,
        OBJECT_DEFINITION(r.id) AS [object_text]
FROM
(
    SELECT  DISTINCT
            t2.id,
            t2.[name] AS [object_name],
            t2.[type] AS [object_type] 
    FROM 
        sys.syscomments  AS t1 WITH (NOLOCK)
        INNER JOIN sys.sysobjects AS t2 WITH (NOLOCK) 
        ON t1.id = t2.id
    WHERE 
        t1.[text] LIKE '%' + @search_string + '%'
        AND t2.[type] = IIF(@search_object_type IS NULL, t2.[type], @search_object_type)
) r
ORDER BY 
    r.object_type ASC,
    r.object_name ASC
