WITH cte_id AS
(
    SELECT id
    FROM (VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9)) AS t(id)
)
SELECT
    ci1.id * 1000 + ci2.id * 100 + ci3.id * 10 + ci4.id + 1 AS row_num--,
    --ci1.id,
    --ci2.id,
    --ci3.id
FROM cte_id ci1
    CROSS JOIN cte_id ci2
        CROSS JOIN cte_id ci3
            CROSS JOIN cte_id ci4
ORDER BY
    ci1.id,
    ci2.id,
    ci3.id,
    ci4.id
