-- Део Г - моделирање: звезда за дисциплину
-- Управа лиге жели да анализира картоне: по судији, клубу, играчу и датуму. Направите звездасту
-- шему.
-- Табела Шта садржи
-- dim_team Сви клубови из teams
-- dim_date Календар - као на часу
-- dim_player Сви играчи из players, плус непознати члан са player_id = -1
-- dim_referee Сви судије из referees
-- fact_card Један ред по картону (yellow_card, second_yellow, red_card) из
-- match_events
-- У fact_card ставите: event_id, match_id, date_key, team_id, player_id, referee_id и врсту
-- картона. Догађаји са играчем кога нема у players добијају player_id = -1.
-- 1. У part_d.sql направите и напуните табеле
-- 2. Упитом покажите да fact_card има исто редова колико има картонских догађаја
-- 3. Колико картона има player_id = -1?
-- 4. У README.md, у пар реченица опишите модел: шта је један ред у fact_card, који су кључеви
-- (везе) и зашто мислите да картони имају своју табелу чињеница.


-- Tabela dim_team:

create or replace table dim_team as
select
    team_id,
    team_name,
    short_name,
    city,
    founded_year,
    stadium_id
from teams;

-- Tabela dim_date:


CREATE OR REPLACE TABLE dim_date AS
SELECT CAST(DATE_FORMAT(d, 'yyyyMMdd') AS INT) AS date_key,
       d                                       AS full_date,
       DATE_FORMAT(d, 'EEEE')                  AS weekday_name,
       DAYOFWEEK(d) IN (1, 7)                  AS is_weekend,
       CASE WHEN MONTH(d) >= 7 THEN CONCAT(YEAR(d), '/', SUBSTRING(CAST(YEAR(d) + 1 AS STRING), 3, 2))
            ELSE CONCAT(YEAR(d) - 1, '/', SUBSTRING(CAST(YEAR(d) AS STRING), 3, 2))
       END                                     AS season
FROM (SELECT EXPLODE(SEQUENCE(DATE'2023-07-01', DATE'2025-06-30', INTERVAL 1 DAY)) AS d);

-- Tabela dim_player:

create or replace table dim_player as
select
    player_id,
    first_name,
    last_name
from players
union all
select
    -1 AS player_id,
    'Unknown' AS first_name,
    'Unknown' AS last_name;

select * from dim_player;


-- Tabela dim_referee:

create or replace table dim_referee as
select
    referee_id,
    referee_name,
    nationality,
    debut_season
from referees;


-- Tabela fact_card:

create or replace table fact_card as
select
    e.event_id,
    e.match_id,
    cast(date_format(m.kickoff_ts, 'yyyyMMdd') as int) AS date_key,
    e.team_id,
    p.player_id,
    m.referee_id,
    e.event_type
from match_events e
join matches m
    on e.match_id = m.match_id
left join dim_player p
    on e.player_id = p.player_id
where e.event_type in ('yellow_card', 'second_yellow', 'red_card');


-- 2. Упитом покажите да fact_card има исто редова колико има картонских догађаја

select
	count(*) as num_row_cards
from fact_card;


-- 3. Колико картона има player_id = -1?

-- Player id -1 ne postoji u fact_card tabeli na nacin na koji sam radio join.

select
    event_type
from fact_card
where player_id = -1;
