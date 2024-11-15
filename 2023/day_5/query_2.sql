DROP SCHEMA IF EXISTS day05 CASCADE;
CREATE SCHEMA day05;

CREATE TABLE day05.raw_input (line TEXT);
\copy day05.raw_input FROM 'input.txt';

CREATE TABLE day05.input AS
    SELECT
        ROW_NUMBER() OVER () AS line_number,
        line
    FROM day05.raw_input;
-- ------------------------------------------

CREATE TABLE day05.input_section AS     -- pépite from hgwood
    SELECT
        *,
        SUM(is_section_header::INTEGER) OVER (
            ORDER BY line_number
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            ) AS section_number
    FROM day05.input
    CROSS JOIN LATERAL (
        SELECT line LIKE '%:%' AS is_section_header
        ) AS _
    WHERE
        line <> '';

-- ______________________________________________
-- PART 1
-- CREATE TABLE day05.seeds AS
--     SELECT parts[1]::bigint AS seed
--     FROM day05.input_section,
--          LATERAL regexp_matches(line, '\d+', 'g') AS parts
--     WHERE section_number = 1;

-- PART 2: Brut Force is not a good idea
-- What would be good is to inverse the maps and start from location 1..N to seed and find the first seed that falls in one of the interval
-- CREATE TABLE day05.seeds AS
CREATE TABLE
WITH seeds AS (
    SELECT parts[1]::bigint AS seed
    FROM day05.input_section,
         LATERAL regexp_matches(line, '\d+', 'g') AS parts
    WHERE section_number = 1
)
    SELECT
    MAX(CASE WHEN rn % 2 = 1 THEN seed END) AS seed,
    MAX(CASE WHEN rn % 2 = 0 THEN seed END) AS range
    FROM (
        SELECT seed, ROW_NUMBER() OVER () AS rn
        FROM seeds
    ) sub
    GROUP BY (rn + 1) / 2:



-- ________________________________________________________

CREATE TABLE day05.mapping AS
    SELECT
        section_number as mapping_number,
        int8range( source_start,
                   source_start + range,
                   '[)'
        ) as range,
        destination_start - source_start as delta
    FROM day05.input_section,
        LATERAL (
            SELECT
                parts[1]::BIGINT AS destination_start,
                parts[2]::BIGINT AS source_start,
                parts[3]::BIGINT AS range
            FROM regexp_split_to_array(line, '\s+') as parts
    )
    WHERE section_number > 1 AND NOT is_section_header;


create function day05.apply_mappings(n bigint, mappings day05.mapping[], seed_number bigint) returns bigint
  return coalesce(
    (
      select coalesce(n, seed_number) + mapping.delta
      from unnest(mappings) as mapping
      where mapping.range @> coalesce(n, seed_number)
    ),
    n,
    seed_number
  );

create aggregate day05.apply_mappings (day05.mapping[], bigint) (
    sfunc = day05.apply_mappings,
    stype = bigint
);

-- Computes the location for each seed by applying all mappings to each seed
-- number.
create table day05.seed_location as
select seed, day05.apply_mappings(mappings, seed order by mapping_number) as location
from
  day05.seeds,
  (
    select
      mapping_number,
      array_agg(mapping.*) as mappings
    from day05.mapping
    group by mapping_number
  ) as _
group by seed;

-- Finally, select the lowest location.
select min(location) from day05.seed_location;