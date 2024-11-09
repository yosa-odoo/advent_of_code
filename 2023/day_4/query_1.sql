\include_relative 'common.sql'

WITH points_power AS (
    SELECT
    card,
    CASE
        WHEN points > 0 THEN POWER(2, points - 1)
        ELSE 0
    END AS points
    FROM day04.points_per_card
)

SELECT SUM(points) FROM points_power;
