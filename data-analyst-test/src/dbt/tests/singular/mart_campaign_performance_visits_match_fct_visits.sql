-- mart visits equal fact visits
select check_name, mart_visits, fct_visits
from (
    select
        'campaign totals' as check_name,
        (select sum(visits_recorded) from {{ ref('mart_campaign_performance') }} where is_campaign_total) as mart_visits,
        (select count(*) from {{ ref('fct_visits') }}) as fct_visits
    union all
    select
        'dated months' as check_name,
        (select sum(visits_recorded) from {{ ref('mart_campaign_performance') }} where not is_campaign_total) as mart_visits,
        (select count(*) from {{ ref('fct_visits') }} where visit_date is not null) as fct_visits
)
where mart_visits is distinct from fct_visits
