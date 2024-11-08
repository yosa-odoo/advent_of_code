DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.records (
    line_text TEXT
);

\COPY day03.records(line_text) FROM 'example.txt';

WITH engine_schematic AS (
    SELECT
        row_number() OVER () AS row_num,
        line_text
    FROM day03.records
),

    symbol_positions AS (
        SELECT row_num,
               gs.col_num,
               substr(line_text, gs.col_num, 1) AS symbol
        FROM engine_schematic AS es
             CROSS JOIN generate_series(1, length(line_text)) AS gs(col_num)
        WHERE substr(line_text, gs.col_num, 1) ~ '\*' -- difference
),
    symbol_adjacent AS (
        SELECT
            row_num + dr AS adj_row,
            col_num + dc AS adj_col
        FROM symbol_positions
             CROSS JOIN
                (generate_series(-1,1,1) AS dr CROSS JOIN generate_series(-1,1,1) AS dc)
),
    table_characters_with_adjency AS (
        SELECT
            es.row_num,
            gs.col_num,
            substr(es.line_text, gs.col_num, 1) AS character,
            CASE
                WHEN substr(es.line_text, gs.col_num, 1) ~ '\d'
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
    digit_sequences AS (
    SELECT
        row_num,
        string_agg(character, '' ORDER BY col_num) AS number_sequence,
        bool_or(is_adjacent_character) AS has_adjacent
    FROM (
        SELECT
            row_num,
            col_num,
            character,
            is_adjacent_character,
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
