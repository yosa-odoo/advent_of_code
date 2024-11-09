\include_relative 'common.sql'

-- New solution: but not really SQL-like (but faster)

DO $$
DECLARE
    max_card INT;
    row RECORD;
    new_copies INT[];
    total_sum INT := 0;
BEGIN
    SELECT MAX(card) INTO max_card FROM day04.points_per_card;
    new_copies := ARRAY_FILL(1, ARRAY[max_card]);

    FOR row IN SELECT * FROM day04.points_per_card LOOP
        for i in 1..row.points LOOP
            IF row.card + i <= max_card THEN
                new_copies[row.card + i] := new_copies[row.card + i]  + new_copies[row.card];
            END IF;
        END LOOP;
    END LOOP;

    FOR i IN 1..array_length(new_copies, 1) LOOP
        total_sum := total_sum + new_copies[i];
    END LOOP;

    RAISE NOTICE '%', total_sum;
END $$;

-- Initial Solution: really slow
-- Generate as many rows as there are cumulated points. That is, 9M+

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