\include_relative 'common.sql'


-- FUNCTIONS
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
            WHERE mapping.range @> COALESCE(n, seed_number)
        ),
        n,
        seed_number
    );
$$ LANGUAGE sql;

CREATE AGGREGATE day05.apply_mappings (day05.mapping[], bigint) (
    sfunc = day05.apply_mappings,
    stype = bigint
);
-- __________________


CREATE TABLE day05.seeds AS
    SELECT parts[1]::bigint AS seed
    FROM day05.input_section,
         LATERAL regexp_matches(line, '\d+', 'g') AS parts
    WHERE section_number = 1;


CREATE TABLE day05.seed_location AS
SELECT
    seed,
    day05.apply_mappings( mappings, seed ORDER BY mapping_number) AS location -- apparently we don't care if the first argument is not given
FROM
    day05.seeds
CROSS JOIN LATERAL (
    SELECT
        mapping_number,
        ARRAY_AGG(mapping.*) AS mappings
    FROM
        day05.mapping
    GROUP BY
        mapping_number
) AS mappings_data
GROUP BY
    seed;

SELECT MIN(location) FROM day05.seed_location;
