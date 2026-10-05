-- statuses add up to recorded
select campaign_id, visit_month, visits_recorded
from {{ ref('mart_campaign_performance') }}
where visits_ok + visits_incident + visits_info + visits_not_done + visits_unknown <> visits_recorded
