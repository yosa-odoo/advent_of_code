DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.raw_input (line TEXT);
\copy day03.raw_input FROM 'input.txt';

CREATE TABLE day03.input AS
    SELECT
        ROW_NUMBER() OVER () AS line_number,
        line
    FROM day03.raw_input;

CREATE TABLE day03.input_grid_cell AS
    SELECT
        row_number() OVER (partition by line_number) AS row,
        line_number AS col,
        value
FROM day03.input, string_to_table(line, NULL) AS value;

CREATE TABLE day03.schematic_unit AS
    SELECT
        day03.input_grid_cell.*,
        substring(day03.input.line FROM row::int - 1 for 1) AS preceding,
        substring(day03.input.line FROM row::int) AS following
    FROM day03.input_grid_cell
    JOIN day03.input ON line_number = col;

CREATE TABLE day03.part_number AS
    SELECT
        row,
        col,
        match[1] AS value
    FROM day03.schematic_unit
        CROSS JOIN regexp_match(following, '^\d+') AS match
    WHERE
        (preceding = '' or regexp_like(preceding, '\D'))
        AND regexp_like(value, '\d');

CREATE TABLE day03.part AS
    SELECT *
    FROM day03.schematic_unit
    WHERE regexp_like(value, '\*');

CREATE FUNCTION day03.adjacent(day03.part, day03.part_number)
    RETURNS BOOLEAN     -- defines the output type of the function
    RETURN (            -- specifies the actual value to be returned when the function is executed
        $1.row BETWEEN $2.row - 1 AND $2.row + LENGTH($2.value)
            AND $1.col BETWEEN $2.col - 1 AND $2.col + 1
);