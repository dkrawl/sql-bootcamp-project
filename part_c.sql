-- Део В - прозорске функције
-- Свако питање мора да користи бар једну прозорску функцију.
-- 1. Колики удео у укупном броју голова лиге у сезони 2024/25 има сваки клуб? Ко има највећи
-- удео?


with tm as (
select
    home_team_id as team_id,
    home_goals as goals
from matches
where season = '2024/25'
union all
select
    away_team_id as team_id,
    away_goals as goals
from matches
where season = '2024/25'
),
team_goals as (
select
    tm.team_id as club_id,
    t.team_name as club_name,
    tm.goals as club_goals
from tm tm
join teams t
    on t.team_id = tm.team_id
),
team_total as (
select
    club_id,
    club_name,
    sum(club_goals) as total_goals
from team_goals
group by club_id, club_name
)
select
    club_id,
    club_name,
    total_goals,
    sum(total_goals) over() as all_goals,
    100.0 * total_goals / sum(total_goals) over() as goal_pct
from team_total
order by goal_pct desc;


-- 2. Која су три стадиона са највећом просечном посетом у сезони 2024/25?

with st as (
select
    s.stadium_name,
    m.attendance,
    avg(m.attendance) over(partition by s.stadium_id) as avg_att
from matches m
join stadiums s
    on m.stadium_id = s.stadium_id
where status = 'played'
    and season = '2024/25'
),
avgs as (
select distinct
    stadium_name,
    avg_att
from st
)
select
    stadium_name,
    dense_rank() over(order by avg_att desc) as rnk
from avgs
qualify rnk <= 3;


-- 3. За сваки клуб, ко је дао последњи гол клуба у сезони 2024/25 и када? Који клуб је последњи
-- гол дао најраније?

select
    m.kickoff_ts,
    e.team_id,
    t.team_name,
    e.event_type,
    e.player_id,
    p.first_name,
    p.last_name,
    row_number() over(
        partition by e.team_id order by m.kickoff_ts desc
        ) as rnk
from matches m
join match_events e
    on m.match_id = e.match_id
join players p
    on p.player_id = e.player_id
join teams t
    on t.team_id = e.team_id
where e.event_type in ('goal', 'penalty_goal')
    and m.season = '2024/25'
qualify rnk = 1
order by kickoff_ts asc;


-- 4. За домаће утакмице клуба Northport United у сезони 2024/25 прикажите посету и промену у
-- односу на претходну домаћу утакмицу. Где је највећи пад?

with club as (
    select team_id, team_name from teams where team_name = 'Northport United'
),
att as (
select
    c.team_name,
    m.match_id,
    m.kickoff_ts,
    m.home_team_id,
    m.attendance,
    lag(m.attendance) over(order by m.kickoff_ts, m.match_id) as prev_attendance,
    m.attendance - lag(m.attendance) over(order by m.kickoff_ts, m.match_id) as attendance_diff
from matches m
join club c
    on c.team_id = m.home_team_id
where m.season = '2024/25'
)
select
    team_name,
    attendance,
    prev_attendance,
    attendance_diff
from att
where attendance_diff is not null
order by attendance_diff asc;


-- 5. Пратите бодове клуба Northport City утакмицу по утакмицу у сезони 2024/25. У којој
-- утакмици по реду и ког датума је прешао 50 бодова?

with club as (
    select team_id, team_name from teams where team_name = 'Northport United'
),
tm as (
    select
        match_id,
        kickoff_ts,
        'home' as venue,
        home_team_id as team_id,
        home_goals as goals_for,
        away_goals as goals_against
    from matches m
    inner join club c
        on c.team_id = m.home_team_id
    where season = '2024/25'
    union all
    select
        match_id,
        kickoff_ts,
        'away' as venue,
        away_team_id as team_id,
        home_goals as goals_against,
        away_goals as goals_for
    from matches m
    inner join club c
        on c.team_id = m.away_team_id
    where season = '2024/25'
),
points as (
select
    match_id,
    team_id,
    kickoff_ts,
    case
        when goals_for > goals_against
        then 3
        when goals_for = goals_against
        then 1
        else 0
    end as points
from tm
)
select
    match_id,
    team_id,
    kickoff_ts,
    points,
    sum(points) over(order by kickoff_ts, match_id) as cumulative_points,
    row_number() over(order by kickoff_ts, match_id) as match_number
from points
qualify cumulative_points > 50;
