\include_relative 'common.sql'

WITH RECURSIVE recursively_won_cards AS (
    SELECT
        card,
        points,
        1 AS copies
    FROM day04.points_per_card

    UNION ALL

    SELECT
        c.card + i AS card,
        m.points,
        c.copies AS copies
    FROM recursively_won_cards AS c
    CROSS JOIN generate_series(1, c.points) AS i
    JOIN day04.points_per_card AS m
        ON c.card + i = m.card
    WHERE c.points > 0
)

SELECT
    SUM(copies) AS total_copies
FROM recursively_won_cards
;

--
-- Our initial non-recursive term will be
-- card | points | copies
-- ------+--------+--------
--     1 |      4 |      1      -> iteration 1
--     2 |      2 |      1
--     3 |      2 |      1
--     4 |      1 |      1
--     5 |      0 |      1
--     6 |      0 |      1
--
-- ITERATION 1
-- select * from (VALUES (1, 4, 1)) as t(card,points,copies);
--  cte: recursively_won_cards
--  card | points | copies
-- ------+--------+--------
--     1 |      4 |      1
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
--
