-- ######################### ITERATION 3

-- Expected:
-- .........9...............23................. -> seed
-- .....................20...........30......... -> map_1_1 delta=-8
-- ..........10.........20.................... -> map_1_2 delta=+2

-- [9, 10), 0       -> [9, 10)
-- [10, 20), 2 	    -> [12, 22)
-- [20, 23), -8     -> [12, 15)
--
--
-- Result
-- ("[9,10)",0),
-- ("[12,22)",2),
-- ("(,)",0),
-- ("[12,15)",-8),
-- ("[9,10)",0),
-- ("[12,22)",2),
-- ("(,)",0),
-- ("[12,15)",-8)}

DROP TABLE IF EXISTS seed_range_table;
DROP TABLE IF EXISTS mapping_range;
DROP FUNCTION IF EXISTS apply_mappings_ranges;
DROP TYPE IF EXISTS mapping;
DROP TYPE IF EXISTS seed_range;


CREATE TYPE seed_range AS (
    range int8range,
    delta BIGINT
);
CREATE TYPE mapping AS (
    mapping_number BIGINT,
    range int8range,
    delta BIGINT
);

CREATE FUNCTION apply_mappings_ranges(
    mappings mapping[],
    seed_ranges seed_range[]
) RETURNS seed_range[] AS $$
DECLARE
    result seed_range[] := '{}';
    mapping mapping;
    current_ranges seed_range[];
    new_ranges seed_range[];
    left_range seed_range;
    intersect_range seed_range;
    right_range seed_range;
    final_range seed_range;
    seed_range seed_range;
BEGIN
    current_ranges := seed_ranges;

    FOREACH mapping IN ARRAY mappings LOOP
        new_ranges := '{}'; -- Reset new_ranges for each mapping

        FOREACH seed_range IN ARRAY current_ranges LOOP
            left_range := CASE
                WHEN lower(seed_range.range) <= lower(mapping.range) THEN
                    ROW(int8range(lower(seed_range.range), LEAST(upper(seed_range.range), lower(mapping.range))), seed_range.delta)::seed_range
                ELSE NULL
            END;

            intersect_range := CASE
                WHEN seed_range.range && mapping.range THEN
                    ROW(int8range(GREATEST(lower(seed_range.range), lower(mapping.range)),
                                  LEAST(upper(seed_range.range), upper(mapping.range))),
                        seed_range.delta + mapping.delta)::seed_range
                ELSE NULL
            END;

            right_range := CASE
                WHEN upper(seed_range.range) >= upper(mapping.range) THEN
                    ROW(int8range(GREATEST(lower(seed_range.range), upper(mapping.range)), upper(seed_range.range)),
                        seed_range.delta)::seed_range
                ELSE NULL
            END;
            IF left_range IS NOT NULL THEN
                new_ranges := array_append(new_ranges, left_range);
            END IF;

            IF intersect_range IS NOT NULL THEN
                new_ranges := array_append(new_ranges, intersect_range);
            END IF;

            IF right_range IS NOT NULL THEN
                new_ranges := array_append(new_ranges, right_range);
            END IF;
        END LOOP;

        current_ranges := new_ranges;
    END LOOP;

    FOREACH final_range IN ARRAY current_ranges LOOP
        final_range.range := int8range(
            lower(final_range.range) + final_range.delta,
            upper(final_range.range) + final_range.delta
        );
        result := array_append(result, final_range);
    END LOOP;

    RETURN result;
END;
$$ LANGUAGE plpgsql;


CREATE TABLE seed_range_table AS
SELECT
    unnest(ARRAY[
        ROW('[9,23)'::int8range, 0)::seed_range
        ]
    ) AS seed_range;

CREATE TABLE mapping_range AS
SELECT
    unnest(ARRAY[
        ROW(1, '[20,30)'::int8range, -8)::mapping,
        ROW(1, '[10,20)'::int8range, 2::bigint)::mapping
        ]
    ) AS source_range;

SELECT
    apply_mappings_ranges(
        array_agg(mapping_range.source_range),
        array_agg(seed_range_table.seed_range)
    )
FROM mapping_range, seed_range_table;



-- #########################" ITERATION 2

DROP TABLE IF EXISTS mapping;
DROP TABLE IF EXISTS seed_range;
DROP TYPE IF EXISTS map;

CREATE TYPE map AS (
    range int8range,
    delta BIGINT
);
CREATE TABLE seed_range AS
SELECT
    unnest(ARRAY[
        '[79,93)'::int8range
        ]
    ) AS seed_range;
CREATE TABLE mapping AS
SELECT
    unnest(ARRAY[
        ROW('[0,10)'::int8range, 2)::map,
        ROW('[12,15)'::int8range, 2)::map,
        ROW('[15,30)'::int8range, 25)::map
        ]
    ) AS source_range;


WITH split_parts AS (
    SELECT
        (m.source_range).delta as delta,
        -- The LEFT part
        CASE
            WHEN lower(seed_range) <= lower((m.source_range).range) THEN
                int8range(lower(seed_range), LEAST(upper(seed_range), lower((m.source_range).range)))
            ELSE NULL
        END AS left_range,
        -- The INTERSECT part
        CASE
            WHEN seed_range && (m.source_range).range THEN
        int8range(GREATEST(lower(seed_range), lower((m.source_range).range)),
                  LEAST(upper(seed_range), upper((m.source_range).range)))
            ELSE NULL
        END AS intersect_range,
        -- The RIGHT part
        CASE
            WHEN upper(seed_range) >= upper((m.source_range).range) THEN
                int8range(GREATEST(lower(seed_range), upper((m.source_range).range)), upper(seed_range))
            ELSE NULL
        END AS right_range
    FROM seed_range
    CROSS JOIN mapping m
),
    split_parts_delta AS (
        SELECT
            left_range,
            CASE
                WHEN intersect_range IS NOT NULL THEN
                    int8range((lower(intersect_range) + delta), (upper(intersect_range) + delta))
            END  AS intersect_range,
            right_range
        FROM split_parts

)
SELECT range_agg(range_part) AS multirange_result
-- SELECT *
FROM split_parts_delta
CROSS JOIN LATERAL (VALUES
                        (left_range),
                        (intersect_range),
                        (right_range)
    ) AS vals(range_part)
WHERE range_part IS NOT NULL AND NOT isempty(range_part);


-- ######################### ITERATION 1

DROP TYPE IF EXISTS map;
CREATE TYPE map AS (
    range int8range,
    delta BIGINT
);

DROP TABLE IF EXISTS seed_range;
CREATE TABLE seed_range AS
SELECT
    unnest(ARRAY[
        '[10,20)'::int8range
        ]
    ) AS seed_range;

DROP TABLE IF EXISTS mapping;
CREATE TABLE mapping AS
SELECT
    unnest(ARRAY[
        '[20,30)'::int8range,
        '[15,30)'::int8range,
        '[12,17)'::int8range,
        '[0,15)'::int8range,
        '[0,9)'::int8range
        ]
    ) AS source_range
;

WITH split_parts AS (
    SELECT
        -- The LEFT part
        CASE
            WHEN lower(seed_range) <= lower(source_range) THEN
                int8range(lower(seed_range), LEAST(upper(seed_range), lower(source_range)))
            ELSE NULL
        END AS left_range,
        -- The INTERSECT part
        CASE
            WHEN seed_range && source_range THEN
        int8range(GREATEST(lower(seed_range), lower(source_range)),
                  LEAST(upper(seed_range), upper(source_range)))
            ELSE NULL
        END AS intersect_range,
        -- The RIGHT part
        CASE
            WHEN upper(seed_range) >= upper(source_range) THEN
                int8range(GREATEST(lower(seed_range), upper(source_range)), upper(seed_range))
            ELSE NULL
        END AS right_range
    FROM seed_range
    CROSS JOIN mapping
)
SELECT range_agg(range_part) AS multirange_result
FROM split_parts
CROSS JOIN LATERAL (VALUES (left_range), (intersect_range), (right_range)) AS vals(range_part)
WHERE range_part IS NOT NULL;