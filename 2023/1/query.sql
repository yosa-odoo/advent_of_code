CREATE TABLE d1_text (
    line_text TEXT
);

\copy d1_text(line_text) FROM 'line_text.csv' WITH CSV;

SELECT * FROM d1_text; -- just to test the result

WITH matched_digits AS (
    SELECT
        line_text,
        -- regexp_substr only available as of psql 15;
        -- similar to regexp_match but returns the substring or NULL
        -- we still need to cast the substring
        regexp_substr(line_text, '[0-9]')::INTEGER as first_digit,
        regexp_substr(reverse(line_text), '[0-9]')::INTEGER as last_digit
    FROM d1_text
)

SELECT
    SUM(first_digit * 10 + last_digit) as solution
FROM matched_digits;