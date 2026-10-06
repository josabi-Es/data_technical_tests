with all_dates as (
    select visit_date as day from {{ ref('stg_visits') }}
    union all
    select campaign_start_date from {{ ref('stg_campaigns') }}
    union all
    select campaign_end_date from {{ ref('stg_campaigns') }}
    union all
    select route_start_date from {{ ref('stg_routes') }}
    union all
    select route_end_date from {{ ref('stg_routes') }}
),

bounds as (
    select min(day) as first_day, max(day) as last_day
    from all_dates
),

spine as (
    select generate_series(first_day, last_day, interval '1 day')::date as date_day
    from bounds
)

select
    to_char(date_day, 'YYYYMMDD')::integer as date_key,
    date_day,
    extract(year from date_day)::integer as year,
    extract(month from date_day)::integer as month,
    extract(week from date_day)::integer as week,
    extract(isodow from date_day)::integer as day_of_week,
    extract(isodow from date_day) >= 6 as is_weekend
from spine

union all

{# unknown row #}
select -1, null::date, null::integer, null::integer, null::integer, null::integer, false
