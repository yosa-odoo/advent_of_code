DROP SCHEMA IF EXISTS day03 CASCADE;
CREATE SCHEMA day03;

CREATE TABLE day03.records (
    engine_text TEXT
);

\COPY day03.records(game_info) FROM 'input.txt';