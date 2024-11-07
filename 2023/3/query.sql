DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.records (
    line_text TEXT
);

\COPY day03.records(line_text) FROM 'example.txt';

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
             CROSS JOIN
                (generate_series(-1,1,1) AS dr CROSS JOIN generate_series(-1,1,1) AS dc) -- cartesian product of all possibilities
),

