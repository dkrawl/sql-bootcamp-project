-- Део А - питања о подацима
-- 1. Колико утакмица је одиграно у фебруару 2025?

select
    count(*) as match_cnt
from matches
where kickoff_ts >= '2025-02-01'
    and kickoff_ts < '2025-03-01';

-- 2. Који стадион има највећи капацитет, а који је највећи стадион неког клуба?

select
    stadium_name,
    max(capacity) as max_capacity
from stadiums
group by stadium_name
order by max_capacity desc
limit 1;

select
    t.team_name,
    s.stadium_name,
    max(s.capacity) as max_capacity
from stadiums s
inner join teams t
    on s.stadium_id = t.stadium_id
group by t.team_name, s.stadium_name
order by max_capacity desc
limit 1;

-- 3. Колико играча у лиги има српско држављанство (nationality = 'Serbia')?

select
    count(distinct player_id) as player_cnt
from players
where nationality = 'Serbia';

select * from players;

select
    first_name,
    last_name
from players
where nationality = 'Serbia';

-- 4. Колико утакмица је завршено резултатом 1:1?

select
    match_id,
    kickoff_ts,
    home_goals,
    away_goals
from matches
where home_goals = 1 and away_goals = 1;

select
    count(*) as matches_cnt
from matches
where home_goals = 1 and away_goals = 1;

-- 5. Колика је просечна посета по сезони?

select
    season,
    round(avg(attendance), 0) as avg_attendance
from matches
group by season;

-- 6. Колико голова је дато из пенала по сезони?

select
    m.season,
    count(e.match_id) as penalty_goals
from matches m
inner join match_events e
    on m.match_id = e.match_id
    and e.event_type = 'penalty_goal'
group by m.season;

-- 7. Колико различитих играча је дало бар један гол у сезони 2024/25?

select distinct event_type from match_events;

select
    count(distinct e.player_id) as player_cnt
from matches m
inner join match_events e
    on m.match_id = e.match_id
where e.event_type in ('goal', 'penalty_goal')
    and m.season = '2024/25';

-- 8. Који судија је највише пута судио утакмице клуба Northport United?

with club as (
    select team_id, team_name from teams where team_name = 'Northport United'
),
tm as (
    select
        match_id,
        referee_id,
        home_team_id as team_id
    from matches
    union all
    select
        match_id,
        referee_id,
        away_team_id as team_id
    from matches
)
select
    r.referee_name,
    count(r.referee_id) as ref_cnt
from tm t
join club c
    on c.team_id = t.team_id
join referees r
    on t.referee_id = r.referee_id
group by r.referee_name
order by ref_cnt desc
limit 1;


-- 9. Који судија је у сезони 2024/25 имао највећи удео утакмица у којима је досуђен бар један
-- пенал, дат или промашен?

with refs as (
select
    r.referee_id,
    r.referee_name as ref_name,
    case
        when e.event_type in ('penalty_miss', 'penalty_goal')
        then 1 else 0
    end as penalty
from matches m
left join match_events e
    on m.match_id = e.match_id
    and e.event_type in ('penalty_miss', 'penalty_goal')
join referees r
    on m.referee_id = r.referee_id
where m.season = '2024/25'
),
pen as (
select
    ref_name,
    sum(penalty) as penalties
from refs
group by ref_name
)
select
    ref_name,
    penalties,
    sum(penalties) over() as total_penalties,
    100.0 * penalties / sum(penalties) over() as avg_pen
from pen
order by avg_pen desc;


-- 10. Који тренер је освојио највише бодова у утакмицама у којима је његов тим губио на
-- полувремену? Рачунајте и домаће и гостујуће утакмице.


select *
from matches m
inner join teams ht
    on m.home_team_id = ht.team_id
inner join teams at
    on m.away_team_id = at.team_id
inner join manager_spells hm
    on m.home_team_id = hm.team_id
    and m.kickoff_ts >= hm.start_date
    and (m.kickoff_ts < hm.end_date or hm.end_date is null)
inner join manager_spells am
    on m.away_team_id = am.team_id
    and m.kickoff_ts >= am.start_date
    and (m.kickoff_ts < am.end_date or am.end_date is null);
