select campaign_key, total_visits_planned, visits_total, visits_completed
from {{ ref('fct_campaign_progress') }}
where total_visits_planned < 0
    or visits_completed > visits_total
    or visits_incidence > visits_completed
