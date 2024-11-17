\include_relative 'common.sql'

-- Implementation of Python algorithm used in https://www.youtube.com/watch?v=iqTopXV13LE
-- Using Allen's intervals: see readme.md for visual details
-- We'll need to apply a delta only on the intersection, th ebefore and after will be kept as it for next iteration

CREATE TABLE day05.seed_ranges AS
WITH seeds AS (
    SELECT parts[1]::bigint AS seed
    FROM day05.input_section,
         LATERAL regexp_matches(line, '\d+', 'g') AS parts
    WHERE section_number = 1
),
    seed_range AS (
        SELECT
            MAX(CASE WHEN rn % 2 = 1 THEN seed END) AS seed,
            MAX(CASE WHEN rn % 2 = 0 THEN seed END) AS range
            FROM (
                SELECT seed, ROW_NUMBER() OVER () AS rn
                FROM seeds
            ) sub
            GROUP BY (rn + 1) / 2
)
-- merge continuous ranges
-- range_agg ( value anyrange ) → anymultirange
-- range_agg ( value anymultirange ) → anymultirange
--      Computes the union of the non-null input values.
SELECT
    unnest(range_agg(int8range(seed, seed + range))) as seed_range
FROM seed_range;

-- => select * from day05.seed_ranges;
--  seed_range
-- ------------
--  [55,68)
--  [79,93)
-- (2 rows)

-- => select * from day05.mapping;
--  mapping_number |  range   | delta
-- ----------------+----------+-------
--               2 | [98,100) |   -48
--               2 | [50,98)  |     2
--               3 | [15,52)  |   -15
--               3 | [52,54)  |   -15
--               3 | [0,15)   |    39
