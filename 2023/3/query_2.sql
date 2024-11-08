\include_relative 'common.sql';

-- Creation of the `multiplication` aggregate (not native)

CREATE FUNCTION mult(BIGINT, BIGINT)
    RETURNS BIGINT
    RETURN (
        $1 * $2
        );

CREATE AGGREGATE mult(BIGINT) (
  SFUNC = mult,     -- sfunc( internal-state, next-data-values ) ---> next-internal-state
  STYPE = bigint,   -- state_data_type
  INITCOND = '1'    -- initial condition
);

CREATE TABLE day03.gear AS
    SELECT
        day03.part.row,
        day03.part.col,
        mult(day03.part_number.value::BIGINT) AS ratio
    FROM day03.part
    JOIN day03.part_number on day03.adjacent(part, part_number)
    WHERE day03.part.value = '*'
    GROUP BY day03.part.row, day03.part.col
    HAVING count(*) = 2;

SELECT SUM(ratio) FROM day03.gear;