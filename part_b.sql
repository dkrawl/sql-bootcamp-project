-- Део Б - извештај о сезони 2024/25
-- Управа лиге тражи кратак извештај о сезони 2024/25. Предајете два фајла: извештај у формату по
-- избору (Markdown, Txt или PDF) и part_b.sql са свим упитима које сте користили. За сваки
-- одељак у извештају дајте малу табелу или неколико бројева, и реченицу или две шта ти бројеви
-- значе.
-- 1. Преглед сезоне: број утакмица и голова, просечан број голова по утакмици, удео победа
-- домаћина, нерешених и победа гостију.
-- 2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у
-- сваком месецу. Који месец се издваја?
-- 3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и
-- утакмица без публике.
-- 4. Судије: за сваког судију број утакмица и картони по утакмици.
-- 5. Играчи: пет најбољих стрелаца и пет најбољих асистената.
-- 6. Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица
-- чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без
-- тренера), са упитима који их проналазе.

select
    count(*) as matches,
    sum(home_goals + away_goals) as total_goals,
    round(avg(home_goals + away_goals), 2) as avg_goals
from matches
where status = 'played'
and season = '2024/25';

-- Ukupan broj odigranih utakmica je 380, ukupan broj golova je 1092 a prosecan
-- broj golova po utakmici je 2.87.

with results as (
select
    case
        when home_goals > away_goals
        then 'home_win'
        when home_goals = away_goals
        then 'draw'
        when home_goals < away_goals
        then 'away_win'
        else 'uknown'
    end as result
from matches
where status = 'played' and season = '2024/25'
)
select
    round(100.0 * sum(
        case
            when result = 'home_win'
            then 1
            else 0
        end
    ) / count(*), 2) as home_win_pct,
    round(100.0 * sum(
        case
            when result = 'draw'
            then 1
            else 0
        end
    ) / count(*), 2) as draw_pct,
    round(100.0 * sum(
        case
            when result = 'away_win'
            then 1
            else 0
        end
    ) / count(*), 2) as away_win_pct
from results;

-- Udeo pobeda domacina je 41.32%, udeo neresenih utakmica je 25% a
-- udeo pobeda gostiju je 33.68%

-- 2. По месецима: број утакмица и голова по месецима, и просечан број голова по утакмици у
-- сваком месецу. Који месец се издваја?

select
    month(kickoff_ts) as month_played,
    count(*) as num_matches,
    sum(home_goals + away_goals) as goals,
    round(avg(home_goals + away_goals), 2) as avg_goals
from matches
where status = 'played'
and season = '2024/25'
group by month_played
order by avg_goals desc;

-- Izdvaja se avgust mesec kada je odigran najmanji broj utakmica (28)
-- a postignut je najveci broj golova po mecu (3.54).


-- 3. Публика: просечна посета и попуњеност по стадиону; утакмице без податка о посети и
-- утакмица без публике.

select
    s.stadium_name,
    s.capacity,
    round(avg(m.attendance), 0) as avg_attendance,
    round(100.0 * avg(m.attendance) / s.capacity, 2) as attendance_rate
from matches m
join stadiums s
    on m.stadium_id = s.stadium_id
where m.status = 'played'
and m.season = '2024/25'
group by s.stadium_name, s.capacity;

-- Utakmice bez podatka o poseti: 9

select
    count(*) as num_matches
from matches m
join stadiums s
    on m.stadium_id = s.stadium_id
where m.attendance is null
and m.season = '2024/25';

-- Utakmice bez publike: 0

select
    count(*) as num_matches
from matches m
join stadiums s
    on m.stadium_id = s.stadium_id
where m.attendance = 0
and m.season = '2024/25';


-- 4. Судије: за сваког судију број утакмица и картони по утакмици.

with refs as (
select
    m.match_id,
    r.referee_id,
    r.referee_name,
    e.event_type
from matches m
left join match_events e
    on m.match_id = e.match_id
join referees r
    on m.referee_id = r.referee_id
where m.season = '2024/25'
)
select
    referee_name,
    count(distinct match_id) as num_matches,
    sum(
        case
            when event_type in ('yellow_card', 'second_yellow', 'red_card')
            then 1
            else 0
        end
    ) as num_cards,
    sum(
        case
            when event_type in ('yellow_card', 'second_yellow', 'red_card')
            then 1
            else 0
        end
    ) / count(distinct match_id) as cards_per_match
from refs
group by referee_id, referee_name;


-- 5. Играчи: пет најбољих стрелаца и пет најбољих асистената.

-- 5 najboljih strelaca

with players as (
select
    e.player_id,
    p.first_name,
    p.last_name,
    e.event_type,
    e.related_player_id
from matches m
left join match_events e
    on m.match_id = e.match_id
join players p
    on e.player_id = p.player_id
where m.season = '2024/25'
    and e.event_type in ('goal', 'penalty_goal')
)
select
    player_id,
    first_name,
    last_name,
    sum(
        case when
            event_type in ('goal', 'penalty_goal')
            then 1
            else 0
        end
    ) as goals
from players
group by player_id, first_name, last_name
order by goals desc
limit 5;


-- 5 najboljih asistenata (koristio sam rank()):

with players as (
select
    e.related_player_id as player_id,
    p.first_name,
    p.last_name,
    e.event_type
from matches m
left join match_events e
    on m.match_id = e.match_id
join players p
    on e.related_player_id = p.player_id
where m.season = '2024/25'
    and e.event_type in ('goal', 'penalty_goal')
    and e.related_player_id is not null
)
select
    player_id,
    first_name,
    last_name,
    count(*) as assists,
    rank() over(order by count(*) desc) as rnk
from players
group by player_id, first_name, last_name
qualify rnk <= 5;


-- 6. Квалитет података: бар два проблема на која сте наишли у подацима (на пример утакмица
-- чији резултат се не слаже са догађајима, догађаји са непостојећим играчем, дан без
-- тренера), са упитима који их проналазе


select *
from match_events e
left join players p
    on e.player_id = p.player_id
where e.player_id is not null
    and p.player_id is null;


-- U tabeli match_events postoje događaji čiji player_id ne postoji u tabeli players


with missing_events as (
select
    m.match_id,
    m.home_goals,
    m.away_goals,
    e.event_type
from matches m
left join match_events e
    on m.match_id = e.match_id
    and e.event_type in ('goal', 'penalty_goal')
where m.season = '2024/25'
    and m.status = 'played'
)
select *
from missing_events
where event_type is null
    and (home_goals > 0 or away_goals > 0);

-- U sezoni postoje zabelezni mecevi gde su padali golovi
-- i gde je event_type nezabelezen (null)
