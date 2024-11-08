DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.records (
    line_text TEXT
);

\COPY day03.records(line_text) FROM 'input.txt';

-- Process: We will use delta positions of the symbols to see if the different sequences of digits falls into them
-- V is a good spot, X not
-- .1...    XVVVX
-- ..*..    XV*VX
-- 2....    XVVVX
--
-- 1 is located at row(1)-col(2) and we know that the start position has valid spot row(1)-col(2)
-- We know that 1 is valid, but 2 is not.

-- [Step 1] Create a table with the row position
WITH engine_schematic AS (
    SELECT
        row_number() OVER () AS row_num, -- row_number(): Returns the number of the current row within its partition, counting from 1 [https://www.postgresql.org/docs/current/functions-window.html#FUNCTIONS-WINDOW]
        line_text
    FROM day03.records
),
-- [Step 2] Identify all symbol positions
    symbol_positions AS (
        SELECT row_num,
               gs.col_num,
--                line_text, -- for debugging purpose
               substr(line_text, gs.col_num, 1) AS symbol -- substr(string, from [, count]):	substr('alphabet', 3, 2) -> ph
        FROM engine_schematic AS es
             CROSS JOIN generate_series(1, length(line_text)) AS gs(col_num) -- CROSS JOIN: cartesian product of the two series: {1; 2} {a; b} -> {1, a; 1, b; 2, a; 2; b} [https://www.postgresql.org/docs/current/queries-table-expressions.html#QUERIES-JOIN]
        WHERE substr(line_text, gs.col_num, 1) ~ '[^.\d]' -- "~" Regular Expression Match Operators: String matches regular expression, case sensitively [https://www.postgresql.org/docs/current/functions-matching.html#FUNCTIONS-POSIX-REGEXP]
),
-- [Step 3] Find adjacent positions: it will be used to check if a sequece of digits falls into those positions
    symbol_adjacent AS (
        SELECT
--             symbol, -- for debugging purpose
            row_num + dr AS adj_row,
            col_num + dc AS adj_col
        FROM symbol_positions
            CROSS JOIN generate_series(-1,1,1) AS dr
            CROSS JOIN generate_series(-1,1,1) AS dc -- cartesian product of all possibilities
),
-- [Step 4] Identify position of all chracters and set for numbers if they are matching a symbol adjacent position
    table_characters_with_adjency AS (
        SELECT
            es.row_num,
            gs.col_num,
            substr(es.line_text, gs.col_num, 1) AS character,
            CASE
                WHEN substr(es.line_text, gs.col_num, 1) ~ '\d'  -- Check if character is a number
                     AND EXISTS (
                        SELECT 1
                        FROM symbol_adjacent ap
                        WHERE ap.adj_row = es.row_num
                          AND ap.adj_col = gs.col_num
                     )
                THEN TRUE
                ELSE FALSE
            END AS is_adjacent_character
        FROM engine_schematic AS es
            CROSS JOIN generate_series(1, length(line_text)) AS gs(col_num)
),
-- [Step 5] Extract all sequences and define if any of their digit has a position that matches a symbol adjacent position
    digit_sequences AS (
    SELECT
        row_num,
        string_agg(character, '' ORDER BY col_num) AS number_sequence, -- [aggr] necessary to aggregate the sequence of digits from a same group: ORDER BY is not necessary (table already sorted)
        bool_or(is_adjacent_character) AS has_adjacent -- [aggr] true if at least one input value is true, otherwise false
    FROM (
        SELECT
            row_num,
            col_num,
            character,
            is_adjacent_character,
            -- Identifier les séquences de chiffres
            col_num - ROW_NUMBER() OVER (PARTITION BY row_num ORDER BY col_num) AS grp
        FROM
            table_characters_with_adjency
        WHERE
            character ~ '\d'
    ) AS digit_groups
    GROUP BY row_num, grp
)

SELECT
    SUM(number_sequence::INTEGER) AS numbers
FROM
    digit_sequences
WHERE
    has_adjacent = TRUE;



--         SELECT
--             row_num,
--             col_num,
--             character,
--             is_adjacent_character,
--             -- Identifier les séquences de chiffres
--             col_num - ROW_NUMBER() OVER (PARTITION BY row_num ORDER BY col_num) AS grp
--         FROM
--             table_characters_with_adjency
--         WHERE
--             character ~ '\d'

--  row_num | col_num | character | is_adjacent_character | grp
-- ---------+---------+-----------+-----------------------+-----
--        1 |       1 | 4         | f                     |   0
--        1 |       2 | 6         | f                     |   0
--        1 |       3 | 7         | t                     |   0
--        1 |       6 | 1         | f                     |   2
--        1 |       7 | 1         | f                     |   2
--        1 |       8 | 4         | f                     |   2
--        3 |       3 | 3         | t                     |   2
--        3 |       4 | 5         | t                     |   2
--        3 |       7 | 6         | t                     |   4
--        3 |       8 | 3         | t                     |   4
--        3 |       9 | 3         | f                     |   4
--        5 |       1 | 6         | f                     |   0
--        5 |       2 | 1         | f                     |   0
--        5 |       3 | 7         | t                     |   0
--        6 |       8 | 5         | f                     |   7


--
--         SELECT
--             row_num,
--             col_num,
--             character,
--             is_adjacent_character,
--
--             ROW_NUMBER() OVER (PARTITION BY row_num ORDER BY col_num) AS grp
--         FROM
--             table_characters_with_adjency
--         WHERE
--             character ~ '\d'

--  row_num | col_num | character | is_adjacent_character | grp
-- ---------+---------+-----------+-----------------------+-----
--        1 |       1 | 4         | f                     |   1
--        1 |       2 | 6         | f                     |   2
--        1 |       3 | 7         | t                     |   3
--        1 |       6 | 1         | f                     |   4
--        1 |       7 | 1         | f                     |   5
--        1 |       8 | 4         | f                     |   6
--        3 |       3 | 3         | t                     |   1
--        3 |       4 | 5         | t                     |   2
--        3 |       7 | 6         | t                     |   3
--        3 |       8 | 3         | t                     |   4
--        3 |       9 | 3         | f                     |   5
--        5 |       1 | 6         | f                     |   1
--        5 |       2 | 1         | f                     |   2
--        5 |       3 | 7         | t                     |   3
--        6 |       8 | 5         | f                     |   1
