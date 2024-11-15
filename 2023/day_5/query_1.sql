\include_relative 'common.sql'

CREATE TABLE day05.seeds AS
    SELECT parts[1]::bigint AS seed
    FROM day05.input_section,
         LATERAL regexp_matches(line, '\d+', 'g') AS parts
    WHERE section_number = 1;

CREATE TABLE day05.seed_location AS
SELECT
    seed,
    day05.apply_mappings(mappings, seed ORDER BY mapping_number) AS location
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
