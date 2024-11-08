DROP SCHEMA IF EXISTS day04 CASCADE;
CREATE SCHEMA day04;

CREATE TABLE day04.raw_input (line TEXT);
\copy day04.raw_input FROM 'input.txt';

CREATE TABLE day04.input AS
SELECT
    SPLIT_PART(line, ':', 1) AS card,
    TRIM(SPLIT_PART(SPLIT_PART(line, ':', 2), '|', 1)) AS left_numbers,
    TRIM(SPLIT_PART(SPLIT_PART(line, ':', 2), '|', 2)) AS right_numbers
FROM
    day04.raw_input;

CREATE TABLE day04.left_nb AS
SELECT
    card,
    unnest(regexp_split_to_array(left_numbers, '\s+')) as value
FROM day04.input;

CREATE TABLE day04.right_nb AS
SELECT
    card,
    unnest(regexp_split_to_array(right_numbers, '\s+')) as value
FROM day04.input;

CREATE TABLE day04.points_per_card AS
    SELECT
        l.card,
        2 ^ (COUNT(l.card) - 1) as points
    FROM day04.left_nb AS l
    INNER JOIN day04.right_nb AS r
        ON l.value = r.value
        AND l.card = r.card
    GROUP BY l.card;

SELECT SUM(points) FROM day04.points_per_card;