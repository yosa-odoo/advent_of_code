DROP SCHEMA IF EXISTS day04 CASCADE;
CREATE SCHEMA day04;

CREATE TABLE day04.raw_input (line TEXT);
\copy day04.raw_input FROM 'example.txt';

CREATE TABLE day04.input AS
SELECT
    ROW_NUMBER() over () as card,
    TRIM(SPLIT_PART(SPLIT_PART(line, ':', 2), '|', 1)) AS left_numbers,
    TRIM(SPLIT_PART(SPLIT_PART(line, ':', 2), '|', 2)) AS right_numbers
FROM
    day04.raw_input;

CREATE TABLE day04.points_per_card AS
SELECT
    p.card,
    CASE
        WHEN COUNT(DISTINCT matched_values.value) > 0
        THEN COUNT(DISTINCT matched_values.value)
        ELSE 0
    END AS points
FROM day04.input AS p
LEFT JOIN LATERAL (
    SELECT DISTINCT l.value
    FROM unnest(regexp_split_to_array(p.left_numbers, '\s+')) AS l(value)
    INNER JOIN unnest(regexp_split_to_array(p.right_numbers, '\s+')) AS r(value)
        ON l.value = r.value
) AS matched_values ON TRUE
GROUP BY p.card
ORDER BY p.card;
