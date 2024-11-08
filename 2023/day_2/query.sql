DROP SCHEMA IF EXISTS day02 CASCADE;
CREATE SCHEMA day02;

CREATE TABLE day02.records (
    game_info TEXT
);

\COPY day02.records(game_info) FROM 'input.txt';

WITH parsed_games AS (
    SELECT
        regexp_replace(game_info, '^Game (\d+):.*$', '\1')::INTEGER AS game_id,
        regexp_split_to_array(
            regexp_replace(game_info, '^Game \d+: ', ''),
            '; '
        ) AS cube_reveals
    FROM day02.records
),
    split_games AS (
    SELECT
        pg.game_id,
        unnest(pg.cube_reveals) AS reveal
        FROM parsed_games pg
),
    colour_count AS (
    SELECT
        sg.game_id,
        COALESCE((regexp_match(sg.reveal, '(\d+) red'))[1]::INTEGER, 0) AS red_count,
        COALESCE((regexp_match(sg.reveal, '(\d+) green'))[1]::INTEGER, 0) AS green_count,
        COALESCE((regexp_match(sg.reveal, '(\d+) blue'))[1]::INTEGER, 0)  AS blue_count
     FROM split_games as sg

),
-- PART 1
--     filtered_games AS (
--         SELECT game_id
--         FROM colour_count
--         GROUP BY game_id
--         HAVING MAX(red_count) <= 12
--            AND MAX(green_count) <= 13
--            AND MAX(blue_count) <= 14
-- )
--
-- SELECT SUM(game_id)
-- FROM filtered_games;

-- PART 2
    fewest_needed AS (
        SELECT
            game_id,
            MAX(red_count) AS min_red_needed,
            MAX(green_count) AS min_green_needed,
            MAX(blue_count) AS min_blue_needed
        FROM colour_count
        GROUP BY game_id
)

SELECT SUM(min_red_needed * min_green_needed * min_blue_needed)
FROM fewest_needed;