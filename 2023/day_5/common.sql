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

CREATE FUNCTION day05.apply_mappings(
    n BIGINT,
    mappings day05.mapping[],
    seed_number BIGINT
)
RETURNS BIGINT
AS $$
BEGIN
    RETURN COALESCE(
        (
            SELECT COALESCE(n, seed_number) + mapping.delta
            FROM UNNEST(mappings) AS mapping
            WHERE mapping.range @> COALESCE(n, seed_number)
        ),
        n,
        seed_number
    );
END;
$$ LANGUAGE plpgsql;

CREATE AGGREGATE day05.apply_mappings (day05.mapping[], bigint) (
    sfunc = day05.apply_mappings,
    stype = bigint
);

