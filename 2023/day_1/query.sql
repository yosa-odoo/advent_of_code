-- ########################################################################
-- PART 1
DROP SCHEMA IF EXISTS day01 CASCADE;
CREATE SCHEMA day01;

CREATE TABLE day01.text (
    line_text TEXT
);

\copy day01.text(line_text) FROM 'input.csv' WITH CSV;

-- SELECT * FROM day01.text; -- just to test the result

WITH matched_digits AS (
    SELECT
        line_text,
        -- regexp_substr only available as of psql 15;
        -- similar to regexp_match but returns the substring or NULL
        -- we still need to cast the substring
        regexp_substr(line_text, '[0-9]')::INTEGER as first_digit,
        regexp_substr(reverse(line_text), '[0-9]')::INTEGER as last_digit
    FROM day01.text
)

SELECT
    SUM(first_digit * 10 + last_digit) as solution
FROM matched_digits;

-- ########################################################################
-- PART 2

-- SELECT * FROM day01.text;

WITH digits_map AS (
    SELECT * FROM (VALUES
        ('one', 1), ('two', 2), ('three', 3), ('four', 4),
        ('five', 5), ('six', 6), ('seven', 7), ('eight', 8),
        ('nine', 9)
    ) AS mapping (word, digit) -- mapping is not command
),
    extracted_digits AS (
        SELECT
            line_text,
            regexp_substr(line_text, '(one|two|three|four|five|six|seven|eight|nine)|[0-9]') as first_digit_text,
            reverse(regexp_substr(reverse(line_text), '(enin|thgie|neves|xis|evif|ruof|eerht|owt|eno)|[0-9]')) as last_digit_text
        FROM day01.text
),
    mapped_digits AS (
    SELECT
        line_text,
        COALESCE(dm1.digit, ed.first_digit_text::INTEGER) AS first_digit,
        COALESCE(dm2.digit, ed.last_digit_text::INTEGER) AS last_digit
    FROM extracted_digits ed
    LEFT JOIN digits_map dm1 ON ed.first_digit_text = dm1.word
    LEFT JOIN digits_map dm2 ON ed.last_digit_text = dm2.word
    )

SELECT
    SUM(first_digit * 10 + last_digit) as solution
FROM mapped_digits;


-- ########################################################################
-- Visualisation of double LEFT JOIN (as asked) and why a OR would not work
WITH digits_map AS (
    SELECT * FROM (VALUES
        ('one', 1), ('two', 2), ('three', 3), ('four', 4),
        ('five', 5), ('six', 6), ('seven', 7), ('eight', 8),
        ('nine', 9)
    ) AS mapping (word, digit) -- mapping is not command
),
    extracted_digits AS (
        SELECT
            line_text,
            regexp_substr(line_text, '(one|two|three|four|five|six|seven|eight|nine)|[0-9]') as first_digit_text,
            reverse(regexp_substr(reverse(line_text), '(enin|thgie|neves|xis|evif|ruof|eerht|owt|eno)|[0-9]')) as last_digit_text
        FROM day01.text
)
    SELECT
        line_text,
        dm1.digit,
        ed.first_digit_text,
        dm2.digit,
        ed.last_digit_text
    FROM extracted_digits ed
    LEFT JOIN digits_map dm1 ON ed.first_digit_text = dm1.word
    LEFT JOIN digits_map dm2 ON ed.last_digit_text = dm2.word
--                        line_text                       | digit | first_digit_text | digit | last_digit_text
-- -------------------------------------------------------+-------+------------------+-------+-----------------
--  9vxfg                                                 |       | 9                |       | 9
--  19qdlpmdrxone7sevennine                               |       | 1                |     9 | nine
--  1dzntwofour9nineffck                                  |       | 1                |     9 | nine
--  7bx8hpldgzqjheight                                    |       | 7                |     8 | eight
--  joneseven2sseven64chvczzn                             |     1 | one              |       | 4
--  seven82683                                            |     7 | seven            |       | 3
--  7onefour1eighttwo5three                               |       | 7                |     3 | three
--  8lmsk871eight7                                        |       | 8                |       | 7
--  ninefivefive2nine5ntvscdfdsmvqgcbxxxt                 |     9 | nine             |       | 5
--  onepx6hbgdssfivexs                                    |     1 | one              |     5 | five
--  cdtjprrbvkftgtwo397seven                              |     2 | two              |     7 | seven
--  2eightsix16                                           |       | 2                |       | 6
--  41pqdmfvptwo                                          |       | 4                |     2 | two

-- Use of OR will take the first matching occurence defining for first and last the same digit

WITH digits_map AS (
    SELECT * FROM (VALUES
        ('one', 1), ('two', 2), ('three', 3), ('four', 4),
        ('five', 5), ('six', 6), ('seven', 7), ('eight', 8),
        ('nine', 9)
    ) AS mapping (word, digit) -- mapping is not command
),
    extracted_digits AS (
        SELECT
            line_text,
            regexp_substr(line_text, '(one|two|three|four|five|six|seven|eight|nine)|[0-9]') as first_digit_text,
            reverse(regexp_substr(reverse(line_text), '(enin|thgie|neves|xis|evif|ruof|eerht|owt|eno)|[0-9]')) as last_digit_text
        FROM day01.text
)
    SELECT
        line_text,
        dm.digit,
        ed.first_digit_text,
        dm.digit,
        ed.last_digit_text
    FROM extracted_digits ed
    LEFT JOIN digits_map dm
        ON ed.first_digit_text = dm.word
        OR ed.last_digit_text = dm.word

--                        line_text                       | digit | first_digit_text | digit | last_digit_text
-- -------------------------------------------------------+-------+------------------+-------+-----------------
--  9vxfg                                                 |       | 9                |       | 9
--  19qdlpmdrxone7sevennine                               |     9 | 1                |     9 | nine
--  1dzntwofour9nineffck                                  |     9 | 1                |     9 | nine
--  7bx8hpldgzqjheight                                    |     8 | 7                |     8 | eight
--  joneseven2sseven64chvczzn                             |     1 | one              |     1 | 4
--  seven82683                                            |     7 | seven            |     7 | 3
--  7onefour1eighttwo5three                               |     3 | 7                |     3 | three
--  8lmsk871eight7                                        |       | 8                |       | 7
--  ninefivefive2nine5ntvscdfdsmvqgcbxxxt                 |     9 | nine             |     9 | 5
--  onepx6hbgdssfivexs                                    |     1 | one              |     1 | five
--  onepx6hbgdssfivexs                                    |     5 | one              |     5 | five
--  cdtjprrbvkftgtwo397seven                              |     2 | two              |     2 | seven
--  cdtjprrbvkftgtwo397seven                              |     7 | two              |     7 | seven
