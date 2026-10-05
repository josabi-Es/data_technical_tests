select
    dc.client_name,
    dc.project_type,
    v.campaign_id,
    v.intervention_point_id,
    count(*) as visits_done
from {{ ref('fct_visits') }} as v
join {{ ref('dim_campaign') }} as dc on v.campaign_id = dc.campaign_id
where {{ is_done_status('v.visit_status') }}
group by dc.client_name, dc.project_type, v.campaign_id, v.intervention_point_id
