\include_relative 'common.sql'

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
    unnest(range_agg(int8range(seed, seed + range, '(]'))) as seed_range
FROM seed_range;

-- we want to inverse the delta to take the mapping path in reverse
ALTER TABLE day05.mapping ADD COLUMN inverted_range int8range;
UPDATE day05.mapping
SET
    delta = - delta,
    inverted_range = int8range(
            LOWER(range),
            UPPER(range),
            '(]'            --  We need to invert the INCL/EXCL bounds !
);

-- The ordered are now the location. We iterate through each location from the minimum one.
-- Once one of the resulting seed matches one of the seed ranges, we'll have our winning seed.
-- Well, traversing it the pther way around is not possible.
-- FUNCTIONS: different as we have to use invert_range
CREATE FUNCTION day05.apply_mappings(
    n BIGINT,
    mappings day05.mapping[],
    seed_number BIGINT
) RETURNS BIGINT
AS $$
    SELECT COALESCE(
        (
            SELECT COALESCE(n, seed_number) + mapping.delta
            FROM UNNEST(mappings) AS mapping
            WHERE mapping.inverted_range @> COALESCE(n, seed_number)
        ),
        n,
        seed_number
    );
$$ LANGUAGE sql;

CREATE AGGREGATE day05.apply_mappings (day05.mapping[], bigint) (
    sfunc = day05.apply_mappings,
    stype = bigint
);

-- _______________

DO $$
DECLARE
    location INT := 0;
    max_location INT := 100;
    seed_f_result JSONB;
BEGIN
    WHILE location < max_location LOOP
        SELECT day05.apply_mappings(mappings_data.mappings, location ORDER BY mapping_number DESC) as r
        INTO seed_f_result
        FROM LATERAL (
            SELECT
                mapping_number,
                ARRAY_AGG(mapping.*) AS mappings
            FROM day05.mapping
            GROUP BY mapping_number
        ) AS mappings_data;

        IF EXISTS (
            SELECT 1
            FROM day05.seed_ranges
            WHERE (seed_f_result->>'value')::BIGINT <@ day05.seed_ranges.seed_range
        ) THEN
            RAISE NOTICE 'Location: %, Seed F: %, Matched Seed Range!', location, seed_f_result;
            EXIT;
        ELSE
            RAISE NOTICE 'Location: %, Seed F: %, No Match Found.', location, seed_f_result;
        END IF;

        location := location + 1;
    END LOOP;
END $$;

